//
//  NotificationService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import UserNotifications

/// Actor responsible for managing local notifications
/// Handles authorization and scheduling of meditation completion notifications
actor NotificationService {

    // MARK: - Types

    /// Notification service errors
    enum NotificationError: Error, LocalizedError {
        case authorizationDenied
        case schedulingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "Notification authorization was denied"
            case .schedulingFailed(let error):
                return "Failed to schedule notification: \(error.localizedDescription)"
            }
        }
    }

    /// Authorization status
    enum AuthorizationStatus: Sendable {
        case notDetermined
        case authorized
        case denied
    }

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// Check current notification authorization status
    /// - Returns: Current authorization status
    func checkAuthorizationStatus() async -> AuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }

    /// Request notification authorization
    /// - Throws: NotificationError if authorization is denied
    func requestAuthorization() async throws {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            guard granted else {
                throw NotificationError.authorizationDenied
            }
        } catch {
            throw NotificationError.authorizationDenied
        }
    }

    // MARK: - Scheduling

    /// Schedule a meditation completion notification
    /// - Parameters:
    ///   - duration: Meditation duration in seconds
    ///   - identifier: Unique identifier for the notification
    /// - Throws: NotificationError if scheduling fails
    func scheduleMeditationCompletionNotification(
        duration: TimeInterval,
        identifier: String = "meditation-completion"
    ) async throws {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Meditation Complete"
        content.body = "Great job! You've completed your meditation session."
        content.sound = .default
        content.badge = 0

        // Create trigger for specified duration
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: duration,
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
        } catch {
            throw NotificationError.schedulingFailed(error)
        }
    }

    /// Cancel a scheduled notification
    /// - Parameter identifier: Identifier of the notification to cancel
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Daily Reminders

    /// Schedule a daily reminder notification
    /// - Parameters:
    ///   - time: Time of day for the reminder
    ///   - identifier: Unique identifier for the notification
    /// - Throws: NotificationError if scheduling fails
    func scheduleDailyReminder(
        at time: DateComponents,
        identifier: String = "daily-reminder"
    ) async throws {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Meditate"
        content.body = "Take a moment for mindfulness today."
        content.sound = .default

        // Create daily repeating trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time,
            repeats: true
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
        } catch {
            throw NotificationError.schedulingFailed(error)
        }
    }

    /// Schedule a daily reminder notification at a specific time
    /// - Parameters:
    ///   - hour: Hour of the day (0-23)
    ///   - minute: Minute of the hour (0-59)
    ///   - identifier: Unique identifier for the notification
    /// - Throws: NotificationError if scheduling fails
    func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        identifier: String = "daily-reminder"
    ) async throws {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        try await scheduleDailyReminder(at: dateComponents, identifier: identifier)
    }

    /// Cancel daily reminder
    func cancelDailyReminder(identifier: String = "daily-reminder") {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Convenience Methods for Timer Events

    /// Schedule completion notification for timer
    /// - Parameter duration: Duration in seconds until completion
    func scheduleCompletionNotification(for duration: TimeInterval) {
        Task {
            try? await scheduleMeditationCompletionNotification(duration: duration)
        }
    }

    /// Cancel completion notification
    func cancelCompletionNotification() {
        cancelNotification(identifier: "meditation-completion")
    }
}
