# No Nonsense Meditation - TODO List

This document tracks fixes, features, and improvements to be implemented in separate git worktrees.


### Feature 1: CloudKit Sync
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

### Feature 2: Notification System
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

### Feature 3: Data Export/Import
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

### Feature 4: App Shortcuts Integration
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

### Feature 5: implement background sounds.
**Branch**: `feature/background-sounds`
**Priority**: Medium
**Estimate**: 2-3 hours

**Current Status**: Not started

**Tasks**:
- [ ] Make sure the media player UI shows on the lockscreen while a meditation is in progress.
- [ ] Make sure the pause/play button is visible in the lockscreen media player UI and that it controls the meditation timer
---

### Feature 6: Sync settings defaults with main app
**Branch**: `feature/sync-settings`
**Priority**: Medium
**Estimate**: 2-3 hours

**Current Status**: Not started

**Tasks**:
- [ ] Make sure the default duration from the settings is the one used in the main screen what the app is launched.

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
- [ ] Make sure the main UI elements are showing without scrolling in the first screen (make the meditation length field the actual scrollable element)
- [ ] Move the settings to a gear icon in the top right corner of the main screen and remove the tabs at the bottom. You go back to the main screen by licking a back button.

**Files Needed**:
- App icon asset
- Launch screen storyboard
- Empty state SVGs

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
