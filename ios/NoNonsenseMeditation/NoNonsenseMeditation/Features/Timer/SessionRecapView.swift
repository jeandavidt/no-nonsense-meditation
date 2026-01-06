//
//  SessionRecapView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// View for displaying meditation session recap
/// Shows statistics and summary of completed meditation session
struct SessionRecapView: View {

    // MARK: - Properties

    /// ViewModel containing session data
    @State private var viewModel: TimerViewModel

    /// Session statistics
    @State private var statistics: SessionStatistics

    /// Whether to show detailed statistics
    @State private var showDetailedStats = false

    // MARK: - Initialization

    init(viewModel: TimerViewModel) {
        self._viewModel = State(initialValue: viewModel)
        
        // Calculate statistics from viewModel data
        let plannedDuration = viewModel.totalDuration
        let actualDuration = viewModel.elapsedTime
        let wasPaused = viewModel.isPaused
        
        self._statistics = State(initialValue: SessionStatistics(
            plannedDuration: plannedDuration,
            actualDuration: actualDuration,
            wasPaused: wasPaused
        ))
    }

    // MARK: - View Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Summary Card
                summaryCard

                // Statistics
                if showDetailedStats {
                    detailedStatisticsSection
                }

                // Action Buttons
                actionButtonsSection

                Spacer()
            }
            .padding()
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Belt and suspenders: ensure audio is stopped
                if viewModel.isRunning {
                    viewModel.stopTimer()
                }
            }
        }
    }

    // MARK: - Subviews

    /// Header section with celebration animation
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Celebration animation
            ZStack {
                Circle()
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.2)
                    .opacity(0.5)

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: UUID())
            }

            Text("Meditation Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text("Great job on completing your meditation session")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    /// Summary card with key metrics
    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Duration summary
            VStack(spacing: 8) {
                Text("Session Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(statistics.formattedActualDuration)
                    .font(.system(size: 36, weight: .bold))
                    .contentTransition(.numericText())

                if statistics.durationDifference > 0 {
                    Text(statistics.formattedDurationDifference)
                        .font(.caption)
                        .foregroundColor(.green)
                } else if statistics.durationDifference < 0 {
                    Text(statistics.formattedDurationDifference)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Divider()

            // Quick stats
            HStack(spacing: 16) {
                statItem("Planned", statistics.formattedPlannedDuration)
                statItem("Focus", statistics.focusPercentage + "%")
            }

            // Toggle for detailed stats
            Button(action: {
                withAnimation {
                    showDetailedStats.toggle()
                }
            }) {
                HStack {
                    Text(showDetailedStats ? "Hide Details" : "View Details")
                    Image(systemName: showDetailedStats ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    /// Detailed statistics section
    private var detailedStatisticsSection: some View {
        VStack(spacing: 16) {
            // Session quality
            VStack(spacing: 8) {
                Text("Session Quality")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    qualityIndicator("Focus Time", statistics.focusPercentage + "%")
                    qualityIndicator("Completion", statistics.completionPercentage + "%")
                }
            }

            // Time breakdown
            if statistics.wasPaused {
                VStack(spacing: 8) {
                    Text("Time Breakdown")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        timeBreakdownItem("Active", statistics.formattedActualDuration)
                        timeBreakdownItem("Paused", "00:00") // Would track actual pause time in full implementation
                    }
                }
            }

            // Achievement
            achievementSection
        }
        .transition(.opacity)
    }

    /// Action buttons section
    private var actionButtonsSection: some View {
        // Intentionally empty - users should use back button
        EmptyView()
    }

    // MARK: - Helper Views

    /// Stat item for summary card
    private func statItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    /// Quality indicator
    private func qualityIndicator(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    /// Time breakdown item
    private func timeBreakdownItem(_ title: String, _ value: String) -> some View {
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

    /// Achievement section
    private var achievementSection: some View {
        VStack(spacing: 12) {
            Text("Achievement Unlocked")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)

                Text("First Session Complete")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("You've completed your first meditation session!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
        }
    }

    // MARK: - Methods

    /// Calculate additional statistics
    private func calculateAdditionalStats() {
        // In a full implementation, this would calculate:
        // - Streak information
        // - Historical comparison
        // - Achievement progress
        // For now, we'll use the basic statistics
    }
}

// MARK: - Preview

#Preview {
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 300)
    viewModel.stopTimer()
    return SessionRecapView(viewModel: viewModel)
}

#Preview("Short Session") {
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 60)
    viewModel.stopTimer()
    return SessionRecapView(viewModel: viewModel)
}