import Testing
@testable import SwiftUtilities
import Foundation

@Suite("Numeric/Decimal Extensions")
struct NumericDecimalExtensionTests {
    @Test
    func numericZeroHelpers() {
        let zInt = 0
        #expect(zInt.isZero)
        #expect(!zInt.isNotZero)

        let nInt = 42
        #expect(!nInt.isZero)
        #expect(nInt.isNotZero)

        let zDouble = 0.0
        #expect(zDouble.isZero)
        #expect(!zDouble.isNotZero)
    }

    @Test
    func decimalSignChecks() {
        let plus = Decimal(10)
        let minus = Decimal(-1)
        let zero = Decimal.zero

        #expect(plus.isPlus)
        #expect(!plus.isMinus)

        #expect(minus.isMinus)
        #expect(!minus.isPlus)

        #expect(!zero.isPlus)
        #expect(!zero.isMinus)
    }
}

