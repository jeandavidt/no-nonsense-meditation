//
//  CloudKitSyncManager.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import CoreData
import CloudKit

/// Manager for monitoring and handling CloudKit sync status
/// Provides sync state monitoring and error handling for iCloud sync
final class CloudKitSyncManager: ObservableObject {

    // MARK: - Types

    /// CloudKit sync status
    enum SyncStatus: Sendable {
        case idle
        case inProgress
        case succeeded
        case failed(Error)
    }

    // MARK: - Properties

    /// Current sync status
    @Published private(set) var syncStatus: SyncStatus = .idle

    /// Whether CloudKit is available
    @Published private(set) var isCloudKitAvailable: Bool = false

    /// Persistence controller
    private let persistenceController: PersistenceController

    // MARK: - Initialization

    /// Initialize CloudKit sync manager
    /// - Parameter persistenceController: CoreData persistence controller
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.isCloudKitAvailable = persistenceController.isCloudKitAvailable

        // Observe sync notifications
        setupSyncObservers()

        // Check CloudKit account status
        checkCloudKitAccountStatus()
    }

    // MARK: - Setup

    /// Setup observers for CloudKit sync events
    private func setupSyncObservers() {
        // Observe import events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistenceController.container.persistentStoreCoordinator
        )

        // Observe export events (optional - for monitoring outgoing sync)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitSyncEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: persistenceController.container
        )
    }

    // MARK: - Notification Handlers

    /// Handle remote change notifications from CloudKit
    /// - Parameter notification: Notification object
    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            // Remote changes detected - data is being synced from iCloud
            self?.syncStatus = .inProgress
        }
    }

    /// Handle CloudKit sync event notifications
    /// - Parameter notification: Notification object
    @objc private func handleCloudKitSyncEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            if event.succeeded {
                self?.syncStatus = .succeeded
            } else if let error = event.error {
                self?.syncStatus = .failed(error)
            }
        }
    }

    // MARK: - CloudKit Status

    /// Check CloudKit account availability
    private func checkCloudKitAccountStatus() {
        let container = CKContainer(identifier: persistenceController.cloudKitContainerIdentifier ?? "")

        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isCloudKitAvailable = false
                    self?.syncStatus = .failed(error)
                    return
                }

                switch status {
                case .available:
                    self?.isCloudKitAvailable = true
                case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    self?.isCloudKitAvailable = false
                @unknown default:
                    self?.isCloudKitAvailable = false
                }
            }
        }
    }

    /// Refresh CloudKit status
    func refreshStatus() {
        checkCloudKitAccountStatus()
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
