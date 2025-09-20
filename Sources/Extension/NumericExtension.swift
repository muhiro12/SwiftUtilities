//
//  NumericExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import Foundation

public extension Numeric {
    /// A Boolean value indicating whether the numeric value equals zero.
    var isZero: Bool {
        self == .zero
    }
    
    /// A Boolean value indicating whether the numeric value is not zero.
    var isNotZero: Bool {
        !isZero
    }
}
