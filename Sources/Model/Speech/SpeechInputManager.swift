import Foundation
import OSLog
@preconcurrency import AVFoundation
@preconcurrency import Speech

public struct TranscriptionResult: Sendable, Equatable {
    public let text: AttributedString
    public let isFinal: Bool

    public init(text: AttributedString, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

/// A reusable, high-level speech input manager that abstracts Apple’s Speech APIs.
/// - Uses the latest iOS 18 (SDK iOS 26.0) SpeechTranscriber/SpeechAnalyzer when available.
/// - Falls back to SFSpeechRecognizer streaming on older iOS versions.
public final class SpeechInputManager {
    // MARK: Public surface
    public enum State: Sendable, Equatable { case idle, recording, paused }
    public private(set) var state: State = .idle

    public enum Event: Sendable, Equatable {
        case info(String)
        case warning(String)
        case error(String)
        case stateChanged(State)
        case permissionsChecked(microphone: Bool, speech: Bool?)
        case modelInstallStarted(Locale)
        case modelInstallCompleted(Locale)
        case analyzerReady
        case engineStarted
        case engineStopped
        case recognitionStarted(legacy: Bool)
    }

    public enum SpeechInputError: LocalizedError, Sendable {
        case microphonePermissionDenied
        case speechPermissionDenied
        case analyzerFormatUnavailable
        case localeNotSupported
        case audioSessionActivationFailed(underlying: Error?)
        case analyzerStartFailed
        case audioEngineStartFailed(underlying: Error?)
        case recognizerUnavailable

        public var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Microphone permission denied"
            case .speechPermissionDenied:
                return "Speech recognition permission denied"
            case .analyzerFormatUnavailable:
                return "No compatible audio format for SpeechAnalyzer"
            case .localeNotSupported:
                return "Locale not supported by on-device model"
            case .audioSessionActivationFailed(let underlying):
                return "Failed to activate audio session\(underlying.map { ": \($0.localizedDescription)" } ?? "")"
            case .analyzerStartFailed:
                return "Failed to start SpeechAnalyzer"
            case .audioEngineStartFailed(let underlying):
                return "Failed to start audio engine\(underlying.map { ": \($0.localizedDescription)" } ?? "")"
            case .recognizerUnavailable:
                return "No available SFSpeechRecognizer for locale"
            }
        }
    }

    public var onEvent: @Sendable (Event) -> Void = { _ in }
    private let logger = Logger(subsystem: "SwiftUtilities", category: "SpeechInput")

    public init() {}

    /// Starts microphone capture and returns an AsyncStream of transcription results.
    /// Call `stop()` to finish. Ensure microphone permission first time.
    @MainActor
    public func start(locale: Locale = .current,
                      reportVolatile: Bool = true) async throws -> AsyncStream<TranscriptionResult> {
        let micOK = await Self.isMicrophoneAuthorized()
        var speechOK: Bool? = nil
        onEvent(.permissionsChecked(microphone: micOK, speech: nil))
        guard micOK else { throw SpeechInputError.microphonePermissionDenied }

        do {
            try self.audioSession.activate()
        } catch {
            onEvent(.error("Audio session activation failed: \(error.localizedDescription)"))
            logger.error("Audio session activation failed: \(error.localizedDescription)")
            throw SpeechInputError.audioSessionActivationFailed(underlying: error)
        }

        if #available(iOS 26.0, *) {
            return try await start_iOS26(locale: locale, reportVolatile: reportVolatile)
        } else {
            return try await start_Legacy(locale: locale, reportVolatile: reportVolatile)
        }
    }

    /// Pauses the audio engine if possible.
    public func pause() {
        guard state == .recording else { return }
        audioEngine?.pause()
        state = .paused
        onEvent(.stateChanged(state))
    }

    /// Resumes the audio engine if possible.
    public func resume() throws {
        guard state == .paused else { return }
        try audioEngine?.start()
        state = .recording
        onEvent(.stateChanged(state))
    }

    /// Stops streaming, finalizes recognition, and deactivates the audio session.
    @MainActor
    public func stop() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        state = .idle
        onEvent(.engineStopped)
        onEvent(.stateChanged(state))

        if #available(iOS 26.0, *) {
            if let pipeline = ios26Pipeline as? IOS26Pipeline {
                pipeline.finish()
            }
            ios26Pipeline = nil
        } else {
            recognitionRequest_legacy?.endAudio()
            recognitionTask_legacy?.cancel()
            recognitionTask_legacy = nil
        }

        audioSession.deactivate()
    }

    // MARK: Microphone authorization
    public static func isMicrophoneAuthorized() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default: return false
        }
    }

    // MARK: Internal audio pipeline
    private var audioEngine: AVAudioEngine?
    private let audioSession = AudioSessionManager()

    private func buildAudioEngine() -> AVAudioEngine {
        let engine = AVAudioEngine()
        engine.inputNode.removeTap(onBus: 0)
        return engine
    }

    // MARK: iOS 26 path (iOS 18 SDK)
    private var ios26Pipeline: Any?
    private let converter = BufferConverter()

    @available(iOS 26.0, *)
    @MainActor
    private func start_iOS26(locale: Locale, reportVolatile: Bool) async throws -> AsyncStream<TranscriptionResult> {
        let reportOptions: Set<SpeechTranscriber.ReportingOption> = reportVolatile ? [.volatileResults] : []
        let attributeOptions: Set<SpeechTranscriber.ResultAttributeOption> = [.audioTimeRange]
        let transcriber = SpeechTranscriber(locale: locale,
                                            transcriptionOptions: [],
                                            reportingOptions: reportOptions,
                                            attributeOptions: attributeOptions)

        // Ensure model availability and install if needed
        try await ensureModel_iOS26(transcriber: transcriber, locale: locale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            onEvent(.error("Analyzer format unavailable"))
            throw SpeechInputError.analyzerFormatUnavailable
        }
        let (sequence, builder) = AsyncStream<AnalyzerInput>.makeStream()

        let engine = buildAudioEngine()
        audioEngine = engine
        let pipeline = IOS26Pipeline(analyzer: analyzer, transcriber: transcriber, inputBuilder: builder, analyzerFormat: analyzerFormat)
        ios26Pipeline = pipeline

        let stream = makeResultStream { continuation in
            // Start reading transcriber results
            pipeline.recognizerTask = Task {
                do {
                    for try await result in transcriber.results {
                        let text = result.text
                        let isFinal = result.isFinal
                        continuation.yield(.init(text: text, isFinal: isFinal))
                    }
                } catch {
                    // Swallow errors into stream termination
                    self.logger.warning("Transcriber results ended with error: \(error.localizedDescription)")
                    self.onEvent(.warning("Transcriber ended: \(error.localizedDescription)"))
                }
            }
        }

        do {
            try await analyzer.start(inputSequence: sequence)
            onEvent(.analyzerReady)
        } catch {
            onEvent(.error("Analyzer start failed: \(error.localizedDescription)"))
            logger.error("Analyzer start failed: \(error.localizedDescription)")
            throw SpeechInputError.analyzerStartFailed
        }

        // Mic tap: capture and convert to analyzer format
        let inputNode = engine.inputNode
        let tapFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                let converted = try self.converter.convert(buffer, to: analyzerFormat)
                let input = AnalyzerInput(buffer: converted)
                pipeline.inputBuilder?.yield(input)
            } catch {
                // ignore bad buffers
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            onEvent(.error("Audio engine start failed: \(error.localizedDescription)"))
            logger.error("Engine start failed: \(error.localizedDescription)")
            throw SpeechInputError.audioEngineStartFailed(underlying: error)
        }
        state = .recording
        onEvent(.engineStarted)
        onEvent(.stateChanged(state))
        return stream
    }

    @available(iOS 26.0, *)
    @MainActor
    private func ensureModel_iOS26(transcriber: SpeechTranscriber, locale: Locale) async throws {
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.map({ $0.identifier(.bcp47) }).contains(locale.identifier(.bcp47)) else {
            onEvent(.warning("Locale not supported: \(locale.identifier(.bcp47))"))
            throw SpeechInputError.localeNotSupported
        }

        let installed = await Set(SpeechTranscriber.installedLocales)
        if installed.map({ $0.identifier(.bcp47) }).contains(locale.identifier(.bcp47)) {
            return
        }

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            onEvent(.modelInstallStarted(locale))
            try await request.downloadAndInstall()
            onEvent(.modelInstallCompleted(locale))
        }
    }

    // MARK: Legacy (iOS 17 and earlier) path
    private var recognitionRequest_legacy: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask_legacy: SFSpeechRecognitionTask?
    private var recognizer_legacy: SFSpeechRecognizer?

    @MainActor
    private func start_Legacy(locale: Locale, reportVolatile: Bool) async throws -> AsyncStream<TranscriptionResult> {
        // Ask Speech permission (separate from mic)
        let auth = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        onEvent(.permissionsChecked(microphone: true, speech: auth == .authorized))
        guard auth == .authorized else { throw SpeechInputError.speechPermissionDenied }

        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer() else {
            onEvent(.error("SFSpeechRecognizer unavailable for locale"))
            throw SpeechInputError.recognizerUnavailable
        }
        recognizer_legacy = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = reportVolatile
        recognitionRequest_legacy = request

        let engine = buildAudioEngine()
        audioEngine = engine

        let stream = makeResultStream { continuation in
            self.recognitionTask_legacy = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let text = AttributedString(result.bestTranscription.formattedString)
                    continuation.yield(.init(text: text, isFinal: result.isFinal))
                } else if error != nil {
                    // terminate on error
                    self.onEvent(.warning("Recognition task ended: \(error!.localizedDescription)"))
                }
            }
            self.onEvent(.recognitionStarted(legacy: true))
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            onEvent(.error("Audio engine start failed: \(error.localizedDescription)"))
            logger.error("Engine start failed: \(error.localizedDescription)")
            throw SpeechInputError.audioEngineStartFailed(underlying: error)
        }
        state = .recording
        onEvent(.engineStarted)
        onEvent(.stateChanged(state))
        return stream
    }

    // MARK: Utilities
    private func makeResultStream(_ setup: (AsyncStream<TranscriptionResult>.Continuation) -> Void) -> AsyncStream<TranscriptionResult> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            setup(continuation)
        }
    }
}

// MARK: - Audio session manager
private final class AudioSessionManager {
    #if os(iOS)
    func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func deactivate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
    #else
    func activate() throws {}
    func deactivate() {}
    #endif
}

// MARK: - iOS26 Pipeline Holder
@available(iOS 26.0, *)
private final class IOS26Pipeline {
    let analyzer: SpeechAnalyzer
    let transcriber: SpeechTranscriber
    var recognizerTask: Task<Void, Error>?
    var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    let analyzerFormat: AVAudioFormat

    init(analyzer: SpeechAnalyzer, transcriber: SpeechTranscriber, inputBuilder: AsyncStream<AnalyzerInput>.Continuation?, analyzerFormat: AVAudioFormat) {
        self.analyzer = analyzer
        self.transcriber = transcriber
        self.inputBuilder = inputBuilder
        self.analyzerFormat = analyzerFormat
    }

    func finish() {
        inputBuilder?.finish()
        let analyzer = self.analyzer
        Task { [analyzer] in
            try? await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        recognizerTask?.cancel()
        recognizerTask = nil
    }
}
