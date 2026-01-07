//
//  IntentCoordinator.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-07.
//  Handles communication between App Intents and the main app UI
//

import Foundation
import Combine

/// Coordinates between App Intents and the main application
/// Allows intents to trigger UI actions when the app opens
@Observable
final class IntentCoordinator {

    // MARK: - Singleton

    static let shared = IntentCoordinator()

    // MARK: - Properties

    /// Pending intent action to execute when app becomes active
    private(set) var pendingAction: PendingIntentAction?

    // MARK: - Initialization

    private init() {}

    // MARK: - Intent Actions

    /// Request to start a meditation session with specified duration
    /// - Parameter durationMinutes: Duration in minutes
    func requestStartMeditation(durationMinutes: Int) {
        pendingAction = .startMeditation(durationMinutes: durationMinutes)
    }

    /// Request to pause the current meditation session
    func requestPauseMeditation() {
        pendingAction = .pauseMeditation
    }

    /// Request to resume the current meditation session
    func requestResumeMeditation() {
        pendingAction = .resumeMeditation
    }

    /// Request to stop the current meditation session
    func requestStopMeditation() {
        pendingAction = .stopMeditation
    }

    /// Clear the pending action after it has been executed
    func clearPendingAction() {
        pendingAction = nil
    }

    /// Check if there's a pending action of a specific type
    /// - Parameter actionType: The type of action to check for
    /// - Returns: True if there's a pending action of the specified type
    func hasPendingAction(ofType actionType: PendingIntentAction) -> Bool {
        guard let pending = pendingAction else { return false }

        switch (pending, actionType) {
        case (.startMeditation, .startMeditation):
            return true
        case (.pauseMeditation, .pauseMeditation):
            return true
        case (.resumeMeditation, .resumeMeditation):
            return true
        case (.stopMeditation, .stopMeditation):
            return true
        default:
            return false
        }
    }
}

// MARK: - Pending Intent Action

/// Represents an action that an App Intent wants the app to perform
enum PendingIntentAction: Equatable {
    case startMeditation(durationMinutes: Int)
    case pauseMeditation
    case resumeMeditation
    case stopMeditation
}
