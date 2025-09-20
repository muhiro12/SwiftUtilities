//
//  DecimalExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2020/06/24.
//  Copyright © 2020 Hiromu Nakano. All rights reserved.
//

import Foundation

public nonisolated extension Decimal {
    /// A Boolean value indicating whether the number is greater than zero.
    var isPlus: Bool {
        self > .zero
    }

    /// A Boolean value indicating whether the number is less than zero.
    var isMinus: Bool {
        self < .zero
    }
}
