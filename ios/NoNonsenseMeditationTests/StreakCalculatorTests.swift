//
//  StreakCalculatorTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
@testable import NoNonsenseMeditation

/// Comprehensive unit tests for StreakCalculator
/// Tests streak calculation logic with various edge cases
final class StreakCalculatorTests: XCTestCase {

    // MARK: - Properties

    var calculator: StreakCalculator!
    var mockPersistence: MockPersistenceController!
    var calendar: Calendar!

    // MARK: - Setup & Teardown

    override func setUp() throws {
        try super.setUp()
        calculator = StreakCalculator()
        mockPersistence = MockPersistenceController()
        mockPersistence.reset()
        calendar = Calendar.current
    }

    override func tearDown() throws {
        calculator = nil
        mockPersistence.reset()
        mockPersistence = nil
        calendar = nil
        try super.tearDown()
    }

    // MARK: - Helper Methods

    func createSession(daysAgo: Int, isValid: Bool = true) -> MeditationSession {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        return mockPersistence.createMockSession(
            durationPlanned: 10,
            durationTotal: isValid ? 10.0 : 0.1,
            isValid: isValid,
            createdAt: date
        )
    }

    func createMultipleSessionsOnDay(daysAgo: Int, count: Int) -> [MeditationSession] {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        return (0..<count).map { offset in
            let sessionDate = date.addingTimeInterval(TimeInterval(offset * 3600)) // 1 hour apart
            return mockPersistence.createMockSession(createdAt: sessionDate)
        }
    }

    // MARK: - Current Streak Tests

    func testCalculateCurrentStreak_NoSessions() {
        let sessions: [MeditationSession] = []
        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 0, "Should return 0 streak for no sessions")
    }

    func testCalculateCurrentStreak_OnlyInvalidSessions() {
        let sessions = [
            createSession(daysAgo: 0, isValid: false),
            createSession(daysAgo: 1, isValid: false),
            createSession(daysAgo: 2, isValid: false)
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 0, "Should return 0 streak for only invalid sessions")
    }

    func testCalculateCurrentStreak_MeditatedToday() {
        let sessions = [
            createSession(daysAgo: 0), // Today
            createSession(daysAgo: 1), // Yesterday
            createSession(daysAgo: 2)  // 2 days ago
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 3, "Should count consecutive days including today")
    }

    func testCalculateCurrentStreak_MeditatedYesterday() {
        let sessions = [
            createSession(daysAgo: 1), // Yesterday
            createSession(daysAgo: 2), // 2 days ago
            createSession(daysAgo: 3)  // 3 days ago
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 3, "Should count consecutive days including yesterday")
    }

    func testCalculateCurrentStreak_StreakBrokenYesterday() {
        let sessions = [
            createSession(daysAgo: 2), // 2 days ago
            createSession(daysAgo: 3), // 3 days ago
            createSession(daysAgo: 4)  // 4 days ago
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 0, "Should return 0 if didn't meditate today or yesterday")
    }

    func testCalculateCurrentStreak_GapInMiddle() {
        let sessions = [
            createSession(daysAgo: 0), // Today
            createSession(daysAgo: 1), // Yesterday
            // Gap on day 2
            createSession(daysAgo: 3), // 3 days ago
            createSession(daysAgo: 4)  // 4 days ago
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 2, "Should stop counting at gap")
    }

    func testCalculateCurrentStreak_OnlyToday() {
        let sessions = [createSession(daysAgo: 0)]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 1, "Should return 1 for only today")
    }

    func testCalculateCurrentStreak_MultipleSessionsSameDay() {
        var sessions = createMultipleSessionsOnDay(daysAgo: 0, count: 3) // 3 sessions today
        sessions += createMultipleSessionsOnDay(daysAgo: 1, count: 2)   // 2 sessions yesterday

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 2, "Should count days, not sessions")
    }

    func testCalculateCurrentStreak_LongStreak() {
        // Create 30 consecutive days
        let sessions = (0..<30).map { createSession(daysAgo: $0) }

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 30, "Should handle long streaks")
    }

    func testCalculateCurrentStreak_MixedValidInvalidSessions() {
        let sessions = [
            createSession(daysAgo: 0, isValid: true),
            createSession(daysAgo: 0, isValid: false), // Invalid on same day
            createSession(daysAgo: 1, isValid: true),
            createSession(daysAgo: 2, isValid: false), // Only invalid on this day
            createSession(daysAgo: 3, isValid: true)
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 2, "Should stop at day with only invalid sessions")
    }

    // MARK: - Longest Streak Tests

    func testCalculateLongestStreak_NoSessions() {
        let sessions: [MeditationSession] = []
        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 0, "Should return 0 for no sessions")
    }

    func testCalculateLongestStreak_OnlyInvalidSessions() {
        let sessions = [
            createSession(daysAgo: 0, isValid: false),
            createSession(daysAgo: 1, isValid: false)
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 0, "Should return 0 for only invalid sessions")
    }

    func testCalculateLongestStreak_SingleDay() {
        let sessions = [createSession(daysAgo: 0)]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 1, "Should return 1 for single day")
    }

    func testCalculateLongestStreak_ConsecutiveDays() {
        let sessions = [
            createSession(daysAgo: 0),
            createSession(daysAgo: 1),
            createSession(daysAgo: 2),
            createSession(daysAgo: 3),
            createSession(daysAgo: 4)
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 5, "Should count all consecutive days")
    }

    func testCalculateLongestStreak_MultipleStreaks() {
        let sessions = [
            // First streak: 3 days
            createSession(daysAgo: 0),
            createSession(daysAgo: 1),
            createSession(daysAgo: 2),
            // Gap
            // Second streak: 5 days (longest)
            createSession(daysAgo: 5),
            createSession(daysAgo: 6),
            createSession(daysAgo: 7),
            createSession(daysAgo: 8),
            createSession(daysAgo: 9),
            // Gap
            // Third streak: 2 days
            createSession(daysAgo: 12),
            createSession(daysAgo: 13)
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 5, "Should return longest streak")
    }

    func testCalculateLongestStreak_EqualLengthStreaks() {
        let sessions = [
            // First streak: 3 days
            createSession(daysAgo: 0),
            createSession(daysAgo: 1),
            createSession(daysAgo: 2),
            // Gap
            // Second streak: 3 days
            createSession(daysAgo: 5),
            createSession(daysAgo: 6),
            createSession(daysAgo: 7)
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 3, "Should handle equal length streaks")
    }

    func testCalculateLongestStreak_MultipleSessionsSameDay() {
        var sessions = createMultipleSessionsOnDay(daysAgo: 0, count: 5)
        sessions += createMultipleSessionsOnDay(daysAgo: 1, count: 3)
        sessions += createMultipleSessionsOnDay(daysAgo: 2, count: 2)

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 3, "Should count days, not sessions")
    }

    func testCalculateLongestStreak_VeryLongStreak() {
        // Create 100 consecutive days
        let sessions = (0..<100).map { createSession(daysAgo: $0) }

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 100, "Should handle very long streaks")
    }

    func testCalculateLongestStreak_NonConsecutiveDays() {
        let sessions = [
            createSession(daysAgo: 0),
            createSession(daysAgo: 2), // Gap
            createSession(daysAgo: 4), // Gap
            createSession(daysAgo: 6)  // Gap
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 1, "Should return 1 when all days are isolated")
    }

    func testCalculateLongestStreak_CurrentStreakIsLongest() {
        let sessions = [
            // Current streak: 5 days (longest)
            createSession(daysAgo: 0),
            createSession(daysAgo: 1),
            createSession(daysAgo: 2),
            createSession(daysAgo: 3),
            createSession(daysAgo: 4),
            // Gap
            // Past streak: 2 days
            createSession(daysAgo: 7),
            createSession(daysAgo: 8)
        ]

        let streak = calculator.calculateLongestStreak(from: sessions)
        XCTAssertEqual(streak, 5, "Should recognize current streak as longest")
    }

    // MARK: - Has Meditated On Date Tests

    func testHasMeditatedOn_NoSessions() {
        let sessions: [MeditationSession] = []
        let hasMeditated = calculator.hasMeditatedOn(date: Date(), sessions: sessions)
        XCTAssertFalse(hasMeditated, "Should return false for no sessions")
    }

    func testHasMeditatedOn_ValidSessionOnDate() {
        let today = Date()
        let sessions = [createSession(daysAgo: 0)]

        let hasMeditated = calculator.hasMeditatedOn(date: today, sessions: sessions)
        XCTAssertTrue(hasMeditated, "Should return true for valid session on date")
    }

    func testHasMeditatedOn_OnlyInvalidSessionOnDate() {
        let today = Date()
        let sessions = [createSession(daysAgo: 0, isValid: false)]

        let hasMeditated = calculator.hasMeditatedOn(date: today, sessions: sessions)
        XCTAssertFalse(hasMeditated, "Should return false for only invalid sessions")
    }

    func testHasMeditatedOn_MultipleSessionsOnDate() {
        let today = Date()
        let sessions = createMultipleSessionsOnDay(daysAgo: 0, count: 3)

        let hasMeditated = calculator.hasMeditatedOn(date: today, sessions: sessions)
        XCTAssertTrue(hasMeditated, "Should return true for multiple sessions on date")
    }

    func testHasMeditatedOn_SessionOnDifferentDate() {
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let sessions = [createSession(daysAgo: 1)]

        let hasMeditated = calculator.hasMeditatedOn(date: today, sessions: sessions)
        XCTAssertFalse(hasMeditated, "Should return false for different date")
    }

    func testHasMeditatedOn_MixedValidInvalidOnDate() {
        let today = Date()
        let sessions = [
            createSession(daysAgo: 0, isValid: true),
            createSession(daysAgo: 0, isValid: false)
        ]

        let hasMeditated = calculator.hasMeditatedOn(date: today, sessions: sessions)
        XCTAssertTrue(hasMeditated, "Should return true if at least one valid session")
    }

    func testHasMeditatedOn_PastDate() {
        let pastDate = calendar.date(byAdding: .day, value: -5, to: Date())!
        let sessions = [createSession(daysAgo: 5)]

        let hasMeditated = calculator.hasMeditatedOn(date: pastDate, sessions: sessions)
        XCTAssertTrue(hasMeditated, "Should work for past dates")
    }

    func testHasMeditatedOn_FutureDate() {
        let futureDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let sessions = [createSession(daysAgo: 0)]

        let hasMeditated = calculator.hasMeditatedOn(date: futureDate, sessions: sessions)
        XCTAssertFalse(hasMeditated, "Should return false for future dates")
    }

    // MARK: - Last Meditation Date Tests

    func testLastMeditationDate_NoSessions() {
        let sessions: [MeditationSession] = []
        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNil(lastDate, "Should return nil for no sessions")
    }

    func testLastMeditationDate_OnlyInvalidSessions() {
        let sessions = [
            createSession(daysAgo: 0, isValid: false),
            createSession(daysAgo: 1, isValid: false)
        ]

        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNil(lastDate, "Should return nil for only invalid sessions")
    }

    func testLastMeditationDate_SingleSession() {
        let sessions = [createSession(daysAgo: 0)]

        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNotNil(lastDate, "Should return date for single session")

        let isToday = calendar.isDateInToday(lastDate!)
        XCTAssertTrue(isToday, "Should be today")
    }

    func testLastMeditationDate_MultipleSessions() {
        let sessions = [
            createSession(daysAgo: 0), // Most recent
            createSession(daysAgo: 5),
            createSession(daysAgo: 10)
        ]

        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNotNil(lastDate, "Should return most recent date")

        let isToday = calendar.isDateInToday(lastDate!)
        XCTAssertTrue(isToday, "Should be today (most recent)")
    }

    func testLastMeditationDate_UnsortedSessions() {
        // Sessions not in chronological order
        let sessions = [
            createSession(daysAgo: 5),
            createSession(daysAgo: 0), // Most recent
            createSession(daysAgo: 10),
            createSession(daysAgo: 2)
        ]

        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNotNil(lastDate, "Should find most recent regardless of order")

        let isToday = calendar.isDateInToday(lastDate!)
        XCTAssertTrue(isToday, "Should be today (most recent)")
    }

    func testLastMeditationDate_MixedValidInvalid() {
        let sessions = [
            createSession(daysAgo: 0, isValid: false), // Most recent but invalid
            createSession(daysAgo: 2, isValid: true),  // Most recent valid
            createSession(daysAgo: 5, isValid: true)
        ]

        let lastDate = calculator.lastMeditationDate(from: sessions)
        XCTAssertNotNil(lastDate, "Should find most recent valid session")

        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let isTwoDaysAgo = calendar.isDate(lastDate!, inSameDayAs: twoDaysAgo)
        XCTAssertTrue(isTwoDaysAgo, "Should skip invalid sessions")
    }

    // MARK: - Edge Cases

    func testStreakCalculation_TimeZoneEdgeCase() {
        // Create sessions at different times of day
        let now = Date()
        let earlyMorning = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: now)!
        let lateMorning = calendar.date(bySettingHour: 11, minute: 59, second: 0, of: now)!
        let lateEvening = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)!

        let sessions = [
            mockPersistence.createMockSession(createdAt: earlyMorning),
            mockPersistence.createMockSession(createdAt: lateMorning),
            mockPersistence.createMockSession(createdAt: lateEvening)
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 1, "Should count as one day despite different times")
    }

    func testStreakCalculation_MidnightBoundary() {
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Session just before midnight yesterday
        let beforeMidnight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
        // Session just after midnight today
        let afterMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 1, of: today)!

        let sessions = [
            mockPersistence.createMockSession(createdAt: afterMidnight),
            mockPersistence.createMockSession(createdAt: beforeMidnight)
        ]

        let streak = calculator.calculateCurrentStreak(from: sessions)
        XCTAssertEqual(streak, 2, "Should correctly handle midnight boundary")
    }

    func testStreakCalculation_EmptyArray() {
        let sessions: [MeditationSession] = []

        let currentStreak = calculator.calculateCurrentStreak(from: sessions)
        let longestStreak = calculator.calculateLongestStreak(from: sessions)

        XCTAssertEqual(currentStreak, 0, "Current streak should be 0")
        XCTAssertEqual(longestStreak, 0, "Longest streak should be 0")
    }

    func testStreakCalculation_VeryOldSessions() {
        // Sessions from a year ago
        let sessions = (365..<370).map { createSession(daysAgo: $0) }

        let currentStreak = calculator.calculateCurrentStreak(from: sessions)
        let longestStreak = calculator.calculateLongestStreak(from: sessions)

        XCTAssertEqual(currentStreak, 0, "Current streak should be 0 for old sessions")
        XCTAssertEqual(longestStreak, 5, "Longest streak should still be calculated")
    }

    // MARK: - Performance Tests

    func testCurrentStreakPerformance() {
        // Create 1000 sessions over 100 days
        let sessions = (0..<100).flatMap { day in
            (0..<10).map { _ in createSession(daysAgo: day) }
        }

        measure {
            _ = calculator.calculateCurrentStreak(from: sessions)
        }
    }

    func testLongestStreakPerformance() {
        // Create 1000 sessions over 100 days
        let sessions = (0..<100).flatMap { day in
            (0..<10).map { _ in createSession(daysAgo: day) }
        }

        measure {
            _ = calculator.calculateLongestStreak(from: sessions)
        }
    }

    func testHasMeditatedOnPerformance() {
        let sessions = (0..<365).map { createSession(daysAgo: $0) }
        let targetDate = Date()

        measure {
            _ = calculator.hasMeditatedOn(date: targetDate, sessions: sessions)
        }
    }
}
