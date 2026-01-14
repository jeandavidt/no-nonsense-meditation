//
//  SessionStatistics.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Updated on 2026-01-14 - Added focus session statistics
//

import Foundation

/// Value type representing computed meditation statistics
/// Used for displaying aggregate data in the UI
struct SessionStatistics: Sendable {

    // MARK: - Properties

    /// Total minutes meditated today
    let todayMinutes: Double

    /// Total minutes meditated this week (Monday-Sunday)
    let thisWeekMinutes: Double

    /// Current consecutive day streak
    let currentStreak: Int

    /// Total minutes meditated all-time
    let totalMinutes: Double

    /// Total number of valid sessions completed
    let totalSessions: Int

    /// Average session duration in minutes
    let averageSessionDuration: Double

    /// Longest single session duration in minutes
    let longestSessionDuration: Double

    /// Date of the last completed session
    let lastSessionDate: Date?

    // MARK: - Focus-Specific Properties

    /// Total focus minutes today
    let focusTodayMinutes: Double

    /// Total focus minutes this week
    let focusThisWeekMinutes: Double

    /// Current focus session streak
    let focusCurrentStreak: Int

    /// Total focus minutes all-time
    let focusTotalMinutes: Double

    /// Total focus sessions completed
    let focusTotalSessions: Int

    /// Average focus session duration
    let focusAverageSessionDuration: Double

    // MARK: - Session-Specific Properties

    /// Planned duration for this session in seconds
    let plannedDuration: TimeInterval

    /// Actual meditation time for this session in seconds
    let actualDuration: TimeInterval

    /// Whether this session was paused
    let wasPaused: Bool

    // MARK: - Computed Properties

    /// Whether the user has meditated today
    var hasMeditatedToday: Bool {
        return todayMinutes > 0
    }

    /// Whether the user has an active streak (meditated today or yesterday)
    var hasActiveStreak: Bool {
        return currentStreak > 0
    }

    /// Formatted current streak display string
    var streakDisplayString: String {
        if currentStreak == 0 {
            return "No streak"
        } else if currentStreak == 1 {
            return "1 day"
        } else {
            return "\(currentStreak) days"
        }
    }

    /// Formatted focus streak display string
    var focusStreakDisplayString: String {
        if focusCurrentStreak == 0 {
            return "No focus streak"
        } else if focusCurrentStreak == 1 {
            return "1 day"
        } else {
            return "\(focusCurrentStreak) days"
        }
    }

    // MARK: - Session-Specific Computed Properties

    /// Duration difference (actual - planned) in seconds
    var durationDifference: TimeInterval {
        return actualDuration - plannedDuration
    }

    /// Focus percentage (actual / planned * 100)
    var focusPercentage: String {
        if plannedDuration <= 0 {
            return "100"
        }
        let percentage = min(max((actualDuration / plannedDuration) * 100, 0), 100)
        return String(format: "%.0f", percentage)
    }

    /// Completion percentage
    var completionPercentage: String {
        if plannedDuration <= 0 {
            return "100"
        }
        let percentage = min(max((actualDuration / plannedDuration) * 100, 0), 100)
        return String(format: "%.0f", percentage)
    }

    /// Formatted planned duration
    var formattedPlannedDuration: String {
        let minutes = Int(plannedDuration) / 60
        let seconds = Int(plannedDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted actual duration
    var formattedActualDuration: String {
        let minutes = Int(actualDuration) / 60
        let seconds = Int(actualDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted duration difference
    var formattedDurationDifference: String {
        let minutes = Int(abs(durationDifference)) / 60
        let seconds = Int(abs(durationDifference)) % 60
        let sign = durationDifference >= 0 ? "+" : "-"
        return sign + String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Initialization

    /// Initialize with default zero values
    init(
        todayMinutes: Double = 0,
        thisWeekMinutes: Double = 0,
        currentStreak: Int = 0,
        totalMinutes: Double = 0,
        totalSessions: Int = 0,
        averageSessionDuration: Double = 0,
        longestSessionDuration: Double = 0,
        lastSessionDate: Date? = nil,
        plannedDuration: TimeInterval = 0,
        actualDuration: TimeInterval = 0,
        wasPaused: Bool = false,
        // Focus-specific parameters
        focusTodayMinutes: Double = 0,
        focusThisWeekMinutes: Double = 0,
        focusCurrentStreak: Int = 0,
        focusTotalMinutes: Double = 0,
        focusTotalSessions: Int = 0,
        focusAverageSessionDuration: Double = 0
    ) {
        self.todayMinutes = todayMinutes
        self.thisWeekMinutes = thisWeekMinutes
        self.currentStreak = currentStreak
        self.totalMinutes = totalMinutes
        self.totalSessions = totalSessions
        self.averageSessionDuration = averageSessionDuration
        self.longestSessionDuration = longestSessionDuration
        self.lastSessionDate = lastSessionDate
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.wasPaused = wasPaused
        self.focusTodayMinutes = focusTodayMinutes
        self.focusThisWeekMinutes = focusThisWeekMinutes
        self.focusCurrentStreak = focusCurrentStreak
        self.focusTotalMinutes = focusTotalMinutes
        self.focusTotalSessions = focusTotalSessions
        self.focusAverageSessionDuration = focusAverageSessionDuration
    }

    // MARK: - Static Factory

    /// Empty statistics with all zero values
    static var empty: SessionStatistics {
        return SessionStatistics()
    }
}

// MARK: - Equatable Conformance

extension SessionStatistics: Equatable {
    static func == (lhs: SessionStatistics, rhs: SessionStatistics) -> Bool {
        return lhs.todayMinutes == rhs.todayMinutes &&
               lhs.thisWeekMinutes == rhs.thisWeekMinutes &&
               lhs.currentStreak == rhs.currentStreak &&
               lhs.totalMinutes == rhs.totalMinutes &&
               lhs.totalSessions == rhs.totalSessions &&
               lhs.averageSessionDuration == rhs.averageSessionDuration &&
               lhs.longestSessionDuration == rhs.longestSessionDuration &&
               lhs.lastSessionDate == rhs.lastSessionDate &&
               lhs.plannedDuration == rhs.plannedDuration &&
               lhs.actualDuration == rhs.actualDuration &&
               lhs.wasPaused == rhs.wasPaused
    }
}
