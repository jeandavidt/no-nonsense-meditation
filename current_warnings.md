Swift Warning Fixes - No Nonsense Meditation iOS App

 Overview

 Fix all warnings and code quality issues found in the iOS meditation app codebase.

 Total Changes:
 - 1 deprecated API fix (HIGH priority)
 - 36 print() statements to migrate to AppLogger (MEDIUM priority)
 - 1 duplicate comment removal (LOW priority)

 Risk Level: LOW - All changes are non-breaking

 ---
 Critical Files to Modify

 1. ios/NoNonsenseMeditation/NoNonsenseMeditation/Features/Timer/ActiveMeditationView.swift
 2. ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Services/HealthKitService.swift
 3. ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Services/SessionManager.swift
 4. ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Persistence/PersistenceController.swift
 5. ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/ViewModels/TimerViewModel.swift

 ---
 Phase 1: Fix Deprecated API (HIGH PRIORITY)

 File: ActiveMeditationView.swift

 Line 85 - Replace deprecated modifier:

 // OLD (deprecated in iOS 14+)
 .edgesIgnoringSafeArea(.all)

 // NEW
 .ignoresSafeArea(.all)

 Testing: Verify background gradient extends to screen edges on iPhone with notch.

 ---
 Phase 2: Migrate to Structured Logging (MEDIUM PRIORITY)

 Pattern Guide

 Replace print() with AppLogger:

 // OLD
 print("[HealthKit] Successfully saved...")

 // NEW
 AppLogger.healthKit.info("Successfully saved...")

 // For errors with context:
 AppLogger.error(.healthKit, "Failed to save", error: error)

 File: HealthKitService.swift (12 replacements)
 Line: 151
 Old Code: print("[HealthKit] HealthKit not available...")
 New Code: AppLogger.healthKit.info("HealthKit not available on this device")
 ────────────────────────────────────────
 Line: 157
 Old Code: print("[HealthKit] Authorization status: \(status)")
 New Code: AppLogger.healthKit.debug("Authorization status: \(status)")
 ────────────────────────────────────────
 Line: 159
 Old Code: print("[HealthKit] Sync blocked...")
 New Code: AppLogger.healthKit.warning("Sync blocked - authorization status: \(status)")
 ────────────────────────────────────────
 Line: 175
 Old Code: print("[HealthKit] Successfully saved...")
 New Code: AppLogger.healthKit.info("Successfully saved mindful session: \(startDate) to \(endDate) (duration: \(String(format: "%.1f", duration)) minutes)")
 ────────────────────────────────────────
 Line: 177
 Old Code: print("[HealthKit] Failed to save sample: \(error)")
 New Code: AppLogger.error(.healthKit, "Failed to save sample", error: error)
 ────────────────────────────────────────
 Line: 178
 Old Code: print("[HealthKit] Current authorization status...")
 New Code: AppLogger.healthKit.debug("Current authorization status: \(checkAuthorizationStatus())")
 ────────────────────────────────────────
 Line: 190
 Old Code: print("[HealthKit] HealthKit not available...")
 New Code: AppLogger.healthKit.info("HealthKit not available on this device")
 ────────────────────────────────────────
 Line: 196
 Old Code: print("[HealthKit] Batch save authorization...")
 New Code: AppLogger.healthKit.debug("Batch save authorization status: \(status)")
 ────────────────────────────────────────
 Line: 198
 Old Code: print("[HealthKit] Batch sync blocked...")
 New Code: AppLogger.healthKit.warning("Batch sync blocked - authorization status: \(status)")
 ────────────────────────────────────────
 Line: 215
 Old Code: print("[HealthKit] Successfully batch saved...")
 New Code: AppLogger.healthKit.info("Successfully batch saved \(samples.count) mindful session(s)")
 ────────────────────────────────────────
 Line: 217
 Old Code: print("[HealthKit] Failed to batch save...")
 New Code: AppLogger.error(.healthKit, "Failed to batch save samples", error: error)
 ────────────────────────────────────────
 Line: 218
 Old Code: print("[HealthKit] Current authorization...")
 New Code: AppLogger.healthKit.debug("Current authorization status: \(checkAuthorizationStatus())")
 File: SessionManager.swift (7 replacements)
 ┌──────┬────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │ Line │                        Old Code                        │                                                  New Code                                                  │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 231  │ print("[SessionManager] Saved cancelled session...")   │ AppLogger.persistence.info("Saved cancelled session as INVALID")                                           │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 249  │ print("[SessionManager] Skipping HealthKit sync...")   │ AppLogger.healthKit.debug("Skipping HealthKit sync - authorization status: \(authStatus)")                 │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 256  │ print("[SessionManager] Skipping HealthKit sync...")   │ AppLogger.healthKit.warning("Skipping HealthKit sync - missing session dates")                             │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 270  │ print("[SessionManager] Successfully synced...")       │ AppLogger.healthKit.info("Successfully synced session to HealthKit and marked as synced")                  │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 273  │ print("[SessionManager] Failed to sync...")            │ AppLogger.error(.healthKit, "Failed to sync session \(session.objectID) to HealthKit", error: error)       │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 309  │ print("[SessionManager] Batch syncing...")             │ AppLogger.healthKit.info("Batch syncing \(sessionData.count) unsynced session(s) to HealthKit")            │
 ├──────┼────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
 │ 317  │ print("[SessionManager] Successfully batch synced...") │ AppLogger.healthKit.info("Successfully batch synced and marked \(sessionData.count) session(s) as synced") │
 └──────┴────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 File: PersistenceController.swift (17 replacements)
 Line: 204
 Old Code: print("CloudKit: Error checking account...")
 New Code: AppLogger.error(.cloudKit, "Error checking account status", error: error)
 ────────────────────────────────────────
 Line: 249
 Old Code: print("CoreData: Failed to load...")
 New Code: AppLogger.error(.persistence, "Failed to load persistent store\nStore: \(storeDescription)\nError: \(error)\nUserInfo: \(error.userInfo)", error: error)
 ────────────────────────────────────────
 Line: 255
 Old Code: print("CoreData: Successfully loaded...")
 New Code: AppLogger.persistence.info("Successfully loaded persistent store")
 ────────────────────────────────────────
 Line: 257
 Old Code: print("CloudKit: Container identifier...")
 New Code: AppLogger.cloudKit.debug("Container identifier - \(cloudKitOptions.containerIdentifier)")
 ────────────────────────────────────────
 Line: 306
 Old Code: print("CoreData: Running on simulator...")
 New Code: AppLogger.persistence.info("Running on simulator - using local-only mode")
 ────────────────────────────────────────
 Line: 324
 Old Code: print("CoreData: User disabled iCloud sync...")
 New Code: AppLogger.cloudKit.info("User disabled iCloud sync - using local-only mode")
 ────────────────────────────────────────
 Line: 331
 Old Code: print("CoreData: CloudKit available...")
 New Code: AppLogger.cloudKit.info("CloudKit available - attempting CloudKit mode")
 ────────────────────────────────────────
 Line: 335
 Old Code: print("CoreData: Successfully loaded...")
 New Code: AppLogger.cloudKit.info("Successfully loaded CloudKit store")
 ────────────────────────────────────────
 Line: 341
 Old Code: print("CoreData: CloudKit store failed...")
 New Code: AppLogger.cloudKit.warning("CloudKit store failed - falling back to local-only")
 ────────────────────────────────────────
 Line: 344
 Old Code: print("CoreData: CloudKit unavailable...")
 New Code: AppLogger.cloudKit.warning("CloudKit unavailable (\(cloudKitReason ?? "unknown")) - using local-only mode")
 ────────────────────────────────────────
 Line: 352
 Old Code: print("CoreData: Successfully loaded local...")
 New Code: AppLogger.persistence.info("Successfully loaded local-only store")
 ────────────────────────────────────────
 Line: 358
 Old Code: print("CoreData: Local store failed...")
 New Code: AppLogger.persistence.warning("Local store failed - falling back to in-memory")
 ────────────────────────────────────────
 Line: 361
 Old Code: print("CoreData: WARNING - Using in-memory...")
 New Code: AppLogger.persistence.warning("Using in-memory store, data will not persist")
 ────────────────────────────────────────
 Line: 450
 Old Code: print("CoreData: Successfully saved view context")
 New Code: AppLogger.persistence.debug("Successfully saved view context")
 ────────────────────────────────────────
 Line: 453
 Old Code: print("CoreData: Failed to save view context...")
 New Code: AppLogger.error(.persistence, "Failed to save view context", error: error)
 ────────────────────────────────────────
 Line: 467
 Old Code: print("CoreData: Successfully saved background...")
 New Code: AppLogger.persistence.debug("Successfully saved background context")
 ────────────────────────────────────────
 Line: 471
 Old Code: print("CoreData: Failed to save background...")
 New Code: AppLogger.error(.persistence, "Failed to save background context", error: error)
 ---
 Phase 3: Code Cleanup (LOW PRIORITY)

 File: TimerViewModel.swift

 Line 382-383 - Remove duplicate comment:

 // OLD (duplicate)
 /// Format time interval as MM:SS string
 /// Format time interval as MM:SS string (handles negative for overtime)

 // NEW (keep only descriptive one)
 /// Format time interval as MM:SS string (handles negative for overtime)

 ---
 Implementation Order

 1. Phase 1 (High Priority) - Fix deprecated API
   - Single line change, immediate benefit
   - Commit: fix(ui): Replace deprecated edgesIgnoringSafeArea with ignoresSafeArea
 2. Phase 2 (Medium Priority) - Migrate logging
   - Do files one at a time: HealthKitService → SessionManager → PersistenceController
   - Test after each file
   - Commit per file: refactor(logging): Migrate HealthKitService to AppLogger
 3. Phase 3 (Low Priority) - Code cleanup
   - Remove duplicate comment
   - Commit: chore(cleanup): Remove duplicate comment in TimerViewModel

 ---
 Verification Strategy

 Build Verification

 1. Build project in Xcode
 2. Verify zero deprecation warnings
 3. Ensure no compilation errors

 Runtime Testing

 1. Enable OSLog in Console.app
 2. Filter by subsystem: com.jeandavidt.NoNonsenseMeditation
 3. Test critical flows:
   - HealthKit authorization (granted/denied)
   - Session lifecycle (start/pause/resume/complete)
   - CloudKit sync (available/unavailable)
   - Persistence mode fallbacks

 Visual Testing

 - Test ActiveMeditationView on iPhone with notch
 - Verify background gradient extends to edges properly

 ---
 Expected Outcomes

 ✅ Zero deprecation warnings
 ✅ Consistent structured logging throughout codebase
 ✅ Better debugging with Console.app filtering
 ✅ Production-ready code for App Store
 ✅ Cleaner build output
 ✅ No behavioral changes (only observability improvement)

 ---
 Notes

 - AppLogger is already implemented and concurrency-safe (enum-based, uses OSLog)
 - All changes are non-breaking
 - No data model or persistence changes
 - Easy to rollback (atomic commits per phase)
 - Target: iOS 17.0+, Swift 5.0, SWIFT_STRICT_CONCURRENCY: complete