//
//  MockPersistenceController.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import CoreData
@testable import NoNonsenseMeditation

/// Mock persistence controller for testing
/// Inherits from PersistenceController to allow injection
class MockPersistenceController: PersistenceController {

    init() {
        super.init(inMemory: true)
    }
    
    // The parent class already has container and viewContext properties
    
    // Helper method to reset the store (delete all data)
    func reset() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MeditationSession")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Failed to reset mock context: \(error)")
        }
    }

    func createMockSession(
        durationPlanned: Int16 = 10,
        durationTotal: Double = 10.0,
        isValid: Bool = true,
        createdAt: Date = Date(),
        wasPaused: Bool = false
    ) -> MeditationSession {
        // Must run on main context
        let session = MeditationSession(context: viewContext)
        session.idSession = UUID()
        session.durationPlanned = durationPlanned
        session.durationTotal = durationTotal
        session.durationElapsed = durationTotal
        session.isSessionValid = isValid
        session.createdAt = createdAt
        session.completedAt = createdAt.addingTimeInterval(durationTotal * 60)
        session.wasPaused = wasPaused
        session.pauseCount = wasPaused ? 1 : 0
        session.syncedToHealthKit = false
        session.syncedToiCloud = false

        try? saveContext()
        return session
    }
}
