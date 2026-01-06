//
//  MeditationTimerService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation

/// Actor responsible for managing meditation timer countdown logic
/// Provides thread-safe timer state management and countdown operations
actor MeditationTimerService {

    // MARK: - Types

    /// Timer state enumeration
    enum TimerState: Sendable {
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

    /// Time when timer was started or resumed
    private var startTime: Date?

    /// Time accumulated before current run (for pause/resume)
    private var accumulatedTime: TimeInterval = 0

    /// Background task for timer continuation
    private var timerTask: Task<Void, Never>?

    // MARK: - Public Methods

    /// Start a new timer with the specified duration
    /// - Parameter duration: Total duration in seconds
    func startTimer(duration: TimeInterval) {
        // Cancel any existing timer
        timerTask?.cancel()

        // Initialize timer state
        self.totalDuration = duration
        self.remainingTime = duration
        self.elapsedTime = 0
        self.accumulatedTime = 0
        self.startTime = Date()
        self.state = .running

        // Start countdown task
        startCountdown()
    }

    /// Pause the currently running timer
    func pauseTimer() {
        guard state == .running else { return }

        // Calculate elapsed time
        if let startTime = startTime {
            let sessionElapsed = Date().timeIntervalSince(startTime)
            accumulatedTime += sessionElapsed
        }

        // Cancel countdown task
        timerTask?.cancel()
        timerTask = nil

        // Update state
        self.startTime = nil
        self.state = .paused
    }

    /// Resume a paused timer
    func resumeTimer() {
        guard state == .paused else { return }

        // Reset start time
        self.startTime = Date()
        self.state = .running

        // Restart countdown
        startCountdown()
    }

    /// Stop the timer and mark as completed
    func stopTimer() {
        // If we're running, capture the final elapsed segment
        if state == .running, let startTime = startTime {
            let sessionElapsed = Date().timeIntervalSince(startTime)
            accumulatedTime += sessionElapsed
        }
        
        // Cancel countdown task
        timerTask?.cancel()
        timerTask = nil

        // Update state
        self.state = .completed
        self.startTime = nil
    }

    /// Reset timer to idle state
    func resetTimer() {
        timerTask?.cancel()
        timerTask = nil

        self.state = .idle
        self.remainingTime = 0
        self.totalDuration = 0
        self.elapsedTime = 0
        self.accumulatedTime = 0
        self.startTime = nil
    }

    /// Get current progress as a value between 0 and 1
    /// - Returns: Progress ratio (0.0 = start, 1.0 = complete)
    func getProgress() -> Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - remainingTime
        return min(max(elapsed / totalDuration, 0), 1)
    }

    /// Get actual meditation time (excluding pause time)
    /// - Returns: Total time actually spent meditating in seconds
    func getActualMeditationTime() -> TimeInterval {
        var total = accumulatedTime

        if state == .running, let startTime = startTime {
            total += Date().timeIntervalSince(startTime)
        }

        return total
    }

    /// Get current timer state
    /// - Returns: Current state of the timer
    func getState() -> TimerState {
        return state
    }

    /// Get remaining time in seconds
    /// - Returns: Time remaining in the meditation session
    func getRemainingTime() -> TimeInterval {
        return remainingTime
    }

    /// Get elapsed time in seconds
    /// - Returns: Total time elapsed including pauses
    func getElapsedTime() -> TimeInterval {
        return elapsedTime
    }

    // MARK: - Private Methods

    /// Start the countdown task
    private func startCountdown() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.1))

                guard !Task.isCancelled else { break }

                await self?.updateTimer()
            }
        }
    }

    /// Update timer state on each tick
    private func updateTimer() {
        guard state == .running, let startTime = startTime else { return }

        // Calculate elapsed time
        let sessionElapsed = Date().timeIntervalSince(startTime)
        let totalElapsed = accumulatedTime + sessionElapsed
        self.elapsedTime = totalElapsed

        // Calculate remaining time
        // Allow negative time for overtime
        self.remainingTime = totalDuration - totalElapsed
        
        // Check for completion time (just passed zero) but DON'T stop automatically
        // The ViewModel will handle the bell and UI updates
        if remainingTime <= 0 && state != .completed {
            // We just let it run. The ViewModel will observe remainingTime <= 0
            // and trigger the bell, but we keep running until stopTimer() is called.
        }
    }
}
