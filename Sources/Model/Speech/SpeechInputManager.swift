import Foundation
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
    public enum State: Equatable { case idle, recording, paused }
    public private(set) var state: State = .idle

    public init() {}

    /// Starts microphone capture and returns an AsyncStream of transcription results.
    /// Call `stop()` to finish. Ensure microphone permission first time.
    @MainActor
    public func start(locale: Locale = .current,
                      reportVolatile: Bool = true) async throws -> AsyncStream<TranscriptionResult> {
        guard await Self.isMicrophoneAuthorized() else {
            throw NSError(domain: "SpeechInputManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
        }

        try self.audioSession.activate()

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
    }

    /// Resumes the audio engine if possible.
    public func resume() throws {
        guard state == .paused else { return }
        try audioEngine?.start()
        state = .recording
    }

    /// Stops streaming, finalizes recognition, and deactivates the audio session.
    @MainActor
    public func stop() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        state = .idle

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
            throw NSError(domain: "SpeechInputManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "No compatible audio format for SpeechAnalyzer"])
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
                }
            }
        }

        try await analyzer.start(inputSequence: sequence)

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
        try engine.start()
        state = .recording
        return stream
    }

    @available(iOS 26.0, *)
    @MainActor
    private func ensureModel_iOS26(transcriber: SpeechTranscriber, locale: Locale) async throws {
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.map({ $0.identifier(.bcp47) }).contains(locale.identifier(.bcp47)) else {
            throw NSError(domain: "SpeechInputManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Locale not supported by on-device model"])
        }

        let installed = await Set(SpeechTranscriber.installedLocales)
        if installed.map({ $0.identifier(.bcp47) }).contains(locale.identifier(.bcp47)) {
            return
        }

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
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
        guard auth == .authorized else {
            throw NSError(domain: "SpeechInputManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer() else {
            throw NSError(domain: "SpeechInputManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "No available SFSpeechRecognizer for locale"])
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
                }
            }
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()
        state = .recording
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

