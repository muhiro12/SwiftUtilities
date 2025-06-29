//
//  IntentPerformer.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import Foundation

public protocol IntentPerformer {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    static func perform(_ input: Input) async throws -> Output
}
