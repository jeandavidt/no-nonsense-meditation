//
//  SessionManager.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import CoreData

/// Actor responsible for managing meditation session lifecycle
/// Handles creation, persistence, and state management of meditation sessions
actor SessionManager {

    // MARK: - Properties

    /// Reference to persistence controller
    private let persistenceController: PersistenceController

    /// Current active session
    private(set) var activeSession: MeditationSession?

    /// Timer service for countdown
    private let timerService: MeditationTimerService

    /// HealthKit service for syncing meditation sessions
    private let healthKitService: HealthKitService

    /// Pause count for current session
    private var pauseCount: Int = 0

    // MARK: - Initialization

    /// Initialize session manager with persistence controller and HealthKit service
    /// - Parameters:
    ///   - persistenceController: CoreData persistence controller
    ///   - healthKitService: HealthKit service for syncing sessions
    init(
        persistenceController: PersistenceController = .shared,
        healthKitService: HealthKitService = HealthKitService()
    ) {
        self.persistenceController = persistenceController
        self.timerService = MeditationTimerService()
        self.healthKitService = healthKitService
    }

    // MARK: - Session Lifecycle

    /// Start a new meditation session
    /// - Parameter configuration: Timer configuration for the session
    /// - Returns: The newly created session
    @discardableResult
    func startSession(configuration: TimerConfiguration) async -> MeditationSession {
        // Create new session in CoreData
        let context = persistenceController.viewContext
        let session = MeditationSession(context: context)

        session.idSession = UUID()
        session.durationPlanned = Int16(configuration.durationMinutes)
        session.createdAt = Date()
        session.isSessionValid = false // Will be set when completed
        session.wasPaused = false
        session.pauseCount = 0
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        // Save context
        try? persistenceController.saveContext()

        // Store as active session
        self.activeSession = session
        self.pauseCount = 0

        // Start timer
        await timerService.startTimer(duration: configuration.durationSeconds)

        return session
    }

    /// Pause the current active session
    func pauseSession() async {
        guard activeSession != nil else { return }

        await timerService.pauseTimer()
        pauseCount += 1
    }

    /// Resume the current paused session
    func resumeSession() async {
        guard activeSession != nil else { return }

        await timerService.resumeTimer()
    }

    /// End the current session and save results
    /// - Returns: The completed session
    @discardableResult
    func endSession() async throws -> MeditationSession? {
        guard let session = activeSession else { return nil }

        // Stop timer
        await timerService.stopTimer()

        // Get actual meditation time
        let actualTime = await timerService.getActualMeditationTime()
        let elapsedTime = await timerService.elapsedTime

        // Update session with final data
        let context = persistenceController.viewContext
        session.completedAt = Date()
        session.durationTotal = actualTime / 60.0 // Convert to minutes
        session.durationElapsed = elapsedTime / 60.0 // Convert to minutes
        session.isSessionValid = actualTime >= 15 // 15 seconds minimum
        session.wasPaused = pauseCount > 0
        session.pauseCount = Int16(pauseCount)

        // Save context
        try persistenceController.saveContext()

        // Sync to HealthKit if authorized and session is valid
        if session.isSessionValid {
            await syncToHealthKit(session: session)
        }

        // Clear active session
        self.activeSession = nil
        self.pauseCount = 0

        // Reset timer
        await timerService.resetTimer()

        return session
    }

    /// Complete a session with specified parameters
    /// - Parameters:
    ///   - plannedDuration: Planned duration in seconds
    ///   - actualDuration: Actual meditation time in seconds
    ///   - wasPaused: Whether the session was paused
    /// - Returns: The completed session
    @discardableResult
    func completeSession(plannedDuration: TimeInterval, actualDuration: TimeInterval, wasPaused: Bool) async -> MeditationSession? {
        // Create new session in CoreData
        let context = persistenceController.viewContext
        let session = MeditationSession(context: context)

        session.idSession = UUID()
        session.durationPlanned = Int16(plannedDuration / 60.0) // Convert to minutes
        session.durationTotal = actualDuration / 60.0 // Convert to minutes
        session.durationElapsed = actualDuration / 60.0 // Convert to minutes
        session.createdAt = Date()
        session.completedAt = Date()
        session.isSessionValid = actualDuration >= 15 // 15 seconds minimum
        session.wasPaused = wasPaused
        session.pauseCount = wasPaused ? 1 : 0
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        // Save context
        try? persistenceController.saveContext()

        // Sync to HealthKit if authorized and session is valid
        if session.isSessionValid {
            await syncToHealthKit(session: session)
        }

        return session
    }

    // MARK: - HealthKit Integration

    /// Sync a meditation session to HealthKit
    /// - Parameter session: The session to sync
    private func syncToHealthKit(session: MeditationSession) async {
        // Check if already synced
        if session.syncedToHealthKit {
            return
        }

        // Check authorization status
        let authStatus = await healthKitService.checkAuthorizationStatus()
        guard authStatus == .authorized else {
            return
        }

        // Calculate session times
        guard let startDate = session.createdAt,
              let endDate = session.completedAt else {
            return
        }

        let duration = session.durationTotal * 60.0 // Convert minutes to seconds

        // Sync to HealthKit
        do {
            try await healthKitService.saveMindfulMinutes(
                duration: duration,
                startDate: startDate,
                endDate: endDate
            )

            // Mark as synced in CoreData
            let context = persistenceController.viewContext
            session.syncedToHealthKit = true
            try? persistenceController.saveContext()
        } catch {
            // Log error but don't fail the session
            print("Failed to sync session to HealthKit: \(error.localizedDescription)")
        }
    }

    /// Sync all unsynced sessions to HealthKit
    /// Call this when user grants HealthKit permission
    func syncAllUnsyncedSessions() async throws {
        // Check authorization status
        let authStatus = await healthKitService.checkAuthorizationStatus()
        guard authStatus == .authorized else {
            return
        }

        // Fetch all unsynced sessions
        let context = persistenceController.viewContext
        let fetchRequest = MeditationSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncedToHealthKit == NO AND isSessionValid == YES")

        guard let sessions = try? context.fetch(fetchRequest) else {
            return
        }

        // Prepare batch data
        var sessionData: [(duration: TimeInterval, startDate: Date, endDate: Date)] = []

        for session in sessions {
            guard let startDate = session.createdAt,
                  let endDate = session.completedAt else {
                continue
            }

            let duration = session.durationTotal * 60.0 // Convert minutes to seconds
            sessionData.append((duration: duration, startDate: startDate, endDate: endDate))
        }

        // Batch sync to HealthKit
        if !sessionData.isEmpty {
            try await healthKitService.batchSaveMindfulMinutes(sessions: sessionData)

            // Mark all as synced
            for session in sessions {
                session.syncedToHealthKit = true
            }
            try? persistenceController.saveContext()
        }
    }

    /// Cancel the current session without saving
    func cancelSession() async {
        guard let session = activeSession else { return }

        // Stop timer
        await timerService.stopTimer()

        // Delete session from CoreData
        let context = persistenceController.viewContext
        context.delete(session)
        try? persistenceController.saveContext()

        // Clear active session
        self.activeSession = nil
        self.pauseCount = 0

        // Reset timer
        await timerService.resetTimer()
    }

    // MARK: - Session State

    /// Get remaining time in current session
    /// - Returns: Remaining time in seconds, or nil if no active session
    func getRemainingTime() async -> TimeInterval? {
        guard activeSession != nil else { return nil }
        return await timerService.remainingTime
    }

    /// Get current timer state
    /// - Returns: Current timer state, or nil if no active session
    func getTimerState() async -> MeditationTimerService.TimerState? {
        guard activeSession != nil else { return nil }
        return await timerService.state
    }

    /// Get current timer progress (0.0 to 1.0)
    /// - Returns: Progress value, or nil if no active session
    func getProgress() async -> Double? {
        guard activeSession != nil else { return nil }
        return await timerService.getProgress()
    }

    /// Check if there is an active session
    var hasActiveSession: Bool {
        return activeSession != nil
    }
}
