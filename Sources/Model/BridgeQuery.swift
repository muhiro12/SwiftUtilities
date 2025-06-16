//
//  BridgeQuery.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import SwiftData
import SwiftUI

@MainActor
@propertyWrapper
public struct BridgeQuery<Entity: ModelBridgeable>: DynamicProperty {
    @Query private var models: [Entity.Model]

    public init(_ query: Query<Entity.Model, [Entity.Model]>) {
        self._models = query
    }

    public init() {
        self._models = .init()
    }

    public var wrappedValue: [Entity] {
        models.compactMap(Entity.init)
    }
}
