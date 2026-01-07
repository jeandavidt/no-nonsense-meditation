//
//  ResumeMeditationIntent.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import AppIntents
import Foundation

/// App Intent for resuming a paused meditation session via Siri
/// Allows users to continue their paused meditation session
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
struct ResumeMeditationIntent: AppIntent {

    // MARK: - Intent Configuration

    static var title: LocalizedStringResource = "Resume Meditation"
    static var description = IntentDescription("Resume the paused meditation session")

    // MARK: - Intent Execution

    /// Perform the intent to resume the paused meditation session
    /// - Returns: Dialog result confirming session resumption
    /// - Throws: IntentError.noActiveSession if no session is active
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check for active session
        guard SessionManager.shared.hasActiveSession else {
            throw IntentError.noActiveSession
        }

        // Resume the session
        await SessionManager.shared.resumeSession()

        // Return success dialog
        return .result(
            dialog: IntentDialog("Meditation resumed")
        )
    }
}
