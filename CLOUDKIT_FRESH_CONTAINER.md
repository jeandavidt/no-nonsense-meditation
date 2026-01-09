# Try Fresh CloudKit Container - Troubleshooting Guide

## Why Try This?

Even though your configuration looks correct, sometimes CloudKit containers can get into a bad state or have hidden configuration issues. Creating a brand new container can help isolate the problem.

## Option 1: Create New Container (Recommended for Testing)

### Step 1: Create New Container in Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → Filter by **CloudKit Containers**
4. Click **+** button
5. Create new container:
   - **Identifier**: `iCloud.com.jeandavidt.NoNonsenseMeditation2`
   - **Description**: `No Nonsense Meditation v2`
6. Click **Continue** → **Register**

### Step 2: Link New Container to App ID

1. Still in Developer Portal → **Identifiers** → Filter by **App IDs**
2. Select `com.jeandavidt.NoNonsenseMeditation`
3. Click **Edit** (or the app ID to expand it)
4. Find **iCloud** capability
5. Click **Configure** or **Edit**
6. In the containers list:
   - **Select**: `iCloud.com.jeandavidt.NoNonsenseMeditation2` (the new one)
   - **Make it default** (checkbox or radio button)
   - You can keep the old one selected too, but make the new one default
7. Click **Save**
8. Click **Continue** → **Save** again

### Step 3: Update Entitlements File

Update the entitlements to use the new container:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.jeandavidt.NoNonsenseMeditation2</string>
</array>
```

### Step 4: Update PersistenceController

The CloudKit container name is specified in PersistenceController.swift.

Look for where the container is initialized and update it to use the new identifier.

### Step 5: Clean and Test

1. Delete app from device
2. Clean build folder in Xcode
3. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Build and run
5. Check console - should NOT see "Invalid bundle ID" error

### Expected Result

If the new container works:
- ✅ No "Invalid bundle ID" error
- ✅ CloudKit sync succeeds
- ✅ `CD_MeditationSession` appears in CloudKit Dashboard after first meditation

## Option 2: Verify Built Entitlements (Diagnostic)

Check what entitlements actually got built into your app:

### Step 1: Build the App

1. Build the app in Xcode (don't run yet)
2. Note where the .app file is created

### Step 2: Extract and View Entitlements

In Terminal:

```bash
# Navigate to DerivedData (your path may vary)
cd ~/Library/Developer/Xcode/DerivedData/NoNonsenseMeditation-*/Build/Products/Debug-iphoneos/

# Extract entitlements from built app
codesign -d --entitlements :- NoNonsenseMeditation.app > entitlements.plist

# View the entitlements
cat entitlements.plist
```

### What to Check

The output should include:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.jeandavidt.NoNonsenseMeditation</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

If it doesn't match, there's a provisioning profile problem.

## Option 3: Manual Signing (Advanced)

If automatic signing keeps causing issues:

### In Xcode:

1. Project Settings → Signing & Capabilities
2. **Uncheck** "Automatically manage signing"
3. Manually select:
   - **Provisioning Profile**: iOS Team Provisioning Profile (or similar)
   - **Team**: Jean-David Therrien (S65RLZRGD2)
4. Xcode will show any errors with the selected profile
5. If profile is invalid, click **Download** or **Create** new one

## Option 4: TestFlight (Skip Development Issues)

Sometimes development provisioning has quirks. Try TestFlight:

1. Archive the app: Product → Archive
2. Distribute → TestFlight Internal Testing
3. Wait for processing (10-15 minutes)
4. Install from TestFlight
5. Test CloudKit functionality

TestFlight uses production provisioning which sometimes works when development doesn't.

## Still Not Working?

If even a fresh container fails with the same error, it suggests:

1. **Apple ID / Team Issue**:
   - The Apple ID signed into the device might not match the team
   - Try: Settings → [Your Name] → Sign Out → Sign back in with correct Apple ID

2. **iCloud Account Issue**:
   - Device needs to be signed into iCloud
   - iCloud Drive must be enabled
   - Try: Settings → [Your Name] → iCloud → iCloud Drive (ON)

3. **Development vs Production**:
   - Development builds use iCloud sandbox
   - Make sure you're signed into iCloud on the device

4. **Regional or Beta Issues**:
   - Some beta versions of iOS have CloudKit bugs
   - Some regions have CloudKit restrictions
   - Check iOS version and region settings

## Quick Debug Checklist

Run through this checklist:

- [ ] Device signed into iCloud with correct Apple ID
- [ ] iCloud Drive enabled on device
- [ ] App ID exists with iCloud + CloudKit enabled
- [ ] CloudKit container exists and belongs to correct team
- [ ] Container is linked to App ID and marked as default
- [ ] Bundle ID matches exactly everywhere
- [ ] Team ID matches (S65RLZRGD2)
- [ ] Provisioning profiles deleted and regenerated
- [ ] App deleted from device before fresh install
- [ ] Using iOS 17.0+ (CloudKit requirement met)

## Contact Apple Support

If everything is configured correctly and it still doesn't work, this might be an issue on Apple's end:

1. File a bug report: https://feedbackassistant.apple.com
2. Contact Developer Support through your Developer Program membership
3. Provide:
   - Bundle ID: com.jeandavidt.NoNonsenseMeditation
   - Container ID: iCloud.com.jeandavidt.NoNonsenseMeditation
   - Team ID: S65RLZRGD2
   - Error message screenshot
   - Console logs
