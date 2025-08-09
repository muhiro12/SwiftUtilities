//
//  SpeechTranscription.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import Foundation

public struct SpeechTranscription: Sendable, Equatable {
    public let text: String
    public let isFinal: Bool
}
