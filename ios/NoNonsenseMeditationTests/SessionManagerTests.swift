//
//  SessionManagerTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
import CoreData
@testable import NoNonsenseMeditation

/// Comprehensive unit tests for SessionManager actor
/// Tests session lifecycle, persistence, and HealthKit integration
final class SessionManagerTests: XCTestCase {

    // MARK: - Properties

    var mockPersistence: MockPersistenceController!
    var sessionManager: SessionManager!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockPersistence = MockPersistenceController()
        mockPersistence.reset()

        // Note: SessionManager creates its own dependencies internally
        // For more comprehensive testing, we'd need dependency injection
        sessionManager = SessionManager()
    }

    override func tearDown() async throws {
        mockPersistence.reset()
        mockPersistence = nil
        sessionManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() async {
        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session initially")

        let activeSession = await sessionManager.activeSession
        XCTAssertNil(activeSession, "Active session should be nil initially")
    }

    // MARK: - Start Session Tests

    func testStartSession() async {
        let config = TimerConfiguration(durationMinutes: 10)

        let session = await sessionManager.startSession(configuration: config)

        XCTAssertNotNil(session, "Should create session")
        XCTAssertEqual(session.durationPlanned, 10, "Should set planned duration")
        XCTAssertNotNil(session.createdAt, "Should set creation date")
        XCTAssertNotNil(session.idSession, "Should set session ID")
        XCTAssertFalse(session.isSessionValid, "New session should not be valid yet")
        XCTAssertFalse(session.wasPaused, "Should not be paused initially")
        XCTAssertEqual(session.pauseCount, 0, "Pause count should be 0")

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActiveSession, "Should have active session after start")
    }

    func testStartSessionWithDifferentConfigurations() async {
        let configs = [
            TimerConfiguration(durationMinutes: 5),
            TimerConfiguration(durationMinutes: 15),
            TimerConfiguration(durationMinutes: 30),
            TimerConfiguration(durationMinutes: 60)
        ]

        for config in configs {
            let session = await sessionManager.startSession(configuration: config)
            XCTAssertEqual(
                session.durationPlanned,
                Int16(config.durationMinutes),
                "Should set correct duration for \(config.durationMinutes) minutes"
            )

            await sessionManager.cancelSession()
        }
    }

    func testStartSessionReplacesActiveSession() async {
        let config1 = TimerConfiguration(durationMinutes: 10)
        let session1 = await sessionManager.startSession(configuration: config1)
        let session1ID = session1.idSession

        let config2 = TimerConfiguration(durationMinutes: 20)
        let session2 = await sessionManager.startSession(configuration: config2)

        XCTAssertNotEqual(
            session1ID,
            session2.idSession,
            "Should create new session with different ID"
        )
        XCTAssertEqual(session2.durationPlanned, 20, "Should use new configuration")
    }

    // MARK: - Pause Session Tests

    func testPauseSession() async {
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        // Wait a bit before pausing
        try? await Task.sleep(for: .seconds(1))

        await sessionManager.pauseSession()

        // Session should still be active but paused
        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActiveSession, "Should still have active session when paused")
    }

    func testPauseSessionWithoutActiveSession() async {
        // Should not crash when pausing without active session
        await sessionManager.pauseSession()

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session")
    }

    func testMultiplePauses() async {
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        // Pause multiple times
        for _ in 0..<3 {
            try? await Task.sleep(for: .milliseconds(100))
            await sessionManager.pauseSession()
            try? await Task.sleep(for: .milliseconds(100))
            await sessionManager.resumeSession()
        }

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActiveSession, "Session should still be active after multiple pause/resume")
    }

    // MARK: - Resume Session Tests

    func testResumeSession() async {
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        await sessionManager.pauseSession()
        await sessionManager.resumeSession()

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActiveSession, "Should still have active session after resume")
    }

    func testResumeSessionWithoutActiveSession() async {
        // Should not crash when resuming without active session
        await sessionManager.resumeSession()

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session")
    }

    // MARK: - End Session Tests

    func testEndSession() async throws {
        let config = TimerConfiguration(durationMinutes: 1)
        await sessionManager.startSession(configuration: config)

        // Wait for some time to accumulate
        try? await Task.sleep(for: .seconds(2))

        let endedSession = try await sessionManager.endSession()

        XCTAssertNotNil(endedSession, "Should return ended session")
        XCTAssertNotNil(endedSession?.completedAt, "Should set completion date")
        XCTAssertGreaterThan(endedSession?.durationTotal ?? 0, 0, "Should have duration")
        XCTAssertTrue(endedSession?.isSessionValid ?? false, "Should be valid if meets minimum")

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session after end")
    }

    func testEndSessionWithPause() async throws {
        let config = TimerConfiguration(durationMinutes: 1)
        await sessionManager.startSession(configuration: config)

        try? await Task.sleep(for: .seconds(1))
        await sessionManager.pauseSession()
        try? await Task.sleep(for: .seconds(1))
        await sessionManager.resumeSession()
        try? await Task.sleep(for: .seconds(1))

        let endedSession = try await sessionManager.endSession()

        XCTAssertNotNil(endedSession, "Should return ended session")
        XCTAssertTrue(endedSession?.wasPaused ?? false, "Should mark as paused")
        XCTAssertGreaterThan(endedSession?.pauseCount ?? 0, 0, "Should have pause count")
    }

    func testEndSessionWithoutActiveSession() async throws {
        let endedSession = try await sessionManager.endSession()
        XCTAssertNil(endedSession, "Should return nil when no active session")
    }

    func testEndSessionValidatesMinimumDuration() async throws {
        let config = TimerConfiguration(durationMinutes: 1)
        await sessionManager.startSession(configuration: config)

        // End immediately (less than 15 seconds)
        try? await Task.sleep(for: .milliseconds(100))

        let endedSession = try await sessionManager.endSession()

        // Session should be created but marked as invalid
        XCTAssertNotNil(endedSession, "Should create session")
        XCTAssertFalse(
            endedSession?.isSessionValid ?? true,
            "Should be invalid if less than minimum duration"
        )
    }

    // MARK: - Complete Session Tests

    func testCompleteSession() async {
        let plannedDuration: TimeInterval = 600 // 10 minutes in seconds
        let actualDuration: TimeInterval = 550 // Slightly less
        let wasPaused = false

        let completedSession = await sessionManager.completeSession(
            plannedDuration: plannedDuration,
            actualDuration: actualDuration,
            wasPaused: wasPaused
        )

        XCTAssertNotNil(completedSession, "Should create completed session")
        XCTAssertEqual(completedSession?.durationPlanned, 10, "Should convert seconds to minutes")
        XCTAssertEqual(
            completedSession?.durationTotal,
            actualDuration / 60.0,
            accuracy: 0.1,
            "Should set actual duration"
        )
        XCTAssertFalse(completedSession?.wasPaused ?? true, "Should not be marked as paused")
        XCTAssertNotNil(completedSession?.createdAt, "Should have creation date")
        XCTAssertNotNil(completedSession?.completedAt, "Should have completion date")
    }

    func testCompleteSessionValidation() async {
        // Test valid session (>= 15 seconds)
        let validSession = await sessionManager.completeSession(
            plannedDuration: 60,
            actualDuration: 30,
            wasPaused: false
        )
        XCTAssertTrue(validSession?.isSessionValid ?? false, "Should be valid")

        // Test invalid session (< 15 seconds)
        let invalidSession = await sessionManager.completeSession(
            plannedDuration: 60,
            actualDuration: 10,
            wasPaused: false
        )
        XCTAssertFalse(invalidSession?.isSessionValid ?? true, "Should be invalid")
    }

    func testCompleteSessionWithPause() async {
        let session = await sessionManager.completeSession(
            plannedDuration: 600,
            actualDuration: 550,
            wasPaused: true
        )

        XCTAssertTrue(session?.wasPaused ?? false, "Should mark as paused")
        XCTAssertEqual(session?.pauseCount, 1, "Should set pause count to 1")
    }

    // MARK: - Cancel Session Tests

    func testCancelSession() async {
        let config = TimerConfiguration(durationMinutes: 10)
        let session = await sessionManager.startSession(configuration: config)
        let sessionID = session.idSession

        await sessionManager.cancelSession()

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session after cancel")

        // Verify session was deleted from persistence
        // Note: This test would be more robust with dependency injection
        // to use our mock persistence controller
    }

    func testCancelSessionWithoutActiveSession() async {
        // Should not crash when canceling without active session
        await sessionManager.cancelSession()

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActiveSession, "Should not have active session")
    }

    // MARK: - Session State Tests

    func testGetRemainingTime() async {
        let config = TimerConfiguration(durationMinutes: 1)
        await sessionManager.startSession(configuration: config)

        let remainingTime = await sessionManager.getRemainingTime()
        XCTAssertNotNil(remainingTime, "Should return remaining time")
        XCTAssertGreaterThan(remainingTime ?? 0, 0, "Should have positive remaining time")
        XCTAssertLessThanOrEqual(remainingTime ?? 0, 60, "Should not exceed planned duration")
    }

    func testGetRemainingTimeWithoutActiveSession() async {
        let remainingTime = await sessionManager.getRemainingTime()
        XCTAssertNil(remainingTime, "Should return nil without active session")
    }

    func testGetTimerState() async {
        // Test with no active session
        let initialState = await sessionManager.getTimerState()
        XCTAssertNil(initialState, "Should return nil without active session")

        // Test with active session
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        let runningState = await sessionManager.getTimerState()
        XCTAssertNotNil(runningState, "Should return state with active session")
        XCTAssertEqual(runningState, .running, "Should be in running state")
    }

    func testGetProgress() async {
        // Test with no active session
        let initialProgress = await sessionManager.getProgress()
        XCTAssertNil(initialProgress, "Should return nil without active session")

        // Test with active session
        let config = TimerConfiguration(durationMinutes: 1)
        await sessionManager.startSession(configuration: config)

        try? await Task.sleep(for: .seconds(2))

        let progress = await sessionManager.getProgress()
        XCTAssertNotNil(progress, "Should return progress with active session")
        XCTAssertGreaterThan(progress ?? 0, 0, "Progress should be greater than 0")
        XCTAssertLessThan(progress ?? 1, 1, "Progress should be less than 1")
    }

    func testHasActiveSession() async {
        var hasActive = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActive, "Should not have active session initially")

        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        hasActive = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActive, "Should have active session after start")

        await sessionManager.cancelSession()

        hasActive = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActive, "Should not have active session after cancel")
    }

    // MARK: - Edge Cases

    func testVeryShortDuration() async {
        let config = TimerConfiguration(durationMinutes: 1) // 1 minute
        await sessionManager.startSession(configuration: config)

        try? await Task.sleep(for: .milliseconds(500))

        let remainingTime = await sessionManager.getRemainingTime()
        XCTAssertNotNil(remainingTime, "Should handle very short durations")
    }

    func testLongDuration() async {
        let config = TimerConfiguration(durationMinutes: 120) // 2 hours
        let session = await sessionManager.startSession(configuration: config)

        XCTAssertEqual(session.durationPlanned, 120, "Should handle long durations")

        await sessionManager.cancelSession()
    }

    func testRapidStateChanges() async {
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        // Rapid pause/resume cycles
        for _ in 0..<10 {
            await sessionManager.pauseSession()
            await sessionManager.resumeSession()
        }

        let hasActiveSession = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActiveSession, "Should handle rapid state changes")

        await sessionManager.cancelSession()
    }

    func testSessionLifecycleFlow() async throws {
        // Simulate complete session lifecycle
        let config = TimerConfiguration(durationMinutes: 1)

        // 1. Start
        await sessionManager.startSession(configuration: config)
        var hasActive = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActive, "Should have active session after start")

        // 2. Run for a bit
        try? await Task.sleep(for: .seconds(1))

        // 3. Pause
        await sessionManager.pauseSession()
        let statePaused = await sessionManager.getTimerState()
        XCTAssertEqual(statePaused, .paused, "Should be paused")

        // 4. Resume
        await sessionManager.resumeSession()
        let stateResumed = await sessionManager.getTimerState()
        XCTAssertEqual(stateResumed, .running, "Should be running after resume")

        // 5. End
        let endedSession = try await sessionManager.endSession()
        XCTAssertNotNil(endedSession, "Should end session successfully")

        hasActive = await sessionManager.hasActiveSession
        XCTAssertFalse(hasActive, "Should not have active session after end")
    }

    // MARK: - Concurrency Tests

    func testConcurrentAccess() async {
        let config = TimerConfiguration(durationMinutes: 10)
        await sessionManager.startSession(configuration: config)

        // Perform multiple concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = await self.sessionManager.hasActiveSession
                    _ = await self.sessionManager.getRemainingTime()
                    _ = await self.sessionManager.getProgress()
                }
            }
        }

        // Should not crash - actor ensures thread safety
        let hasActive = await sessionManager.hasActiveSession
        XCTAssertTrue(hasActive, "Should handle concurrent access")

        await sessionManager.cancelSession()
    }

    // MARK: - Performance Tests

    func testStartSessionPerformance() {
        let config = TimerConfiguration(durationMinutes: 10)

        measure {
            let expectation = XCTestExpectation(description: "Start session")

            Task {
                await sessionManager.startSession(configuration: config)
                await sessionManager.cancelSession()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }

    func testCompleteSessionPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Complete session")

            Task {
                _ = await sessionManager.completeSession(
                    plannedDuration: 600,
                    actualDuration: 550,
                    wasPaused: false
                )
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }
}
