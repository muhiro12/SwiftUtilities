//
//  SpeechTranscriber.swift
//  SwiftUtilities
//
//  Created by SwiftUtilities.
//

import Foundation
import AVFoundation
import Speech

public struct SpeechTranscription: Sendable, Equatable {
    public let text: String
    public let isFinal: Bool
}

public enum SpeechTranscriberError: Error {
    case speechNotAuthorized
    case microphoneNotAuthorized
    case recognizerUnavailable
    case noResult
    case cancelled
}

public enum SpeechTranscriber {
    public enum Strategy: Sendable {
        case realtime // AVAudioEngine + SFSpeechAudioBufferRecognitionRequest
        case fileBuffered // AVAudioRecorder -> SFSpeechURLRecognitionRequest
    }
    // MARK: Public APIs

    /// Captures voice from the microphone and returns a single finalized transcription.
    /// - Parameters:
    ///   - locale: Locale for recognition. Defaults to current.
    ///   - onDeviceOnly: Prefer on-device recognition when available.
    /// - Returns: Final recognized text.
    public static func transcribeOnce(
        locale: Locale = .current,
        onDeviceOnly: Bool = true,
        strategy: Strategy = .realtime,
        maxDuration: TimeInterval = 15,
        silenceTimeout: TimeInterval = 1.2
    ) async throws -> String {
        switch strategy {
        case .realtime:
            let controller = RecognitionController(locale: locale, onDeviceOnly: onDeviceOnly)
            defer { controller.stop() }
            try await controller.prepare()
            return try await withTaskCancellationHandler(operation: {
                try await controller.startAndAwaitFinal()
            }, onCancel: {
                controller.cancel()
            })
        case .fileBuffered:
            let controller = FileBufferedController(locale: locale, onDeviceOnly: onDeviceOnly)
            try await controller.prepare()
            return try await withTaskCancellationHandler(operation: {
                try await controller.recordAndTranscribe(maxDuration: maxDuration, silenceTimeout: silenceTimeout)
            }, onCancel: {
                controller.cancel()
            })
        }
    }

    /// Returns an AsyncSequence that yields partial and final transcriptions while listening.
    /// Consumption stops automatically when a final result arrives or the consumer cancels.
    /// - Parameters:
    ///   - locale: Locale for recognition. Defaults to current.
    ///   - onDeviceOnly: Prefer on-device recognition when available.
    /// - Returns: AsyncSequence of SpeechTranscription.
    public static func transcriptions(
        locale: Locale = .current,
        onDeviceOnly: Bool = true,
        strategy: Strategy = .realtime,
        maxDuration: TimeInterval = 15,
        silenceTimeout: TimeInterval = 1.2
    ) -> AsyncThrowingStream<SpeechTranscription, Error> {
        switch strategy {
        case .realtime:
            let controller = RecognitionController(locale: locale, onDeviceOnly: onDeviceOnly)
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        try await controller.prepare()
                        try await controller.start { transcription, isFinal in
                            continuation.yield(SpeechTranscription(text: transcription, isFinal: isFinal))
                            if isFinal {
                                continuation.finish()
                            }
                        }
                    } catch is CancellationError {
                        controller.cancel()
                        continuation.finish(throwing: SpeechTranscriberError.cancelled)
                    } catch {
                        controller.cancel()
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    controller.stop()
                }
            }
        case .fileBuffered:
            // For fileBuffered strategy, we yield only a single final transcription.
            return AsyncThrowingStream { continuation in
                let controller = FileBufferedController(locale: locale, onDeviceOnly: onDeviceOnly)
                Task {
                    do {
                        try await controller.prepare()
                        let text = try await controller.recordAndTranscribe(maxDuration: maxDuration, silenceTimeout: silenceTimeout)
                        continuation.yield(SpeechTranscription(text: text, isFinal: true))
                        continuation.finish()
                    } catch is CancellationError {
                        controller.cancel()
                        continuation.finish(throwing: SpeechTranscriberError.cancelled)
                    } catch {
                        controller.cancel()
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    controller.cancel()
                }
            }
        }
    }

    // MARK: - Internal Recognition Controller

    private final class RecognitionController: @unchecked Sendable {
        private let locale: Locale
        private let onDeviceOnly: Bool
        private let speechRecognizer: SFSpeechRecognizer?
        private let audioEngine = AVAudioEngine()
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var recognitionTask: SFSpeechRecognitionTask?
        private var finalContinuation: CheckedContinuation<String, Error>?

        init(locale: Locale, onDeviceOnly: Bool) {
            self.locale = locale
            self.onDeviceOnly = onDeviceOnly
            self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        }

        func prepare() async throws {
            try await SpeechTranscriber.ensureAuthorizations()
            guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                throw SpeechTranscriberError.recognizerUnavailable
            }
            // Configure audio session
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }

        func startAndAwaitFinal() async throws -> String {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
                self.finalContinuation = cont
                do {
                    try self.start { [weak self] text, isFinal in
                        guard let self else { return }
                        if isFinal, let cont = self.finalContinuation {
                            self.finalContinuation = nil
                            cont.resume(returning: text)
                        }
                    }
                } catch {
                    self.finalContinuation = nil
                    cont.resume(throwing: error)
                }
            }
        }

        func start(onResult: @escaping @Sendable (_ text: String, _ isFinal: Bool) -> Void) throws {
            guard let recognizer = speechRecognizer else { throw SpeechTranscriberError.recognizerUnavailable }

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = onDeviceOnly
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    onResult(text, result.isFinal)
                    if result.isFinal {
                        self.stop()
                    }
                }
                if let error {
                    self.stop()
                    if let cont = self.finalContinuation {
                        self.finalContinuation = nil
                        cont.resume(throwing: error)
                    }
                    // Bubble up if sequence is still active; caller will handle finish.
                    // For the one-shot path, if no result yet, we don't resume twice.
                }
            }
        }

        func stop() {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        func cancel() {
            recognitionTask?.cancel()
            stop()
        }

        // Authorization moved to SpeechTranscriber.ensureAuthorizations()
    }

    // MARK: - File Buffered Controller

    private final class FileBufferedController: @unchecked Sendable {
        private let locale: Locale
        private let onDeviceOnly: Bool
        private let speechRecognizer: SFSpeechRecognizer?
        private var recorder: AVAudioRecorder?
        private var tempURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("speech_recording.m4a")

        init(locale: Locale, onDeviceOnly: Bool) {
            self.locale = locale
            self.onDeviceOnly = onDeviceOnly
            self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        }

        func prepare() async throws {
            try await SpeechTranscriber.ensureAuthorizations()
            guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                throw SpeechTranscriberError.recognizerUnavailable
            }
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }

        func recordAndTranscribe(maxDuration: TimeInterval, silenceTimeout: TimeInterval) async throws -> String {
            try startRecording()
            defer { stopRecording() }
            try await waitForSilenceOrTimeout(maxDuration: maxDuration, silenceTimeout: silenceTimeout)

            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            request.requiresOnDeviceRecognition = onDeviceOnly
            request.shouldReportPartialResults = false

            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
                speechRecognizer?.recognitionTask(with: request) { result, error in
                    if let result, result.isFinal {
                        cont.resume(returning: result.bestTranscription.formattedString)
                    } else if let error {
                        cont.resume(throwing: error)
                    }
                }
            }
        }

        func cancel() {
            stopRecording()
        }

        private func startRecording() throws {
            // Remove old temp file
            try? FileManager.default.removeItem(at: tempURL)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.isMeteringEnabled = true
            guard recorder?.record() == true else { throw SpeechTranscriberError.recognizerUnavailable }
        }

        private func stopRecording() {
            if recorder?.isRecording == true {
                recorder?.stop()
            }
            recorder = nil
        }

        private func waitForSilenceOrTimeout(maxDuration: TimeInterval, silenceTimeout: TimeInterval) async throws {
            let start = Date()
            var lastNonSilent = Date()
            let silenceThreshold: Float = -45 // dB
            while true {
                try Task.checkCancellation()
                recorder?.updateMeters()
                if let power = recorder?.averagePower(forChannel: 0) {
                    if power > silenceThreshold {
                        lastNonSilent = Date()
                    }
                }
                let elapsed = Date().timeIntervalSince(start)
                let silenceElapsed = Date().timeIntervalSince(lastNonSilent)
                if elapsed >= maxDuration || silenceElapsed >= silenceTimeout {
                    break
                }
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }

    // Shared authorization helper
    private static func ensureAuthorizations() async throws {
        let speechAuthorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechAuthorized else { throw SpeechTranscriberError.speechNotAuthorized }

        let micAuthorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        guard micAuthorized else { throw SpeechTranscriberError.microphoneNotAuthorized }
    }
}
