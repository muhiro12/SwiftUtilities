//
//  ModelContextExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 10/12/24.
//

import SwiftData

public extension ModelContext {
    /// Fetches the first model matching the given descriptor.
    /// - Parameter descriptor: A fetch descriptor describing the query.
    /// - Returns: The first matching model, or `nil` when no results exist.
    /// - Throws: Any error thrown by the underlying fetch operation.
    func fetchFirst<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T : PersistentModel {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    /// Fetches a single random model from the result set described by the descriptor.
    /// - Parameter descriptor: A fetch descriptor describing the population.
    /// - Returns: A random model from the population, or `nil` when the population is empty.
    /// - Throws: Any error thrown by `fetchCount` or the subsequent fetch.
    func fetchRandom<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T : PersistentModel {
        let count = try fetchCount(descriptor)

        guard count.isNotZero else {
            return nil
        }

        let offset = Int.random(in: .zero..<count)

        var descriptor = descriptor
        descriptor.fetchOffset = offset

        return try fetchFirst(descriptor)
    }
}
