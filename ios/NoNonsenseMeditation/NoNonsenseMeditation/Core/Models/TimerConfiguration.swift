//
//  TimerConfiguration.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation

/// Configuration model for meditation timer setup
/// Defines the parameters for starting a new meditation session
struct TimerConfiguration: Sendable {

    // MARK: - Properties

    /// Planned duration in minutes
    let durationMinutes: Int

    /// Whether to keep the screen awake during meditation
    let keepScreenAwake: Bool

    /// Whether to play bell sound on completion
    let playBellSound: Bool

    /// Whether to override silent mode for bell sound
    let overrideSilentMode: Bool

    /// Whether to provide haptic feedback on completion
    let hapticFeedbackEnabled: Bool

    // MARK: - Computed Properties

    /// Duration in seconds
    var durationSeconds: TimeInterval {
        return TimeInterval(durationMinutes * 60)
    }

    /// Whether the configuration is valid
    var isValid: Bool {
        return durationMinutes >= 1 && durationMinutes <= 120
    }

    // MARK: - Initialization

    /// Initialize timer configuration with specified parameters
    /// - Parameters:
    ///   - durationMinutes: Meditation duration in minutes (1-120)
    ///   - keepScreenAwake: Whether to prevent screen from sleeping
    ///   - playBellSound: Whether to play completion bell
    ///   - overrideSilentMode: Whether to play sound even in silent mode
    ///   - hapticFeedbackEnabled: Whether to provide haptic feedback
    init(
        durationMinutes: Int,
        keepScreenAwake: Bool = true,
        playBellSound: Bool = true,
        overrideSilentMode: Bool = false,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.durationMinutes = durationMinutes
        self.keepScreenAwake = keepScreenAwake
        self.playBellSound = playBellSound
        self.overrideSilentMode = overrideSilentMode
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    // MARK: - Presets

    /// Default meditation configuration (15 minutes)
    static var `default`: TimerConfiguration {
        return TimerConfiguration(durationMinutes: 15)
    }

    /// Common preset durations
    static let presetDurations = [5, 10, 15, 20, 30, 45, 60]

    /// Quick 5-minute session
    static var quick: TimerConfiguration {
        return TimerConfiguration(durationMinutes: 5)
    }

    /// Standard 15-minute session
    static var standard: TimerConfiguration {
        return TimerConfiguration(durationMinutes: 15)
    }

    /// Extended 30-minute session
    static var extended: TimerConfiguration {
        return TimerConfiguration(durationMinutes: 30)
    }

    /// Long 60-minute session
    static var long: TimerConfiguration {
        return TimerConfiguration(durationMinutes: 60)
    }
}

// MARK: - Equatable Conformance

extension TimerConfiguration: Equatable {
    static func == (lhs: TimerConfiguration, rhs: TimerConfiguration) -> Bool {
        return lhs.durationMinutes == rhs.durationMinutes &&
               lhs.keepScreenAwake == rhs.keepScreenAwake &&
               lhs.playBellSound == rhs.playBellSound &&
               lhs.overrideSilentMode == rhs.overrideSilentMode &&
               lhs.hapticFeedbackEnabled == rhs.hapticFeedbackEnabled
    }
}

// MARK: - Codable Conformance

extension TimerConfiguration: Codable {
    // Automatic synthesis for persistence to UserDefaults if needed
}
