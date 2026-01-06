//
//  MockHealthKitService.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import Foundation
@testable import NoNonsenseMeditation

/// Mock HealthKit service for testing
/// Simulates HealthKit behavior without requiring actual authorization
actor MockHealthKitService {

    // MARK: - Mock State

    var authorizationStatus: HealthKitService.AuthorizationStatus = .notDetermined
    var savedSessions: [(duration: TimeInterval, startDate: Date, endDate: Date)] = []
    var shouldThrowOnSave: Bool = false
    var saveCallCount: Int = 0
    var batchSaveCallCount: Int = 0

    // MARK: - Mock Methods

    func checkAuthorizationStatus() -> HealthKitService.AuthorizationStatus {
        return authorizationStatus
    }

    func requestAuthorization() async throws {
        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.authorizationDenied
        }
        authorizationStatus = .authorized
    }

    func saveMindfulMinutes(
        duration: TimeInterval,
        startDate: Date,
        endDate: Date
    ) async throws {
        saveCallCount += 1

        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }

        if authorizationStatus != .authorized {
            throw HealthKitService.HealthKitError.authorizationDenied
        }

        savedSessions.append((duration: duration, startDate: startDate, endDate: endDate))
    }

    func batchSaveMindfulMinutes(
        sessions: [(duration: TimeInterval, startDate: Date, endDate: Date)]
    ) async throws {
        batchSaveCallCount += 1

        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }

        if authorizationStatus != .authorized {
            throw HealthKitService.HealthKitError.authorizationDenied
        }

        savedSessions.append(contentsOf: sessions)
    }

    // MARK: - Test Helpers

    func reset() {
        authorizationStatus = .notDetermined
        savedSessions = []
        shouldThrowOnSave = false
        saveCallCount = 0
        batchSaveCallCount = 0
    }
}
