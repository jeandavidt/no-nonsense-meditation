# CloudKit "Invalid Bundle ID" Diagnostic Guide

## Current Error
```
"Permission Failure" (10/2007); server message = "Invalid bundle ID for container"
Container ID: iCloud.com.jeandavidt.NoNonsenseMeditation
```

## What We Know
✅ CloudKit container exists: `iCloud.com.jeandavidt.NoNonsenseMeditation`
✅ Container is assigned to app (per your screenshot)
✅ Team ID set: `S65RLZRGD2`
✅ Bundle ID in code: `com.jeandavidt.NoNonsenseMeditation`
✅ Entitlements file has correct container
⚠️ **Issue**: App ID in Developer Portal may not be properly configured

## Step-by-Step Fix

### Step 1: Verify App ID Exists and Has CloudKit

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Click **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in sidebar
4. In the dropdown at top-right, select **App IDs**
5. Look for: `com.jeandavidt.NoNonsenseMeditation`

**If it DOESN'T exist:**
- Click **+** button
- Select **App IDs** → Continue
- Select **App** → Continue
- Fill in:
  - Description: `No Nonsense Meditation`
  - Bundle ID: `com.jeandavidt.NoNonsenseMeditation` (Explicit)
- Enable these capabilities:
  - ✅ HealthKit
  - ✅ iCloud (check "CloudKit")
  - ✅ Push Notifications
  - ✅ Background Modes
- Click **Continue** → **Register**

**If it DOES exist:**
- Click on it to open
- Verify these capabilities are enabled:
  - ✅ iCloud (with CloudKit checked)
  - ✅ HealthKit
  - ✅ Push Notifications
- If any are missing, click **Edit**:
  - Enable missing capabilities
  - For iCloud: Make sure **CloudKit** checkbox is checked
  - Click **Save**

### Step 2: Link CloudKit Container to App ID

Even if the container exists, it must be explicitly linked:

1. In Developer Portal → Identifiers → App IDs
2. Select `com.jeandavidt.NoNonsenseMeditation`
3. Find **iCloud** capability
4. Click **Configure** or **Edit** next to iCloud
5. In the CloudKit section:
   - Select container: `iCloud.com.jeandavidt.NoNonsenseMeditation`
   - ✅ Check "Include CloudKit support (requires Xcode 5)"
   - Make it the **default container** (checkbox or radio button)
6. Click **Save**
7. Click **Continue** at top if prompted
8. Click **Save** again to save the App ID

### Step 3: Verify Container in CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select: `iCloud.com.jeandavidt.NoNonsenseMeditation`
3. Select **Development** environment
4. Currently shows only "Users" record type - **this is normal**
5. CoreData types (like `CD_MeditationSession`) will appear automatically after first successful sync

### Step 4: Delete Provisioning Profiles (Force Regeneration)

1. In Xcode, close the project
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Delete provisioning profiles:
   ```bash
   rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
   ```
4. Reopen project in Xcode
5. Go to project settings → Signing & Capabilities
6. Verify:
   - Team: `Jean-David Therrien (S65RLZRGD2)` or similar
   - Automatically manage signing: ✅ Checked
   - Signing Certificate: Apple Development
7. Xcode will regenerate profiles automatically

### Step 5: Clean Build and Test

1. In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
2. Delete app from device
3. Build and run
4. Check console logs:
   - ✅ Should see: "Successfully loaded CloudKit store"
   - ❌ Should NOT see: "Invalid bundle ID for container"

### Step 6: Verify CloudKit Schema Created

After successfully running the app and completing a meditation:

1. Go to CloudKit Dashboard
2. Select container → Development → Data
3. You should now see:
   - `CD_MeditationSession` record type
   - Fields: `CD_idSession`, `CD_createdAt`, `CD_completedAt`, etc.
   - One or more records

## Common Issues and Solutions

### "App ID not found"
- **Cause**: App ID was never created in Developer Portal
- **Fix**: Complete Step 1 above

### "Container not linked to App ID"
- **Cause**: Container exists but not associated with App ID
- **Fix**: Complete Step 2 above

### "Still getting permission error after setup"
- **Cause**: Provisioning profile cached with old configuration
- **Fix**: Complete Step 4 above

### "Record types not appearing in CloudKit"
- **Cause**: App hasn't successfully synced yet (blocked by permission error)
- **Fix**: Once permission error is resolved, record types auto-create on first sync

## Why CoreData Entities Aren't Visible Yet

The CloudKit Dashboard currently shows only "Users" because:

1. **Permission error is blocking CoreData** from creating its schema
2. CoreData needs to successfully connect to CloudKit to create record types
3. Once the "Invalid bundle ID" error is fixed, CoreData will:
   - Automatically create `CD_MeditationSession` record type
   - Add all attributes as fields
   - Create necessary indexes
   - Sync your first records

**This is normal!** The record types will appear automatically once CloudKit sync works.

## Expected Result

After completing these steps, you should see:

**Console Logs:**
```
CoreData: CloudKit available - attempting CloudKit mode
CoreData: Successfully loaded persistent store
CoreData: Successfully loaded CloudKit store
✅ NO permission errors
```

**CloudKit Dashboard:**
```
Development Environment → Data:
  - CD_MeditationSession (record type)
    - Fields: CD_idSession, CD_createdAt, CD_completedAt, CD_durationTotal, etc.
  - 1+ records (your meditation sessions)
```

## Still Having Issues?

If you've completed all steps and still see the error:

1. **Check bundle ID match exactly**:
   - Xcode project: `com.jeandavidt.NoNonsenseMeditation`
   - Developer Portal App ID: `com.jeandavidt.NoNonsenseMeditation`
   - Entitlements: `iCloud.com.jeandavidt.NoNonsenseMeditation`

2. **Verify Team ID matches**:
   - Xcode Signing: `S65RLZRGD2`
   - Developer Portal: Same team

3. **Try TestFlight**:
   - Sometimes sandbox/development environment has quirks
   - Build → Archive → Distribute to TestFlight
   - Install from TestFlight and test

## Need More Help?

Provide these details:
- Screenshot of App ID configuration page showing capabilities
- Screenshot of CloudKit container assignment
- Console log output when app launches
- Whether App ID exists in Developer Portal (yes/no)
