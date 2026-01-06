//
//  DateTestHelpers.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import Foundation

/// Helper utilities for working with dates in tests
enum DateTestHelpers {

    /// Create a date with specific components
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day
    ///   - hour: Hour (0-23), default 12
    ///   - minute: Minute (0-59), default 0
    ///   - second: Second (0-59), default 0
    /// - Returns: Date with specified components
    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        let calendar = Calendar.current
        return calendar.date(from: components) ?? Date()
    }

    /// Create a date relative to now
    /// - Parameters:
    ///   - days: Number of days to add (negative for past)
    ///   - hours: Number of hours to add (negative for past)
    ///   - minutes: Number of minutes to add (negative for past)
    /// - Returns: Date relative to current date
    static func dateFromNow(
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0
    ) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = days
        components.hour = hours
        components.minute = minutes

        return calendar.date(byAdding: components, to: Date()) ?? Date()
    }

    /// Get start of day for a date
    /// - Parameter date: Input date
    /// - Returns: Start of day
    static func startOfDay(_ date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    /// Get end of day for a date
    /// - Parameter date: Input date
    /// - Returns: End of day (23:59:59)
    static func endOfDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = 1
        components.second = -1

        let startOfNextDay = calendar.date(
            byAdding: components,
            to: calendar.startOfDay(for: date)
        ) ?? date

        return startOfNextDay
    }

    /// Check if two dates are on the same day
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if dates are on same day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    /// Create an array of consecutive dates
    /// - Parameters:
    ///   - count: Number of dates to create
    ///   - startingFrom: Starting date (default: today)
    ///   - goingBackward: If true, dates go backward in time
    /// - Returns: Array of consecutive dates
    static func consecutiveDates(
        count: Int,
        startingFrom: Date = Date(),
        goingBackward: Bool = true
    ) -> [Date] {
        let calendar = Calendar.current
        let direction = goingBackward ? -1 : 1

        return (0..<count).map { offset in
            calendar.date(
                byAdding: .day,
                value: offset * direction,
                to: startingFrom
            ) ?? startingFrom
        }
    }

    /// Create dates with gaps
    /// - Parameters:
    ///   - pattern: Array of day offsets from start
    ///   - startingFrom: Starting date
    /// - Returns: Array of dates with gaps
    static func datesWithGaps(
        pattern: [Int],
        startingFrom: Date = Date()
    ) -> [Date] {
        let calendar = Calendar.current

        return pattern.map { offset in
            calendar.date(
                byAdding: .day,
                value: offset,
                to: startingFrom
            ) ?? startingFrom
        }
    }
}
