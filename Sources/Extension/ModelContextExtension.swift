//
//  ModelContextExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 10/12/24.
//

import SwiftData

public extension ModelContext {
    func fetchFirst<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T : PersistentModel {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    func fetchRandom<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T : PersistentModel {
        let count = try fetchCount(descriptor)
        let offset = Int.random(in: 0..<count)

        var descriptor = descriptor
        descriptor.fetchOffset = offset

        return try fetchFirst(descriptor)
    }
}
