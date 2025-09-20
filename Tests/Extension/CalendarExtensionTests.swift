import Testing
@testable import SwiftUtilities
import Foundation

@Suite("Calendar Extensions")
struct CalendarExtensionTests {
    private var utc: Calendar {
        .utc
    }

    @Test
    func endOfDay() {
        let cal = utc
        let date = cal.date(from: .init(year: 2024, month: 2, day: 29, hour: 15, minute: 30, second: 45))!
        let end = cal.endOfDay(for: date)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        #expect(comps.year == 2024 && comps.month == 2 && comps.day == 29)
        #expect(comps.hour == 23 && comps.minute == 59 && comps.second == 59)
    }

    @Test
    func monthBoundaries() {
        let cal = utc
        let mid = cal.date(from: .init(year: 2023, month: 4, day: 15, hour: 12))!

        let start = cal.startOfMonth(for: mid)
        let s = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        #expect(s.year == 2023 && s.month == 4 && s.day == 1)
        #expect(s.hour == 0 && s.minute == 0 && s.second == 0)

        let end = cal.endOfMonth(for: mid)
        let e = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        #expect(e.year == 2023 && e.month == 4 && e.day == 30)
        #expect(e.hour == 23 && e.minute == 59 && e.second == 59)
    }

    @Test
    func yearBoundaries() {
        let cal = utc
        let mid = cal.date(from: .init(year: 2024, month: 6, day: 15))!

        let start = cal.startOfYear(for: mid)
        let s = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        #expect(s.year == 2024 && s.month == 1 && s.day == 1)
        #expect(s.hour == 0 && s.minute == 0 && s.second == 0)

        let end = cal.endOfYear(for: mid)
        let e = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        #expect(e.year == 2024 && e.month == 12 && e.day == 31)
        #expect(e.hour == 23 && e.minute == 59 && e.second == 59)
    }

    @Test
    func shiftedDateBetweenCalendars() {
        // Components from JST should map 1:1 into UTC calendar
        var jst = Calendar(identifier: .gregorian)
        jst.timeZone = .init(secondsFromGMT: 9 * 3600)!
        let original = jst.date(from: .init(year: 2024, month: 1, day: 2, hour: 3, minute: 4, second: 5))!
        let shifted = utc.shiftedDate(componentsFrom: original, in: jst)

        let comps = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: shifted)
        #expect(comps.year == 2024 && comps.month == 1 && comps.day == 2)
        #expect(comps.hour == 3 && comps.minute == 4 && comps.second == 5)
    }
}
