//
//  MockHealthStore.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-06.
//

import Foundation
import HealthKit
@testable import NoNonsenseMeditation

/// Mock implementation of HealthStoreProtocol for testing HealthKitService
final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    
    // MARK: - State
    
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var savedObjects: [HKObject] = []
    
    var shouldThrowOnRequestAuth = false
    var shouldThrowOnSave = false
    
    var requestAuthCalled = false
    
    // MARK: - Protocol Methods
    
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatus
    }
    
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws {
        requestAuthCalled = true
        if shouldThrowOnRequestAuth {
            throw HealthKitService.HealthKitError.authorizationDenied
        }
        // Simulate successful authorization
        authorizationStatus = .sharingAuthorized
    }
    
    func save(_ object: HKObject) async throws {
        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }
        savedObjects.append(object)
    }
    
    func save(_ objects: [HKObject]) async throws {
        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }
        savedObjects.append(contentsOf: objects)
    }
}
