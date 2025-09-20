//
//  CalendarExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/08/10.
//

import Foundation

public nonisolated extension Calendar {
    /// A Gregorian calendar fixed to the UTC time zone.
    static var utc: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .init(secondsFromGMT: .zero) ?? .current
        return calendar
    }

    /// Returns the last moment (23:59:59) of the day that contains the given date.
    /// - Parameter date: A date in this calendar.
    /// - Returns: A date representing the end of the day.
    func endOfDay(for date: Date) -> Date {
        guard let next = self.date(byAdding: .day, value: 1, to: date) else {
            assertionFailure()
            return date
        }
        return startOfDay(for: next) - 1
    }

    /// Returns the first moment (00:00:00) of the month that contains the given date.
    /// - Parameter date: A date in this calendar.
    /// - Returns: A date representing the start of the month.
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        guard let start = self.date(from: components) else {
            assertionFailure()
            return date
        }
        return start
    }

    /// Returns the last moment (23:59:59) of the month that contains the given date.
    /// - Parameter date: A date in this calendar.
    /// - Returns: A date representing the end of the month.
    func endOfMonth(for date: Date) -> Date {
        guard let next = self.date(byAdding: .month, value: 1, to: date) else {
            assertionFailure()
            return date
        }
        return startOfMonth(for: next) - 1
    }

    /// Returns the first moment (00:00:00) of the year that contains the given date.
    /// - Parameter date: A date in this calendar.
    /// - Returns: A date representing the start of the year.
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        guard let start = self.date(from: components) else {
            assertionFailure()
            return date
        }
        return start
    }

    /// Returns the last moment (23:59:59) of the year that contains the given date.
    /// - Parameter date: A date in this calendar.
    /// - Returns: A date representing the end of the year.
    func endOfYear(for date: Date) -> Date {
        guard let next = self.date(byAdding: .year, value: 1, to: date) else {
            assertionFailure()
            return date
        }
        return startOfYear(for: next) - 1
    }

    /// Creates a date in this calendar by copying Y/M/D h:m:s components from a date in another calendar.
    /// - Parameters:
    ///   - date: The source date whose components will be copied.
    ///   - calendar: The calendar from which to read components.
    /// - Returns: A new date in this calendar built from the copied components.
    func shiftedDate(componentsFrom date: Date, in calendar: Calendar) -> Date {
        let shifted = self.date(
            from: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
        )
        guard let shifted else {
            assertionFailure("Failed to shift date components from \(calendar) to \(self) for date: \(date)")
            return date
        }
        return shifted
    }
}
