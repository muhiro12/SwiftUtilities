//
//  CollectionExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

public extension Collection where Self: RangeReplaceableCollection {
    static var empty: Self {
        .init()
    }

    var isNotEmpty: Bool {
        !isEmpty
    }
}
