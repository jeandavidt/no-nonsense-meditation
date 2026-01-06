//
//  TestDataFactory.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import Foundation
import CoreData
@testable import NoNonsenseMeditation

/// Factory for creating test data with realistic values
enum TestDataFactory {

    // MARK: - Timer Configuration

    /// Create a timer configuration for testing
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - keepScreenAwake: Keep screen awake setting
    ///   - playBellSound: Play bell sound setting
    ///   - overrideSilentMode: Override silent mode setting
    ///   - hapticFeedbackEnabled: Haptic feedback setting
    /// - Returns: Timer configuration
    static func createTimerConfiguration(
        durationMinutes: Int = 10,
        keepScreenAwake: Bool = true,
        playBellSound: Bool = true,
        overrideSilentMode: Bool = false,
        hapticFeedbackEnabled: Bool = true
    ) -> TimerConfiguration {
        return TimerConfiguration(
            durationMinutes: durationMinutes,
            keepScreenAwake: keepScreenAwake,
            playBellSound: playBellSound,
            overrideSilentMode: overrideSilentMode,
            hapticFeedbackEnabled: hapticFeedbackEnabled
        )
    }

    // MARK: - Meditation Session

    /// Create a meditation session for testing
    /// - Parameters:
    ///   - context: Core Data context
    ///   - durationPlanned: Planned duration in minutes
    ///   - durationTotal: Actual meditation duration in minutes
    ///   - durationElapsed: Total elapsed time in minutes
    ///   - isValid: Whether session is valid
    ///   - createdAt: Creation date
    ///   - completedAt: Completion date
    ///   - wasPaused: Whether session was paused
    ///   - pauseCount: Number of pauses
    /// - Returns: Meditation session
    static func createMeditationSession(
        in context: NSManagedObjectContext,
        durationPlanned: Int16 = 10,
        durationTotal: Double = 10.0,
        durationElapsed: Double = 10.0,
        isValid: Bool = true,
        createdAt: Date = Date(),
        completedAt: Date? = Date(),
        wasPaused: Bool = false,
        pauseCount: Int16 = 0
    ) -> MeditationSession {
        let session = MeditationSession(context: context)
        session.idSession = UUID()
        session.durationPlanned = durationPlanned
        session.durationTotal = durationTotal
        session.durationElapsed = durationElapsed
        session.isSessionValid = isValid
        session.createdAt = createdAt
        session.completedAt = completedAt
        session.wasPaused = wasPaused
        session.pauseCount = pauseCount
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        return session
    }

    /// Create multiple sessions for streak testing
    /// - Parameters:
    ///   - context: Core Data context
    ///   - daysAgo: Array of day offsets (0 = today, 1 = yesterday, etc.)
    ///   - validSessions: Whether sessions should be valid
    /// - Returns: Array of meditation sessions
    static func createSessionsForStreak(
        in context: NSManagedObjectContext,
        daysAgo: [Int],
        validSessions: Bool = true
    ) -> [MeditationSession] {
        let calendar = Calendar.current

        return daysAgo.map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return createMeditationSession(
                in: context,
                durationTotal: validSessions ? 10.0 : 0.1,
                isValid: validSessions,
                createdAt: date,
                completedAt: date.addingTimeInterval(600)
            )
        }
    }

    /// Create realistic session data for testing
    /// - Parameters:
    ///   - context: Core Data context
    ///   - count: Number of sessions to create
    ///   - daysBack: How many days back to generate sessions
    /// - Returns: Array of realistic meditation sessions
    static func createRealisticSessions(
        in context: NSManagedObjectContext,
        count: Int = 10,
        daysBack: Int = 30
    ) -> [MeditationSession] {
        let calendar = Calendar.current
        let durations: [Int16] = [5, 10, 15, 20, 30]

        return (0..<count).map { index in
            let randomDayOffset = Int.random(in: 0..<daysBack)
            let date = calendar.date(byAdding: .day, value: -randomDayOffset, to: Date()) ?? Date()

            let plannedDuration = durations.randomElement() ?? 10
            let actualDuration = Double(plannedDuration) + Double.random(in: -2...2)
            let wasPaused = Bool.random()
            let elapsedDuration = wasPaused ? actualDuration + Double.random(in: 0...5) : actualDuration

            return createMeditationSession(
                in: context,
                durationPlanned: plannedDuration,
                durationTotal: max(actualDuration, 0),
                durationElapsed: max(elapsedDuration, 0),
                isValid: actualDuration >= 0.25,
                createdAt: date,
                completedAt: date.addingTimeInterval(elapsedDuration * 60),
                wasPaused: wasPaused,
                pauseCount: wasPaused ? Int16.random(in: 1...3) : 0
            )
        }
    }

    // MARK: - Common Test Scenarios

    /// Create a perfect meditation session (completed as planned, no pauses)
    static func createPerfectSession(
        in context: NSManagedObjectContext,
        durationMinutes: Int16 = 15
    ) -> MeditationSession {
        let createdAt = Date()
        let completedAt = createdAt.addingTimeInterval(TimeInterval(durationMinutes * 60))

        return createMeditationSession(
            in: context,
            durationPlanned: durationMinutes,
            durationTotal: Double(durationMinutes),
            durationElapsed: Double(durationMinutes),
            isValid: true,
            createdAt: createdAt,
            completedAt: completedAt,
            wasPaused: false,
            pauseCount: 0
        )
    }

    /// Create a session that was paused multiple times
    static func createPausedSession(
        in context: NSManagedObjectContext,
        pauseCount: Int16 = 3
    ) -> MeditationSession {
        let plannedDuration: Int16 = 15
        let actualMeditation: Double = 13.0
        let totalElapsed: Double = 18.0

        return createMeditationSession(
            in: context,
            durationPlanned: plannedDuration,
            durationTotal: actualMeditation,
            durationElapsed: totalElapsed,
            isValid: true,
            createdAt: Date(),
            completedAt: Date().addingTimeInterval(totalElapsed * 60),
            wasPaused: true,
            pauseCount: pauseCount
        )
    }

    /// Create an invalid session (too short)
    static func createInvalidSession(
        in context: NSManagedObjectContext
    ) -> MeditationSession {
        return createMeditationSession(
            in: context,
            durationPlanned: 10,
            durationTotal: 0.1, // Less than 15 seconds
            durationElapsed: 0.1,
            isValid: false,
            createdAt: Date(),
            completedAt: Date().addingTimeInterval(6)
        )
    }

    /// Create a session that ended early
    static func createEarlyEndedSession(
        in context: NSManagedObjectContext
    ) -> MeditationSession {
        let plannedDuration: Int16 = 30
        let actualDuration: Double = 12.0

        return createMeditationSession(
            in: context,
            durationPlanned: plannedDuration,
            durationTotal: actualDuration,
            durationElapsed: actualDuration,
            isValid: true,
            createdAt: Date(),
            completedAt: Date().addingTimeInterval(actualDuration * 60)
        )
    }
}
