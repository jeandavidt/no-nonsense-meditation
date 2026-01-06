//
//  SessionRecapViewTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
@testable import NoNonsenseMeditation

final class SessionRecapViewTests: XCTestCase {

    func testSessionRecapViewInitialization() throws {
        // Create a viewModel with a completed session
        let viewModel = TimerViewModel()
        viewModel.startTimer(duration: 300) // 5 minutes
        viewModel.stopTimer()

        // Create the SessionRecapView
        let recapView = SessionRecapView(viewModel: viewModel)

        // Verify the view can be created without crashing
        XCTAssertNotNil(recapView)
    }

    func testSessionStatisticsCalculation() throws {
        // Test various session scenarios
        let testCases = [
            // (plannedDuration, actualDuration, wasPaused, expectedFocusPercentage)
            (300, 300, false, "100"),    // Perfect session
            (300, 240, false, "80"),     // 80% completion
            (300, 360, false, "100"),    // Overachieved (capped at 100%)
            (300, 180, true, "60"),      // Paused session
            (60, 60, false, "100"),       // Short perfect session
            (600, 420, false, "70")      // Long session with 70% focus
        ]

        for testCase in testCases {
            let (planned, actual, paused, expectedFocus) = testCase

            let stats = SessionStatistics(
                plannedDuration: TimeInterval(planned),
                actualDuration: TimeInterval(actual),
                wasPaused: paused
            )

            XCTAssertEqual(stats.focusPercentage, expectedFocus, 
                          "Failed for planned: " + String(planned) + ", actual: " + String(actual))
        }
    }

    func testTimeFormatting() throws {
        let testCases = [
            // (duration, expectedFormatted)
            (0, "00:00"),
            (45, "00:45"),
            (60, "01:00"),
            (125, "02:05"),
            (3600, "60:00"),
            (3665, "61:05")
        ]

        for testCase in testCases {
            let (duration, expected) = testCase
            let stats = SessionStatistics(plannedDuration: TimeInterval(duration), actualDuration: TimeInterval(duration))

            XCTAssertEqual(stats.formattedPlannedDuration, expected)
            XCTAssertEqual(stats.formattedActualDuration, expected)
        }
    }

    func testDurationDifferenceCalculation() throws {
        let testCases = [
            // (planned, actual, expectedDifference)
            (300, 300, 0),      // No difference
            (300, 240, -60),     // 1 minute short
            (300, 360, 60),      // 1 minute over
            (600, 420, -180),    // 3 minutes short
            (120, 180, 60)       // 1 minute over
        ]

        for testCase in testCases {
            let (planned, actual, expectedDiff) = testCase

            let stats = SessionStatistics(
                plannedDuration: TimeInterval(planned),
                actualDuration: TimeInterval(actual)
            )

            XCTAssertEqual(stats.durationDifference, TimeInterval(expectedDiff),
                          "Failed for planned: " + String(planned) + ", actual: " + String(actual))
        }
    }

    func testCompletionPercentage() throws {
        let testCases = [
            // (planned, actual, expectedPercentage)
            (300, 300, "100"),
            (300, 150, "50"),
            (300, 225, "75"),
            (60, 30, "50"),
            (600, 480, "80")
        ]

        for testCase in testCases {
            let (planned, actual, expectedPct) = testCase

            let stats = SessionStatistics(
                plannedDuration: TimeInterval(planned),
                actualDuration: TimeInterval(actual)
            )

            XCTAssertEqual(stats.completionPercentage, expectedPct,
                          "Failed for planned: " + String(planned) + ", actual: " + String(actual))
        }
    }

    func testEquatableConformance() throws {
        let stats1 = SessionStatistics(
            plannedDuration: 300,
            actualDuration: 240,
            wasPaused: true
        )

        let stats2 = SessionStatistics(
            plannedDuration: 300,
            actualDuration: 240,
            wasPaused: true
        )

        let stats3 = SessionStatistics(
            plannedDuration: 300,
            actualDuration: 300,
            wasPaused: false
        )

        XCTAssertEqual(stats1, stats2)
        XCTAssertNotEqual(stats1, stats3)
    }

    func testViewModelIntegration() async throws {
        // Test that SessionRecapView properly integrates with TimerViewModel
        let viewModel = TimerViewModel()
        viewModel.startTimer(duration: 180) // 3 minutes

        // Simulate some elapsed time
        try await Task.sleep(for: .seconds(0.1))

        viewModel.stopTimer()

        let recapView = SessionRecapView(viewModel: viewModel)

        // View should be created successfully
        XCTAssertNotNil(recapView)

        // Statistics should be calculated correctly from viewModel properties
        XCTAssertGreaterThan(viewModel.elapsedTime, 0)
        XCTAssertLessThanOrEqual(viewModel.elapsedTime, 180)
    }
}