//
//  StringExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

public extension String {
    func containsNormalized(_ otherString: String) -> Bool {
        let normalizedSelf = self
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .lowercased() ?? .empty

        let normalizedOther = otherString
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .lowercased() ?? .empty

        return normalizedSelf.contains(normalizedOther)
    }
}
