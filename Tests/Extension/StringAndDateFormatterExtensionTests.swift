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
        let comps = DateComponents(calendar: .init(identifier: .gregorian), timeZone: .current, year: 2024, month: 1, day: 2)
        let date = comps.date!
        #expect(fixed.string(from: date) == "20240102")

        // Default uses provided locale
        let us = Locale(identifier: "en_US")
        let formatted = DateFormatter.default(.yyyyMMMd, locale: us).string(from: date)
        // Template "yyyyMMMd" in en_US becomes e.g. "Jan 2, 2024"
        #expect(formatted == "Jan 2, 2024")
    }

    @Test
    func dateFormatterFactoriesCreateIndependentInstances() {
        #expect(DateFormatter.fixed(.yyyyMMdd) !== DateFormatter.fixed(.yyyyMMdd))

        let us = Locale(identifier: "en_US")
        #expect(DateFormatter.default(.yyyyMMMd, locale: us) !== DateFormatter.default(.yyyyMMMd, locale: us))
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

    @Test
    func fixedTemplatesDoNotMixUnderParallelExecution() async {
        let date = "20240102".dateValueWithoutLocale(.yyyyMMdd)!

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 24 {
                group.addTask {
                    for _ in 0 ..< 600 {
                        let yyyy = date.stringValueWithoutLocale(.yyyy)
                        #expect(yyyy == "2024")
                        #expect(yyyy.dateValueWithoutLocale(.yyyy)?.stringValueWithoutLocale(.yyyy) == "2024")

                        let yyyyMM = date.stringValueWithoutLocale(.yyyyMM)
                        #expect(yyyyMM == "202401")
                        #expect(yyyyMM.dateValueWithoutLocale(.yyyyMM)?.stringValueWithoutLocale(.yyyyMM) == "202401")

                        let yyyyMMdd = date.stringValueWithoutLocale(.yyyyMMdd)
                        #expect(yyyyMMdd == "20240102")
                        #expect(yyyyMMdd.dateValueWithoutLocale(.yyyyMMdd)?.stringValueWithoutLocale(.yyyyMMdd) == "20240102")

                        let yyyyMMM = date.stringValueWithoutLocale(.yyyyMMM)
                        #expect(yyyyMMM == "2024Jan")
                        #expect(yyyyMMM.dateValueWithoutLocale(.yyyyMMM)?.stringValueWithoutLocale(.yyyyMMM) == "2024Jan")
                    }
                }
            }
            await group.waitForAll()
        }
    }

    @Test
    func localeAwareTemplatesDoNotMixUnderParallelExecution() async {
        let comps = DateComponents(calendar: .init(identifier: .gregorian), timeZone: .current, year: 2024, month: 1, day: 2)
        let date = comps.date!
        let expectedYYYY = DateFormatter.default(.yyyy, locale: Locale(identifier: "en_US")).string(from: date)
        let expectedYYYYMM = DateFormatter.default(.yyyyMM, locale: Locale(identifier: "en_US")).string(from: date)
        let expectedYYYYMMDD = DateFormatter.default(.yyyyMMdd, locale: Locale(identifier: "en_US")).string(from: date)
        let expectedYYYYMMM = DateFormatter.default(.yyyyMMM, locale: Locale(identifier: "en_US")).string(from: date)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 24 {
                group.addTask {
                    for _ in 0 ..< 600 {
                        let locale = Locale(identifier: "en_US")
                        #expect(date.stringValue(.yyyy, locale: locale) == expectedYYYY)
                        #expect(date.stringValue(.yyyyMM, locale: locale) == expectedYYYYMM)
                        #expect(date.stringValue(.yyyyMMdd, locale: locale) == expectedYYYYMMDD)
                        #expect(date.stringValue(.yyyyMMM, locale: locale) == expectedYYYYMMM)
                    }
                }
            }
            await group.waitForAll()
        }
    }
}
