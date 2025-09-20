//
//  StringExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2020/04/11.
//  Copyright © 2020 Hiromu Nakano. All rights reserved.
//

import Foundation

public nonisolated extension String {
    /// A Boolean value indicating whether the string is empty or can be parsed as a `Decimal`.
    var isEmptyOrDecimal: Bool {
        if isEmpty {
            return true
        }
        return Decimal(string: self) != nil
    }

    /// Parses the string as a `Decimal`, or returns `.zero` on failure.
    var decimalValue: Decimal {
        guard let value = Decimal(string: self) else {
            return .zero
        }
        return value
    }

    /// Parses the string to a `Date` using a fixed (locale-independent) date format template.
    /// - Parameter template: A date format template defined by ``DateFormatter/Template``.
    /// - Returns: A `Date` when parsing succeeds; otherwise `nil`.
    func dateValueWithoutLocale(_ template: DateFormatter.Template) -> Date? {
        DateFormatter.fixed(template).date(from: self)
    }
}
