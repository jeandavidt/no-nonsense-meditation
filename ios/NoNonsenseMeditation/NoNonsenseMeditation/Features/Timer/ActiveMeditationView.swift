//
//  ActiveMeditationView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// View for displaying active meditation session
/// Shows timer countdown, progress, and control buttons
struct ActiveMeditationView: View {

    // MARK: - Properties

    /// ViewModel for timer state management
    @State private var viewModel: TimerViewModel

    /// Navigation state
    @State private var showSessionRecap = false

    /// Whether to show confirmation for early termination
    @State private var showCancelConfirmation = false

    // MARK: - Initialization

    init(viewModel: TimerViewModel) {
        self._viewModel = State(initialValue: viewModel)
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
                .navigationDestination(isPresented: $showSessionRecap) {
                    SessionRecapView(viewModel: viewModel)
                }
            }
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

            // Title
            Text("Meditation in Progress")
                .font(.headline)
                .foregroundColor(.primary)

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
            if viewModel.isRunning {
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
                .controlSize(.regular)
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
                .controlSize(.regular)

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
                .controlSize(.regular)
                .foregroundColor(.red)
            } else if viewModel.isRunning && viewModel.remainingTime <= 0 {
                // Overtime State - "Finish Session" button
                Button(action: {
                    let success = UINotificationFeedbackGenerator()
                    success.notificationOccurred(.success)
                    // Stop timer explicitly before showing recap
                    // This creates the checkpoint and stops audio
                    viewModel.stopTimer()
                    showSessionRecap = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish Session")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(.green) // distinct color to show completion
            } else if viewModel.isCompleted {
                // Complete button (fallback if already stopped)
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showSessionRecap = true
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

    /// End meditation early (before completion)
    private func endMeditationEarly() {
        viewModel.stopTimer()
        showSessionRecap = true
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