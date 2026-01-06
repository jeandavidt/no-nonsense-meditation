//
//  MeditationTimerServiceTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
@testable import NoNonsenseMeditation

/// Comprehensive unit tests for MeditationTimerService actor
/// Tests timer countdown, pause/resume, state management, and accuracy
final class MeditationTimerServiceTests: XCTestCase {

    // MARK: - Properties

    var timerService: MeditationTimerService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        timerService = MeditationTimerService()
    }

    override func tearDown() async throws {
        timerService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() async {
        let state = await timerService.state
        let remainingTime = await timerService.remainingTime
        let totalDuration = await timerService.totalDuration
        let elapsedTime = await timerService.elapsedTime

        XCTAssertEqual(state, .idle, "Timer should start in idle state")
        XCTAssertEqual(remainingTime, 0, "Initial remaining time should be 0")
        XCTAssertEqual(totalDuration, 0, "Initial total duration should be 0")
        XCTAssertEqual(elapsedTime, 0, "Initial elapsed time should be 0")
    }

    // MARK: - Start Timer Tests

    func testStartTimer() async {
        let duration: TimeInterval = 60 // 1 minute

        await timerService.startTimer(duration: duration)

        let state = await timerService.state
        let remainingTime = await timerService.remainingTime
        let totalDuration = await timerService.totalDuration
        let elapsedTime = await timerService.elapsedTime

        XCTAssertEqual(state, .running, "Timer should be in running state after start")
        XCTAssertEqual(remainingTime, duration, accuracy: 0.5, "Remaining time should match duration")
        XCTAssertEqual(totalDuration, duration, "Total duration should match input")
        XCTAssertEqual(elapsedTime, 0, accuracy: 0.5, "Elapsed time should be near 0 at start")
    }

    func testStartTimerWithZeroDuration() async {
        await timerService.startTimer(duration: 0)

        let state = await timerService.state
        let totalDuration = await timerService.totalDuration

        XCTAssertEqual(state, .running, "Timer should start even with 0 duration")
        XCTAssertEqual(totalDuration, 0, "Total duration should be 0")
    }

    func testStartTimerReplacesExistingTimer() async {
        // Start first timer
        await timerService.startTimer(duration: 60)

        // Wait a moment
        try? await Task.sleep(for: .seconds(1))

        // Start second timer with different duration
        await timerService.startTimer(duration: 120)

        let totalDuration = await timerService.totalDuration
        let remainingTime = await timerService.remainingTime

        XCTAssertEqual(totalDuration, 120, "Total duration should be updated to new timer")
        XCTAssertEqual(remainingTime, 120, accuracy: 0.5, "Remaining time should reset to new duration")
    }

    // MARK: - Pause Timer Tests

    func testPauseTimer() async {
        await timerService.startTimer(duration: 60)

        // Wait for timer to run
        try? await Task.sleep(for: .seconds(2))

        await timerService.pauseTimer()

        let state = await timerService.state
        let remainingTime = await timerService.remainingTime

        XCTAssertEqual(state, .paused, "Timer should be in paused state")
        XCTAssertLessThan(remainingTime, 60, "Remaining time should have decreased")
        XCTAssertGreaterThan(remainingTime, 0, "Remaining time should still be positive")
    }

    func testPauseWhenNotRunning() async {
        // Pause when idle
        await timerService.pauseTimer()
        let state = await timerService.state
        XCTAssertEqual(state, .idle, "Pausing idle timer should have no effect")

        // Pause when already paused
        await timerService.startTimer(duration: 60)
        await timerService.pauseTimer()
        await timerService.pauseTimer() // Second pause

        let finalState = await timerService.state
        XCTAssertEqual(finalState, .paused, "Multiple pauses should maintain paused state")
    }

    func testPausePreservesRemainingTime() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(2))
        await timerService.pauseTimer()

        let remainingBeforeWait = await timerService.remainingTime

        // Wait while paused
        try? await Task.sleep(for: .seconds(2))

        let remainingAfterWait = await timerService.remainingTime

        XCTAssertEqual(
            remainingBeforeWait,
            remainingAfterWait,
            accuracy: 0.1,
            "Remaining time should not change while paused"
        )
    }

    // MARK: - Resume Timer Tests

    func testResumeTimer() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(1))
        await timerService.pauseTimer()

        let remainingAtPause = await timerService.remainingTime

        await timerService.resumeTimer()

        let state = await timerService.state
        XCTAssertEqual(state, .running, "Timer should be running after resume")

        try? await Task.sleep(for: .seconds(2))

        let remainingAfterResume = await timerService.remainingTime
        XCTAssertLessThan(
            remainingAfterResume,
            remainingAtPause,
            "Remaining time should decrease after resume"
        )
    }

    func testResumeWhenNotPaused() async {
        // Resume when idle
        await timerService.resumeTimer()
        let state = await timerService.state
        XCTAssertEqual(state, .idle, "Resuming idle timer should have no effect")

        // Resume when already running
        await timerService.startTimer(duration: 60)
        await timerService.resumeTimer() // Try to resume running timer

        let finalState = await timerService.state
        XCTAssertEqual(finalState, .running, "Resuming running timer should have no effect")
    }

    func testMultiplePauseResumeCycles() async {
        await timerService.startTimer(duration: 60)

        // First cycle
        try? await Task.sleep(for: .seconds(1))
        await timerService.pauseTimer()
        try? await Task.sleep(for: .seconds(1))
        await timerService.resumeTimer()

        // Second cycle
        try? await Task.sleep(for: .seconds(1))
        await timerService.pauseTimer()
        try? await Task.sleep(for: .seconds(1))
        await timerService.resumeTimer()

        // Third cycle
        try? await Task.sleep(for: .seconds(1))
        await timerService.pauseTimer()

        let state = await timerService.state
        let remainingTime = await timerService.remainingTime
        let elapsedTime = await timerService.elapsedTime

        XCTAssertEqual(state, .paused, "Should be paused after multiple cycles")
        XCTAssertLessThan(remainingTime, 60, "Remaining time should have decreased")
        XCTAssertGreaterThan(elapsedTime, 0, "Elapsed time should have accumulated")
    }

    // MARK: - Stop Timer Tests

    func testStopTimer() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(2))

        await timerService.stopTimer()

        let state = await timerService.state
        XCTAssertEqual(state, .completed, "Timer should be completed after stop")
    }

    func testStopPausedTimer() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(1))
        await timerService.pauseTimer()
        await timerService.stopTimer()

        let state = await timerService.state
        XCTAssertEqual(state, .completed, "Should be able to stop paused timer")
    }

    func testStopIdleTimer() async {
        await timerService.stopTimer()

        let state = await timerService.state
        XCTAssertEqual(state, .completed, "Stopping idle timer should set to completed")
    }

    // MARK: - Reset Timer Tests

    func testResetTimer() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(2))
        await timerService.resetTimer()

        let state = await timerService.state
        let remainingTime = await timerService.remainingTime
        let totalDuration = await timerService.totalDuration
        let elapsedTime = await timerService.elapsedTime

        XCTAssertEqual(state, .idle, "Timer should be idle after reset")
        XCTAssertEqual(remainingTime, 0, "Remaining time should be 0 after reset")
        XCTAssertEqual(totalDuration, 0, "Total duration should be 0 after reset")
        XCTAssertEqual(elapsedTime, 0, "Elapsed time should be 0 after reset")
    }

    func testResetPausedTimer() async {
        await timerService.startTimer(duration: 60)
        await timerService.pauseTimer()
        await timerService.resetTimer()

        let state = await timerService.state
        XCTAssertEqual(state, .idle, "Should reset paused timer to idle")
    }

    // MARK: - Progress Tests

    func testGetProgress_Initial() async {
        let progress = await timerService.getProgress()
        XCTAssertEqual(progress, 0, "Initial progress should be 0")
    }

    func testGetProgress_Running() async {
        await timerService.startTimer(duration: 10)
        try? await Task.sleep(for: .seconds(2))

        let progress = await timerService.getProgress()

        XCTAssertGreaterThan(progress, 0, "Progress should be greater than 0")
        XCTAssertLessThan(progress, 1, "Progress should be less than 1")
    }

    func testGetProgress_Completed() async {
        await timerService.startTimer(duration: 2)
        try? await Task.sleep(for: .seconds(3))

        let progress = await timerService.getProgress()
        XCTAssertEqual(progress, 1, accuracy: 0.1, "Progress should be 1 when completed")
    }

    func testGetProgress_ZeroDuration() async {
        await timerService.startTimer(duration: 0)
        let progress = await timerService.getProgress()
        XCTAssertEqual(progress, 0, "Progress should be 0 for zero duration")
    }

    // MARK: - Actual Meditation Time Tests

    func testGetActualMeditationTime_NoPause() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(3))
        await timerService.stopTimer()

        let actualTime = await timerService.getActualMeditationTime()

        XCTAssertGreaterThan(actualTime, 2, "Actual time should be at least 2 seconds")
        XCTAssertLessThan(actualTime, 5, "Actual time should be less than 5 seconds")
    }

    func testGetActualMeditationTime_WithPause() async {
        await timerService.startTimer(duration: 60)

        // Run for 2 seconds
        try? await Task.sleep(for: .seconds(2))
        await timerService.pauseTimer()

        // Pause for 2 seconds
        try? await Task.sleep(for: .seconds(2))
        await timerService.resumeTimer()

        // Run for 2 more seconds
        try? await Task.sleep(for: .seconds(2))
        await timerService.stopTimer()

        let actualTime = await timerService.getActualMeditationTime()

        // Should be around 4 seconds (2 + 2), not 6
        XCTAssertGreaterThan(actualTime, 3, "Actual time should be at least 3 seconds")
        XCTAssertLessThan(actualTime, 6, "Actual time should not include pause time")
    }

    func testGetActualMeditationTime_WhileRunning() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(2))

        let actualTime = await timerService.getActualMeditationTime()

        XCTAssertGreaterThan(actualTime, 1, "Should track time while running")
    }

    func testGetActualMeditationTime_ExceedsTotalDuration() async {
        // This tests that actual time is capped at total duration
        await timerService.startTimer(duration: 2)
        try? await Task.sleep(for: .seconds(4))

        let actualTime = await timerService.getActualMeditationTime()
        let totalDuration = await timerService.totalDuration

        XCTAssertLessThanOrEqual(actualTime, totalDuration, "Actual time should not exceed total duration")
    }

    // MARK: - Timer Accuracy Tests

    func testTimerAccuracy_ShortDuration() async {
        let duration: TimeInterval = 3
        await timerService.startTimer(duration: duration)

        // Wait for completion
        try? await Task.sleep(for: .seconds(4))

        let state = await timerService.state
        let remainingTime = await timerService.remainingTime

        XCTAssertEqual(state, .completed, "Timer should complete after duration")
        XCTAssertEqual(remainingTime, 0, accuracy: 0.1, "Remaining time should be 0")
    }

    func testTimerAccuracy_Countdown() async {
        let duration: TimeInterval = 10
        await timerService.startTimer(duration: duration)

        // Sample remaining time at intervals
        var previousRemaining = await timerService.remainingTime

        for _ in 0..<3 {
            try? await Task.sleep(for: .seconds(2))
            let currentRemaining = await timerService.remainingTime

            XCTAssertLessThan(
                currentRemaining,
                previousRemaining,
                "Remaining time should decrease over time"
            )

            previousRemaining = currentRemaining
        }
    }

    // MARK: - Edge Cases

    func testLargeDuration() async {
        let duration: TimeInterval = 7200 // 2 hours
        await timerService.startTimer(duration: duration)

        let state = await timerService.state
        let totalDuration = await timerService.totalDuration

        XCTAssertEqual(state, .running, "Should handle large durations")
        XCTAssertEqual(totalDuration, duration, "Should store large duration correctly")
    }

    func testNegativeDuration() async {
        let duration: TimeInterval = -10
        await timerService.startTimer(duration: duration)

        let totalDuration = await timerService.totalDuration
        let remainingTime = await timerService.remainingTime

        // Service should handle negative duration
        XCTAssertEqual(totalDuration, duration, "Should store negative duration")
        XCTAssertEqual(remainingTime, duration, accuracy: 0.5, "Remaining time reflects input")
    }

    func testElapsedTimeAccumulation() async {
        await timerService.startTimer(duration: 60)

        // Let it run
        try? await Task.sleep(for: .seconds(2))
        let elapsed1 = await timerService.elapsedTime

        // Pause and resume
        await timerService.pauseTimer()
        try? await Task.sleep(for: .seconds(1))
        await timerService.resumeTimer()

        // Let it run more
        try? await Task.sleep(for: .seconds(2))
        let elapsed2 = await timerService.elapsedTime

        XCTAssertGreaterThan(elapsed2, elapsed1, "Elapsed time should accumulate")
        XCTAssertGreaterThan(elapsed2, 3, "Should have at least 3 seconds elapsed")
    }

    // MARK: - State Accessor Tests

    func testStateAccessors() async {
        // Test getting state property directly
        let initialState = await timerService.state
        XCTAssertEqual(initialState, .idle)

        await timerService.startTimer(duration: 60)
        let runningState = await timerService.state
        XCTAssertEqual(runningState, .running)

        await timerService.pauseTimer()
        let pausedState = await timerService.state
        XCTAssertEqual(pausedState, .paused)

        await timerService.stopTimer()
        let completedState = await timerService.state
        XCTAssertEqual(completedState, .completed)
    }

    func testRemainingTimeAccessor() async {
        let duration: TimeInterval = 60
        await timerService.startTimer(duration: duration)

        let remaining = await timerService.remainingTime
        XCTAssertEqual(remaining, duration, accuracy: 0.5)
    }

    func testElapsedTimeAccessor() async {
        await timerService.startTimer(duration: 60)
        try? await Task.sleep(for: .seconds(2))

        let elapsed = await timerService.elapsedTime
        XCTAssertGreaterThan(elapsed, 1)
        XCTAssertLessThan(elapsed, 3)
    }

    func testTotalDurationAccessor() async {
        let duration: TimeInterval = 123
        await timerService.startTimer(duration: duration)

        let total = await timerService.totalDuration
        XCTAssertEqual(total, duration)
    }

    // MARK: - Concurrency Tests

    func testConcurrentAccess() async {
        await timerService.startTimer(duration: 60)

        // Perform multiple concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = await self.timerService.getProgress()
                    _ = await self.timerService.state
                    _ = await self.timerService.remainingTime
                }
            }
        }

        // Should not crash - actor ensures thread safety
        let state = await timerService.state
        XCTAssertNotNil(state, "Should handle concurrent access")
    }

    // MARK: - Performance Tests

    func testStartPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Start timer")

            Task {
                await timerService.startTimer(duration: 60)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testStateTransitionPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "State transitions")

            Task {
                await timerService.startTimer(duration: 60)
                await timerService.pauseTimer()
                await timerService.resumeTimer()
                await timerService.stopTimer()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }
}
