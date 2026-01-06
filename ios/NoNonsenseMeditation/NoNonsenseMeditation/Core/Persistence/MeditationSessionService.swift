//
//  MeditationSessionService.swift
//  NoNonsenseMeditation
//
//  Created by Backend Architect on 2026-01-05.
//

import CoreData
import Foundation

/// Service layer for meditation session data operations
/// Provides high-level API for creating, reading, updating sessions
class MeditationSessionService {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create Operations

    /// Create a new meditation session
    /// - Parameters:
    ///   - plannedDuration: User's intended duration in minutes
    ///   - startDate: When the session started (defaults to now)
    /// - Returns: The created MeditationSession
    /// - Throws: CoreData save errors
    func createSession(plannedDuration: Int, startDate: Date = Date()) throws -> MeditationSession {
        let context = persistenceController.viewContext

        let session = MeditationSession(context: context)
        session.idSession = UUID()
        session.durationPlanned = Int16(plannedDuration)
        session.durationTotal = 0.0
        session.durationElapsed = 0.0
        session.isSessionValid = false
        session.createdAt = startDate
        session.completedAt = nil
        session.wasPaused = false
        session.pauseCount = 0
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        try persistenceController.saveContext()

        print("✅ Created session: \(session.idSession?.uuidString ?? "unknown")")
        return session
    }

    // MARK: - Update Operations

    /// Complete a meditation session
    /// - Parameters:
    ///   - session: The session to complete
    ///   - actualDuration: Actual meditation time in minutes
    ///   - elapsedDuration: Total elapsed time including pauses in minutes
    ///   - pauseCount: Number of times session was paused
    ///   - completedDate: When the session was completed (defaults to now)
    /// - Throws: CoreData save errors
    func completeSession(
        _ session: MeditationSession,
        actualDuration: Double,
        elapsedDuration: Double,
        pauseCount: Int = 0,
        completedDate: Date = Date()
    ) throws {
        session.durationTotal = actualDuration
        session.durationElapsed = elapsedDuration
        session.pauseCount = Int16(pauseCount)
        session.wasPaused = pauseCount > 0
        session.completedAt = completedDate

        // Session is valid if it lasted at least 15 seconds (0.25 minutes)
        session.isSessionValid = actualDuration >= 0.25

        try persistenceController.saveContext()

        print("✅ Completed session: \(session.idSession?.uuidString ?? "unknown"), valid: \(session.isSessionValid)")
    }

    /// Mark a session as synced to HealthKit
    /// - Parameter session: The session to update
    /// - Throws: CoreData save errors
    func markSyncedToHealthKit(_ session: MeditationSession) throws {
        session.syncedToHealthKit = true
        try persistenceController.saveContext()

        print("✅ Marked session synced to HealthKit: \(session.idSession?.uuidString ?? "unknown")")
    }

    /// Update pause count for an active session
    /// - Parameters:
    ///   - session: The session to update
    ///   - pauseCount: New pause count
    /// - Throws: CoreData save errors
    func updatePauseCount(_ session: MeditationSession, pauseCount: Int) throws {
        session.pauseCount = Int16(pauseCount)
        session.wasPaused = pauseCount > 0
        try persistenceController.saveContext()

        print("✅ Updated pause count for session: \(session.idSession?.uuidString ?? "unknown")")
    }

    // MARK: - Read Operations

    /// Fetch all meditation sessions sorted by most recent
    /// - Returns: Array of all sessions
    /// - Throws: CoreData fetch errors
    func fetchAllSessions() throws -> [MeditationSession] {
        return try persistenceController.fetchAllSessions()
    }

    /// Fetch only valid meditation sessions (>= 15 seconds)
    /// - Returns: Array of valid sessions
    /// - Throws: CoreData fetch errors
    func fetchValidSessions() throws -> [MeditationSession] {
        return try persistenceController.fetchValidSessions()
    }

    /// Fetch sessions within a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of sessions in range
    /// - Throws: CoreData fetch errors
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [MeditationSession] {
        let request = MeditationSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: false)
        ]

        return try persistenceController.viewContext.fetch(request)
    }

    /// Fetch sessions for a specific day
    /// - Parameter date: The date to fetch sessions for
    /// - Returns: Array of sessions for that day
    /// - Throws: CoreData fetch errors
    func fetchSessions(for date: Date) throws -> [MeditationSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try fetchSessions(from: startOfDay, to: endOfDay)
    }

    /// Fetch a specific session by ID
    /// - Parameter id: The session UUID
    /// - Returns: The session if found, nil otherwise
    /// - Throws: CoreData fetch errors
    func fetchSession(byId id: UUID) throws -> MeditationSession? {
        let request = MeditationSession.fetchRequest()
        request.predicate = NSPredicate(format: "idSession == %@", id as CVarArg)
        request.fetchLimit = 1

        return try persistenceController.viewContext.fetch(request).first
    }

    /// Fetch sessions that need syncing to HealthKit
    /// - Returns: Array of unsynced valid sessions
    /// - Throws: CoreData fetch errors
    func fetchSessionsNeedingHealthKitSync() throws -> [MeditationSession] {
        return try persistenceController.fetchSessionsNeedingHealthKitSync()
    }

    // MARK: - Delete Operations

    /// Delete a specific session
    /// - Parameter session: The session to delete
    /// - Throws: CoreData save errors
    func deleteSession(_ session: MeditationSession) throws {
        let context = persistenceController.viewContext
        let sessionId = session.idSession?.uuidString ?? "unknown"

        context.delete(session)
        try persistenceController.saveContext()

        print("✅ Deleted session: \(sessionId)")
    }

    /// Delete multiple sessions
    /// - Parameter sessions: Array of sessions to delete
    /// - Throws: CoreData save errors
    func deleteSessions(_ sessions: [MeditationSession]) throws {
        let context = persistenceController.viewContext

        for session in sessions {
            context.delete(session)
        }

        try persistenceController.saveContext()

        print("✅ Deleted \(sessions.count) sessions")
    }

    /// Delete all sessions (use with caution!)
    /// - Parameter includeValid: Whether to delete valid sessions too (default: false)
    /// - Throws: CoreData save/fetch errors
    func deleteAllSessions(includeValid: Bool = false) throws {
        let request = MeditationSession.fetchRequest()

        if !includeValid {
            request.predicate = NSPredicate(format: "isSessionValid == NO")
        }

        let sessions = try persistenceController.viewContext.fetch(request)
        try deleteSessions(sessions)

        print("✅ Deleted all \(includeValid ? "" : "invalid ")sessions")
    }

    // MARK: - Statistics

    /// Calculate total meditation time
    /// - Parameter validOnly: Whether to count only valid sessions (default: true)
    /// - Returns: Total minutes meditated
    /// - Throws: CoreData fetch errors
    func totalMeditationTime(validOnly: Bool = true) throws -> Double {
        let request = MeditationSession.fetchRequest()

        if validOnly {
            request.predicate = NSPredicate(format: "isSessionValid == YES")
        }

        let sessions = try persistenceController.viewContext.fetch(request)
        return sessions.reduce(0.0) { $0 + $1.durationTotal }
    }

    /// Count total sessions
    /// - Parameter validOnly: Whether to count only valid sessions (default: true)
    /// - Returns: Number of sessions
    /// - Throws: CoreData fetch errors
    func sessionCount(validOnly: Bool = true) throws -> Int {
        let request = MeditationSession.fetchRequest()

        if validOnly {
            request.predicate = NSPredicate(format: "isSessionValid == YES")
        }

        return try persistenceController.viewContext.count(for: request)
    }

    /// Calculate average session duration
    /// - Parameter validOnly: Whether to include only valid sessions (default: true)
    /// - Returns: Average duration in minutes, or 0 if no sessions
    /// - Throws: CoreData fetch errors
    func averageSessionDuration(validOnly: Bool = true) throws -> Double {
        let total = try totalMeditationTime(validOnly: validOnly)
        let count = try sessionCount(validOnly: validOnly)

        guard count > 0 else { return 0.0 }
        return total / Double(count)
    }

    /// Get current meditation streak (consecutive days with valid sessions)
    /// - Returns: Number of consecutive days with meditation
    /// - Throws: CoreData fetch errors
    func currentStreak() throws -> Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0

        // Check each day going backwards
        for _ in 0..<365 { // Max 1 year streak check
            let sessions = try fetchSessions(for: currentDate)
            let hasValidSession = sessions.contains { $0.isSessionValid }

            if hasValidSession {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }

        return streak
    }

    /// Get meditation statistics for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Dictionary with statistics
    /// - Throws: CoreData fetch errors
    func statistics(from startDate: Date, to endDate: Date) throws -> MeditationStatistics {
        let sessions = try fetchSessions(from: startDate, to: endDate)
        let validSessions = sessions.filter { $0.isSessionValid }

        let totalTime = validSessions.reduce(0.0) { $0 + $1.durationTotal }
        let totalPauses = validSessions.reduce(0) { $0 + Int($1.pauseCount) }
        let averageDuration = validSessions.isEmpty ? 0.0 : totalTime / Double(validSessions.count)
        let longestSession = validSessions.map { $0.durationTotal }.max() ?? 0.0

        return MeditationStatistics(
            totalSessions: validSessions.count,
            totalTime: totalTime,
            averageDuration: averageDuration,
            longestSession: longestSession,
            totalPauses: totalPauses,
            sessionsWithPauses: validSessions.filter { $0.wasPaused }.count
        )
    }
}

// MARK: - Statistics Model

/// Statistics summary for meditation sessions
struct MeditationStatistics {
    let totalSessions: Int
    let totalTime: Double // minutes
    let averageDuration: Double // minutes
    let longestSession: Double // minutes
    let totalPauses: Int
    let sessionsWithPauses: Int

    /// Percentage of sessions that were paused
    var pausePercentage: Double {
        guard totalSessions > 0 else { return 0.0 }
        return Double(sessionsWithPauses) / Double(totalSessions) * 100.0
    }

    /// Average pauses per session
    var averagePausesPerSession: Double {
        guard totalSessions > 0 else { return 0.0 }
        return Double(totalPauses) / Double(totalSessions)
    }

    /// Format total time as human-readable string
    var formattedTotalTime: String {
        let hours = Int(totalTime / 60)
        let minutes = Int(totalTime.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Background Operations Extension

extension MeditationSessionService {

    /// Import sessions on a background thread (useful for batch operations)
    /// - Parameter sessionData: Array of session data dictionaries
    /// - Parameter completion: Completion handler called on main thread
    func importSessions(
        _ sessionData: [(plannedDuration: Int, actualDuration: Double, date: Date)],
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        persistenceController.performBackgroundTask { context in
            var importedCount = 0

            for data in sessionData {
                let session = MeditationSession(context: context)
                session.idSession = UUID()
                session.durationPlanned = Int16(data.plannedDuration)
                session.durationTotal = data.actualDuration
                session.durationElapsed = data.actualDuration
                session.isSessionValid = data.actualDuration >= 0.25
                session.createdAt = data.date
                session.completedAt = data.date.addingTimeInterval(data.actualDuration * 60)
                session.wasPaused = false
                session.pauseCount = 0
                session.syncedToHealthKit = false
                session.syncedToiCloud = false

                importedCount += 1
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    completion(.success(importedCount))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
