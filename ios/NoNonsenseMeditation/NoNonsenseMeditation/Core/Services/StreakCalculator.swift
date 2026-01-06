//
//  StreakCalculator.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation

/// Value type for calculating meditation streaks from sessions
/// Provides algorithms for computing consecutive day streaks
struct StreakCalculator: Sendable {

    // MARK: - Streak Calculation

    /// Calculate the current meditation streak (consecutive days with valid sessions)
    /// - Parameter sessions: Array of meditation sessions sorted by date (newest first)
    /// - Returns: Number of consecutive days with at least one valid session
    func calculateCurrentStreak(from sessions: [MeditationSession]) -> Int {
        // Filter valid sessions only
        let validSessions = sessions.filter { $0.isSessionValid }

        guard !validSessions.isEmpty else { return 0 }

        // Get calendar for date comparisons
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group sessions by day
        let sessionsByDay = groupSessionsByDay(validSessions, calendar: calendar)

        // Check if user meditated today or yesterday
        let hasMeditatedToday = sessionsByDay.keys.contains { calendar.isDate($0, inSameDayAs: today) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let hasMeditatedYesterday = sessionsByDay.keys.contains { calendar.isDate($0, inSameDayAs: yesterday) }

        // Streak is broken if didn't meditate today or yesterday
        guard hasMeditatedToday || hasMeditatedYesterday else {
            return 0
        }

        // Start counting from today or yesterday
        var streakCount = 0
        var currentDate = hasMeditatedToday ? today : yesterday

        // Count consecutive days backwards
        while sessionsByDay.keys.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
            streakCount += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streakCount
    }

    /// Calculate the longest streak ever achieved
    /// - Parameter sessions: Array of meditation sessions sorted by date
    /// - Returns: Length of the longest streak
    func calculateLongestStreak(from sessions: [MeditationSession]) -> Int {
        let validSessions = sessions.filter { $0.isSessionValid }
        guard !validSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sessionsByDay = groupSessionsByDay(validSessions, calendar: calendar)

        // Sort days chronologically
        let sortedDays = sessionsByDay.keys.sorted()

        var longestStreak = 0
        var currentStreak = 1

        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i - 1]
            let currentDay = sortedDays[i]

            // Check if days are consecutive
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: currentDay) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return max(longestStreak, currentStreak)
    }

    // MARK: - Helper Methods

    /// Group meditation sessions by day
    /// - Parameters:
    ///   - sessions: Array of meditation sessions
    ///   - calendar: Calendar to use for date operations
    /// - Returns: Dictionary mapping dates to sessions on that day
    private func groupSessionsByDay(
        _ sessions: [MeditationSession],
        calendar: Calendar
    ) -> [Date: [MeditationSession]] {
        var sessionsByDay: [Date: [MeditationSession]] = [:]

        for session in sessions {
            guard let createdAt = session.createdAt else { continue }
            let dayStart = calendar.startOfDay(for: createdAt)
            if sessionsByDay[dayStart] != nil {
                sessionsByDay[dayStart]?.append(session)
            } else {
                sessionsByDay[dayStart] = [session]
            }
        }

        return sessionsByDay
    }

    /// Check if a specific date has any valid meditation sessions
    /// - Parameters:
    ///   - date: Date to check
    ///   - sessions: Array of meditation sessions
    /// - Returns: True if there are valid sessions on the date
    func hasMeditatedOn(date: Date, sessions: [MeditationSession]) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        return sessions.contains { session in
            guard let createdAt = session.createdAt else { return false }
            return session.isSessionValid &&
                calendar.isDate(calendar.startOfDay(for: createdAt), inSameDayAs: targetDay)
        }
    }

    /// Get the last date when user meditated
    /// - Parameter sessions: Array of meditation sessions sorted by date (newest first)
    /// - Returns: Date of last valid session, or nil if no valid sessions
    func lastMeditationDate(from sessions: [MeditationSession]) -> Date? {
        return sessions.first { $0.isSessionValid }?.createdAt
    }
}
