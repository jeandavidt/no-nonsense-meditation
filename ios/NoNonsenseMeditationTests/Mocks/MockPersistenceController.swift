//
//  MockPersistenceController.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import CoreData
@testable import NoNonsenseMeditation

/// Mock persistence controller for testing
/// Uses in-memory store to avoid affecting real data
class MockPersistenceController {

    static let shared = MockPersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    init(inMemory: Bool = true) {
        container = NSPersistentContainer(name: "NoNonsenseMeditation")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load mock store: \(error)")
            }
        }

        viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }

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
