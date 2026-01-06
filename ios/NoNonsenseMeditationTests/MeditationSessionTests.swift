//
//  MeditationSessionTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
import CoreData
@testable import NoNonsenseMeditation

/// Comprehensive unit tests for MeditationSession model
/// Tests computed properties, validation, and CoreData functionality
final class MeditationSessionTests: XCTestCase {

    // MARK: - Properties

    var mockPersistence: MockPersistenceController!

    // MARK: - Setup & Teardown

    override func setUp() throws {
        try super.setUp()
        mockPersistence = MockPersistenceController()
        mockPersistence.reset()
    }

    override func tearDown() throws {
        mockPersistence.reset()
        mockPersistence = nil
        try super.tearDown()
    }

    // MARK: - Helper Methods

    func createSession(
        durationPlanned: Int16 = 10,
        durationTotal: Double = 10.0,
        durationElapsed: Double = 10.0,
        isValid: Bool = true,
        wasPaused: Bool = false,
        pauseCount: Int16 = 0
    ) -> MeditationSession {
        let session = MeditationSession(context: mockPersistence.viewContext)
        session.idSession = UUID()
        session.durationPlanned = durationPlanned
        session.durationTotal = durationTotal
        session.durationElapsed = durationElapsed
        session.isSessionValid = isValid
        session.createdAt = Date()
        session.completedAt = Date()
        session.wasPaused = wasPaused
        session.pauseCount = pauseCount
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        try? mockPersistence.saveContext()
        return session
    }

    // MARK: - Basic Property Tests

    func testSessionCreation() {
        let session = createSession()

        XCTAssertNotNil(session.idSession, "Session should have ID")
        XCTAssertNotNil(session.createdAt, "Session should have creation date")
        XCTAssertEqual(session.durationPlanned, 10)
        XCTAssertEqual(session.durationTotal, 10.0)
        XCTAssertTrue(session.isSessionValid)
    }

    func testSessionIdentifiable() {
        let session = createSession()
        let id = session.id

        XCTAssertEqual(id, session.idSession, "ID should match idSession")
    }

    // MARK: - Computed Property Tests: Minimum Duration

    func testMeetsMinimumDuration_ValidSession() {
        // 15 seconds = 0.25 minutes
        let session = createSession(durationTotal: 0.25)
        XCTAssertTrue(session.meetsMinimumDuration, "0.25 minutes should meet minimum")
    }

    func testMeetsMinimumDuration_AboveMinimum() {
        let session = createSession(durationTotal: 10.0)
        XCTAssertTrue(session.meetsMinimumDuration, "10 minutes should meet minimum")
    }

    func testMeetsMinimumDuration_BelowMinimum() {
        let session = createSession(durationTotal: 0.1)
        XCTAssertFalse(session.meetsMinimumDuration, "0.1 minutes should not meet minimum")
    }

    func testMeetsMinimumDuration_JustBelow() {
        let session = createSession(durationTotal: 0.24)
        XCTAssertFalse(session.meetsMinimumDuration, "0.24 minutes should not meet minimum")
    }

    func testMeetsMinimumDuration_Zero() {
        let session = createSession(durationTotal: 0.0)
        XCTAssertFalse(session.meetsMinimumDuration, "0 minutes should not meet minimum")
    }

    // MARK: - Computed Property Tests: Efficiency Ratio

    func testEfficiencyRatio_PerfectEfficiency() {
        let session = createSession(
            durationTotal: 10.0,
            durationElapsed: 10.0
        )

        XCTAssertEqual(
            session.efficiencyRatio,
            1.0,
            accuracy: 0.001,
            "Perfect efficiency should be 1.0"
        )
    }

    func testEfficiencyRatio_WithPauses() {
        let session = createSession(
            durationTotal: 10.0,  // 10 minutes meditating
            durationElapsed: 15.0 // 15 minutes total (5 minutes paused)
        )

        XCTAssertEqual(
            session.efficiencyRatio,
            10.0 / 15.0,
            accuracy: 0.001,
            "Efficiency should be meditation time / total time"
        )
    }

    func testEfficiencyRatio_HighEfficiency() {
        let session = createSession(
            durationTotal: 9.5,
            durationElapsed: 10.0
        )

        XCTAssertGreaterThan(session.efficiencyRatio, 0.9, "Should have high efficiency")
        XCTAssertLessThan(session.efficiencyRatio, 1.0, "Should be less than perfect")
    }

    func testEfficiencyRatio_LowEfficiency() {
        let session = createSession(
            durationTotal: 5.0,
            durationElapsed: 20.0
        )

        XCTAssertEqual(
            session.efficiencyRatio,
            0.25,
            accuracy: 0.001,
            "Low efficiency should be calculated correctly"
        )
    }

    func testEfficiencyRatio_ZeroElapsed() {
        let session = createSession(
            durationTotal: 10.0,
            durationElapsed: 0.0
        )

        XCTAssertEqual(session.efficiencyRatio, 0, "Efficiency should be 0 for zero elapsed time")
    }

    func testEfficiencyRatio_BothZero() {
        let session = createSession(
            durationTotal: 0.0,
            durationElapsed: 0.0
        )

        XCTAssertEqual(session.efficiencyRatio, 0, "Efficiency should be 0 when both are zero")
    }

    // MARK: - Computed Property Tests: Was Completed As Planned

    func testWasCompletedAsPlanned_ExactMatch() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 10.0
        )

        XCTAssertTrue(session.wasCompletedAsPlanned, "Exact match should be completed as planned")
    }

    func testWasCompletedAsPlanned_WithinTolerance() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 10.08 // Within 0.1 minute (6 second) tolerance
        )

        XCTAssertTrue(
            session.wasCompletedAsPlanned,
            "Within tolerance should be completed as planned"
        )
    }

    func testWasCompletedAsPlanned_BelowTolerance() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 9.93 // Within 0.1 minute tolerance
        )

        XCTAssertTrue(
            session.wasCompletedAsPlanned,
            "Within tolerance should be completed as planned"
        )
    }

    func testWasCompletedAsPlanned_OutsideTolerance() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 8.5 // Outside tolerance
        )

        XCTAssertFalse(
            session.wasCompletedAsPlanned,
            "Outside tolerance should not be completed as planned"
        )
    }

    func testWasCompletedAsPlanned_SignificantlyLess() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 5.0
        )

        XCTAssertFalse(
            session.wasCompletedAsPlanned,
            "Significantly less should not be completed as planned"
        )
    }

    func testWasCompletedAsPlanned_SignificantlyMore() {
        let session = createSession(
            durationPlanned: 10,
            durationTotal: 15.0
        )

        XCTAssertFalse(
            session.wasCompletedAsPlanned,
            "Significantly more should not be completed as planned"
        )
    }

    func testWasCompletedAsPlanned_ZeroPlanned() {
        let session = createSession(
            durationPlanned: 0,
            durationTotal: 5.0
        )

        XCTAssertFalse(
            session.wasCompletedAsPlanned,
            "Zero planned should not be completed as planned"
        )
    }

    // MARK: - Pause Tracking Tests

    func testPauseTracking_NoPause() {
        let session = createSession(
            wasPaused: false,
            pauseCount: 0
        )

        XCTAssertFalse(session.wasPaused, "Should not be marked as paused")
        XCTAssertEqual(session.pauseCount, 0, "Pause count should be 0")
    }

    func testPauseTracking_SinglePause() {
        let session = createSession(
            wasPaused: true,
            pauseCount: 1
        )

        XCTAssertTrue(session.wasPaused, "Should be marked as paused")
        XCTAssertEqual(session.pauseCount, 1, "Pause count should be 1")
    }

    func testPauseTracking_MultiplePauses() {
        let session = createSession(
            wasPaused: true,
            pauseCount: 5
        )

        XCTAssertTrue(session.wasPaused, "Should be marked as paused")
        XCTAssertEqual(session.pauseCount, 5, "Pause count should be 5")
    }

    // MARK: - Sync Status Tests

    func testSyncStatus_Initial() {
        let session = createSession()

        XCTAssertFalse(session.syncedToHealthKit, "Should not be synced to HealthKit initially")
        XCTAssertFalse(session.syncedToiCloud, "Should not be synced to iCloud initially")
    }

    func testSyncStatus_HealthKitSynced() {
        let session = createSession()
        session.syncedToHealthKit = true
        try? mockPersistence.saveContext()

        XCTAssertTrue(session.syncedToHealthKit, "Should be marked as synced to HealthKit")
    }

    func testSyncStatus_iCloudSynced() {
        let session = createSession()
        session.syncedToiCloud = true
        try? mockPersistence.saveContext()

        XCTAssertTrue(session.syncedToiCloud, "Should be marked as synced to iCloud")
    }

    func testSyncStatus_BothSynced() {
        let session = createSession()
        session.syncedToHealthKit = true
        session.syncedToiCloud = true
        try? mockPersistence.saveContext()

        XCTAssertTrue(session.syncedToHealthKit, "Should be synced to HealthKit")
        XCTAssertTrue(session.syncedToiCloud, "Should be synced to iCloud")
    }

    // MARK: - Fetch Request Tests

    func testFetchRequest() {
        let fetchRequest = MeditationSession.fetchRequest()

        XCTAssertNotNil(fetchRequest, "Fetch request should not be nil")
        XCTAssertEqual(fetchRequest.entityName, "MeditationSession", "Entity name should match")
    }

    func testFetchAllSessions() throws {
        // Create multiple sessions
        _ = createSession(durationPlanned: 5)
        _ = createSession(durationPlanned: 10)
        _ = createSession(durationPlanned: 15)

        let fetchRequest = MeditationSession.fetchRequest()
        let sessions = try mockPersistence.viewContext.fetch(fetchRequest)

        XCTAssertEqual(sessions.count, 3, "Should fetch all 3 sessions")
    }

    func testFetchValidSessions() throws {
        // Create mix of valid and invalid sessions
        _ = createSession(isValid: true)
        _ = createSession(isValid: false)
        _ = createSession(isValid: true)

        let fetchRequest = MeditationSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSessionValid == YES")

        let validSessions = try mockPersistence.viewContext.fetch(fetchRequest)

        XCTAssertEqual(validSessions.count, 2, "Should fetch only valid sessions")
    }

    // MARK: - Edge Cases

    func testNegativeDurations() {
        let session = createSession(
            durationPlanned: -10,
            durationTotal: -5.0,
            durationElapsed: -5.0
        )

        // Should handle negative values gracefully
        XCTAssertFalse(session.meetsMinimumDuration, "Negative duration should not meet minimum")
    }

    func testVeryLargeDurations() {
        let session = createSession(
            durationPlanned: 1000,
            durationTotal: 1000.0,
            durationElapsed: 1000.0
        )

        XCTAssertTrue(session.meetsMinimumDuration, "Large duration should meet minimum")
        XCTAssertEqual(session.efficiencyRatio, 1.0, "Efficiency should be 1.0")
        XCTAssertTrue(session.wasCompletedAsPlanned, "Should be completed as planned")
    }

    func testEfficiencyGreaterThanOne() {
        // This could happen if elapsed time is less than total meditation time
        // (unlikely but should handle gracefully)
        let session = createSession(
            durationTotal: 10.0,
            durationElapsed: 8.0
        )

        let efficiency = session.efficiencyRatio
        XCTAssertGreaterThan(efficiency, 1.0, "Efficiency can be > 1.0 in edge cases")
    }

    func testBoundaryToleranceValues() {
        // Test exact boundary of 0.1 minute tolerance
        let exactBoundary = createSession(
            durationPlanned: 10,
            durationTotal: 10.1
        )
        XCTAssertTrue(exactBoundary.wasCompletedAsPlanned, "Exact boundary should pass")

        let justOverBoundary = createSession(
            durationPlanned: 10,
            durationTotal: 10.11
        )
        XCTAssertFalse(justOverBoundary.wasCompletedAsPlanned, "Just over boundary should fail")
    }

    // MARK: - Date Tests

    func testSessionDates() {
        let createdAt = Date()
        let completedAt = createdAt.addingTimeInterval(600) // 10 minutes later

        let session = MeditationSession(context: mockPersistence.viewContext)
        session.idSession = UUID()
        session.durationPlanned = 10
        session.durationTotal = 10.0
        session.durationElapsed = 10.0
        session.isSessionValid = true
        session.createdAt = createdAt
        session.completedAt = completedAt
        session.wasPaused = false
        session.pauseCount = 0
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        XCTAssertEqual(session.createdAt, createdAt, "Created date should match")
        XCTAssertEqual(session.completedAt, completedAt, "Completed date should match")

        let duration = completedAt.timeIntervalSince(createdAt)
        XCTAssertEqual(duration, 600, "Duration should be 10 minutes")
    }

    func testSessionWithoutCompletionDate() {
        let session = MeditationSession(context: mockPersistence.viewContext)
        session.idSession = UUID()
        session.createdAt = Date()
        session.completedAt = nil

        XCTAssertNil(session.completedAt, "Completion date can be nil for active sessions")
    }

    // MARK: - CoreData Integration Tests

    func testSessionPersistence() throws {
        let session = createSession()
        let sessionID = session.idSession

        // Save context
        try mockPersistence.saveContext()

        // Create new context and fetch
        let fetchRequest = MeditationSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "idSession == %@", sessionID as CVarArg)

        let fetchedSessions = try mockPersistence.viewContext.fetch(fetchRequest)

        XCTAssertEqual(fetchedSessions.count, 1, "Should fetch persisted session")
        XCTAssertEqual(fetchedSessions.first?.idSession, sessionID, "IDs should match")
    }

    func testSessionUpdate() throws {
        let session = createSession(durationTotal: 10.0)
        try mockPersistence.saveContext()

        // Update session
        session.durationTotal = 15.0
        session.isSessionValid = false
        try mockPersistence.saveContext()

        // Fetch and verify
        let fetchRequest = MeditationSession.fetchRequest()
        let sessions = try mockPersistence.viewContext.fetch(fetchRequest)

        XCTAssertEqual(sessions.first?.durationTotal, 15.0, "Duration should be updated")
        XCTAssertFalse(sessions.first?.isSessionValid ?? true, "Validity should be updated")
    }

    func testSessionDeletion() throws {
        let session = createSession()
        try mockPersistence.saveContext()

        // Delete session
        mockPersistence.viewContext.delete(session)
        try mockPersistence.saveContext()

        // Verify deletion
        let fetchRequest = MeditationSession.fetchRequest()
        let sessions = try mockPersistence.viewContext.fetch(fetchRequest)

        XCTAssertEqual(sessions.count, 0, "Session should be deleted")
    }

    // MARK: - Performance Tests

    func testSessionCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = createSession()
            }
        }
    }

    func testComputedPropertiesPerformance() {
        let sessions = (0..<100).map { _ in createSession() }

        measure {
            for session in sessions {
                _ = session.meetsMinimumDuration
                _ = session.efficiencyRatio
                _ = session.wasCompletedAsPlanned
            }
        }
    }
}
