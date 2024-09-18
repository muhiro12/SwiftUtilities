//
//  StringExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

extension String {
    func containsNormalized(_ otherString: String) -> Bool {
        let normalizedSelf = self
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .lowercased() ?? .empty

        let normalizedOther = otherString
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .lowercased() ?? .empty

        return normalizedSelf.contains(normalizedOther)
    }
}
