# No Nonsense meditation

## Prodcut overview

When meditating with an iPhone app, all you need really is a timer and a way to log your time. This app should be just that: A timer, an integration to the Health app to record mindful minutes, and a streak counter. The app is mainly for me (homebrewed software). It's using SwiftUI for the UI, App Intents to allow shortcuts to start meditations, and CoreData to store the backend and sync the user data to their icloud.

- Product Overview
    - What the app is, who it is for, what tech stack it’s using. Be specific.
- File Structure:
    ```
    NoNonsenseMeditation/
    ├── NoNonsenseMeditation.xcodeproj/
    ├── NoNonsenseMeditation/
    │   ├── App/
    │   │   ├── NoNonsenseMeditationApp.swift          # @main entry point
    │   │   ├── AppDelegate.swift                       # HealthKit authorization on launch
    │   │   └── Info.plist
    │   ├── Core/
    │   │   ├── Models/
    │   │   │   ├── MeditationSession.swift            # CoreData entity class
    │   │   │   ├── SessionStatistics.swift            # Computed stats model
    │   │   │   └── TimerConfiguration.swift           # Timer setup model
    │   │   ├── Persistence/
    │   │   │   ├── PersistenceController.swift        # CoreData stack
    │   │   │   ├── NoNonsenseMeditation.xcdatamodeld/
    │   │   │   └── CloudKitSyncManager.swift          # iCloud sync
    │   │   ├── Services/
    │   │   │   ├── MeditationTimerService.swift       # Timer logic (actor)
    │   │   │   ├── HealthKitService.swift             # HealthKit integration (actor)
    │   │   │   ├── SessionManager.swift               # Session lifecycle (actor)
    │   │   │   ├── StreakCalculator.swift             # Streak computation
    │   │   │   ├── AudioService.swift                 # Bell sound playback
    │   │   │   └── NotificationService.swift          # Local notifications
    │   │   └── Utilities/
    │   │       ├── Constants.swift
    │   │       ├── Extensions/
    │   │       │   ├── Date+Extensions.swift
    │   │       │   ├── TimeInterval+Extensions.swift
    │   │       │   └── View+Extensions.swift
    │   │       └── Logging/
    │   │           └── AppLogger.swift
    │   ├── Features/
    │   │   ├── Timer/
    │   │   │   ├── Views/
    │   │   │   │   ├── TimerTabView.swift
    │   │   │   │   ├── TimerSetupView.swift
    │   │   │   │   ├── ActiveMeditationView.swift
    │   │   │   │   ├── SessionRecapView.swift
    │   │   │   │   └── Components/
    │   │   │   │       ├── CircularTimerDial.swift
    │   │   │   │       ├── MinutePickerDial.swift
    │   │   │   │       └── TimerControlButton.swift
    │   │   │   └── ViewModels/
    │   │   │       ├── TimerViewModel.swift
    │   │   │       └── SessionRecapViewModel.swift
    │   │   └── Settings/
    │   │       ├── Views/
    │   │       │   ├── SettingsTabView.swift
    │   │       │   ├── StatisticsHeaderView.swift
    │   │       │   ├── SettingsListView.swift
    │   │       │   └── Components/
    │   │       │       ├── SettingsToggleRow.swift
    │   │       │       └── StatisticCardView.swift
    │   │       └── ViewModels/
    │   │           └── SettingsViewModel.swift
    │   ├── UI/
    │   │   ├── Theme/
    │   │   │   ├── AppTheme.swift
    │   │   │   ├── Typography.swift
    │   │   │   └── Spacing.swift
    │   │   ├── Components/
    │   │   │   ├── PrimaryButton.swift
    │   │   │   ├── SecondaryButton.swift
    │   │   │   └── LoadingIndicator.swift
    │   │   └── Modifiers/
    │   │       ├── CardModifier.swift
    │   │       └── AdaptiveTextModifier.swift
    │   ├── Intents/
    │   │   ├── StartMeditationIntent.swift
    │   │   ├── AppShortcutsProvider.swift
    │   │   └── IntentError.swift
    │   ├── Resources/
    │   │   ├── Assets.xcassets/
    │   │   │   ├── AppIcon.appiconset/
    │   │   │   ├── AccentColor.colorset/
    │   │   │   └── Colors/
    │   │   ├── Sounds/
    │   │   │   └── meditation_bell.wav
    │   │   └── Localization/
    │   │       └── Localizable.strings
    │   └── NoNonsenseMeditation.entitlements
    ├── NoNonsenseMeditationTests/
    └── NoNonsenseMeditationUITests/
    ```
- Naming Patterns:
    - **Files**: Match primary type name (e.g., `TimerViewModel.swift` contains `TimerViewModel`)
    - **Types**:
        - Protocols: `{Capability}able`, `{Noun}Protocol`, or `{Noun}ing` (e.g., `Persistable`, `SessionManaging`)
        - Structs/Classes: `{Noun}` or `{Adjective}{Noun}` (e.g., `MeditationSession`, `TimerConfiguration`)
        - Actors: `{Noun}Service` or `{Noun}Manager` (e.g., `HealthKitService`, `SessionManager`)
        - Enums: `{Noun}` or `{Noun}State` (e.g., `SessionState`, `TimerError`)
        - SwiftUI Views: `{Purpose}View` (e.g., `TimerSetupView`, `ActiveMeditationView`)
        - ViewModels: `{Feature}ViewModel` with `@MainActor` and `@Observable` (e.g., `TimerViewModel`)
    - **Variables/Constants**: lowerCamelCase
        - Booleans read as assertions: `isSessionActive`, `canSyncToCloud`, `hasActiveSession`
        - Collections are plural: `activeSessions`, `sessionsByDate`
    - **Functions**: lowerCamelCase, start with verb
        - `func startMeditation(duration: TimeInterval)`
        - `func calculateStreak(from sessions: [MeditationSession]) -> Int`
        - Booleans return questions: `func isSessionValid() -> Bool`
    - **SwiftUI State**: `@State private var selectedDuration: Int`, `@Binding var isPresented: Bool`
    - **CoreData Entities**: PascalCase matching Swift class names
        - Entity: `MeditationSession`
        - Attributes: lowerCamelCase (`idSession`, `durationPlanned`, `isSessionValid`)
    - **Project-Specific Terms**:
        - Use "Session" not "meditation" alone
        - Use "Timer" for countdown mechanism
        - Use "Duration" for time periods (not "length")
        - Use "Recap" for post-session summary
    - **Access Control**: Use `private` for internal implementation, `fileprivate` sparingly
    - **Documentation**: Use `///` markup for all public APIs
- UI Design
    - **Icons** (SF Symbols):
        - Timer Tab: `timer` or `clock.fill`
        - Settings Tab: `gearshape.fill`
        - Start Button: `play.circle.fill` (size: .large or custom 60-80pt)
        - Pause Button: `pause.circle.fill`
        - Resume Button: `play.circle.fill`
        - End Session: `xmark.circle.fill` or `stop.circle.fill`
        - Close/Dismiss: `xmark` (weight: .medium)
        - Health Integration: `heart.fill` or `cross.case.fill`
        - iCloud Sync: `icloud.fill`
        - Streak Counter: `flame.fill` or `calendar.badge.checkmark`
        - Meditation Minutes: `clock.arrow.circlepath` or `hourglass`

    - **Typography** (SF Pro - system default):
        - Timer Display (countdown): `.system(size: 72, weight: .thin, design: .rounded)`
        - Large Titles (recap stats): `.system(size: 48, weight: .light, design: .rounded)`
        - Section Headers: `.system(size: 20, weight: .semibold, design: .default)`
        - Body Text: `.system(size: 17, weight: .regular, design: .default)`
        - Secondary Text: `.system(size: 15, weight: .regular, design: .default)`
        - Button Labels: `.system(size: 17, weight: .semibold, design: .default)`
        - Support Dynamic Type for accessibility

    - **Color Scheme**:
        - Accent Color: `#2C5F7C` (light) / `#5B9EC9` (dark) - deep calming blue
        - Timer Active: `#7C6C5B` (light) / `#A89B8C` (dark) - warm grounding tone
        - Success Green: `#5A7C5F` (light) / `#7FA584` (dark) - subtle green
        - Use semantic system colors for backgrounds, text, and separators
        - All colors must pass WCAG AA contrast (4.5:1 minimum)

    - **Visual Style**:
        - Minimalist, calm, focused design philosophy
        - Primary buttons: Filled capsule with 50pt height minimum, 25pt corner radius
        - Timer dial: 12pt stroke for progress, 8pt background track
        - Cards: 16pt corner radius, 20pt padding, subtle shadow
        - Spacing system: 4pt/8pt/16pt/24pt/32pt/48pt for consistent layout
        - Animations: `.spring` for buttons, `.linear` for timer, `.easeInOut` for transitions

- Key Features and UserFlow
    **First Tab - Timer Flow**:
    - **Timer Setup Screen**:
        - Picker or segmented control for duration selection (default 15 min, range 5-120 min)
        - Presets: 5, 10, 15, 20, 30, 45, 60 minutes
        - Large "Start Meditation" button (full-width, primary style)
    - **Active Session Screen** (fullScreenCover, tabs hidden):
        - Large circular progress ring showing remaining time
        - Time remaining displayed in 72pt, thin, rounded font
        - Pause/Resume button (bottom-left)
        - "End Early" button (bottom-right, secondary style)
        - Screen wake-lock option (keep screen on during meditation)
        - **Background behavior**: Timer continues when app backgrounded, local notification fires on completion
        - **Sound**: Bell plays on completion, respects silent mode with optional override setting
        - **Haptic**: Success haptic feedback (`UINotificationFeedbackGenerator`) on completion
    - **Session Recap Screen** (presented as sheet):
        - "Session Complete" header
        - Duration meditated (actual time, may differ from planned if ended early)
        - Current streak (days in a row with mindful minutes)
        - Milestone celebrations for 7, 30, 100, 365-day streaks
        - "Done" button (top-right, dismisses sheet and returns to timer setup)
        - Session automatically saved to CoreData and synced to HealthKit (if enabled)

    **Second Tab - Stats & Settings**:
    - **Statistics Header**:
        - Today's minutes
        - This week's minutes
        - Current streak (days)
        - Total minutes (all-time)
        - Optional: Calendar heatmap or chart visualization
    - **Settings Sections**:
        - **Data Sync**:
            - "Sync to iCloud" toggle (with sync status indicator)
            - "Sync to Apple Health" toggle (with authorization status, deep link to Settings if denied)
        - **Sound & Haptics**:
            - Bell sound selection (picker with preview)
            - Haptic feedback toggle
            - "Override Silent Mode" toggle
        - **Session Defaults**:
            - Default timer duration
            - Auto-dim screen toggle
        - **Reminders** (optional):
            - Daily reminder toggle
            - Reminder time picker
        - **About**:
            - App version
            - Credits

    **Special States**:
    - **Empty state** (first launch): Encouraging message to start first session
    - **Onboarding** (first launch): Request HealthKit and notification permissions with context
    - **Error states**: Handle HealthKit sync failures, iCloud unavailable gracefully with retry options
    - **Permission denied**: Show clear status and provide deep link to Settings

    **Accessibility**:
    - Full VoiceOver support with clear labels for all controls
    - Timer announces progress periodically during meditation
    - Dynamic Type support (all text scales with system settings)
    - Reduce Motion support (static alternatives to animations)
    - High contrast mode support
    - All colors meet WCAG AA contrast ratio (4.5:1 minimum)
- Backend (CoreData Schema)
    - **MeditationSession Entity**:
        - `idSession` (UUID, primary key)
        - `durationPlanned` (Int16, minutes) - User's intended duration
        - `durationTotal` (Double, minutes) - Actual meditation time (may differ if ended early)
        - `durationElapsed` (Double, minutes) - Total elapsed time including pauses
        - `isSessionValid` (Bool) - True if session >= 15 seconds
        - `createdAt` (Date) - When session was started
        - `completedAt` (Date, optional) - When session ended
        - `wasPaused` (Bool) - Whether session was paused during meditation
        - `pauseCount` (Int16) - Number of times session was paused
        - `syncedToHealthKit` (Bool) - Whether successfully synced to HealthKit
        - `syncedToiCloud` (Bool) - Whether synced to iCloud (managed by CloudKit)
    - **UserPreferences** (UserDefaults/AppStorage):
        - `defaultDuration` (Int) - Default timer duration in minutes
        - `iCloudSyncEnabled` (Bool)
        - `healthKitSyncEnabled` (Bool)
        - `selectedBellSound` (String) - Bell sound identifier
        - `hapticFeedbackEnabled` (Bool)
        - `overrideSilentMode` (Bool)
        - `keepScreenAwake` (Bool)
        - `dailyReminderEnabled` (Bool, optional)
        - `dailyReminderTime` (Date, optional)
    - **Computed Data**:
        - Current streak: Calculated from sessions with consecutive days
        - Today's minutes: Sum of valid sessions from today
        - This week's minutes: Sum of valid sessions from current week
        - Total minutes: Sum of all valid sessions
- Constraints
    - It should be compatible with iOS 26.0 and above. Don't add dependencies outside the iOS SDK.

## Technical Implementation Guide

### SwiftUI Architecture Patterns

**State Management**:
```swift
// Use @Observable macro for ViewModels (iOS 17+)
@MainActor
@Observable
final class TimerViewModel {
    var selectedDuration: Int = 15
    var isSessionActive: Bool = false
    var remainingTime: TimeInterval = 0

    private let sessionManager: SessionManager
    private var timerTask: Task<Void, Never>?
}
```

**Navigation Patterns**:
- Main app: `TabView` with badge support for milestone notifications
- Active session: `.fullScreenCover(isPresented:)` to hide tabs during meditation
- Recap screen: `.sheet(isPresented:)` for dismissible post-session summary
- Settings: Standard `NavigationStack` for deep linking to system Settings

**Timer Implementation**:
```swift
// Use structured concurrency for timer
func startCountdown() {
    timerTask = Task { @MainActor in
        while remainingTime > 0 {
            try? await Task.sleep(for: .seconds(1))
            remainingTime -= 1

            if remainingTime == 0 {
                await handleCompletion()
            }
        }
    }
}

// Background continuation with BackgroundTask
func enableBackgroundMode() {
    let taskID = UIApplication.shared.beginBackgroundTask {
        // Handle expiration
    }
    // Schedule local notification for completion
}
```

**Progress Ring Animation**:
```swift
// Custom progress ring using Circle with trim
Circle()
    .trim(from: 0, to: progress)
    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .animation(.linear(duration: 1), value: progress)
```

**View Transitions**:
- Setup → Active: `.transition(.asymmetric(insertion: .scale, removal: .opacity))`
- Active → Recap: `.transition(.move(edge: .bottom).combined(with: .opacity))`
- Button taps: `.spring(response: 0.3, dampingFraction: 0.6)`

### Services Architecture

**HealthKit Service** (Actor for thread safety):
```swift
actor HealthKitService {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        // Request mindful session permission
    }

    func saveMindfulMinutes(duration: TimeInterval, start: Date) async throws {
        // Save HKCategorySample
    }
}
```

**Session Manager** (Actor for managing session lifecycle):
```swift
actor SessionManager {
    func startSession(duration: TimeInterval) -> MeditationSession
    func pauseSession()
    func resumeSession()
    func endSession() async throws
}
```

**Streak Calculator** (Value type for computation):
```swift
struct StreakCalculator {
    func calculateCurrentStreak(from sessions: [MeditationSession]) -> Int {
        // Algorithm: Find consecutive days with valid sessions
    }
}
```

### CoreData + CloudKit Setup

```swift
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    private init() {
        container = NSPersistentCloudKitContainer(name: "NoNonsenseMeditation")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve store description")
        }

        // Enable CloudKit sync
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourteam.NoNonsenseMeditation"
        )

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
```

### App Intents for Shortcuts

```swift
import AppIntents

struct StartMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Meditation"

    @Parameter(title: "Duration (minutes)", default: 15)
    var duration: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        // Access shared session manager
        await SessionManager.shared.startSession(duration: TimeInterval(duration * 60))
        return .result()
    }
}

struct MeditationAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMeditationIntent(),
            phrases: [
                "Start meditation in \(.applicationName)",
                "Meditate for \(\\.duration) minutes"
            ],
            shortTitle: "Meditate",
            systemImageName: "figure.mind.and.body"
        )
    }
}
```

### Performance Considerations

- Timer updates: 1Hz refresh rate (no need for 60fps countdown)
- View updates: Use `Equatable` conformance on models to minimize re-renders
- CoreData fetches: Use `@FetchRequest` with proper predicates and sorting
- Background tasks: Limit to essential timer continuation only
- Profile with Instruments to maintain smooth 60fps UI throughout

