//
//  TimerConfigurationTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
@testable import NoNonsenseMeditation

/// Comprehensive unit tests for TimerConfiguration model
/// Tests validation, computed properties, and presets
final class TimerConfigurationTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let config = TimerConfiguration(durationMinutes: 10)

        XCTAssertEqual(config.durationMinutes, 10)
        XCTAssertTrue(config.keepScreenAwake, "Should keep screen awake by default")
        XCTAssertTrue(config.playBellSound, "Should play bell sound by default")
        XCTAssertFalse(config.overrideSilentMode, "Should not override silent mode by default")
        XCTAssertTrue(config.hapticFeedbackEnabled, "Should enable haptic feedback by default")
    }

    func testCustomInitialization() {
        let config = TimerConfiguration(
            durationMinutes: 15,
            keepScreenAwake: false,
            playBellSound: false,
            overrideSilentMode: true,
            hapticFeedbackEnabled: false
        )

        XCTAssertEqual(config.durationMinutes, 15)
        XCTAssertFalse(config.keepScreenAwake)
        XCTAssertFalse(config.playBellSound)
        XCTAssertTrue(config.overrideSilentMode)
        XCTAssertFalse(config.hapticFeedbackEnabled)
    }

    // MARK: - Computed Property Tests

    func testDurationSeconds() {
        let config1 = TimerConfiguration(durationMinutes: 10)
        XCTAssertEqual(config1.durationSeconds, 600, "10 minutes should be 600 seconds")

        let config2 = TimerConfiguration(durationMinutes: 1)
        XCTAssertEqual(config2.durationSeconds, 60, "1 minute should be 60 seconds")

        let config3 = TimerConfiguration(durationMinutes: 60)
        XCTAssertEqual(config3.durationSeconds, 3600, "60 minutes should be 3600 seconds")
    }

    func testDurationSecondsZero() {
        let config = TimerConfiguration(durationMinutes: 0)
        XCTAssertEqual(config.durationSeconds, 0, "0 minutes should be 0 seconds")
    }

    // MARK: - Validation Tests

    func testIsValid_ValidDurations() {
        let validDurations = [1, 5, 10, 15, 30, 60, 90, 120]

        for duration in validDurations {
            let config = TimerConfiguration(durationMinutes: duration)
            XCTAssertTrue(
                config.isValid,
                "\(duration) minutes should be valid"
            )
        }
    }

    func testIsValid_InvalidDurations() {
        let invalidDurations = [0, -1, -10, 121, 150, 200, 500]

        for duration in invalidDurations {
            let config = TimerConfiguration(durationMinutes: duration)
            XCTAssertFalse(
                config.isValid,
                "\(duration) minutes should be invalid"
            )
        }
    }

    func testIsValid_BoundaryValues() {
        let minValid = TimerConfiguration(durationMinutes: 1)
        XCTAssertTrue(minValid.isValid, "1 minute should be valid (lower boundary)")

        let maxValid = TimerConfiguration(durationMinutes: 120)
        XCTAssertTrue(maxValid.isValid, "120 minutes should be valid (upper boundary)")

        let belowMin = TimerConfiguration(durationMinutes: 0)
        XCTAssertFalse(belowMin.isValid, "0 minutes should be invalid (below boundary)")

        let aboveMax = TimerConfiguration(durationMinutes: 121)
        XCTAssertFalse(aboveMax.isValid, "121 minutes should be invalid (above boundary)")
    }

    // MARK: - Preset Tests

    func testDefaultPreset() {
        let config = TimerConfiguration.default

        XCTAssertEqual(config.durationMinutes, 15, "Default should be 15 minutes")
        XCTAssertTrue(config.isValid, "Default preset should be valid")
        XCTAssertTrue(config.keepScreenAwake)
        XCTAssertTrue(config.playBellSound)
        XCTAssertFalse(config.overrideSilentMode)
        XCTAssertTrue(config.hapticFeedbackEnabled)
    }

    func testQuickPreset() {
        let config = TimerConfiguration.quick

        XCTAssertEqual(config.durationMinutes, 5, "Quick preset should be 5 minutes")
        XCTAssertTrue(config.isValid, "Quick preset should be valid")
    }

    func testStandardPreset() {
        let config = TimerConfiguration.standard

        XCTAssertEqual(config.durationMinutes, 15, "Standard preset should be 15 minutes")
        XCTAssertTrue(config.isValid, "Standard preset should be valid")
    }

    func testExtendedPreset() {
        let config = TimerConfiguration.extended

        XCTAssertEqual(config.durationMinutes, 30, "Extended preset should be 30 minutes")
        XCTAssertTrue(config.isValid, "Extended preset should be valid")
    }

    func testLongPreset() {
        let config = TimerConfiguration.long

        XCTAssertEqual(config.durationMinutes, 60, "Long preset should be 60 minutes")
        XCTAssertTrue(config.isValid, "Long preset should be valid")
    }

    func testAllPresetsAreValid() {
        let presets = [
            TimerConfiguration.default,
            TimerConfiguration.quick,
            TimerConfiguration.standard,
            TimerConfiguration.extended,
            TimerConfiguration.long
        ]

        for preset in presets {
            XCTAssertTrue(preset.isValid, "All presets should be valid")
        }
    }

    func testPresetDurations() {
        let expectedDurations = [5, 10, 15, 20, 30, 45, 60]
        XCTAssertEqual(
            TimerConfiguration.presetDurations,
            expectedDurations,
            "Preset durations should match expected values"
        )
    }

    func testAllPresetDurationsAreValid() {
        for duration in TimerConfiguration.presetDurations {
            let config = TimerConfiguration(durationMinutes: duration)
            XCTAssertTrue(
                config.isValid,
                "Preset duration \(duration) should be valid"
            )
        }
    }

    // MARK: - Equatable Tests

    func testEquatable_EqualConfigurations() {
        let config1 = TimerConfiguration(
            durationMinutes: 10,
            keepScreenAwake: true,
            playBellSound: true,
            overrideSilentMode: false,
            hapticFeedbackEnabled: true
        )

        let config2 = TimerConfiguration(
            durationMinutes: 10,
            keepScreenAwake: true,
            playBellSound: true,
            overrideSilentMode: false,
            hapticFeedbackEnabled: true
        )

        XCTAssertEqual(config1, config2, "Identical configurations should be equal")
    }

    func testEquatable_DifferentDurations() {
        let config1 = TimerConfiguration(durationMinutes: 10)
        let config2 = TimerConfiguration(durationMinutes: 15)

        XCTAssertNotEqual(config1, config2, "Different durations should not be equal")
    }

    func testEquatable_DifferentSettings() {
        let config1 = TimerConfiguration(durationMinutes: 10, keepScreenAwake: true)
        let config2 = TimerConfiguration(durationMinutes: 10, keepScreenAwake: false)

        XCTAssertNotEqual(config1, config2, "Different settings should not be equal")
    }

    func testEquatable_AllDifferentSettings() {
        let config1 = TimerConfiguration(
            durationMinutes: 10,
            keepScreenAwake: true,
            playBellSound: true,
            overrideSilentMode: false,
            hapticFeedbackEnabled: true
        )

        let config2 = TimerConfiguration(
            durationMinutes: 10,
            keepScreenAwake: false,
            playBellSound: false,
            overrideSilentMode: true,
            hapticFeedbackEnabled: false
        )

        XCTAssertNotEqual(config1, config2, "Completely different settings should not be equal")
    }

    func testEquatable_PresetComparison() {
        let quick = TimerConfiguration.quick
        let standard = TimerConfiguration.standard

        XCTAssertNotEqual(quick, standard, "Different presets should not be equal")
    }

    // MARK: - Codable Tests

    func testCodableEncode() throws {
        let config = TimerConfiguration(
            durationMinutes: 15,
            keepScreenAwake: true,
            playBellSound: false,
            overrideSilentMode: true,
            hapticFeedbackEnabled: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        XCTAssertFalse(data.isEmpty, "Encoded data should not be empty")
    }

    func testCodableDecode() throws {
        let config = TimerConfiguration(
            durationMinutes: 20,
            keepScreenAwake: false,
            playBellSound: true,
            overrideSilentMode: false,
            hapticFeedbackEnabled: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(TimerConfiguration.self, from: data)

        XCTAssertEqual(decodedConfig, config, "Decoded config should match original")
    }

    func testCodableRoundTrip() throws {
        let configs = [
            TimerConfiguration.quick,
            TimerConfiguration.standard,
            TimerConfiguration.extended,
            TimerConfiguration.long,
            TimerConfiguration(durationMinutes: 25, keepScreenAwake: false)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for config in configs {
            let data = try encoder.encode(config)
            let decoded = try decoder.decode(TimerConfiguration.self, from: data)
            XCTAssertEqual(decoded, config, "Round trip should preserve configuration")
        }
    }

    // MARK: - Sendable Tests

    func testSendableConformance() async {
        let config = TimerConfiguration(durationMinutes: 10)

        // Test that configuration can be safely passed to actor
        await withCheckedContinuation { continuation in
            Task {
                // If this compiles, Sendable conformance is working
                let _ = config
                continuation.resume()
            }
        }
    }

    // MARK: - Edge Cases

    func testNegativeDuration() {
        let config = TimerConfiguration(durationMinutes: -10)

        XCTAssertEqual(config.durationMinutes, -10, "Should store negative value")
        XCTAssertFalse(config.isValid, "Negative duration should be invalid")
        XCTAssertEqual(config.durationSeconds, -600, "Should calculate negative seconds")
    }

    func testZeroDuration() {
        let config = TimerConfiguration(durationMinutes: 0)

        XCTAssertEqual(config.durationMinutes, 0, "Should store zero")
        XCTAssertFalse(config.isValid, "Zero duration should be invalid")
        XCTAssertEqual(config.durationSeconds, 0, "Should be 0 seconds")
    }

    func testVeryLargeDuration() {
        let config = TimerConfiguration(durationMinutes: 10000)

        XCTAssertEqual(config.durationMinutes, 10000, "Should store large value")
        XCTAssertFalse(config.isValid, "Very large duration should be invalid")
        XCTAssertEqual(config.durationSeconds, 600000, "Should calculate large seconds value")
    }

    func testMaxValidDuration() {
        let config = TimerConfiguration(durationMinutes: 120)

        XCTAssertTrue(config.isValid, "120 minutes should be valid")
        XCTAssertEqual(config.durationSeconds, 7200, "120 minutes = 2 hours = 7200 seconds")
    }

    func testMinValidDuration() {
        let config = TimerConfiguration(durationMinutes: 1)

        XCTAssertTrue(config.isValid, "1 minute should be valid")
        XCTAssertEqual(config.durationSeconds, 60, "1 minute = 60 seconds")
    }

    // MARK: - Configuration Combination Tests

    func testAllCombinationsOfBooleanSettings() {
        let boolCombinations: [(Bool, Bool, Bool, Bool)] = [
            (true, true, true, true),
            (true, true, true, false),
            (true, true, false, true),
            (true, false, true, true),
            (false, true, true, true),
            (false, false, false, false),
            (true, false, false, false),
            (false, true, false, false)
        ]

        for (keepAwake, playBell, overrideSilent, haptic) in boolCombinations {
            let config = TimerConfiguration(
                durationMinutes: 10,
                keepScreenAwake: keepAwake,
                playBellSound: playBell,
                overrideSilentMode: overrideSilent,
                hapticFeedbackEnabled: haptic
            )

            XCTAssertEqual(config.keepScreenAwake, keepAwake)
            XCTAssertEqual(config.playBellSound, playBell)
            XCTAssertEqual(config.overrideSilentMode, overrideSilent)
            XCTAssertEqual(config.hapticFeedbackEnabled, haptic)
        }
    }

    // MARK: - Performance Tests

    func testInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = TimerConfiguration(durationMinutes: 10)
            }
        }
    }

    func testValidationPerformance() {
        let configs = (1...100).map { TimerConfiguration(durationMinutes: $0) }

        measure {
            for config in configs {
                _ = config.isValid
            }
        }
    }

    func testEncodingPerformance() throws {
        let config = TimerConfiguration.standard
        let encoder = JSONEncoder()

        measure {
            for _ in 0..<1000 {
                _ = try? encoder.encode(config)
            }
        }
    }

    func testDecodingPerformance() throws {
        let config = TimerConfiguration.standard
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let decoder = JSONDecoder()

        measure {
            for _ in 0..<1000 {
                _ = try? decoder.decode(TimerConfiguration.self, from: data)
            }
        }
    }
}
