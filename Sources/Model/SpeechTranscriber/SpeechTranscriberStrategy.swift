//
//  SpeechTranscriberStrategy.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import Foundation

public enum SpeechTranscriberStrategy: Sendable {
    case realtime // AVAudioEngine + SFSpeechAudioBufferRecognitionRequest
    case fileBuffered // AVAudioRecorder -> SFSpeechURLRecognitionRequest
}
