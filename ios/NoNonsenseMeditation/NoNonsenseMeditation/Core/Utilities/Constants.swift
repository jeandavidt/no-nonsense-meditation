//
//  Constants.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import SwiftUI

/// Application-wide constants
enum Constants {

    // MARK: - App Information

    enum App {
        static let name = "No Nonsense Meditation"
        static let bundleIdentifier = "com.jeandavidt.NoNonsenseMeditation"
        static let cloudKitContainerIdentifier = "iCloud.com.jeandavidt.NoNonsenseMeditation"
    }

    // MARK: - Timer Defaults

    enum Timer {
        /// Default meditation duration in minutes
        static let defaultDuration = 15

        /// Minimum meditation duration in minutes
        static let minimumDuration = 1

        /// Maximum meditation duration in minutes
        static let maximumDuration = 120

        /// Preset duration options in minutes
        static let presetDurations = [5, 10, 15, 20, 30, 45, 60]

        /// Minimum session duration to be considered valid (in seconds)
        static let minimumValidSessionSeconds: TimeInterval = 15

        /// Minimum session percentage to be considered valid (5% of planned duration)
        static let minimumValidSessionPercentage: Double = 0.05

        /// Timer update interval in seconds
        static let updateInterval: TimeInterval = 1.0
    }

    // MARK: - Colors

    enum Colors {
        // Accent Color
        static let accentLight = Color(hex: "2C5F7C")
        static let accentDark = Color(hex: "5B9EC9")

        // Timer Active State
        static let timerActiveLight = Color(hex: "7C6C5B")
        static let timerActiveDark = Color(hex: "A89B8C")

        // Success/Completion
        static let successLight = Color(hex: "5A7C5F")
        static let successDark = Color(hex: "7FA584")

        /// Dynamic accent color based on color scheme
        static func accent(for colorScheme: ColorScheme) -> Color {
            return colorScheme == .dark ? accentDark : accentLight
        }

        /// Dynamic timer active color based on color scheme
        static func timerActive(for colorScheme: ColorScheme) -> Color {
            return colorScheme == .dark ? timerActiveDark : timerActiveLight
        }

        /// Dynamic success color based on color scheme
        static func success(for colorScheme: ColorScheme) -> Color {
            return colorScheme == .dark ? successDark : successLight
        }
    }

    // MARK: - Typography

    enum Typography {
        /// Timer countdown display
        static let timerDisplay = Font.system(size: 72, weight: .thin, design: .rounded)

        /// Large statistics numbers
        static let largeStat = Font.system(size: 48, weight: .light, design: .rounded)

        /// Section headers
        static let sectionHeader = Font.system(size: 20, weight: .semibold, design: .default)

        /// Body text
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Secondary/caption text
        static let secondary = Font.system(size: 15, weight: .regular, design: .default)

        /// Button labels
        static let button = Font.system(size: 17, weight: .semibold, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let huge: CGFloat = 48
    }

    // MARK: - Layout

    enum Layout {
        /// Primary button height
        static let primaryButtonHeight: CGFloat = 50

        /// Primary button corner radius
        static let primaryButtonCornerRadius: CGFloat = 25

        /// Card corner radius
        static let cardCornerRadius: CGFloat = 16

        /// Card padding
        static let cardPadding: CGFloat = 20

        /// Timer progress ring stroke width (active)
        static let timerRingStrokeWidth: CGFloat = 12

        /// Timer progress ring background stroke width
        static let timerRingBackgroundStrokeWidth: CGFloat = 8

        /// Minimum tap target size (accessibility)
        static let minimumTapTarget: CGFloat = 44
    }

    // MARK: - Animation

    enum Animation {
        /// Spring animation for buttons
        static let buttonSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)

        /// Linear animation for timer countdown
        static let timerLinear = SwiftUI.Animation.linear(duration: 1.0)

        /// Ease in-out for view transitions
        static let transition = SwiftUI.Animation.easeInOut(duration: 0.3)
    }

    // MARK: - Sound

    enum Sound {
        /// Default meditation bell sound filename
        static let defaultBell = "meditation_bell"

        /// Available bell sound options
        static let availableBells = ["meditation_bell"]
    }

    // MARK: - Notifications

    enum Notifications {
        /// Meditation completion notification identifier
        static let completionIdentifier = "meditation-completion"

        /// Daily reminder notification identifier
        static let dailyReminderIdentifier = "daily-reminder"
    }

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let defaultDuration = "defaultDuration"
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let healthKitSyncEnabled = "healthKitSyncEnabled"
        static let selectedBellSound = "selectedBellSound"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let overrideSilentMode = "overrideSilentMode"
        static let keepScreenAwake = "keepScreenAwake"
        static let dailyReminderEnabled = "dailyReminderEnabled"
        static let dailyReminderTime = "dailyReminderTime"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    // MARK: - Streak Milestones

    enum Milestones {
        static let streakMilestones = [7, 30, 100, 365]

        /// Get milestone message for a given streak
        /// - Parameter streak: Current streak count
        /// - Returns: Milestone message if applicable
        static func message(for streak: Int) -> String? {
            switch streak {
            case 7:
                return "7-day streak! You're building a habit!"
            case 30:
                return "30-day streak! One month of mindfulness!"
            case 100:
                return "100-day streak! You're a meditation master!"
            case 365:
                return "365-day streak! A full year of practice!"
            default:
                return nil
            }
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "2C5F7C")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
