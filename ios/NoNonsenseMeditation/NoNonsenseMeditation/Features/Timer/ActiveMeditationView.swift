//
//  ActiveMeditationView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Updated on 2026-01-14 - Added session type support for focus sessions
//

import SwiftUI

/// View for displaying active meditation session
/// Shows timer countdown, progress, and control buttons
struct ActiveMeditationView: View {

    // MARK: - Properties

    /// ViewModel for timer state management
    @State private var viewModel: TimerViewModel

    /// Session type (meditation or focus)
    private let sessionType: SessionType

    /// Navigation state
    @State private var recapInput: RecapInput? = nil

    /// Whether to show confirmation for early termination
    @State private var showCancelConfirmation = false

    // MARK: - Initialization

    init(viewModel: TimerViewModel, sessionType: SessionType = .meditation) {
        self._viewModel = State(initialValue: viewModel)
        self.sessionType = sessionType
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient

                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Timer Dial
                    timerDialSection

                    // Control Buttons
                    controlButtonsSection

                    Spacer()
                }
                .padding()
                .navigationDestination(item: $recapInput) { recap in
                    SessionRecapView(recap: recap)
                }
            }
        }
        .confirmationDialog(
            "Cancel \(sessionType.displayName)?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Session", role: .destructive) {
                handleCancelSession()
            }
            Button("Keep Going", role: .cancel) {
                // Dialog dismisses automatically
            }
        } message: {
            Text("This session will be saved as invalid and won't count toward your stats or streak.")
        }
    }

    // MARK: - Subviews

    /// Background gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.accentColor.opacity(0.1),
                Color.accentColor.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    /// Header section with back button and title
    private var headerSection: some View {
        HStack {
            // Back button (only visible when not running)
            if !viewModel.isRunning {
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Title based on session type
            HStack(spacing: 8) {
                Image(systemName: sessionType.iconName)
                    .foregroundColor(sessionType.color)
                Text("\(sessionType.displayName) in Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Empty space for symmetry
            Color.clear
                .frame(width: 32, height: 32)
        }
    }

    /// Timer dial section with circular progress indicator
    private var timerDialSection: some View {
        VStack(spacing: 24) {
            CircularTimerDial(
                progress: viewModel.progress,
                totalDuration: viewModel.totalDuration,
                remainingTime: viewModel.remainingTime,
                isRunning: viewModel.isRunning,
                isPaused: viewModel.isPaused,
                isCompleted: viewModel.isCompleted
            )

            // Additional info
            if viewModel.isRunning || viewModel.isPaused {
                HStack(spacing: 24) {
                    infoItem("Planned", viewModel.formattedTotalDuration)
                    infoItem("Elapsed", viewModel.formattedElapsedTime)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    /// Control buttons section
    private var controlButtonsSection: some View {
        VStack(spacing: 16) {
            if viewModel.isRunning && viewModel.isInOvertimeMode {
                // Overtime running state - show Pause and End controls
                // Pause button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    viewModel.pauseTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // End session button (saves actual overtime)
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    endMeditationEarly()
                }) {
                    Text("End Session")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundColor(.red)
            } else if viewModel.isRunning && viewModel.remainingTime <= 0 {
                // Overtime State - Two options
                VStack(spacing: 16) {
                    // End Session button (primary action)
                    Button(action: {
                        let success = UINotificationFeedbackGenerator()
                        success.notificationOccurred(.success)
                        viewModel.endSessionAtPlannedDuration()

                        // Build deterministic recap input and navigate immediately
                        let newlyUnlocked = AchievementService.shared.checkAndUnlockAchievements()
                        let recap = RecapInput(
                            plannedDuration: viewModel.totalDuration,
                            actualDuration: viewModel.totalDuration,
                            wasOvertimeDiscarded: true,
                            wasPaused: viewModel.isPaused,
                            unlockedAchievements: newlyUnlocked,
                            isSessionValid: isSessionValid(plannedDuration: viewModel.totalDuration, actualDuration: viewModel.totalDuration),
                            sessionType: sessionType
                        )
                        recapInput = recap
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("End Session")
                        }
                        .frame(minWidth: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // Add Overtime button (secondary action)
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        viewModel.stopTimer(suppressCompletionIfOvertime: true)

                        let newlyUnlocked = AchievementService.shared.checkAndUnlockAchievements()
                        let recap = RecapInput(
                            plannedDuration: viewModel.totalDuration,
                            actualDuration: viewModel.elapsedTime,
                            wasOvertimeDiscarded: false,
                            wasPaused: viewModel.isPaused,
                            unlockedAchievements: newlyUnlocked,
                            isSessionValid: isSessionValid(plannedDuration: viewModel.totalDuration, actualDuration: viewModel.elapsedTime),
                            sessionType: sessionType
                        )
                        recapInput = recap
                    }) {
                        Text("End and Save Overtime")
                            .frame(minWidth: 160)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else if viewModel.isRunning {
                // Pause button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    viewModel.pauseTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else if viewModel.isPaused {
                // Resume button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.resumeTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // End session button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    endMeditationEarly()
                }) {
                    Text("End Session")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundColor(.red)
            } else if viewModel.isCompleted {
                // Complete button (fallback if already stopped)
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                    // Completed state: derive recap from view model
                    let actual = viewModel.wasOvertimeDiscarded ? viewModel.totalDuration : viewModel.elapsedTime
                    let newlyUnlocked = AchievementService.shared.checkAndUnlockAchievements()
                    let recap = RecapInput(
                        plannedDuration: viewModel.totalDuration,
                        actualDuration: actual,
                        wasOvertimeDiscarded: viewModel.wasOvertimeDiscarded,
                        wasPaused: viewModel.isPaused,
                        unlockedAchievements: newlyUnlocked,
                        isSessionValid: isSessionValid(plannedDuration: viewModel.totalDuration, actualDuration: actual),
                        sessionType: sessionType
                    )
                    print("[ActiveMeditationView] Creating recap with actualDuration=%.2f seconds", actual)
                    recapInput = recap
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                        Text("View Session Recap")
                    }
                    .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Helper Views

    /// Info item for displaying timer statistics
    private func infoItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Methods

    /// Check if a meditation session meets the minimum duration requirement
    /// - Parameters:
    ///   - plannedDuration: Planned session duration in seconds
    ///   - actualDuration: Actual meditation time in seconds
    /// - Returns: True if session meets minimum threshold
    private func isSessionValid(plannedDuration: TimeInterval, actualDuration: TimeInterval) -> Bool {
        let minimumDuration = min(
            Constants.Timer.minimumValidSessionSeconds,
            plannedDuration * Constants.Timer.minimumValidSessionPercentage
        )
        return actualDuration >= minimumDuration
    }

    /// End meditation early (before completion)
    private func endMeditationEarly() {
        viewModel.stopTimer(suppressCompletionIfOvertime: true)

        let newlyUnlocked = AchievementService.shared.checkAndUnlockAchievements()
        let actualMeditationTime = viewModel.elapsedTime
        let recap = RecapInput(
            plannedDuration: viewModel.totalDuration,
            actualDuration: actualMeditationTime,
            wasOvertimeDiscarded: false,
            wasPaused: viewModel.isPaused,
            unlockedAchievements: newlyUnlocked,
            isSessionValid: isSessionValid(plannedDuration: viewModel.totalDuration, actualDuration: actualMeditationTime),
            sessionType: sessionType
        )
        recapInput = recap
    }

    /// Handle session cancellation
    private func handleCancelSession() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Cancel session (saves as invalid)
        viewModel.cancelSession()

        // Navigation pops back automatically
    }

    /// Handle timer completion
    private func handleTimerCompletion() {
        // This would be triggered by the ViewModel when timer completes
        // For now, we'll let the ViewModel handle state changes
    }
}

// MARK: - Preview

#Preview {
    // Preview with running timer
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 300) // 5 minutes
    return ActiveMeditationView(viewModel: viewModel)
}

#Preview("Paused State") {
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 300)
    viewModel.pauseTimer()
    return ActiveMeditationView(viewModel: viewModel)
}

#Preview("Completed State") {
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 60)
    viewModel.stopTimer()
    return ActiveMeditationView(viewModel: viewModel)
}

#Preview("Short Session Recap") {
    let recap = RecapInput(
        plannedDuration: 300,
        actualDuration: 10, // 10 seconds - below 15 second minimum
        wasOvertimeDiscarded: false,
        wasPaused: false,
        unlockedAchievements: [],
        isSessionValid: false
    )
    return SessionRecapView(recap: recap)
}

