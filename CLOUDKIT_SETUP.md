# CloudKit Setup Guide

## Current Error

```
"Permission Failure" (10/2007); server message = "Invalid bundle ID for container"
Container ID: iCloud.com.jeandavidt.NoNonsenseMeditation
```

This error indicates that the CloudKit container needs to be configured in the **Apple Developer Portal**.

## What's Already Configured (Code)

✅ **Entitlements** (`NoNonsenseMeditation.entitlements`):
- HealthKit: Enabled
- CloudKit container: `iCloud.com.jeandavidt.NoNonsenseMeditation`
- iCloud services: CloudKit
- iCloud KV storage: Enabled
- App Groups: `group.com.jeandavidt.NoNonsenseMeditation`

✅ **CoreData Model**:
- `idSession` attribute: Optional (CloudKit-compatible)
- Unique constraints: Removed (CloudKit doesn't support them)

✅ **Background Modes**:
- Configured in `project.yml`: `fetch remote-notification`

## Required Setup in Apple Developer Portal

### Step 1: Create CloudKit Container

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** from the sidebar
4. Click the **+** button to add a new identifier
5. Select **App IDs** → **Continue**
6. Choose **App** → **Continue**
7. Configure:
   - **Description**: No Nonsense Meditation
   - **Bundle ID**: `com.jeandavidt.NoNonsenseMeditation` (Explicit)
8. Under **Capabilities**, enable:
   - ✅ **HealthKit**
   - ✅ **iCloud** (check "CloudKit" option)
   - ✅ **Push Notifications** (for CloudKit sync)
   - ✅ **Background Modes** (for remote notifications)
9. Click **Continue** → **Register**

### Step 2: Create/Verify CloudKit Container

1. In Developer Portal, go to **Identifiers**
2. Filter by **CloudKit Containers** (dropdown at top right)
3. Check if `iCloud.com.jeandavidt.NoNonsenseMeditation` exists
4. If not, click **+** to create it:
   - **Identifier**: `iCloud.com.jeandavidt.NoNonsenseMeditation`
   - **Description**: No Nonsense Meditation CloudKit Container
5. Click **Continue** → **Register**

### Step 3: Associate Container with App ID

1. Go back to **Identifiers** → Filter by **App IDs**
2. Select `com.jeandavidt.NoNonsenseMeditation`
3. Click **Edit** or **Configure**
4. Under **iCloud** capability:
   - Ensure **CloudKit** is checked
   - Click **Edit** next to CloudKit
   - Select the container: `iCloud.com.jeandavidt.NoNonsenseMeditation`
   - Make it the **default container** (check the box)
5. Click **Save**

### Step 4: Regenerate Provisioning Profiles

1. Go to **Profiles** in Developer Portal
2. Delete old provisioning profiles for this app
3. In Xcode:
   - Open project settings
   - Select target → **Signing & Capabilities**
   - Enable **Automatically manage signing**
   - Select your **Team**
   - Xcode will regenerate profiles with new capabilities

### Step 5: CloudKit Dashboard Configuration

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.jeandavidt.NoNonsenseMeditation`
3. For Development environment:
   - Record types should be auto-created by CoreData
   - Verify `CD_MeditationSession` type exists after first sync
4. For Production:
   - Deploy schema from Development when ready

## Testing CloudKit

After completing the setup:

1. **Delete the app** from your device
2. **Rebuild and reinstall** the app
3. Check console logs:
   ```
   ✅ CoreData: Successfully loaded CloudKit store
   ❌ Should NOT see: "Invalid bundle ID for container"
   ```
4. Complete a meditation session
5. Verify in CloudKit Dashboard:
   - Go to Data → Development
   - Check for `CD_MeditationSession` records

## Common Issues

### "Invalid bundle ID for container"
- **Cause**: Container not created or not associated with app ID
- **Fix**: Complete Steps 2 & 3 above

### "Account not found"
- **Cause**: Not signed into iCloud on device
- **Fix**: Settings → [Your Name] → Sign in to iCloud

### "Network unavailable"
- **Cause**: No internet connection or iCloud Drive disabled
- **Fix**: Enable iCloud Drive in Settings → [Your Name] → iCloud

### "Operation not permitted"
- **Cause**: App ID doesn't have iCloud capability
- **Fix**: Complete Step 1, regenerate profiles (Step 4)

## Background Modes Warning

The warning about `remote-notification` background mode is informational:
```
BUG IN CLIENT OF CLOUDKIT: CloudKit push notifications require the 'remote-notification' background mode in your info plist.
```

This is already configured in `project.yml`:
```yaml
INFOPLIST_KEY_UIBackgroundModes: "fetch remote-notification"
```

The warning may persist but CloudKit will still work. To verify it's configured:
1. Build the app
2. Check the generated Info.plist in build products
3. Look for `UIBackgroundModes` array containing `remote-notification`

## Development vs Production

- **Development**: Use your personal iCloud account for testing
- **Production**: Requires deploying CloudKit schema from Development environment
- **Note**: Production schema changes require review/approval from Apple

## Data Privacy

- CloudKit stores data in user's personal iCloud account
- Each user only sees their own meditation sessions
- No server-side code needed - Apple manages infrastructure
- Data automatically syncs across user's devices

## Troubleshooting Commands

Check CloudKit status in Xcode console:
```
po NSPersistentCloudKitContainer.canModifyManagedObjectModel(forStoreAt: storeURL)
```

Reset CloudKit Development Environment (if needed):
1. CloudKit Dashboard → Data → Development
2. Click gear icon → Reset Development Environment
3. **WARNING**: This deletes all development data!
