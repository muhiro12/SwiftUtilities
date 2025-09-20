import Testing
@testable import SwiftUtilities
import Foundation

@Suite("StringProtocol normalizedContains")
struct StringProtocolExtensionTests {
    @Test
    func halfwidthAndHiraganaNormalization() {
        // Halfwidth to fullwidth
        #expect("ｶﾀｶﾅ".normalizedContains("カタカナ"))
        #expect("カタカナ".normalizedContains("ｶﾀｶﾅ"))

        // Hiragana to Katakana
        #expect("ひらがな".normalizedContains("ヒラガナ"))
        #expect("ヒラガナ".normalizedContains("ひらがな"))

        // Also supports substrings
        #expect("これはｶﾀｶﾅです".normalizedContains("カタ"))
    }
}

