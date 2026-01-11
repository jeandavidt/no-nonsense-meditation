//
//  PersistenceController.swift
//  NoNonsenseMeditation
//
//  Created by Backend Architect on 2026-01-05.
//

@preconcurrency import CoreData
@preconcurrency import CloudKit
import SwiftUI

/// Persistence controller errors
enum PersistenceError: Error, LocalizedError {
    case cloudKitUnavailable(String)
    case cloudKitLoadFailed(Error)
    case localStoreLoadFailed(Error)
    case inMemoryStoreFallback(String)

    var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable(let reason):
            return "iCloud sync unavailable: \(reason)"
        case .cloudKitLoadFailed(let error):
            return "Failed to load iCloud store: \(error.localizedDescription)"
        case .localStoreLoadFailed(let error):
            return "Failed to load local store: \(error.localizedDescription)"
        case .inMemoryStoreFallback(let reason):
            return "Using temporary storage: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cloudKitUnavailable:
            return "Sign in to iCloud in Settings to enable sync."
        case .cloudKitLoadFailed:
            return "Your data is saved locally. Check iCloud status in Settings."
        case .localStoreLoadFailed:
            return "Using temporary storage. Your data will not persist after closing the app."
        case .inMemoryStoreFallback:
            return "Your data will not be saved. Please restart the app or check device storage."
        }
    }
}

/// Current persistence mode
enum PersistenceMode: Sendable {
    case cloudKit           // Full CloudKit sync enabled
    case localOnly          // Local storage only, no sync
    case inMemory          // Volatile in-memory storage
    case failed(String)    // Failed to initialize (with error message)

    var isFullyFunctional: Bool {
        if case .failed = self { return false }
        return true
    }

    var displayName: String {
        switch self {
        case .cloudKit: return "iCloud Sync"
        case .localOnly: return "Local Only"
        case .inMemory: return "Temporary"
        case .failed: return "Error"
        }
    }

    var description: String {
        switch self {
        case .cloudKit:
            return "Syncing across devices"
        case .localOnly:
            return "Data saved locally"
        case .inMemory:
            return "Data not persisting"
        case .failed(let message):
            return message
        }
    }

    var icon: String {
        switch self {
        case .cloudKit: return "icloud.fill"
        case .localOnly: return "internaldrive.fill"
        case .inMemory: return "memorychip.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .cloudKit: return .blue
        case .localOnly: return .green
        case .inMemory: return .orange
        case .failed: return .red
        }
    }
}

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

    // MARK: - Persistence Status

    /// Current persistence mode
    private(set) var persistenceMode: PersistenceMode = .failed("Not initialized")

    /// Last error encountered (if any)
    private(set) var lastError: PersistenceError?

    /// Whether CloudKit is currently active
    var isCloudKitActive: Bool {
        if case .cloudKit = persistenceMode {
            return true
        }
        return false
    }

    /// Whether data is persisting (not in-memory)
    var isDataPersisting: Bool {
        switch persistenceMode {
        case .cloudKit, .localOnly:
            return true
        case .inMemory, .failed:
            return false
        }
    }

    /// User-facing status message
    var statusMessage: String {
        persistenceMode.description
    }

    // MARK: - CloudKit Availability

    /// Synchronously check CloudKit account status (used during init only)
    /// - Note: Uses semaphore for synchronous operation. Only called once during initialization.
    private func checkCloudKitAccountStatusSync() -> CKAccountStatus {
        let semaphore = DispatchSemaphore(value: 0)
        var accountStatus: CKAccountStatus = .couldNotDetermine
        let container = CKContainer(identifier: "iCloud.com.jeandavidt.NoNonsenseMeditation")

        container.accountStatus { status, error in
            if let error = error {
                print("CloudKit: Error checking account status - \(error)")
                accountStatus = .couldNotDetermine
            } else {
                accountStatus = status
            }
            semaphore.signal()
        }

        // Wait up to 3 seconds for response
        _ = semaphore.wait(timeout: .now() + 3.0)
        return accountStatus
    }

    /// Check if CloudKit should be enabled based on account status
    /// - Returns: Tuple indicating if CloudKit should be enabled and the reason if not
    private func shouldEnableCloudKit() -> (enabled: Bool, reason: String?) {
        let status = checkCloudKitAccountStatusSync()

        switch status {
        case .available:
            return (true, nil)
        case .noAccount:
            return (false, "No iCloud account signed in")
        case .restricted:
            return (false, "iCloud access restricted")
        case .couldNotDetermine:
            return (false, "Could not determine iCloud status")
        case .temporarilyUnavailable:
            return (false, "iCloud temporarily unavailable")
        @unknown default:
            return (false, "Unknown iCloud status")
        }
    }

    // MARK: - Store Configuration

    /// Load persistent stores synchronously with error handling
    /// - Returns: True if successful, false if failed
    @discardableResult
    private func loadStoreSync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var success = false

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("CoreData: Failed to load persistent store")
                print("Store Description: \(storeDescription)")
                print("Error: \(error)")
                print("User Info: \(error.userInfo)")
                success = false
            } else {
                print("CoreData: Successfully loaded persistent store")
                if let cloudKitOptions = storeDescription.cloudKitContainerOptions {
                    print("CloudKit: Container identifier - \(cloudKitOptions.containerIdentifier)")
                }
                success = true
            }
            semaphore.signal()
        }

        // Wait for load to complete (up to 10 seconds)
        _ = semaphore.wait(timeout: .now() + 10.0)
        return success
    }

    /// Configure store for in-memory mode
    private func configureInMemoryStore() {
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil
    }

    /// Configure store for local-only mode (no CloudKit)
    private func configureLocalOnlyStore() {
        // Remove CloudKit options but keep file-based storage
        container.persistentStoreDescriptions.first?.cloudKitContainerOptions = nil

        // Still enable persistent history tracking for potential future sync
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
    }

    // MARK: - Initialization

    /// Initialize the persistence controller with graceful fallback handling
    /// - Parameter inMemory: Whether to use an in-memory store (for testing/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoNonsenseMeditation")

        // Handle in-memory mode (for previews/testing)
        if inMemory {
            configureInMemoryStore()
            loadStoreSync()
            configureViewContext()
            self.persistenceMode = .inMemory
            self.lastError = nil
            return
        }

        // Handle simulator (always use local-only)
        #if targetEnvironment(simulator)
        print("CoreData: Running on simulator - using local-only mode")
        configureLocalOnlyStore()
        loadStoreSync()
        configureViewContext()
        self.persistenceMode = .localOnly
        self.lastError = nil
        return
        #endif

        // PRODUCTION PATH: Attempt CloudKit, then fallback

        // Step 1: Check user's iCloud sync preference
        let userEnabledSync = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true

        // Track the reason for not using CloudKit
        var cloudKitUnavailableReason: String? = nil

        if !userEnabledSync {
            print("CoreData: User disabled iCloud sync - using local-only mode")
            cloudKitUnavailableReason = "User disabled iCloud sync"
        } else {
            // Step 2: Check CloudKit availability
            let (cloudKitEnabled, cloudKitReason) = shouldEnableCloudKit()

            if cloudKitEnabled {
                print("CoreData: CloudKit available - attempting CloudKit mode")
                configureCloudKitContainer()

                if loadStoreSync() {
                    print("CoreData: Successfully loaded CloudKit store")
                    configureViewContext()
                    self.persistenceMode = .cloudKit
                    self.lastError = nil
                    return
                }
                print("CoreData: CloudKit store failed - falling back to local-only")
                cloudKitUnavailableReason = "CloudKit store load failed"
            } else {
                print("CoreData: CloudKit unavailable (\(cloudKitReason ?? "unknown")) - using local-only mode")
                cloudKitUnavailableReason = cloudKitReason
            }
        }

        // Step 3: Try Local-Only store
        configureLocalOnlyStore()
        if loadStoreSync() {
            print("CoreData: Successfully loaded local-only store")
            configureViewContext()
            self.persistenceMode = .localOnly
            self.lastError = PersistenceError.cloudKitUnavailable(cloudKitUnavailableReason ?? "unknown")
            return
        }
        print("CoreData: Local store failed - falling back to in-memory")

        // Step 3: In-Memory fallback (last resort)
        print("CoreData: WARNING - Using in-memory store, data will not persist")
        configureInMemoryStore()
        loadStoreSync()
        configureViewContext()
        self.persistenceMode = .inMemory
        self.lastError = PersistenceError.inMemoryStoreFallback("Local storage unavailable")
    }

    // MARK: - Configuration

    /// Configure CloudKit container options for the persistent store
    private func configureCloudKitContainer() {
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            return
        }

        // CloudKit container identifier (must match entitlements)
        // Using v2 container to avoid corrupted original container
        let containerIdentifier = "iCloud.com.jeandavidt.NoNonsenseMeditation.v2"

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
