//
//  TimeInterval+Extensions.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation

extension TimeInterval {

    // MARK: - Conversions

    /// Convert seconds to minutes
    var minutes: Double {
        return self / 60.0
    }

    /// Convert seconds to hours
    var hours: Double {
        return self / 3600.0
    }

    /// Convert seconds to days
    var days: Double {
        return self / 86400.0
    }

    /// Create TimeInterval from minutes
    /// - Parameter minutes: Number of minutes
    /// - Returns: TimeInterval in seconds
    static func minutes(_ minutes: Double) -> TimeInterval {
        return minutes * 60.0
    }

    /// Create TimeInterval from hours
    /// - Parameter hours: Number of hours
    /// - Returns: TimeInterval in seconds
    static func hours(_ hours: Double) -> TimeInterval {
        return hours * 3600.0
    }

    // MARK: - Formatting

    /// Format as MM:SS string
    var timerString: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format as HH:MM:SS string (for durations >= 1 hour)
    var longTimerString: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Format as human-readable duration (e.g., "5 min", "1 hr 30 min")
    var humanReadable: String {
        let totalMinutes = Int(self / 60)

        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60

            if minutes == 0 {
                return hours == 1 ? "1 hr" : "\(hours) hrs"
            } else {
                return "\(hours) hr \(minutes) min"
            }
        }
    }

    /// Format as compact duration (e.g., "5m", "1h 30m")
    var compactString: String {
        let totalMinutes = Int(self / 60)

        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60

            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }

    // MARK: - Validation

    /// Check if duration is valid for meditation session
    var isValidMeditationDuration: Bool {
        let minutes = Int(self / 60)
        return minutes >= Constants.Timer.minimumDuration &&
               minutes <= Constants.Timer.maximumDuration
    }

    /// Check if duration meets minimum valid session threshold
    var meetsMinimumThreshold: Bool {
        return self >= Constants.Timer.minimumValidSessionSeconds
    }

    // MARK: - Rounding

    /// Round to nearest minute
    var roundedToMinute: TimeInterval {
        return (self / 60.0).rounded() * 60.0
    }

    /// Round down to whole minutes
    var flooredToMinute: TimeInterval {
        return floor(self / 60.0) * 60.0
    }

    /// Round up to whole minutes
    var ceiledToMinute: TimeInterval {
        return ceil(self / 60.0) * 60.0
    }
}
