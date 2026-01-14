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
    
    /// Selected music library item (when using user library)
    var selectedMusicLibraryItem: MusicLibraryItem?
    
    /// Whether the completion sound has been played for the current session
    private var hasPlayedCompletionSound = false
    
    /// Session start time for tracking actual meditation duration
    private var sessionStartTime: Date?
    
    /// Whether user chose to continue into overtime mode
    private(set) var isInOvertimeMode: Bool = false
    
    /// Timestamp when overtime was activated
    private var overtimeStartTime: Date?
    
    /// Whether overtime was discarded (user clicked "End Session" during overtime)
    private(set) var wasOvertimeDiscarded: Bool = false

    /// Current session type (meditation or focus)
    var sessionType: SessionType = .meditation

    /// Last time we updated lockscreen info — used to throttle expensive updates
    private var lastLockscreenUpdate: Date?
    
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
        loadMusicLibraryItemPreference()
        setupRemoteCommandCallbacks()
    }
    
    // MARK: - Public Methods
    
    /// Start a new timer with the specified duration
    /// - Parameter duration: Total duration in seconds
    func startTimer(duration: TimeInterval) {
        startTimer(duration: duration, sessionType: .meditation)
    }

    /// Start a new timer with the specified duration and session type
    /// - Parameter duration: Total duration in seconds
    /// - Parameter sessionType: The type of session (meditation or focus)
    func startTimer(duration: TimeInterval, sessionType: SessionType) {
        Task {
            // Set session type
            self.sessionType = sessionType

            // Reset state
            self.state = .idle
            self.remainingTime = duration
            self.totalDuration = duration
            self.elapsedTime = 0
            self.progress = 0
            self.formattedTime = formatTime(duration)

            // Record session start time for HealthKit accuracy
            self.sessionStartTime = Date()

            // Start timer service
            await timerService.startTimer(duration: duration)
            await updateFromTimerService()

            // Start background sound if selected
            if selectedBackgroundSound == .userLibrary, let musicItem = selectedMusicLibraryItem {
                // Play from user's music library
                try? await audioService.startUserLibraryMusic(musicItem)
            } else if selectedBackgroundSound != .none {
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
            
            // Only schedule notification if there's time remaining
            if remainingTime > 0 {
                await notificationService.scheduleCompletionNotification(for: remainingTime)
            }
            
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
    func stopTimer(suppressCompletionIfOvertime: Bool = false) {
        Task {
            await timerService.stopTimer()
            await updateFromTimerService()

            // Stop background sound
            await audioService.stopBackgroundSound()

            // Determine actual meditation time
            let actualMeditationTime = await timerService.getActualMeditationTime()

            // Play completion sound only if not suppressed due to overtime
            let isOvertime = actualMeditationTime > totalDuration
            if !(suppressCompletionIfOvertime && isOvertime) {
                await audioService.playCompletionSound()
            }

            // Cancel notification (in case it hasn't fired yet)
            await notificationService.cancelCompletionNotification()

            // Save session
            _ = await sessionManager.completeSession(
                plannedDuration: totalDuration,
                actualDuration: actualMeditationTime,
                wasPaused: state == .paused,
                startDate: sessionStartTime,  // Pass actual start time for accurate HealthKit duration
                sessionType: sessionType
            )

            // Update state
            self.state = .completed

            // Reset overtime tracking
            self.isInOvertimeMode = false
            self.overtimeStartTime = nil

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
    
    /// Cancel current meditation session (saves as invalid)
    func cancelSession() {
        Task {
            // Stop timer
            await timerService.stopTimer()
            
            // Stop background sound
            await audioService.stopBackgroundSound()
            
            // Cancel notification
            await notificationService.cancelCompletionNotification()
            
            // Get elapsed time
            let elapsedTime = await timerService.getElapsedTime()
            
            // Save session as INVALID
            _ = await sessionManager.completeCancelledSession(
                plannedDuration: totalDuration,
                elapsedDuration: elapsedTime,
                startDate: sessionStartTime
            )
            
            // Reset state
            self.state = .idle
            self.sessionStartTime = nil
            self.isInOvertimeMode = false
            self.overtimeStartTime = nil
        }
    }
    
    /// End session at planned duration (ignore overtime accumulated)
    func endSessionAtPlannedDuration() {
        Task {
            await timerService.stopTimer()
            await updateFromTimerService()
            
            // Stop background sound
            await audioService.stopBackgroundSound()
            
            // Cancel notification
            await notificationService.cancelCompletionNotification()
            
            // Mark that overtime was discarded (for UI display in recap)
            self.wasOvertimeDiscarded = true
            
            // Reset elapsed time to match planned duration (discard overtime from display)
            self.elapsedTime = totalDuration
            
            // When ending at planned duration, ONLY save the planned duration
            // Do NOT include overtime that may have accumulated
            _ = await sessionManager.completeSession(
                plannedDuration: totalDuration,
                actualDuration: totalDuration, // Use planned, not actual elapsed time
                wasPaused: state == .paused,
                startDate: sessionStartTime,
                sessionType: sessionType
            )
            
            // Reset state
            self.isInOvertimeMode = false
            self.overtimeStartTime = nil
            self.state = .completed
            self.wasOvertimeDiscarded = false
            
            // Update lockscreen
            await audioService.updateNowPlayingInfo(
                title: "Meditation Complete",
                artist: "No Nonsense Meditation",
                duration: nil,
                elapsed: nil,
                playbackRate: 0
            )
        }
    }
    
    /// Continue session into overtime to accumulate extra time
    func continueIntoOvertime() {
        // Mark overtime mode activated
        isInOvertimeMode = true
        wasOvertimeDiscarded = false
        overtimeStartTime = Date()
        
        // Cancel any pending completion notification since we've passed planned end
        Task { [notificationService] in
            await notificationService.cancelCompletionNotification()
        }
        
        // The timer keeps running; background sound continues. We intentionally do not change state here.
        // Debug log
        print("[TimerViewModel] continueIntoOvertime: totalDuration=\(totalDuration), elapsedTime=\(elapsedTime), remaining=\(remainingTime)")
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
            
            // Clear session start time
            self.sessionStartTime = nil
            
            // Update state
            self.state = .idle
        }
    }
    
    // MARK: - Private Methods
    
    /// Set up subscriptions to timer service updates
    private func setupSubscriptions() {
        // Create a timer that updates the UI four times per second (no need for 10Hz)
        Timer.publish(every: 0.25, on: .main, in: .common)
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
        
        // Update lockscreen with current progress, but throttle to at most once per second
        if state == .running || state == .paused {
            let now = Date()
            if let last = lastLockscreenUpdate {
                if now.timeIntervalSince(last) >= 1.0 {
                    lastLockscreenUpdate = now
                    await updateLockscreenInfo()
                }
            } else {
                lastLockscreenUpdate = now
                await updateLockscreenInfo()
            }
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
    
    /// Load saved music library item preference
    func loadMusicLibraryItemPreference() {
        self.selectedMusicLibraryItem = MusicLibraryItem.loadFromUserDefaults()
    }
    
    /// Set the music library item for the meditation session
    /// - Parameter item: The music library item to use
    func setMusicLibraryItem(_ item: MusicLibraryItem) {
        self.selectedMusicLibraryItem = item
        self.selectedBackgroundSound = .userLibrary
        item.saveToUserDefaults()
        BackgroundSound.userLibrary.saveToUserDefaults()
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
            
            // Debug log before clamping elapsed time
            print("[TimerViewModel] endSessionAtPlannedDuration called: totalDuration=\(totalDuration), elapsedTime(before)=\(elapsedTime), remaining=\(remainingTime), isInOvertimeMode=\(isInOvertimeMode)")
            
            // Reset elapsed time to match planned duration (discard overtime from display)
            self.elapsedTime = totalDuration
            
            // Debug log after clamping
            print("[TimerViewModel] endSessionAtPlannedDuration: elapsedTime(after)=\(elapsedTime)")
        }
    }
}

