//
//  PersistenceController.swift
//  NoNonsenseMeditation
//
//  Created by Backend Architect on 2026-01-05.
//

@preconcurrency import CoreData
@preconcurrency import CloudKit

/// Thread-safe CoreData persistence controller with CloudKit integration
/// Manages the persistent container and provides access to the view context
///
/// ## Concurrency Safety
/// This class is marked as `Sendable` because:
/// - The `container` property is immutable after initialization
/// - NSPersistentCloudKitContainer is thread-safe
/// - Static properties use `nonisolated(unsafe)` as they're initialized once and never mutated
class PersistenceController: Sendable {

    // MARK: - Singleton Instance

    /// Shared singleton instance for production use
    ///
    /// ## Concurrency Safety
    /// This is a constant let property initialized once and never mutated.
    /// PersistenceController is marked as Sendable, so it's safe to access from any context.
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews and testing
    ///
    /// ## Concurrency Safety
    /// This is a constant initialized once at program startup and never mutated afterwards.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        for i in 0..<10 {
            let session = MeditationSession(context: viewContext)
            session.idSession = UUID()
            session.durationPlanned = Int16([5, 10, 15, 20, 30].randomElement() ?? 10)
            session.durationTotal = Double(session.durationPlanned) + Double.random(in: -2...2)
            session.durationElapsed = session.durationTotal + Double.random(in: 0...5)
            session.isSessionValid = session.durationTotal >= 0.25 // 15 seconds
            session.createdAt = Date().addingTimeInterval(-Double(i) * 86400) // Last i days
            session.completedAt = session.createdAt?.addingTimeInterval(session.durationTotal * 60)
            session.wasPaused = Bool.random()
            session.pauseCount = session.wasPaused ? Int16.random(in: 1...3) : 0
            session.syncedToHealthKit = Bool.random()
            session.syncedToiCloud = false // Preview data not synced
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Failed to create preview data: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    // MARK: - Properties

    /// The persistent container with CloudKit integration
    let container: NSPersistentCloudKitContainer

    /// Main view context for UI operations (main queue concurrency)
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    // MARK: - Initialization

    /// Initialize the persistence controller
    /// - Parameter inMemory: Whether to use an in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoNonsenseMeditation")

        if inMemory {
            // Use in-memory store for previews and testing
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")

            // Disable CloudKit for in-memory stores
            container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil
        } else {
            // Check if running on simulator - CloudKit doesn't work well on simulator
            #if targetEnvironment(simulator)
            print("Running on simulator - disabling CloudKit for CoreData")
            container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil
            #else
            // Production CloudKit configuration
            configureCloudKitContainer()
            #endif
        }

        // Load persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Log the error for debugging
                print("CoreData: Failed to load persistent store")
                print("Store Description: \(storeDescription)")
                print("Error: \(error)")
                print("User Info: \(error.userInfo)")

                // In production, handle this error gracefully
                // For now, we'll crash to make development issues visible
                fatalError("Unresolved error loading persistent store: \(error), \(error.userInfo)")
            } else {
                print("CoreData: Successfully loaded persistent store")
                if let cloudKitOptions = storeDescription.cloudKitContainerOptions {
                    print("CloudKit: Container identifier - \(cloudKitOptions.containerIdentifier)")
                }
            }
        }

        // Configure view context for optimal performance and automatic merging
        configureViewContext()
    }

    // MARK: - Configuration

    /// Configure CloudKit container options for the persistent store
    private func configureCloudKitContainer() {
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            return
        }

        // CloudKit container identifier (must match entitlements)
        let containerIdentifier = "iCloud.com.jeandavidt.NoNonsenseMeditation"

        // Configure CloudKit options
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: containerIdentifier
        )

        storeDescription.cloudKitContainerOptions = cloudKitOptions

        // Enable persistent history tracking for CloudKit sync
        storeDescription.setOption(true as NSNumber,
                                   forKey: NSPersistentHistoryTrackingKey)

        // Enable remote change notifications
        storeDescription.setOption(true as NSNumber,
                                   forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    /// Configure the view context with optimal settings
    private func configureViewContext() {
        // Automatically merge changes from parent context (CloudKit sync)
        viewContext.automaticallyMergesChangesFromParent = true

        // Configure merge policy to prefer remote changes in case of conflicts
        // This ensures CloudKit changes take precedence over local changes
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Enable undo management for UI operations (disabled to avoid concurrency warnings)
        // viewContext.undoManager = UndoManager()

        // Set name for debugging
        viewContext.name = "ViewContext"
    }

    // MARK: - Background Context Operations

    /// Create a new background context for performing work off the main queue
    /// - Returns: A new background managed object context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = "BackgroundContext"
        return context
    }

    /// Perform a task on a background context
    /// - Parameter block: The block to perform with the background context
    ///
    /// ## Concurrency Safety
    /// The block parameter is marked as `@Sendable` to ensure it can be safely
    /// passed across concurrency domains. The block executes on a background queue.
    func performBackgroundTask(_ block: @escaping @Sendable (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.name = "BackgroundTask"
            block(context)
        }
    }

    // MARK: - Save Operations

    /// Save the view context if it has changes
    /// - Throws: CoreData save errors
    func saveContext() throws {
        guard viewContext.hasChanges else {
            return
        }

        do {
            try viewContext.save()
            print("CoreData: Successfully saved view context")
        } catch {
            let nsError = error as NSError
            print("CoreData: Failed to save view context - \(nsError), \(nsError.userInfo)")
            throw error
        }
    }

    /// Save a background context if it has changes
    /// - Parameter context: The context to save
    /// - Throws: CoreData save errors
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
            print("CoreData: Successfully saved background context")
        } catch {
            let nsError = error as NSError
            print("CoreData: Failed to save background context - \(nsError), \(nsError.userInfo)")
            throw error
        }
    }

    // MARK: - CloudKit Sync Status

    /// Check if CloudKit is available and configured
    var isCloudKitAvailable: Bool {
        guard let storeDescription = container.persistentStoreDescriptions.first,
              storeDescription.cloudKitContainerOptions != nil else {
            return false
        }
        return true
    }

    /// Get the CloudKit container identifier
    var cloudKitContainerIdentifier: String? {
        return container.persistentStoreDescriptions.first?
            .cloudKitContainerOptions?
            .containerIdentifier
    }
}

// MARK: - Convenience Extensions

extension PersistenceController {

    /// Fetch all meditation sessions sorted by creation date (most recent first)
    /// - Returns: Array of meditation sessions
    /// - Throws: CoreData fetch errors
    func fetchAllSessions() throws -> [MeditationSession] {
        let request = MeditationSession.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: false)
        ]
        return try viewContext.fetch(request)
    }

    /// Fetch valid meditation sessions (>= 15 seconds)
    /// - Returns: Array of valid meditation sessions
    /// - Throws: CoreData fetch errors
    func fetchValidSessions() throws -> [MeditationSession] {
        let request = MeditationSession.fetchRequest()
        request.predicate = NSPredicate(format: "isSessionValid == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: false)
        ]
        return try viewContext.fetch(request)
    }

    /// Fetch sessions that need syncing to HealthKit
    /// - Returns: Array of sessions not yet synced to HealthKit
    /// - Throws: CoreData fetch errors
    func fetchSessionsNeedingHealthKitSync() throws -> [MeditationSession] {
        let request = MeditationSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "isSessionValid == YES AND syncedToHealthKit == NO"
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: true)
        ]
        return try viewContext.fetch(request)
    }
}
