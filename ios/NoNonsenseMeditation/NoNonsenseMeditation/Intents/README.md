# Siri App Intents Integration

This directory contains all App Intent implementations for Siri integration with No Nonsense Meditation.

## Overview

The app provides four primary Siri shortcuts for meditation session control:

1. **Start Meditation** - Begin a new meditation session with custom duration
2. **Pause Meditation** - Pause the current active session
3. **Resume Meditation** - Resume a paused session
4. **Stop Meditation** - End and save the current session

## Files

### Intent Implementations

- `StartMeditationIntent.swift` - Starts a meditation session with specified duration (1-120 minutes)
- `PauseMeditationIntent.swift` - Pauses the active meditation session
- `ResumeMeditationIntent.swift` - Resumes a paused meditation session
- `StopMeditationIntent.swift` - Stops and saves the active meditation session

### Supporting Files

- `MeditationAppShortcuts.swift` - Registers all app shortcuts with Siri phrases
- Shared `IntentError` enum (in StartMeditationIntent.swift) - Standardized error handling

## Siri Phrases

Users can invoke these intents using natural language:

### Start Meditation
- "Start meditation in No Nonsense Meditation"
- "Begin meditation with No Nonsense Meditation"
- "Meditate for 20 minutes in No Nonsense Meditation"
- "Start a 15 minute meditation in No Nonsense Meditation"

### Pause Meditation
- "Pause meditation in No Nonsense Meditation"
- "Pause my meditation"

### Resume Meditation
- "Resume meditation in No Nonsense Meditation"
- "Continue meditation in No Nonsense Meditation"
- "Resume my meditation"

### Stop Meditation
- "Stop meditation in No Nonsense Meditation"
- "End meditation in No Nonsense Meditation"
- "Finish my meditation"

## Architecture

### SessionManager Integration

All intents use `SessionManager.shared` (singleton) for session operations:

- Thread-safe with `@MainActor` isolation
- Async/await pattern for all operations
- Proper error handling with typed errors

### Error Handling

The `IntentError` enum provides comprehensive error handling:

- `invalidDuration` - Duration outside 1-120 minute range
- `noActiveSession` - No session active for pause/resume/stop operations
- `sessionOperationFailed` - Operation failed with detailed reason

All errors conform to `LocalizedError` for user-friendly messages.

### Duration Validation

Start meditation validates duration against app constants:
- Minimum: `Constants.Timer.minimumDuration` (1 minute)
- Maximum: `Constants.Timer.maximumDuration` (120 minutes)
- Default: 15 minutes

## Implementation Details

### StartMeditationIntent

**Parameters:**
- `duration: Int` - Meditation duration in minutes (default: 15, range: 1-120)

**Behavior:**
1. Validates duration against Constants.Timer constraints
2. Creates `TimerConfiguration` with specified duration
3. Calls `SessionManager.shared.startSession(configuration:)`
4. Returns success dialog: "Starting {duration}-minute meditation"

### PauseMeditationIntent

**Parameters:** None

**Behavior:**
1. Checks `SessionManager.shared.hasActiveSession`
2. Throws `noActiveSession` error if no session active
3. Calls `SessionManager.shared.pauseSession()`
4. Returns success dialog: "Meditation paused"

### ResumeMeditationIntent

**Parameters:** None

**Behavior:**
1. Checks `SessionManager.shared.hasActiveSession`
2. Throws `noActiveSession` error if no session active
3. Calls `SessionManager.shared.resumeSession()`
4. Returns success dialog: "Meditation resumed"

### StopMeditationIntent

**Parameters:** None

**Behavior:**
1. Checks `SessionManager.shared.hasActiveSession`
2. Throws `noActiveSession` error if no session active
3. Calls `try await SessionManager.shared.endSession()`
4. Catches and wraps errors in `sessionOperationFailed`
5. Returns success dialog: "Meditation session completed"

## Testing

### Manual Testing via Siri

1. Enable Siri shortcuts in Settings > Siri & Search
2. Use voice commands with the registered phrases
3. Verify proper session state transitions
4. Test error cases (e.g., pause without active session)

### Unit Testing

Test coverage should include:
- Duration validation (valid and invalid ranges)
- Session state checks (active/inactive)
- Error handling for all error cases
- SessionManager integration
- Dialog response verification

### Example Test Cases

```swift
// StartMeditationIntent
- Valid duration (15 minutes)
- Minimum duration (1 minute)
- Maximum duration (120 minutes)
- Below minimum (0 minutes) - should throw
- Above maximum (121 minutes) - should throw

// PauseMeditationIntent
- With active session - should succeed
- Without active session - should throw

// ResumeMeditationIntent
- With active session - should succeed
- Without active session - should throw

// StopMeditationIntent
- With active session - should succeed
- Without active session - should throw
- SessionManager.endSession() throws - should wrap error
```

## Requirements

- iOS 16.0+, macOS 13.0+, watchOS 9.0+
- AppIntents framework
- SessionManager singleton
- TimerConfiguration model
- Constants.Timer definitions

## Future Enhancements

Potential improvements:
- Query intents for session status
- Entity support for preset durations
- Shortcuts app integration
- Suggested shortcuts based on usage patterns
- Localization for multiple languages
