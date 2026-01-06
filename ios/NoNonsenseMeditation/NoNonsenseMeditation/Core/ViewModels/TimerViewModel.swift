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
/// Isolated to MainActor for UI updates and concurrency safety
@MainActor
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

    /// Total duration of the session in seconds
    private(set) var totalDuration: TimeInterval = 0

    /// Remaining time in seconds
    private(set) var remainingTime: TimeInterval = 0

    /// Elapsed time in seconds
    private(set) var elapsedTime: TimeInterval = 0

    /// Progress from 0.0 to 1.0 for UI progress rings
    private(set) var progress: Double = 0.0

    /// Formatted time string (MM:SS)
    private(set) var formattedTime: String = "00:00"

    /// Selected background sound
    private(set) var selectedBackgroundSound: BackgroundSound = .none
    
    /// Whether the completion sound has been played for the current session
    private var hasPlayedCompletionSound = false

    // MARK: - Dependencies

    /// Timer service for handling countdown logic
    private let timerService = MeditationTimerService()

    /// Audio service for sound playback
    private let audioService: AudioServiceProtocol

    /// Notification service for local notifications
    private let notificationService = NotificationService()

    /// Session manager for session lifecycle
    private let sessionManager = SessionManager()

    /// Combine cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(audioService: AudioServiceProtocol = AudioService.shared) {
        self.audioService = audioService
        setupSubscriptions()
        loadBackgroundSoundPreference()
        setupRemoteCommandCallbacks()
    }

    // MARK: - Public Methods

    /// Start a new timer with the specified duration
    /// - Parameter duration: Total duration in seconds
    func startTimer(duration: TimeInterval) {
        Task {
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

            // Start background sound if selected
            if selectedBackgroundSound != .none {
                try? await audioService.startBackgroundSound(selectedBackgroundSound)
            }

            // Play start sound
            try? await audioService.playStartSound()

            // Schedule completion notification
            await notificationService.scheduleCompletionNotification(for: duration)

            // Update state
            self.state = .running

            // Update lockscreen info
            await updateLockscreenInfo()
        }
    }

    /// Pause the currently running timer
    func pauseTimer() {
        Task {
            guard state == .running else { return }

            await timerService.pauseTimer()
            await updateFromTimerService()

            // Pause background sound
            await audioService.pauseBackgroundSound()

            // Play pause sound
            try? await audioService.playPauseSound()

            // Cancel completion notification
            await notificationService.cancelCompletionNotification()

            // Update state
            self.state = .paused

            // Update lockscreen info
            await updateLockscreenInfo()
        }
    }

    /// Resume a paused timer
    func resumeTimer() {
        Task {
            guard state == .paused else { return }

            // Calculate remaining time for notification
            let remainingTime = await timerService.getRemainingTime()
            await notificationService.scheduleCompletionNotification(for: remainingTime)

            await timerService.resumeTimer()
            await updateFromTimerService()

            // Resume background sound
            await audioService.resumeBackgroundSound()

            // Play resume sound
            try? await audioService.playResumeSound()

            // Update state
            self.state = .running

            // Update lockscreen info
            await updateLockscreenInfo()
        }
    }

    /// Stop the timer and mark as completed
    func stopTimer() {
        Task {
            await timerService.stopTimer()
            await updateFromTimerService()

            // Stop background sound
            await audioService.stopBackgroundSound()

            // Play completion sound
            await audioService.playCompletionSound()

            // Cancel notification (in case it hasn't fired yet)
            await notificationService.cancelCompletionNotification()

            // Save session
            let actualMeditationTime = await timerService.getActualMeditationTime()
            _ = await sessionManager.completeSession(
                plannedDuration: totalDuration,
                actualDuration: actualMeditationTime,
                wasPaused: state == .paused
            )

            // Update state
            self.state = .completed

            // Update lockscreen info for completion
            await audioService.updateNowPlayingInfo(
                title: "Meditation Complete",
                artist: "No Nonsense Meditation",
                duration: nil,
                elapsed: nil,
                playbackRate: 0
            )
        }
    }

    /// Reset timer to idle state
    func resetTimer() {
        Task {
            await timerService.resetTimer()
            await updateFromTimerService()

            // Stop background sound
            await audioService.stopBackgroundSound()

            // Cancel any pending notifications
            await notificationService.cancelCompletionNotification()

            // Update state
            self.state = .idle
        }
    }

    // MARK: - Private Methods

    /// Set up subscriptions to timer service updates
    private func setupSubscriptions() {
        // Create a timer that updates the UI every 0.1 second
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
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

        // Update state (already on MainActor)
        self.state = mapTimerState(timerState)
        self.remainingTime = remainingTime
        self.elapsedTime = elapsedTime
        self.progress = progress
        self.formattedTime = formatTime(remainingTime)

        // Update lockscreen with current progress
        if state == .running || state == .paused {
            await updateLockscreenInfo()
        }

        // Check for completion (overtime start)
        // If we hit 0 or go negative, and haven't played sound yet, play it.
        // But we DO NOT stop the background sound here.
        if remainingTime <= 0 && !hasPlayedCompletionSound && state == .running {
            hasPlayedCompletionSound = true
            await audioService.playCompletionSound()
            // We do NOT call stopBackgroundSound() here anymore.
            // It continues until user explicitly stops it.
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
    /// Format time interval as MM:SS string (handles negative for overtime)
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let absTime = abs(timeInterval)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        if timeInterval < 0 {
            return "+\(timeString)"
        } else {
            return timeString
        }
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

    // MARK: - Background Sound Management

    /// Set the background sound for the meditation session
    /// - Parameter sound: The background sound to use
    func setBackgroundSound(_ sound: BackgroundSound) {
        self.selectedBackgroundSound = sound
        sound.saveToUserDefaults()
    }

    /// Load saved background sound preference
    func loadBackgroundSoundPreference() {
        self.selectedBackgroundSound = BackgroundSound.loadFromUserDefaults()
    }

    /// Set up remote command callbacks for lockscreen controls
    private func setupRemoteCommandCallbacks() {
        guard let audioService = audioService as? AudioService else { return }

        Task {
            await audioService.setRemoteCommandCallbacks(
                onPause: { [weak self] in
                    await MainActor.run {
                        self?.pauseTimer()
                    }
                },
                onPlay: { [weak self] in
                    await MainActor.run {
                        self?.resumeTimer()
                    }
                }
            )
        }
    }

    /// Update lockscreen media player info with current meditation state
    private func updateLockscreenInfo() async {
        let meditationTitle = "Meditation Session"
        let meditationArtist = "No Nonsense Meditation"
        let rate: Float = state == .paused ? 0.0 : 1.0

        await audioService.updateNowPlayingInfo(
            title: meditationTitle,
            artist: meditationArtist,
            duration: totalDuration,
            elapsed: elapsedTime,
            playbackRate: rate
        )
    }

    /// Preview a background sound
    /// - Parameter sound: The sound to preview
    func previewBackgroundSound(_ sound: BackgroundSound) {
        Task {
            await audioService.stopPreview()
            try? await audioService.previewBackgroundSound(sound, duration: 3.0)
        }
    }

    /// Stop any preview playback
    func stopPreview() {
        Task {
            await audioService.stopPreview()
        }
    }
}