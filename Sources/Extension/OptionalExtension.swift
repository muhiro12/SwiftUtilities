//
//  OptionalExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import Foundation

public extension Optional where Wrapped: RangeReplaceableCollection {
    /// Returns the wrapped collection or an empty instance when the value is `nil`.
    var orEmpty: Wrapped {
        self ?? .init()
    }

    /// A Boolean value indicating whether the optional collection is non-empty.
    ///
    /// When the value is `nil`, this returns `false`.
    var isNotEmpty: Bool {
        orEmpty.isNotEmpty
    }
}
