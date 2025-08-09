//
//  SpeechTranscriber.swift
//  SwiftUtilities
//
//  Created by SwiftUtilities.
//

import Foundation
import AVFoundation
import Speech

public enum SpeechTranscriber {
    // MARK: Public APIs

    /// Captures voice from the microphone and returns a single finalized transcription.
    /// - Parameters:
    ///   - locale: Locale for recognition. Defaults to current.
    ///   - onDeviceOnly: Prefer on-device recognition when available.
    /// - Returns: Final recognized text.
    public static func transcribeOnce(
        locale: Locale = .current,
        onDeviceOnly: Bool = true,
        strategy: SpeechTranscriberStrategy = .realtime,
        maxDuration: TimeInterval = 15,
        silenceTimeout: TimeInterval = 1.2
    ) async throws -> String {
        switch strategy {
        case .realtime:
            let controller = SpeechRecognitionController(locale: locale, onDeviceOnly: onDeviceOnly)
            defer { controller.stop() }
            try await controller.prepare()
            return try await withTaskCancellationHandler(operation: {
                try await controller.startAndAwaitFinal()
            }, onCancel: {
                controller.cancel()
            })
        case .fileBuffered:
            let controller = SpeechFileBufferedController(locale: locale, onDeviceOnly: onDeviceOnly)
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
        strategy: SpeechTranscriberStrategy = .realtime,
        maxDuration: TimeInterval = 15,
        silenceTimeout: TimeInterval = 1.2
    ) -> AsyncThrowingStream<SpeechTranscription, Error> {
        switch strategy {
        case .realtime:
            let controller = SpeechRecognitionController(locale: locale, onDeviceOnly: onDeviceOnly)
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        try await controller.prepare()
                        try controller.start(
                            onResult: { transcription, isFinal in
                                continuation.yield(SpeechTranscription(text: transcription, isFinal: isFinal))
                                if isFinal {
                                    continuation.finish()
                                }
                            },
                            onError: { error in
                                continuation.finish(throwing: error)
                            }
                        )
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
                let controller = SpeechFileBufferedController(locale: locale, onDeviceOnly: onDeviceOnly)
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

    // Shared authorization helper
    static func ensureAuthorizations() async throws {
        let status = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
        guard status == .authorized else { throw SpeechTranscriberError.speechNotAuthorized(status: status) }

        let micAuthorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        guard micAuthorized else { throw SpeechTranscriberError.microphoneNotAuthorized }
    }
}
