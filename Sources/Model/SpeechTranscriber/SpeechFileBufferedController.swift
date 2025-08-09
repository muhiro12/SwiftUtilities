//
//  SpeechFileBufferedController.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import Speech

final class SpeechFileBufferedController: @unchecked Sendable {
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
        guard let recognizer = speechRecognizer else {
            throw SpeechTranscriberError.recognizerUnavailable()
        }
        if onDeviceOnly, #available(iOS 13.0, *), recognizer.supportsOnDeviceRecognition == false {
            throw SpeechTranscriberError.onDeviceRecognitionUnavailable
        }
        guard recognizer.isAvailable else {
            throw SpeechTranscriberError.recognizerUnavailable(reason: "Recognizer reports isAvailable == false")
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechTranscriberError.audioSessionConfigurationFailed(underlying: error)
        }
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
        guard recorder?.record() == true else { throw SpeechTranscriberError.recognizerUnavailable() }
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
