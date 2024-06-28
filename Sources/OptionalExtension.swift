//
//  OptionalExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

public extension Optional where Wrapped: RangeReplaceableCollection {
    var orEmpty: Wrapped {
        self ?? .init()
    }
}
