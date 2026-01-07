//
//  HealthKitService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import HealthKit

// MARK: - Protocol Definition

/// Protocol abstraction for HKHealthStore to enable testing
protocol HealthStoreProtocol: Sendable {
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws
    func save(_ object: HKObject) async throws
    func save(_ objects: [HKObject]) async throws
}

// Wrapper to bridge HKHealthStore to HealthStoreProtocol
// This avoids issues with implicit protocol conformance of system classes
struct HKHealthStoreWrapper: HealthStoreProtocol {
    let store: HKHealthStore

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return store.authorizationStatus(for: type)
    }

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws {
        try await store.requestAuthorization(toShare: typesToShare ?? [], read: typesToRead ?? [])
    }

    func save(_ object: HKObject) async throws {
        try await store.save(object)
    }

    func save(_ objects: [HKObject]) async throws {
        try await store.save(objects)
    }
}

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

    private let healthStore: HealthStoreProtocol?
    private let mindfulSessionType = HKCategoryType(.mindfulSession)

    // MARK: - Initialization

    /// Initialize HealthKitService
    /// - Parameter store: Optional HealthStoreProtocol injection for testing. If nil, uses default HKHealthStore if available.
    init(store: HealthStoreProtocol? = nil) {
        if let store = store {
            self.healthStore = store
        } else if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStoreWrapper(store: HKHealthStore())
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
    ///   - startDate: When the session started
    ///   - endDate: When the session ended
    /// - Throws: HealthKitError if sync fails
    func saveMindfulMinutes(
        startDate: Date,
        endDate: Date
    ) async throws {
        guard let healthStore = healthStore else {
            print("[HealthKit] HealthKit not available on this device")
            throw HealthKitError.notAvailable
        }

        // Verify authorization
        let status = checkAuthorizationStatus()
        print("[HealthKit] Authorization status: \(status)")
        guard status == .authorized else {
            print("[HealthKit] Sync blocked - authorization status: \(status)")
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
            let duration = endDate.timeIntervalSince(startDate) / 60.0
            print("[HealthKit] Successfully saved mindful session: \(startDate) to \(endDate) (duration: \(String(format: "%.1f", duration)) minutes)")
        } catch {
            print("[HealthKit] Failed to save sample: \(error)")
            print("[HealthKit] Current authorization status: \(checkAuthorizationStatus())")
            throw HealthKitError.syncFailed(error)
        }
    }

    /// Batch save multiple meditation sessions to HealthKit
    /// - Parameter sessions: Array of tuples (startDate, endDate)
    /// - Throws: HealthKitError if sync fails
    func batchSaveMindfulMinutes(
        sessions: [(startDate: Date, endDate: Date)]
    ) async throws {
        guard let healthStore = healthStore else {
            print("[HealthKit] HealthKit not available on this device")
            throw HealthKitError.notAvailable
        }

        // Verify authorization
        let status = checkAuthorizationStatus()
        print("[HealthKit] Batch save authorization status: \(status)")
        guard status == .authorized else {
            print("[HealthKit] Batch sync blocked - authorization status: \(status)")
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
            print("[HealthKit] Successfully batch saved \(samples.count) mindful session(s)")
        } catch {
            print("[HealthKit] Failed to batch save samples: \(error)")
            print("[HealthKit] Current authorization status: \(checkAuthorizationStatus())")
            throw HealthKitError.syncFailed(error)
        }
    }
}
