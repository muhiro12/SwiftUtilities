//
//  SpeechRecognitionController.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import Speech

final class SpeechRecognitionController: @unchecked Sendable {
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
        guard let recognizer = speechRecognizer else {
            throw SpeechTranscriberError.recognizerUnavailable()
        }
        if onDeviceOnly, #available(iOS 13.0, *), recognizer.supportsOnDeviceRecognition == false {
            throw SpeechTranscriberError.onDeviceRecognitionUnavailable
        }
        guard recognizer.isAvailable else {
            throw SpeechTranscriberError.recognizerUnavailable(reason: "Recognizer reports isAvailable == false")
        }
        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechTranscriberError.audioSessionConfigurationFailed(underlying: error)
        }
    }

    func startAndAwaitFinal() async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            self.finalContinuation = cont
            do {
                try self.start(
                    onResult: { [weak self] text, isFinal in
                        guard let self else { return }
                        if isFinal, let cont = self.finalContinuation {
                            self.finalContinuation = nil
                            cont.resume(returning: text)
                        }
                    },
                    onError: { [weak self] err in
                        guard let self, let cont = self.finalContinuation else { return }
                        self.finalContinuation = nil
                        cont.resume(throwing: err)
                    }
                )
            } catch {
                self.finalContinuation = nil
                cont.resume(throwing: error)
            }
        }
    }

    func start(
        onResult: @escaping @Sendable (_ text: String, _ isFinal: Bool) -> Void,
        onError: @escaping @Sendable (_ error: Error) -> Void
    ) throws {
        guard let recognizer = speechRecognizer else { throw SpeechTranscriberError.recognizerUnavailable() }

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
        do {
            try audioEngine.start()
        } catch {
            throw SpeechTranscriberError.startAudioEngineFailed(underlying: error)
        }

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
                onError(SpeechTranscriberError.recognitionFailed(underlying: error))
                if let cont = self.finalContinuation {
                    self.finalContinuation = nil
                    cont.resume(throwing: SpeechTranscriberError.recognitionFailed(underlying: error))
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
