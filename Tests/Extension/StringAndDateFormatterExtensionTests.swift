import Testing
@testable import SwiftUtilities
import Foundation

@Suite("String/DateFormatter/Date Extensions")
struct StringAndDateFormatterExtensionTests {
    @Test
    func stringDecimalHelpers() {
        #expect("".isEmptyOrDecimal)
        #expect("123".isEmptyOrDecimal)
        #expect(!"abc".isEmptyOrDecimal)

        #expect("42.5".decimalValue == Decimal(string: "42.5"))
        #expect("abc".decimalValue == .zero)
    }

    @Test
    func dateFormatterFixedAndDefault() {
        // Fixed format is literal and locale-independent
        let fixed = DateFormatter.fixed(.yyyyMMdd)
        let comps = DateComponents(calendar: .init(identifier: .gregorian), timeZone: .init(secondsFromGMT: 0), year: 2024, month: 1, day: 2)
        let date = comps.date!
        #expect(fixed.string(from: date) == "20240102")

        // Default uses provided locale
        let us = Locale(identifier: "en_US")
        let formatted = DateFormatter.default(.yyyyMMMd, locale: us).string(from: date)
        // Template "yyyyMMMd" in en_US becomes e.g. "Jan 2, 2024"
        #expect(formatted == "Jan 2, 2024")
    }

    @Test
    func dateStringBridging() {
        let tz = TimeZone(secondsFromGMT: 0)!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let date = cal.date(from: .init(year: 2023, month: 9, day: 26))!

        // stringValue with explicit locale
        let us = Locale(identifier: "en_US")
        let str = date.stringValue(.yyyyMMMd, locale: us)
        #expect(str == "Sep 26, 2023")

        // Locale-independent fixed format round-trip
        let fixedStr = date.stringValueWithoutLocale(.yyyyMMdd)
        #expect(fixedStr == "20230926")
        #expect(fixedStr.dateValueWithoutLocale(.yyyyMMdd)?.stringValueWithoutLocale(.yyyyMMdd) == fixedStr)
    }
}

