//
//  StopMeditationIntent.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import AppIntents
import Foundation

/// App Intent for stopping an active meditation session via Siri
/// Allows users to end their current meditation session and save the results
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
struct StopMeditationIntent: AppIntent {

    // MARK: - Intent Configuration

    static var title: LocalizedStringResource = "Stop Meditation"
    static var description = IntentDescription("Stop and complete the current meditation session")

    // MARK: - Intent Execution

    /// Perform the intent to stop the active meditation session
    /// - Returns: Dialog result confirming session completion
    /// - Throws: IntentError.noActiveSession if no session is active
    /// - Throws: IntentError.sessionOperationFailed if ending session fails
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check for active session
        guard SessionManager.shared.hasActiveSession else {
            throw IntentError.noActiveSession
        }

        // End the session
        do {
            try await SessionManager.shared.endSession()
        } catch {
            throw IntentError.sessionOperationFailed(error.localizedDescription)
        }

        // Return success dialog
        return .result(
            dialog: IntentDialog("Meditation session completed")
        )
    }
}
