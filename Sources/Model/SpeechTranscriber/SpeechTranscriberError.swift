//
//  SpeechTranscriberError.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import Speech

public enum SpeechTranscriberError: Error, LocalizedError {
    case speechNotAuthorized(status: SFSpeechRecognizerAuthorizationStatus)
    case microphoneNotAuthorized
    case recognizerUnavailable(reason: String = "Recognizer is not available")
    case onDeviceRecognitionUnavailable
    case audioSessionConfigurationFailed(underlying: Error)
    case startAudioEngineFailed(underlying: Error)
    case recognitionFailed(underlying: Error)
    case silenceTimeoutReached
    case maxDurationReached
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .speechNotAuthorized(let status):
            return "Speech recognition not authorized: \(status)"
        case .microphoneNotAuthorized:
            return "Microphone permission not granted"
        case .recognizerUnavailable(let reason):
            return "Speech recognizer unavailable: \(reason)"
        case .onDeviceRecognitionUnavailable:
            return "On-device recognition is not supported for this locale/device"
        case .audioSessionConfigurationFailed(let underlying):
            return "Failed to configure audio session: \(underlying.localizedDescription)"
        case .startAudioEngineFailed(let underlying):
            return "Failed to start audio engine: \(underlying.localizedDescription)"
        case .recognitionFailed(let underlying):
            let ns = underlying as NSError
            return "Recognition failed: \(ns.domain)(\(ns.code)) \(underlying.localizedDescription)"
        case .silenceTimeoutReached:
            return "Stopped due to silence timeout"
        case .maxDurationReached:
            return "Stopped due to max duration"
        case .cancelled:
            return "Operation was cancelled"
        }
    }
}
