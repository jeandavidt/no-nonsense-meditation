//
//  PauseMeditationIntent.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import AppIntents
import Foundation

/// App Intent for pausing an active meditation session via Siri
/// Allows users to pause their current meditation session
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
struct PauseMeditationIntent: AppIntent {

    // MARK: - Intent Configuration

    static var title: LocalizedStringResource = "Pause Meditation"
    static var description = IntentDescription("Pause the current meditation session")

    // MARK: - Intent Execution

    /// Perform the intent to pause the active meditation session
    /// - Returns: Dialog result confirming session pause
    /// - Throws: IntentError.noActiveSession if no session is active
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check for active session
        guard SessionManager.shared.hasActiveSession else {
            throw IntentError.noActiveSession
        }

        // Pause the session
        await SessionManager.shared.pauseSession()

        // Return success dialog
        return .result(
            dialog: IntentDialog("Meditation paused")
        )
    }
}
