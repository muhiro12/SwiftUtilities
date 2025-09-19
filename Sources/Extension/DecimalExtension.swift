//
//  DecimalExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2020/06/24.
//  Copyright © 2020 Hiromu Nakano. All rights reserved.
//

import Foundation

public nonisolated extension Decimal {
    var isPlus: Bool {
        self > .zero
    }

    var isMinus: Bool {
        self < .zero
    }
}
