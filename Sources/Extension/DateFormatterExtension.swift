//
//  DateFormatterExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2023/09/26.
//  Copyright © 2023 Hiromu Nakano. All rights reserved.
//

import Foundation

public nonisolated extension DateFormatter {
    /// A small set of date format templates used across the library.
    enum Template: String {
        case yyyy
        case yyyyMM
        case yyyyMMM
        case MMMd
        case yyyyMMdd
        case yyyyMMMd
    }

    private static let defaultFormatter = DateFormatter()

    /// Returns a reusable date formatter configured with the given template and locale.
    /// - Parameters:
    ///   - template: A template used to derive a locale-appropriate date format.
    ///   - locale: The locale to use when formatting.
    /// - Returns: A shared `DateFormatter` instance configured for the inputs.
    static func `default`(_ template: Template, locale: Locale) -> DateFormatter {
        let formatter = defaultFormatter
        formatter.dateFormat = dateFormat(
            fromTemplate: template.rawValue,
            options: .zero,
            locale: locale
        )
        formatter.locale = locale
        return formatter
    }

    /// Returns a reusable date formatter configured with a fixed, locale-independent format.
    /// - Parameter template: A template used directly as the `dateFormat`.
    /// - Returns: A shared `DateFormatter` instance using the POSIX locale.
    static func fixed(_ template: Template) -> DateFormatter {
        let formatter = defaultFormatter
        formatter.dateFormat = template.rawValue
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }
}
