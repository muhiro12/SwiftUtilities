//
//  CollectionExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import Foundation

public extension Collection where Self: RangeReplaceableCollection {
    /// An empty instance of the conforming collection.
    static var empty: Self {
        .init()
    }

    /// A Boolean value indicating whether the collection contains at least one element.
    var isNotEmpty: Bool {
        !isEmpty
    }
}
