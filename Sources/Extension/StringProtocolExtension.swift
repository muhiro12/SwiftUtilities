//
//  StringProtocolExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

import Foundation

public extension StringProtocol {
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
