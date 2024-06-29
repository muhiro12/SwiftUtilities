//
//  NumericExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

public extension Numeric {
    var isZero: Bool {
        self == .zero
    }
    
    var isNotZero: Bool {
        !isZero
    }
}
