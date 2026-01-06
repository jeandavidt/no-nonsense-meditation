//
//  Date+Extensions.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation

extension Date {

    // MARK: - Day Boundaries

    /// Get start of day for this date
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// Get end of day for this date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Week Boundaries

    /// Get start of week for this date (Monday)
    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? self
    }

    /// Get end of week for this date (Sunday)
    var endOfWeek: Date {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return self
        }
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)?.endOfDay ?? self
    }

    // MARK: - Relative Dates

    /// Check if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    /// Check if date is in current week
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Check if date is in same day as another date
    /// - Parameter date: Date to compare with
    /// - Returns: True if dates are on the same day
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    // MARK: - Date Arithmetic

    /// Add days to date
    /// - Parameter days: Number of days to add (can be negative)
    /// - Returns: New date with days added
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add weeks to date
    /// - Parameter weeks: Number of weeks to add (can be negative)
    /// - Returns: New date with weeks added
    func adding(weeks: Int) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    /// Add months to date
    /// - Parameter months: Number of months to add (can be negative)
    /// - Returns: New date with months added
    func adding(months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    // MARK: - Formatting

    /// Format date as relative string (e.g., "Today", "Yesterday", "3 days ago")
    var relativeString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let days = calendar.dateComponents([.day], from: self, to: now).day, days < 7 {
            return "\(days) days ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }

    /// Format date as short string (e.g., "Jan 5")
    var shortString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Format date as time string (e.g., "3:30 PM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    // MARK: - Day Difference

    /// Calculate number of days between this date and another date
    /// - Parameter date: Date to compare with
    /// - Returns: Number of days difference (positive if this date is later)
    func days(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date.startOfDay, to: self.startOfDay)
        return components.day ?? 0
    }
}
