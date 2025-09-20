//
//  StringProtocolExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

import Foundation

public extension StringProtocol {
    /// Returns `true` if the receiver contains `other` after applying Unicode-aware normalization.
    ///
    /// The normalization converts full-width to half-width characters and Hiragana to Katakana
    /// before performing a localized, case-insensitive contains check.
    /// - Parameter other: A substring to search for.
    func normalizedContains<T>(_ other: T) -> Bool where T : StringProtocol {
        let normalizedSelf = self
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false) ?? .empty

        let normalizedOther = other
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false) ?? .empty

        return normalizedSelf.localizedStandardContains(normalizedOther)
    }
}
