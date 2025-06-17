//
//  ModelBridgeable.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import SwiftData

@MainActor
public protocol ModelBridgeable: Sendable {
    associatedtype Model: PersistentModel

    init?(_ model: Model)
}
