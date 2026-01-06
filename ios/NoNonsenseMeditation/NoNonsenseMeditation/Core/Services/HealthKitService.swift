//
//  HealthKitService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import HealthKit

/// Actor responsible for HealthKit integration
/// Manages authorization and syncing of mindful minutes to Apple Health
actor HealthKitService {

    // MARK: - Types

    /// HealthKit service errors
    enum HealthKitError: Error, LocalizedError {
        case notAvailable
        case authorizationDenied
        case syncFailed(Error)

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .authorizationDenied:
                return "HealthKit authorization was denied"
            case .syncFailed(let error):
                return "Failed to sync to HealthKit: \(error.localizedDescription)"
            }
        }
    }

    /// Authorization status
    enum AuthorizationStatus: Sendable {
        case notDetermined
        case authorized
        case denied
        case notAvailable
    }

    // MARK: - Properties

    private let healthStore: HKHealthStore?
    private let mindfulSessionType = HKCategoryType(.mindfulSession)

    // MARK: - Initialization

    init() {
        // HealthKit is only available on iOS devices (not simulators in some cases)
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
    }

    // MARK: - Authorization

    /// Check current authorization status
    /// - Returns: Current authorization status
    func checkAuthorizationStatus() -> AuthorizationStatus {
        guard let healthStore = healthStore else {
            return .notAvailable
        }

        let status = healthStore.authorizationStatus(for: mindfulSessionType)

        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingAuthorized:
            return .authorized
        case .sharingDenied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }

    /// Request HealthKit authorization for mindful sessions
    /// - Throws: HealthKitError if authorization fails
    func requestAuthorization() async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        let typesToShare: Set<HKSampleType> = [mindfulSessionType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
        } catch {
            throw HealthKitError.authorizationDenied
        }
    }

    // MARK: - Syncing

    /// Save a meditation session to HealthKit as mindful minutes
    /// - Parameters:
    ///   - duration: Duration in minutes
    ///   - startDate: When the session started
    ///   - endDate: When the session ended
    /// - Throws: HealthKitError if sync fails
    func saveMindfulMinutes(
        duration: TimeInterval,
        startDate: Date,
        endDate: Date
    ) async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        // Verify authorization
        let status = checkAuthorizationStatus()
        guard status == .authorized else {
            throw HealthKitError.authorizationDenied
        }

        // Create mindful session sample
        let sample = HKCategorySample(
            type: mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        // Save to HealthKit
        do {
            try await healthStore.save(sample)
        } catch {
            throw HealthKitError.syncFailed(error)
        }
    }

    /// Batch save multiple meditation sessions to HealthKit
    /// - Parameter sessions: Array of tuples (duration, startDate, endDate)
    /// - Throws: HealthKitError if sync fails
    func batchSaveMindfulMinutes(
        sessions: [(duration: TimeInterval, startDate: Date, endDate: Date)]
    ) async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        // Verify authorization
        let status = checkAuthorizationStatus()
        guard status == .authorized else {
            throw HealthKitError.authorizationDenied
        }

        // Create samples
        let samples = sessions.map { session in
            HKCategorySample(
                type: mindfulSessionType,
                value: HKCategoryValue.notApplicable.rawValue,
                start: session.startDate,
                end: session.endDate
            )
        }

        // Batch save
        do {
            try await healthStore.save(samples)
        } catch {
            throw HealthKitError.syncFailed(error)
        }
    }
}
