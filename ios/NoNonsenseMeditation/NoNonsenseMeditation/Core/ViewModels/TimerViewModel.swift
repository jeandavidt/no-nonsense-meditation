//
//  TimerViewModel.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import Observation
import Combine

/// ViewModel for managing meditation timer state and user interactions
/// Uses @Observable macro for SwiftUI observation
@Observable
class TimerViewModel {

    // MARK: - Types

    /// Timer state enumeration for UI binding
    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }

    // MARK: - Properties

    /// Current timer state
    private(set) var state: TimerState = .idle

    /// Remaining time in seconds
    private(set) var remainingTime: TimeInterval = 0

    /// Total planned duration in seconds
    private(set) var totalDuration: TimeInterval = 0

    /// Time elapsed in current session (including pauses)
    private(set) var elapsedTime: TimeInterval = 0

    /// Current progress as a value between 0 and 1
    private(set) var progress: Double = 0

    /// Formatted remaining time string for display
    private(set) var formattedTime: String = "00:00"

    /// Timer service for countdown logic
    private let timerService = MeditationTimerService()

    /// Audio service for bell sounds
    private let audioService = AudioService()

    /// Notification service for background notifications
    private let notificationService = NotificationService()

    /// Session manager for session lifecycle
    private let sessionManager = SessionManager()

    /// Combine cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupSubscriptions()
    }

    // MARK: - Public Methods

    /// Start a new timer with the specified duration
    /// - Parameter duration: Total duration in seconds
    func startTimer(duration: TimeInterval) {
        Task { @MainActor in
            // Reset state
            self.state = .idle
            self.remainingTime = duration
            self.totalDuration = duration
            self.elapsedTime = 0
            self.progress = 0
            self.formattedTime = formatTime(duration)

            // Start timer service
            await timerService.startTimer(duration: duration)
            await updateFromTimerService()

            // Play start sound
            await audioService.playStartSound()

            // Schedule completion notification
            await notificationService.scheduleCompletionNotification(for: duration)

            // Update state
            self.state = .running
        }
    }

    /// Pause the currently running timer
    func pauseTimer() {
        Task { @MainActor in
            guard state == .running else { return }

            await timerService.pauseTimer()
            await updateFromTimerService()

            // Play pause sound
            await audioService.playPauseSound()

            // Cancel completion notification
            await notificationService.cancelCompletionNotification()

            // Update state
            self.state = .paused
        }
    }

    /// Resume a paused timer
    func resumeTimer() {
        Task { @MainActor in
            guard state == .paused else { return }

            // Calculate remaining time for notification
            let remainingTime = await timerService.getRemainingTime()
            await notificationService.scheduleCompletionNotification(for: remainingTime)

            await timerService.resumeTimer()
            await updateFromTimerService()

            // Play resume sound
            await audioService.playResumeSound()

            // Update state
            self.state = .running
        }
    }

    /// Stop the timer and mark as completed
    func stopTimer() {
        Task { @MainActor in
            await timerService.stopTimer()
            await updateFromTimerService()

            // Play completion sound
            await audioService.playCompletionSound()

            // Cancel notification (in case it hasn't fired yet)
            await notificationService.cancelCompletionNotification()

            // Save session
            let actualMeditationTime = await timerService.getActualMeditationTime()
            await sessionManager.completeSession(
                plannedDuration: totalDuration,
                actualDuration: actualMeditationTime,
                wasPaused: state == .paused
            )

            // Update state
            self.state = .completed
        }
    }

    /// Reset timer to idle state
    func resetTimer() {
        Task { @MainActor in
            await timerService.resetTimer()
            await updateFromTimerService()

            // Cancel any pending notifications
            await notificationService.cancelCompletionNotification()

            // Update state
            self.state = .idle
        }
    }

    // MARK: - Private Methods

    /// Set up subscriptions to timer service updates
    private func setupSubscriptions() {
        // Create a timer that updates the UI every second
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateFromTimerService()
                }
            }
            .store(in: &cancellables)
    }

    /// Update view model state from timer service
    private func updateFromTimerService() async {
        let timerState = await timerService.getState()
        let remainingTime = await timerService.getRemainingTime()
        let elapsedTime = await timerService.getElapsedTime()
        let progress = await timerService.getProgress()

        // Update state on main actor
        await MainActor.run {
            self.state = mapTimerState(timerState)
            self.remainingTime = remainingTime
            self.elapsedTime = elapsedTime
            self.progress = progress
            self.formattedTime = formatTime(remainingTime)
        }
    }

    /// Map timer service state to view model state
    private func mapTimerState(_ serviceState: MeditationTimerService.TimerState) -> TimerState {
        switch serviceState {
        case .idle:
            return .idle
        case .running:
            return .running
        case .paused:
            return .paused
        case .completed:
            return .completed
        }
    }

    /// Format time interval as MM:SS string
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Convenience Methods

    /// Check if timer is currently running
    var isRunning: Bool {
        return state == .running
    }

    /// Check if timer is paused
    var isPaused: Bool {
        return state == .paused
    }

    /// Check if timer is completed
    var isCompleted: Bool {
        return state == .completed
    }

    /// Check if timer is idle
    var isIdle: Bool {
        return state == .idle
    }

    /// Get formatted elapsed time
    var formattedElapsedTime: String {
        return formatTime(elapsedTime)
    }

    /// Get formatted total duration
    var formattedTotalDuration: String {
        return formatTime(totalDuration)
    }
}