//
//  HealthKitViewModel.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import Observation
import UIKit

/// ViewModel for managing HealthKit authorization and integration
/// Uses @Observable macro for SwiftUI observation
@Observable
@MainActor
class HealthKitViewModel {

    // MARK: - Types

    /// UI-friendly authorization status
    enum AuthState: Equatable {
        case notDetermined
        case authorized
        case denied
        case notAvailable
        case requesting
        case error(String)

        var isAuthorized: Bool {
            if case .authorized = self {
                return true
            }
            return false
        }

        var canRequest: Bool {
            switch self {
            case .notDetermined, .denied:
                return true
            case .authorized, .notAvailable, .requesting, .error:
                return false
            }
        }
    }

    // MARK: - Properties

    /// Current authorization state
    private(set) var authState: AuthState = .notDetermined

    /// HealthKit service actor
    private let healthKitService: HealthKitService

    /// Session manager for syncing unsynced sessions
    private let sessionManager: SessionManager

    /// Flag to track if we should show HealthKit permission view
    private(set) var shouldShowPermissionView: Bool = false

    // MARK: - Initialization

    #if DEBUG
    /// For testing/preview purposes only - set the authorization state directly
    /// - Parameter state: The state to set
    func setAuthState(_ state: AuthState) {
        self.authState = state
    }
    #endif

    init(
        healthKitService: HealthKitService = HealthKitService(),
        sessionManager: SessionManager = SessionManager()
    ) {
        self.healthKitService = healthKitService
        self.sessionManager = sessionManager
    }

    // MARK: - Public Methods

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let status = await healthKitService.checkAuthorizationStatus()
        authState = mapAuthorizationStatus(status)

        // Show permission view if not determined or denied
        shouldShowPermissionView = authState.canRequest
    }

    /// Request HealthKit authorization
    func requestAuthorization() async {
        // Update state to requesting
        authState = .requesting

        do {
            try await healthKitService.requestAuthorization()

            // Check the actual status after request
            // Note: Due to HealthKit privacy, we may not know if user denied
            let status = await healthKitService.checkAuthorizationStatus()
            authState = mapAuthorizationStatus(status)

            // Hide permission view if authorized
            if authState.isAuthorized {
                shouldShowPermissionView = false

                // Sync all unsynced sessions to HealthKit in the background
                Task {
                    do {
                        try await sessionManager.syncAllUnsyncedSessions()
                    } catch {
                        // Log error but don't fail authorization flow
                        print("Failed to sync unsynced sessions: \(error.localizedDescription)")
                    }
                }
            }
        } catch let error as HealthKitService.HealthKitError {
            authState = .error(error.localizedDescription)
        } catch {
            authState = .error("An unexpected error occurred")
        }
    }

    /// Dismiss the permission view (user chose not to enable)
    func dismissPermissionView() {
        shouldShowPermissionView = false
    }

    /// Show permission view again
    func showPermissionView() {
        shouldShowPermissionView = true
    }

    /// Open iOS Settings app to allow user to enable HealthKit permissions
    func openSettings() {
        if let settingsURL = URL(string: "App-prefs:root=HEALTH") {
            // Try health-specific settings first
            Task {
                if await canOpenURL(settingsURL) {
                    await openURL(settingsURL)
                } else {
                    // Fallback to general settings
                    if let generalSettings = URL(string: UIApplication.openSettingsURLString) {
                        await openURL(generalSettings)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Map service authorization status to view model state
    private func mapAuthorizationStatus(_ status: HealthKitService.AuthorizationStatus) -> AuthState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notAvailable:
            return .notAvailable
        }
    }

    /// Check if URL can be opened (iOS compatibility wrapper)
    private func canOpenURL(_ url: URL) async -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    /// Open URL (iOS compatibility wrapper)
    private func openURL(_ url: URL) async {
        await UIApplication.shared.open(url)
    }
}
