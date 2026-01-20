//
//  SessionRecapView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Updated on 2026-01-14 - Added session type support for focus sessions
//

import SwiftUI
/// Lightweight value object passed to the recap view to make it deterministic
struct RecapInput: Identifiable, Hashable {
    let id = UUID()
    let plannedDuration: TimeInterval
    let actualDuration: TimeInterval
    let wasOvertimeDiscarded: Bool
    let wasPaused: Bool
    let unlockedAchievements: [Achievement]
    let isSessionValid: Bool
    let sessionType: SessionType

    /// Default initializer for meditation sessions
    init(
        plannedDuration: TimeInterval,
        actualDuration: TimeInterval,
        wasOvertimeDiscarded: Bool,
        wasPaused: Bool,
        unlockedAchievements: [Achievement],
        isSessionValid: Bool,
        sessionType: SessionType = .meditation
    ) {
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.wasOvertimeDiscarded = wasOvertimeDiscarded
        self.wasPaused = wasPaused
        self.unlockedAchievements = unlockedAchievements
        self.isSessionValid = isSessionValid
        self.sessionType = sessionType
    }
}

/// View for displaying meditation session recap
/// Shows statistics and summary of completed meditation session
struct SessionRecapView: View {

    // MARK: - Properties

    /// ViewModel containing session data
    /// Recap input (single source of truth for display)
    @State private var recap: RecapInput

    /// Session statistics
    @State private var statistics: SessionStatistics

    /// Whether to show detailed statistics
    @State private var showDetailedStats = false

    // MARK: - Initialization

    init(recap: RecapInput) {
        self._recap = State(initialValue: recap)

        // Calculate statistics from viewModel data
        // Compute deterministic statistics from the provided recap input
        let plannedDuration = recap.plannedDuration
        let actualDuration = recap.actualDuration
        let wasPaused = recap.wasPaused

        print("[SessionRecapView] init: planned=\(plannedDuration), actualUsed=\(actualDuration), wasOvertimeDiscarded=\(recap.wasOvertimeDiscarded), isSessionValid=\(recap.isSessionValid)")

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
                // Statistics already computed from `recap` on init; nothing else required here.
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
                        recap.isSessionValid ? recap.sessionType.color : Color.red,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.2)
                    .opacity(0.5)

                Image(systemName: recap.isSessionValid ? recap.sessionType.completionIconName : "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(recap.isSessionValid ? recap.sessionType.color : .red)
                    .symbolEffect(.bounce, value: UUID())
            }

            Text(recap.isSessionValid ? "\(recap.sessionType.displayName) Complete!" : "Session Too Short")
                .font(.title)
                .fontWeight(.bold)

            Text(recap.isSessionValid ? sessionCompleteMessage : "This session was too short to count")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    /// Returns the appropriate completion message based on session type
    private var sessionCompleteMessage: String {
        switch recap.sessionType {
        case .meditation:
            return "Great job on completing your meditation session"
        case .focus:
            return "Great job on completing your focus session"
        }
    }

    /// Summary card with key metrics
    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Duration summary
            VStack(spacing: 8) {
                Text("Session Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(recap.wasOvertimeDiscarded ? statistics.formattedPlannedDuration : statistics.formattedActualDuration)
                    .font(.system(size: 36, weight: .bold))
                    .contentTransition(.numericText())

                if !recap.wasOvertimeDiscarded {
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
            }

            Divider()

            // Quick stats with glass containers
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
                .foregroundColor(recap.isSessionValid ? recap.sessionType.color : .secondary)
            }
        }
        .glassSummaryCard(isValid: recap.isSessionValid, sessionType: recap.sessionType)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            (recap.isSessionValid ? recap.sessionType.color : Color.gray).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            (recap.isSessionValid ? recap.sessionType.color : Color.gray).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            (recap.isSessionValid ? recap.sessionType.color : Color.gray).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    /// Achievement section
    private var achievementSection: some View {
        Group {
            if recap.unlockedAchievements.isEmpty {
                EmptyView()
            } else {
                VStack(spacing: 12) {
                    Text(recap.unlockedAchievements.count == 1 ? "Achievement Unlocked!" : "Achievements Unlocked!")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(recap.unlockedAchievements) { achievement in
                        HStack(spacing: 12) {
                            Image(systemName: achievement.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(achievement.color)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(achievement.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .glassAchievementCard(isUnlocked: true, color: achievement.color)
                    }
                }
            }
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
    let actual = viewModel.wasOvertimeDiscarded ? viewModel.totalDuration : viewModel.elapsedTime
    let recap = RecapInput(
        plannedDuration: viewModel.totalDuration,
        actualDuration: actual,
        wasOvertimeDiscarded: viewModel.wasOvertimeDiscarded,
        wasPaused: viewModel.isPaused,
        unlockedAchievements: [],
        isSessionValid: actual >= 15,
        sessionType: .meditation
    )
    return SessionRecapView(recap: recap)
}

#Preview("Focus Session Recap") {
    let viewModel = TimerViewModel()
    viewModel.startTimer(duration: 1500) // 25 minutes for focus
    viewModel.stopTimer()
    let actual = viewModel.wasOvertimeDiscarded ? viewModel.totalDuration : viewModel.elapsedTime
    let recap = RecapInput(
        plannedDuration: viewModel.totalDuration,
        actualDuration: actual,
        wasOvertimeDiscarded: viewModel.wasOvertimeDiscarded,
        wasPaused: viewModel.isPaused,
        unlockedAchievements: [],
        isSessionValid: actual >= 15,
        sessionType: .focus
    )
    return SessionRecapView(recap: recap)
}
