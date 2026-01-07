//
//  StartMeditationIntent.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import AppIntents
import Foundation

/// App Intent for starting a meditation session via Siri
/// Allows users to initiate a meditation session with custom duration
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
struct StartMeditationIntent: AppIntent {

    // MARK: - Intent Configuration

    static var title: LocalizedStringResource = "Start Meditation"
    static var description = IntentDescription("Start a meditation session with specified duration")
    static var opensIntent: Bool = true

    // MARK: - Parameters

    /// Meditation duration in minutes (1-120)
    @Parameter(
        title: "Duration",
        description: "Meditation duration in minutes",
        default: 15,
        controlStyle: .field,
        inclusiveRange: (1, 120)
    )
    var duration: Int

    // MARK: - Intent Execution

    /// Perform the intent to start a meditation session
    /// - Returns: Dialog result confirming session start
    /// - Throws: IntentError if validation fails
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate duration against app constants
        guard duration >= Constants.Timer.minimumDuration else {
            throw IntentError.invalidDuration(
                provided: duration,
                minimum: Constants.Timer.minimumDuration,
                maximum: Constants.Timer.maximumDuration
            )
        }

        guard duration <= Constants.Timer.maximumDuration else {
            throw IntentError.invalidDuration(
                provided: duration,
                minimum: Constants.Timer.minimumDuration,
                maximum: Constants.Timer.maximumDuration
            )
        }

        // Request app to start meditation with specified duration
        // The app will handle this when it opens (opensIntent = true)
        IntentCoordinator.shared.requestStartMeditation(durationMinutes: duration)

        // Return success dialog
        return .result(
            dialog: IntentDialog("Starting \(duration)-minute meditation")
        )
    }
}

// MARK: - Intent Error

/// Custom error type for App Intent failures
enum IntentError: LocalizedError {
    case invalidDuration(provided: Int, minimum: Int, maximum: Int)
    case noActiveSession
    case sessionOperationFailed(String)

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .invalidDuration(let provided, let minimum, let maximum):
            return "Invalid duration: \(provided) minutes. Duration must be between \(minimum) and \(maximum) minutes."

        case .noActiveSession:
            return "No active meditation session found. Please start a meditation session first."

        case .sessionOperationFailed(let reason):
            return "Session operation failed: \(reason)"
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidDuration(let provided, _, _):
            return "The provided duration of \(provided) minutes is outside the allowed range."

        case .noActiveSession:
            return "There is currently no meditation session in progress."

        case .sessionOperationFailed(let reason):
            return reason
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidDuration(_, let minimum, let maximum):
            return "Please choose a duration between \(minimum) and \(maximum) minutes."

        case .noActiveSession:
            return "Start a new meditation session before attempting to pause, resume, or stop."

        case .sessionOperationFailed:
            return "Try again or check the app for more details."
        }
    }
}
