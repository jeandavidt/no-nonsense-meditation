# CoreData Persistence Layer

## Overview

This directory contains the CoreData persistence layer with CloudKit integration for the No Nonsense Meditation app. The implementation provides thread-safe data storage, automatic cloud synchronization, and optimized query performance.

## Architecture

### Files

- **NoNonsenseMeditation.xcdatamodeld/** - CoreData model definition with entity schemas
- **PersistenceController.swift** - Persistence management with CloudKit integration

### Entity Schema

#### MeditationSession

Stores meditation session data with comprehensive tracking and sync status.

**Attributes:**

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| `idSession` | UUID | No | - | Primary key, unique identifier |
| `durationPlanned` | Int16 | No | 0 | User's intended duration (minutes) |
| `durationTotal` | Double | No | 0.0 | Actual meditation time (minutes) |
| `durationElapsed` | Double | No | 0.0 | Total elapsed time including pauses (minutes) |
| `isSessionValid` | Boolean | No | false | True if session >= 15 seconds |
| `createdAt` | Date | No | current | When session was started |
| `completedAt` | Date | Yes | - | When session ended (nil if incomplete) |
| `wasPaused` | Boolean | No | false | Whether session was paused |
| `pauseCount` | Int16 | No | 0 | Number of pause events |
| `syncedToHealthKit` | Boolean | No | false | HealthKit sync status |
| `syncedToiCloud` | Boolean | No | false | iCloud sync status (CloudKit managed) |

**Indexes:**

- `byCreatedAt` - Descending index on `createdAt` for efficient recent session queries
- `byCompletedAt` - Descending index on `completedAt` for completed session queries

**Constraints:**

- Uniqueness constraint on `idSession` prevents duplicate sessions

### Performance Optimizations

1. **Fetch Indexes** - Binary indexes on `createdAt` and `completedAt` for sub-20ms query times
2. **Automatic Merging** - `automaticallyMergesChangesFromParent` enabled for seamless CloudKit sync
3. **Background Contexts** - Dedicated background contexts for non-UI operations
4. **Batch Operations** - Use `newBackgroundContext()` for bulk data operations

## CloudKit Integration

### Configuration

**Container Identifier:** `iCloud.com.jeandavidt.NoNonsenseMeditation`

**Entitlements Required:**
- `com.apple.developer.icloud-container-identifiers`
- `com.apple.developer.icloud-services` (CloudKit)

### Sync Behavior

- **Automatic Sync** - NSPersistentCloudKitContainer handles sync automatically
- **Conflict Resolution** - `NSMergeByPropertyObjectTrumpMergePolicy` prefers remote changes
- **History Tracking** - Persistent history tracking enabled for reliable sync
- **Remote Notifications** - Listens for remote changes to merge immediately

### Sync Status

Use the `syncedToiCloud` attribute to track sync status:
- `false` - Not yet synced or sync pending
- `true` - Successfully synced to CloudKit (managed automatically)

## Usage Examples

### Basic Operations

```swift
import CoreData

// Get the shared persistence controller
let persistence = PersistenceController.shared

// Access the view context (main queue)
let context = persistence.viewContext

// Create a new meditation session
let session = MeditationSession(context: context)
session.idSession = UUID()
session.durationPlanned = 10
session.createdAt = Date()
session.isSessionValid = true

// Save to persistence
try? persistence.saveContext()
```

### Background Operations

```swift
// Perform work on background thread
persistence.performBackgroundTask { context in
    let session = MeditationSession(context: context)
    session.idSession = UUID()
    session.durationPlanned = 15
    session.createdAt = Date()

    try? context.save()
}

// Or create a dedicated background context
let backgroundContext = persistence.newBackgroundContext()
backgroundContext.perform {
    // Perform work...
    try? persistence.saveContext(backgroundContext)
}
```

### Fetching Data

```swift
// Fetch all sessions (sorted by most recent)
let allSessions = try? persistence.fetchAllSessions()

// Fetch only valid sessions (>= 15 seconds)
let validSessions = try? persistence.fetchValidSessions()

// Fetch sessions needing HealthKit sync
let unsyncedSessions = try? persistence.fetchSessionsNeedingHealthKitSync()

// Custom fetch request
let request = MeditationSession.fetchRequest()
request.predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
request.sortDescriptors = [NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: false)]
request.fetchLimit = 10
let sessions = try? context.fetch(request)
```

### SwiftUI Integration

```swift
import SwiftUI

@main
struct NoNonsenseMeditationApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}

// In SwiftUI views, use @FetchRequest
struct SessionListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeditationSession.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isSessionValid == YES"),
        animation: .default
    )
    private var sessions: FetchedResults<MeditationSession>

    var body: some View {
        List(sessions) { session in
            Text(session.createdAt?.formatted() ?? "Unknown")
        }
    }
}
```

### Preview Support

```swift
import SwiftUI

struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListView()
            .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
    }
}
```

## Error Handling

### Save Errors

```swift
do {
    try persistence.saveContext()
} catch {
    print("Failed to save: \(error.localizedDescription)")
    // Handle error appropriately
}
```

### Fetch Errors

```swift
let request = MeditationSession.fetchRequest()
do {
    let sessions = try context.fetch(request)
    // Use sessions
} catch {
    print("Failed to fetch: \(error.localizedDescription)")
    // Handle error appropriately
}
```

## Thread Safety

### Main Thread Operations

- **View Context** - Always use on main thread for UI updates
- **@FetchRequest** - Automatically updates UI on main thread

### Background Thread Operations

- **Background Contexts** - Use for bulk operations, imports, or heavy processing
- **performBackgroundTask** - Automatically creates and manages background context
- **Automatic Merging** - Changes automatically merge to view context

### Best Practices

1. Never access view context from background threads
2. Always use `perform` or `performAndWait` when accessing contexts
3. Create separate background contexts for long-running operations
4. Let CloudKit handle sync - don't manually manage `syncedToiCloud`

## Migration Strategy

### Future Schema Changes

When adding new attributes or entities:

1. Create new model version in Xcode (Editor > Add Model Version)
2. Make schema changes in new version
3. Create NSMappingModel if needed for complex migrations
4. Update `.xccurrentversion` to point to new version
5. Test migration with existing data before release

### Lightweight Migration

The current setup supports automatic lightweight migration for:
- Adding new attributes with default values
- Removing attributes
- Making attributes optional
- Renaming attributes (with renaming identifier)

## Monitoring and Debugging

### CloudKit Dashboard

Monitor sync status at: https://icloud.developer.apple.com/dashboard

- View records in development/production databases
- Check sync errors and conflicts
- Monitor container usage and quotas

### Console Logging

The PersistenceController logs key events:
- Persistent store loading success/failure
- CloudKit container configuration
- Context save operations
- Errors with detailed information

### Xcode CoreData Debugging

Enable CoreData SQL debugging in scheme:
```
-com.apple.CoreData.SQLDebug 1
```

Enable CloudKit debugging:
```
-com.apple.CoreData.CloudKitDebug 1
```

## Security Considerations

### Data Protection

- CoreData files are encrypted when device is locked (iOS default)
- CloudKit data encrypted in transit and at rest
- App-specific entitlements prevent unauthorized access

### Privacy

- No personally identifiable information stored by default
- Session data is private to user's iCloud account
- HealthKit sync requires explicit user permission

## Performance Benchmarks

**Expected Performance:**

- Session creation: < 5ms
- Session fetch (all): < 20ms with index
- Background save: < 10ms
- CloudKit sync: Automatic, non-blocking

**Optimization Tips:**

1. Use fetch request batching for large datasets
2. Implement pagination for UI lists > 100 items
3. Use background contexts for bulk operations
4. Minimize relationships to reduce fetch overhead

## Support

For issues with:
- CoreData schema: Check model consistency in Xcode
- CloudKit sync: Verify entitlements and container configuration
- Performance: Review indexes and fetch request optimization
- Conflicts: Check merge policy settings

---

**Last Updated:** 2026-01-05
**Model Version:** 1.0
**CloudKit Container:** iCloud.com.jeandavidt.NoNonsenseMeditation
