# No Nonsense Meditation - TODO List

This document tracks fixes, features, and improvements to be implemented in separate git worktrees.

**Last Updated**: 2026-01-05
**Current Status**: Build successful, Timer UI complete, Settings UI complete

**Project Structure**:
- Xcode project: `ios/NoNonsenseMeditation.xcodeproj`
- Source files: `ios/NoNonsenseMeditation/NoNonsenseMeditation/`
- Build command: `cd ios && xcodebuild -scheme NoNonsenseMeditation -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`

---

## 🔴 Critical Fixes

### Fix 1: Swift Concurrency Warnings
**Branch**: `fix/concurrency-warnings`
**Priority**: High
**Estimate**: 1-2 hours

**Issues**:
- Multiple data race warnings in TimerViewModel
- Non-Sendable types being passed between actors
- PersistenceController has non-concurrency-safe static properties
- View+Extensions uses deprecated NavigationLink initializer

**Files to Fix**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/ViewModels/TimerViewModel.swift`
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Persistence/PersistenceController.swift`
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Utilities/Extensions/View+Extensions.swift`

**Acceptance Criteria**:
- [ ] Zero concurrency warnings in build
- [ ] All actor isolation issues resolved
- [ ] Proper @MainActor annotations where needed
- [ ] Replace deprecated NavigationLink with modern API

---

### Fix 2: MeditationStatistics Model Missing
**Branch**: `fix/missing-meditation-statistics`
**Priority**: High
**Estimate**: 30 minutes

**Issues**:
- SettingsViewModel references `MeditationStatistics` type
- File exists but not tracked: `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Models/MeditationStatistics.swift`

**Tasks**:
- [ ] Add MeditationStatistics.swift to git
- [ ] Verify it matches SettingsViewModel usage
- [ ] Add unit tests for MeditationStatistics

---

### Fix 3: Missing Audio Assets
**Branch**: `fix/audio-assets`
**Priority**: Medium
**Estimate**: 1 hour

**Issues**:
- AudioService references sound files that don't exist
- Required: meditation_start.wav, meditation_pause.wav, meditation_resume.wav, meditation_completion.wav

**Tasks**:
- [ ] Source or create meditation bell sounds
- [ ] Add to Assets.xcassets or Resources folder
- [ ] Test audio playback on device
- [ ] Ensure silent mode override works correctly

---

### Fix 4: Redundant UI elements
**Branch**: `fix/redundant-ui`
**Priority**: High
**Estimate**: 10 min

**Issues**:
- Superfluous UI elements need to be removed:
    - Advanced settings
    - Quick-Select
    - Back to home button

**Tasks**:
    - Remove Advanced settings
    - Remove Quick-Select
    - Remove Back to home button
---

## ✨ Feature Implementation

### Feature 1: HealthKit Integration Complete
**Branch**: `feature/healthkit-integration`
**Priority**: High
**Estimate**: 3-4 hours

**Current Status**: UI exists, service partially implemented

**Tasks**:
- [ ] Complete HealthKitService implementation
- [ ] Test authorization flow on physical device
- [ ] Implement mindful minutes sync after session
- [ ] Handle authorization denied gracefully
- [ ] Add deep link to Settings app
- [ ] Write integration tests

**Files**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Services/HealthKitService.swift`
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/ViewModels/HealthKitViewModel.swift`
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Features/Settings/Views/HealthKitPermissionView.swift`

---

### Feature 2: CloudKit Sync Implementation
**Branch**: `feature/cloudkit-sync`
**Priority**: Medium
**Estimate**: 4-6 hours

**Current Status**: CloudKitSyncManager stub exists

**Tasks**:
- [ ] Implement CloudKitSyncManager.sync()
- [ ] Handle merge conflicts
- [ ] Test sync across multiple devices
- [ ] Add sync status UI indicator
- [ ] Handle offline scenarios
- [ ] Write integration tests

**Files**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Persistence/CloudKitSyncManager.swift`

---

### Feature 3: Notification System
**Branch**: `feature/notifications`
**Priority**: Medium
**Estimate**: 2-3 hours

**Current Status**: NotificationService exists, needs implementation

**Tasks**:
- [ ] Implement daily reminder scheduling
- [ ] Request notification permissions
- [ ] Handle permission denial
- [ ] Test notification delivery
- [ ] Add notification actions (Quick Start)
- [ ] Write unit tests

**Files**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Services/NotificationService.swift`

---

### Feature 4: Data Export/Import
**Branch**: `feature/data-export-import`
**Priority**: Low
**Estimate**: 2-3 hours

**Current Status**: Export UI exists in SettingsTabView

**Tasks**:
- [ ] Implement SettingsViewModel.exportData()
- [ ] Create JSON export format
- [ ] Add import functionality
- [ ] Handle large datasets efficiently
- [ ] Add CSV export option
- [ ] Write tests for export/import

**Files**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/ViewModels/SettingsViewModel.swift`

---

### Feature 5: App Shortcuts Integration
**Branch**: `feature/app-shortcuts`
**Priority**: Low
**Estimate**: 2-3 hours

**Current Status**: Not started

**Tasks**:
- [ ] Create App Intent for quick meditation start
- [ ] Add Siri suggestions
- [ ] Implement widget for quick access
- [ ] Test on iOS 17+
- [ ] Add Focus Filter support

**New Files**:
- `ios/NoNonsenseMeditation/NoNonsenseMeditation/Core/Intents/StartMeditationIntent.swift`
- `ios/NoNonsenseMeditationWidget/` (new target)

---

### Feature 6: implement background sounds.
**Branch**: `feature/background-sounds`
**Priority**: Medium
**Estimate**: 2-3 hours

**Current Status**: Not started

**Tasks**:
- [ ] add the background sound assets to the project (see ./background-sounds)
- [ ] create a sound picker in the setup screen.
- [ ] implement sound preview playback upon tapping.
- [ ] implement sound playback during meditation (looping)

---

## 🧪 Testing & Quality

### Test 1: Increase Test Coverage
**Branch**: `test/improve-coverage`
**Priority**: High
**Estimate**: 4-6 hours

**Current Status**: 25% coverage (target: >70%)

**Tasks**:
- [ ] Write tests for all ViewModels
- [ ] Add UI tests for complete meditation flow
- [ ] Test pause/resume functionality
- [ ] Test data persistence
- [ ] Test streak calculation edge cases
- [ ] Add snapshot tests for UI components

**Target Coverage**: 70%+

---

### Test 2: Performance Testing
**Branch**: `test/performance`
**Priority**: Medium
**Estimate**: 2-3 hours

**Tasks**:
- [ ] Profile app launch time (target: <2s)
- [ ] Test UI at 60fps
- [ ] Memory leak detection
- [ ] Battery usage profiling
- [ ] Test with 1000+ sessions
- [ ] Optimize CoreData queries

**Acceptance Criteria**:
- [ ] Launch time <2s
- [ ] 60fps UI scrolling
- [ ] No memory leaks
- [ ] <5% battery drain per hour

---

## 🎨 UI/UX Improvements

### UI 1: Accessibility Compliance
**Branch**: `ui/accessibility`
**Priority**: High
**Estimate**: 3-4 hours

**Tasks**:
- [ ] VoiceOver support for all screens
- [ ] Dynamic Type support
- [ ] WCAG AA contrast compliance
- [ ] Reduce Motion support
- [ ] Test with Accessibility Inspector
- [ ] Add accessibility labels/hints

**Acceptance Criteria**:
- [ ] Full VoiceOver navigation
- [ ] 4.5:1 contrast ratio minimum
- [ ] All text scales properly
- [ ] Animations respect Reduce Motion

---

### UI 2: Visual Polish
**Branch**: `ui/visual-polish`
**Priority**: Medium
**Estimate**: 2-3 hours

**Tasks**:
- [ ] Add app icon (1024x1024)
- [ ] Create launch screen
- [ ] Refine color scheme
- [ ] Add haptic feedback
- [ ] Polish animations
- [ ] Add empty state illustrations

**Files Needed**:
- App icon asset
- Launch screen storyboard
- Empty state SVGs

---

### UI 3: iPad Support
**Branch**: `ui/ipad-support`
**Priority**: Low
**Estimate**: 2-3 hours

**Tasks**:
- [ ] Optimize layouts for iPad
- [ ] Test in split view
- [ ] Add landscape support
- [ ] Keyboard navigation
- [ ] Multi-window support

---

## 📱 Device Testing

### Device 1: Physical Device Testing
**Branch**: `test/device-testing`
**Priority**: High
**Estimate**: 2-3 hours

**Devices to Test**:
- [ ] iPhone 17 Pro (iOS 26.2)

**Test Scenarios**:
- [ ] Complete meditation flow
- [ ] Background timer continuation
- [ ] Notification delivery
- [ ] HealthKit sync
- [ ] Low battery scenarios
- [ ] Poor network conditions

---

## 🔧 Technical Debt

### Tech 1: Remove Unused Code
**Branch**: `refactor/cleanup-unused`
**Priority**: Low
**Estimate**: 1 hour

**Tasks**:
- [ ] Remove commented-out code
- [ ] Delete unused imports
- [ ] Remove debug print statements
- [ ] Clean up TODOs in code

---


### Tech 3: Documentation
**Branch**: `docs/comprehensive-docs`
**Priority**: Low
**Estimate**: 2-3 hours

**Tasks**:
- [ ] Add DocC documentation
- [ ] Document all public APIs
- [ ] Create architecture diagram
- [ ] Write contributor guide
- [ ] Add inline code comments

---

## 📊 Analytics & Monitoring

### Analytics 1: App Analytics
**Branch**: `feature/analytics`
**Priority**: Low
**Estimate**: 2-3 hours

**Tasks**:
- [ ] Add basic analytics (privacy-friendly)
- [ ] Track meditation completion rate
- [ ] Monitor crash reports
- [ ] Add performance metrics
- [ ] Respect user privacy preferences

**Note**: Use Apple's built-in analytics only, no third-party tracking

---

## 🚀 Release Preparation

### Release 1: App Store Prep
**Branch**: `release/v1.0`
**Priority**: Future
**Estimate**: 4-6 hours

**Tasks**:
- [ ] Create App Store screenshots
- [ ] Write App Store description
- [ ] Prepare privacy policy
- [ ] Set up App Store Connect
- [ ] Create promotional materials
- [ ] Submit for review

---

## Work Queue Priority

**Immediate (This Week)**:
1. Fix/concurrency-warnings
2. Fix/missing-meditation-statistics
3. Feature/healthkit-integration
4. Test/improve-coverage

**Short Term (Next Week)**:
5. Fix/audio-assets
6. Feature/notifications
7. UI/accessibility
8. Test/device-testing

**Medium Term (This Month)**:
9. Feature/cloudkit-sync
10. UI/visual-polish
11. Test/performance
12. Feature/data-export-import

**Long Term (Future)**:
13. Feature/app-shortcuts
14. UI/ipad-support
15. Tooling/swiftlint
16. Docs/comprehensive-docs

---

## Worktree Setup Commands

```bash
# Create worktree for a fix
git worktree add ../no-nonsense-meditation-fix-concurrency fix/concurrency-warnings

# Create worktree for a feature
git worktree add ../no-nonsense-meditation-healthkit feature/healthkit-integration

# List all worktrees
git worktree list

# Remove completed worktree
git worktree remove ../no-nonsense-meditation-fix-concurrency
```

---

## Notes

- Each branch should be focused on a single task
- Write tests before merging to main
- Update PROGRESS.md after completing each task
- Run full test suite before merging
- Ensure build succeeds with zero warnings
- Get code review for significant changes

