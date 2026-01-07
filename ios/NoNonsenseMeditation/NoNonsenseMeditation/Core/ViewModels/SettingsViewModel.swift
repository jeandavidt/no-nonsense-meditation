//
//  SettingsViewModel.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import Observation
import SwiftUI
import UserNotifications

/// ViewModel for managing app settings and preferences
/// Uses @Observable macro for SwiftUI observation
@Observable
@MainActor
class SettingsViewModel {

    // MARK: - Types

    /// Bell sound configuration
    enum BellSound: String, CaseIterable, Identifiable {
        case meditationBell = "meditation_bell"
        case none = "none"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .meditationBell:
                return "Meditation Bell"
            case .none:
                return "None (Silent)"
            }
        }
    }

    /// Confirmation dialog states
    enum ConfirmationDialog: Identifiable {
        case clearAllData
        case exportData
        case restartRequired

        var id: String {
            switch self {
            case .clearAllData:
                return "clearAllData"
            case .exportData:
                return "exportData"
            case .restartRequired:
                return "restartRequired"
            }
        }
    }

    /// Alert types
    enum AlertType: Identifiable {
        case error(String)
        case success(String)
        case dataCleared
        case dataExported

        var id: String {
            switch self {
            case .error:
                return "error"
            case .success:
                return "success"
            case .dataCleared:
                return "dataCleared"
            case .dataExported:
                return "dataExported"
            }
        }

        var title: String {
            switch self {
            case .error:
                return "Error"
            case .success:
                return "Success"
            case .dataCleared:
                return "Data Cleared"
            case .dataExported:
                return "Data Exported"
            }
        }

        var message: String {
            switch self {
            case .error(let message):
                return message
            case .success(let message):
                return message
            case .dataCleared:
                return "All meditation data has been permanently deleted."
            case .dataExported:
                return "Your meditation data has been exported successfully."
            }
        }
    }

    // MARK: - Published Properties

    /// Default meditation duration in minutes
    var defaultDuration: Int {
        didSet {
            UserDefaults.standard.set(defaultDuration, forKey: Constants.UserDefaultsKeys.defaultDuration)
        }
    }

    /// Selected bell sound
    var selectedBellSound: BellSound {
        didSet {
            UserDefaults.standard.set(selectedBellSound.rawValue, forKey: Constants.UserDefaultsKeys.selectedBellSound)
        }
    }

    /// Whether notifications are enabled
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Constants.UserDefaultsKeys.dailyReminderEnabled)
        }
    }

    /// Whether daily reminder is enabled
    var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: Constants.UserDefaultsKeys.dailyReminderEnabled)
            if dailyReminderEnabled {
                Task {
                    await scheduleDailyReminder()
                }
            } else {
                Task {
                    await cancelDailyReminder()
                }
            }
        }
    }

    /// Daily reminder time
    var dailyReminderTime: Date {
        didSet {
            if let timeData = try? JSONEncoder().encode(dailyReminderTime) {
                UserDefaults.standard.set(timeData, forKey: Constants.UserDefaultsKeys.dailyReminderTime)
            }
            if dailyReminderEnabled {
                Task {
                    await scheduleDailyReminder()
                }
            }
        }
    }

    /// Whether to keep screen awake during meditation
    var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenAwake, forKey: Constants.UserDefaultsKeys.keepScreenAwake)
        }
    }

    /// Whether haptic feedback is enabled
    var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Constants.UserDefaultsKeys.hapticFeedbackEnabled)
        }
    }

    /// Whether to override silent mode for bell sounds
    var overrideSilentMode: Bool {
        didSet {
            UserDefaults.standard.set(overrideSilentMode, forKey: Constants.UserDefaultsKeys.overrideSilentMode)
        }
    }

    /// Whether iCloud sync is enabled
    var iCloudSyncEnabled: Bool {
        didSet {
            // Show restart confirmation when user changes the setting
            if oldValue != iCloudSyncEnabled {
                previousICloudSyncValue = oldValue
                activeConfirmationDialog = .restartRequired
            }
        }
    }

    /// Previous value of iCloud sync setting (for canceling)
    private var previousICloudSyncValue: Bool = false

    /// Current confirmation dialog
    var activeConfirmationDialog: ConfirmationDialog?

    /// Current alert
    var activeAlert: AlertType?

    /// Whether data export is in progress
    var isExporting: Bool = false

    /// Whether data clearing is in progress
    var isClearing: Bool = false

    /// Total meditation statistics
    var statistics: MeditationStatistics?

    /// Current notification authorization status
    var notificationAuthStatus: NotificationService.AuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let sessionService: MeditationSessionService
    private let notificationService: NotificationService
    private let persistenceController: PersistenceController
    private let importService = DataImportService()

    // MARK: - Computed Properties

    /// App version string
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    /// Current streak count
    var currentStreak: Int {
        (try? sessionService.currentStreak()) ?? 0
    }

    /// Total sessions count
    var totalSessions: Int {
        (try? sessionService.sessionCount()) ?? 0
    }

    /// Total meditation time in minutes
    var totalMeditationTime: Double {
        (try? sessionService.totalMeditationTime()) ?? 0.0
    }

    /// Formatted total meditation time
    var formattedTotalTime: String {
        let hours = Int(totalMeditationTime / 60)
        let minutes = Int(totalMeditationTime.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Available duration options for picker
    var durationOptions: [Int] {
        Constants.Timer.presetDurations
    }

    // MARK: - Persistence Status

    /// Current persistence mode
    var persistenceMode: PersistenceMode {
        persistenceController.persistenceMode
    }

    /// User-facing persistence status message
    var persistenceStatusMessage: String {
        persistenceMode.description
    }

    /// Icon for persistence status
    var persistenceStatusIcon: String {
        persistenceMode.icon
    }

    /// Color for persistence status icon
    var persistenceStatusColor: Color {
        persistenceMode.iconColor
    }

    // MARK: - Initialization

    init(
        sessionService: MeditationSessionService = MeditationSessionService(),
        notificationService: NotificationService = NotificationService(),
        persistenceController: PersistenceController = .shared
    ) {
        self.sessionService = sessionService
        self.notificationService = notificationService
        self.persistenceController = persistenceController

        // Load settings from UserDefaults
        let savedDuration = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.defaultDuration)
        let defaultDurationValue = savedDuration == 0 ? Constants.Timer.defaultDuration : savedDuration

        let bellSoundRaw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedBellSound) ?? BellSound.meditationBell.rawValue
        let selectedBellSoundValue = BellSound(rawValue: bellSoundRaw) ?? .meditationBell

        let notificationsEnabledValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.dailyReminderEnabled)
        let dailyReminderEnabledValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.dailyReminderEnabled)

        let dailyReminderTimeValue: Date
        if let timeData = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.dailyReminderTime),
           let savedTime = try? JSONDecoder().decode(Date.self, from: timeData) {
            dailyReminderTimeValue = savedTime
        } else {
            // Default to 9:00 AM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            dailyReminderTimeValue = calendar.date(from: components) ?? Date()
        }

        let keepScreenAwakeValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.keepScreenAwake)
        let hapticFeedbackEnabledValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hapticFeedbackEnabled)
        let overrideSilentModeValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.overrideSilentMode)

        // iCloud sync enabled - default to true if not set
        let iCloudSyncEnabledValue: Bool
        if UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.iCloudSyncEnabled) != nil {
            iCloudSyncEnabledValue = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.iCloudSyncEnabled)
        } else {
            // First launch - default to true and save it
            iCloudSyncEnabledValue = true
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.iCloudSyncEnabled)
        }

        // Initialize all properties
        self.defaultDuration = defaultDurationValue
        self.selectedBellSound = selectedBellSoundValue
        self.notificationsEnabled = notificationsEnabledValue
        self.dailyReminderEnabled = dailyReminderEnabledValue
        self.dailyReminderTime = dailyReminderTimeValue
        self.keepScreenAwake = keepScreenAwakeValue
        self.hapticFeedbackEnabled = hapticFeedbackEnabledValue
        self.overrideSilentMode = overrideSilentModeValue
        self.iCloudSyncEnabled = iCloudSyncEnabledValue
    }

    // MARK: - Public Methods

    /// Load statistics from the session service
    func loadStatistics() async {
        do {
            let allSessions = try sessionService.fetchValidSessions()
            let validSessions = allSessions.filter { $0.isSessionValid }

            let totalTime = validSessions.reduce(0.0) { $0 + $1.durationTotal }
            let totalPauses = validSessions.reduce(0) { $0 + Int($1.pauseCount) }
            let averageDuration = validSessions.isEmpty ? 0.0 : totalTime / Double(validSessions.count)
            let longestSession = validSessions.map { $0.durationTotal }.max() ?? 0.0

            statistics = MeditationStatistics(
                totalSessions: validSessions.count,
                totalTime: totalTime,
                averageDuration: averageDuration,
                longestSession: longestSession,
                totalPauses: totalPauses,
                sessionsWithPauses: validSessions.filter { $0.wasPaused }.count
            )
        } catch {
            print("Failed to load statistics: \(error.localizedDescription)")
            activeAlert = .error("Failed to load statistics: \(error.localizedDescription)")
        }
    }

    /// Show confirmation dialog for clearing all data
    func showClearDataConfirmation() {
        activeConfirmationDialog = .clearAllData
    }

    /// Clear all meditation data
    func clearAllData() async {
        isClearing = true

        do {
            // Delete all sessions (including valid ones)
            try sessionService.deleteAllSessions(includeValid: true)

            // Reload statistics
            await loadStatistics()

            isClearing = false
            activeAlert = .dataCleared
        } catch {
            isClearing = false
            activeAlert = .error("Failed to clear data: \(error.localizedDescription)")
        }
    }

    /// Show confirmation dialog for exporting data
    func showExportDataConfirmation() {
        activeConfirmationDialog = .exportData
    }

    /// Export meditation data as JSON
    func exportData() async -> URL? {
        isExporting = true

        do {
            let sessions = try sessionService.fetchAllSessions()

            // Convert to exportable format
            let exportData = sessions.map { session in
                [
                    "id": session.idSession?.uuidString ?? "",
                    "plannedDuration": session.durationPlanned,
                    "actualDuration": session.durationTotal,
                    "elapsedDuration": session.durationElapsed,
                    "createdAt": session.createdAt?.ISO8601Format() ?? "",
                    "completedAt": session.completedAt?.ISO8601Format() ?? "",
                    "isValid": session.isSessionValid,
                    "wasPaused": session.wasPaused,
                    "pauseCount": session.pauseCount
                ] as [String : Any]
            }

            // Create JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)

            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "meditation-data-\(Date().ISO8601Format()).json"
            let fileURL = tempDir.appendingPathComponent(fileName)

            try jsonData.write(to: fileURL)

            isExporting = false
            activeAlert = .dataExported

            return fileURL
        } catch {
            isExporting = false
            activeAlert = .error("Failed to export data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Import meditation data from JSON file
    func importData(from url: URL, strategy: DataImportService.MergeStrategy = .skipDuplicates) async -> DataImportService.ImportResult? {
        isExporting = true // Reuse loading flag

        do {
            let result = try await importService.importSessions(from: url, strategy: strategy)

            // Reload statistics
            await loadStatistics()

            isExporting = false

            // Show success
            activeAlert = .success("Imported \(result.successCount) of \(result.totalProcessed) sessions")

            return result
        } catch {
            isExporting = false
            activeAlert = .error("Failed to import data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Confirm restart and apply iCloud sync setting change
    func confirmRestart() {
        // Save the new setting
        UserDefaults.standard.set(iCloudSyncEnabled, forKey: Constants.UserDefaultsKeys.iCloudSyncEnabled)

        // Exit the app - iOS will kill it and user can relaunch
        exit(0)
    }

    /// Cancel iCloud sync change and revert to previous value
    func cancelRestart() {
        // Revert to previous value
        iCloudSyncEnabled = previousICloudSyncValue
        // Clear the confirmation dialog
        activeConfirmationDialog = nil
    }

    /// Request notification permissions
    func requestNotificationPermissions() async {
        do {
            try await notificationService.requestAuthorization()
            notificationsEnabled = true
            if dailyReminderEnabled {
                await scheduleDailyReminder()
            }
        } catch {
            notificationsEnabled = false
            activeAlert = .error("Notification permission denied. Please enable in Settings.")
        }
    }

    /// Open iOS Settings app
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            Task {
                await UIApplication.shared.open(settingsURL)
            }
        }
    }

    /// Update notification authorization status
    func updateNotificationAuthStatus() async {
        let status = await notificationService.checkAuthorizationStatus()
        notificationAuthStatus = status
    }

    // MARK: - Private Methods

    /// Schedule daily reminder notification
    private func scheduleDailyReminder() async {
        do {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)

            try await notificationService.scheduleDailyReminder(
                hour: components.hour ?? 9,
                minute: components.minute ?? 0
            )
        } catch {
            print("Failed to schedule daily reminder: \(error.localizedDescription)")
            activeAlert = .error("Failed to schedule reminder: \(error.localizedDescription)")
        }
    }

    /// Cancel daily reminder notification
    private func cancelDailyReminder() async {
        await notificationService.cancelDailyReminder()
    }
}
