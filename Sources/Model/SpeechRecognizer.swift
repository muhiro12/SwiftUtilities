//  SpeechRecognizer.swift
//  SwiftUtilities
//
//  Modern implementation for iOS 26+ using SpeechAnalyzer / SpeechTranscriber
//  NOTE: Package minimum should target iOS 26+. Info.plist needs NSSpeechRecognitionUsageDescription / NSMicrophoneUsageDescription.

import Foundation
import Speech
@preconcurrency import AVFAudio
import CoreMedia

@available(iOS 26, *)
public enum SpeechError: Error, CustomStringConvertible {
    case notAuthorized
    case analyzerUnavailable
    case noResult
    case cancelled
    case internalError(Error)
    public var description: String {
        switch self {
        case .notAuthorized: return "Speech recognition not authorized."
        case .analyzerUnavailable: return "SpeechAnalyzer not available."
        case .noResult: return "No speech result."
        case .cancelled: return "Recognition cancelled."
        case .internalError(let error): return "Error: \(error)"
        }
    }
}

private struct AudioSession {
    static func activate() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP])
        try s.setActive(true, options: [.notifyOthersOnDeactivation])
    }
    static func deactivate() { try? AVAudioSession.sharedInstance().setActive(false) }
}

// MARK: - Locale / Transcriber fallback helper
@available(iOS 26, *)
private enum TranscriberKind { case speech, dictation }

@available(iOS 26, *)
private func pickTranscriberLocale(_ requested: Locale) async -> (kind: TranscriberKind, locale: Locale) {
    // Exact match first
    if await SpeechTranscriber.supportedLocales.contains(requested) {
        return (.speech, requested)
    }
    if await DictationTranscriber.supportedLocales.contains(requested) {
        return (.dictation, requested)
    }

    // Try same language fallback in DictationTranscriber, then SpeechTranscriber
    let languageCode = requested.language.languageCode?.identifier
    if let code = languageCode {
        if let dictLang = await DictationTranscriber.supportedLocales.first(where: { $0.language.languageCode?.identifier == code }) {
            return (.dictation, dictLang)
        }
        if let speechLang = await SpeechTranscriber.supportedLocales.first(where: { $0.language.languageCode?.identifier == code }) {
            return (.speech, speechLang)
        }
    }

    // Last resort: English (widely available for dictation)
    return (.dictation, Locale(identifier: "en_US"))
}

// MARK: - Model availability / Asset management (WWDC'25 #277)
@available(iOS 26, *)
private func supported(locale: Locale) async -> Bool {
    let supported = await SpeechTranscriber.supportedLocales
    return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
}

@available(iOS 26, *)
private func installed(locale: Locale) async -> Bool {
    let installed = await Set(SpeechTranscriber.installedLocales)
    return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
}

@available(iOS 26, *)
private func ensureModel(for transcriber: SpeechTranscriber, locale: Locale) async throws {
    guard await supported(locale: locale) else {
        throw SpeechError.analyzerUnavailable
    }
    if await installed(locale: locale) { return }
    try await downloadIfNeeded(for: transcriber)
}

@available(iOS 26, *)
private func downloadIfNeeded(for module: SpeechTranscriber) async throws {
    if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
        try await request.downloadAndInstall()
    }
}

@available(iOS 26, *)
public func deallocateSpeechAssets() async {
    let allocated = await AssetInventory.allocatedLocales
    for locale in allocated { await AssetInventory.deallocate(locale: locale) }
}

@available(iOS 26, *)
public struct RecognitionStream: AsyncSequence {
    public typealias Element = String
    private let locale: Locale
    private let timeout: TimeInterval
    private let onDevice: Bool
    private let hint: SFSpeechRecognitionTaskHint
    public init(locale: Locale, timeout: TimeInterval, onDevice: Bool, hint: SFSpeechRecognitionTaskHint) {
        self.locale = locale
        self.timeout = timeout
        self.onDevice = onDevice
        self.hint = hint
    }
    public func makeAsyncIterator() -> Iterator { Iterator(locale: locale, timeout: timeout, onDevice: onDevice, hint: hint) }

    public struct Iterator: AsyncIteratorProtocol {
        public typealias Element = String

        private final class Box: @unchecked Sendable {
            var finished = false
            var audioEngine: AVAudioEngine?
            var analyzer: SpeechAnalyzer?
            var speechTranscriber: SpeechTranscriber?
            var dictationTranscriber: DictationTranscriber?
        }
        private var box: Box? = nil

        private let locale: Locale
        private let timeout: TimeInterval
        private let onDevice: Bool
        private let hint: SFSpeechRecognitionTaskHint

        public init(locale: Locale, timeout: TimeInterval, onDevice: Bool, hint: SFSpeechRecognitionTaskHint) {
            self.locale = locale; self.timeout = timeout; self.onDevice = onDevice; self.hint = hint
        }

        public mutating func next() async throws -> String? {
            if let b = box, b.finished { return nil }
            try AudioSession.activate()

            let b = box ?? Box(); box = b
            let choice = await pickTranscriberLocale(locale)

            // Build module according to locale decision
            switch choice.kind {
            case .speech:
                let t = SpeechTranscriber(
                    locale: choice.locale,
                    transcriptionOptions: [],
                    reportingOptions: [.volatileResults],
                    attributeOptions: [.audioTimeRange]
                )
                b.speechTranscriber = t
                // Ensure speech model presence per WWDC guidance
                try await ensureModel(for: t, locale: choice.locale)
                b.analyzer = SpeechAnalyzer(modules: [t])
            case .dictation:
                let t = DictationTranscriber(locale: choice.locale, preset: .progressiveShortDictation)
                b.dictationTranscriber = t
                b.analyzer = SpeechAnalyzer(modules: [t])
            }

            guard let analyzer = b.analyzer else { throw SpeechError.analyzerUnavailable }

            // Determine analyzer-preferred format and set up converter
            var modules: [any LocaleDependentSpeechModule] = []
            if let t = b.speechTranscriber { modules.append(t) }
            if let d = b.dictationTranscriber { modules.append(d) }
            let preferredFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules)

            let engine = AVAudioEngine(); b.audioEngine = engine
            let input = engine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)

            // Converter will be used only if formats differ
            let converter: AVAudioConverter?
            if let pf = preferredFormat, pf != inputFormat {
                converter = AVAudioConverter(from: inputFormat, to: pf)
            } else {
                converter = nil
            }

            let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
            try await analyzer.start(inputSequence: inputStream)

            input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
                if let converter, let pf = preferredFormat {
                    if let converted = buffer.converted(to: pf, using: converter) {
                        inputContinuation.yield(AnalyzerInput(buffer: converted))
                    }
                } else {
                    inputContinuation.yield(AnalyzerInput(buffer: buffer))
                }
            }

            engine.prepare(); try engine.start()

            // Wait for either a (volatile) partial or a final chunk, or timeout
            return try await withTaskCancellationHandler {
                let timeoutNanos = UInt64(timeout * 1_000_000_000)
                return try await withThrowingTaskGroup(of: String?.self) { group -> String? in
                    group.addTask { @Sendable () -> String? in // results
                        if let t = b.speechTranscriber {
                            for try await r in t.results {
                                if r.isFinal { b.finished = true; return String(r.text.characters) }
                                else { return String(r.text.characters) }
                            }
                        } else if let d = b.dictationTranscriber {
                            for try await r in d.results {
                                if r.isFinal { b.finished = true; return String(r.text.characters) }
                                else { return String(r.text.characters) }
                            }
                        }
                        return nil
                    }
                    group.addTask { @Sendable () -> String? in // timeout
                        try await Task.sleep(nanoseconds: timeoutNanos)
                        return nil
                    }
                    for try await candidate in group {
                        if let candidate { return candidate }
                    }
                    return (nil as String?)
                }
            } onCancel: {
                engine.stop(); input.removeTap(onBus: 0)
                inputContinuation.finish()
                Task { try? await b.analyzer?.finalizeAndFinishThroughEndOfInput() }
                AudioSession.deactivate(); b.finished = true
            }
        }
    }
}

@available(iOS 26, *)
public actor SpeechRecognizer {
    private let requestLocale: Locale
    public init(locale: Locale = .current) { self.requestLocale = locale }

    // MARK: - One-shot API
    public func recognizeOnce(prompt: String? = nil,
                              timeout: TimeInterval = 10,
                              onDevice: Bool = true,
                              hint: SFSpeechRecognitionTaskHint = .unspecified) async throws -> String {
        // Modern stack does not require SFSpeechRecognizer auth, but mic permission is still needed via AVAudioSession
        guard await Self.requestAuthorization() else { throw SpeechError.notAuthorized }

        try AudioSession.activate()

        defer { AudioSession.deactivate() }

        let choice = await pickTranscriberLocale(requestLocale)
        let analyzer: SpeechAnalyzer
        var speechTranscriber: SpeechTranscriber? = nil
        var dictationTranscriber: DictationTranscriber? = nil

        switch choice.kind {
        case .speech:
            let t = SpeechTranscriber(
                locale: choice.locale,
                transcriptionOptions: [],
                reportingOptions: [.volatileResults],
                attributeOptions: [.audioTimeRange]
            )
            try await ensureModel(for: t, locale: choice.locale)
            speechTranscriber = t
            analyzer = SpeechAnalyzer(modules: [t])
        case .dictation:
            let t = DictationTranscriber(locale: choice.locale, preset: .shortDictation)
            dictationTranscriber = t
            analyzer = SpeechAnalyzer(modules: [t])
        }

        // Preferred analyzer format
        var modules: [any LocaleDependentSpeechModule] = []
        if let t = speechTranscriber { modules.append(t) }
        if let d = dictationTranscriber { modules.append(d) }
        let preferredFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules)

        // Prepare mic capture and feed into analyzer via AsyncStream
        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let converter: AVAudioConverter?
        if let pf = preferredFormat, pf != inputFormat {
            converter = AVAudioConverter(from: inputFormat, to: pf)
        } else { converter = nil }

        let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
        try await analyzer.start(inputSequence: inputStream)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            if let converter, let pf = preferredFormat {
                if let converted = buffer.converted(to: pf, using: converter) {
                    inputContinuation.yield(AnalyzerInput(buffer: converted))
                }
            } else {
                inputContinuation.yield(AnalyzerInput(buffer: buffer))
            }
        }
        audioEngine.prepare(); try audioEngine.start()

        defer {
            audioEngine.stop(); inputNode.removeTap(onBus: 0)
            inputContinuation.finish()
            Task { try? await analyzer.finalizeAndFinishThroughEndOfInput() }
        }

        // Await final result from transcriber
        return try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: String?.self) { group in
                // Timeout watchdog
                group.addTask { @Sendable () -> String? in
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    return nil
                }
                // Consume results (AsyncSequence)
                let st = speechTranscriber
                let dt = dictationTranscriber
                group.addTask { @Sendable () -> String? in
                    if let t = st {
                        for try await r in t.results { if r.isFinal { return String(r.text.characters) } }
                    } else if let d = dt {
                        for try await r in d.results { if r.isFinal { return String(r.text.characters) } }
                    }
                    return nil
                }
                for try await candidate in group { if let text = candidate { return text } }
                throw SpeechError.noResult
            }
        } onCancel: {
            audioEngine.stop(); inputNode.removeTap(onBus: 0)
        }
    }

    public func recognitionStream(shouldReportPartial: Bool = true, timeout: TimeInterval = 15, onDevice: Bool = true, hint: SFSpeechRecognitionTaskHint = .unspecified) -> RecognitionStream {
        // `shouldReportPartial` is implied by the modern API (iterator returns partial first). Keep parameter for API compatibility.
        .init(locale: requestLocale, timeout: timeout, onDevice: onDevice, hint: hint)
    }

    public static func requestAuthorization() async -> Bool {
        // Microphone permission (AVAudioSession) still governs capture
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }
}

@available(iOS 26, *)
private extension AVAudioPCMBuffer {
    func converted(to format: AVAudioFormat, using converter: AVAudioConverter) -> AVAudioPCMBuffer? {
        let frameCapacity = AVAudioFrameCount(Double(self.frameLength) * (format.sampleRate / self.format.sampleRate))
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else { return nil }
        out.frameLength = frameCapacity
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return self
        }
        converter.convert(to: out, error: &error, withInputFrom: inputBlock)
        return (error == nil) ? out : nil
    }
}
