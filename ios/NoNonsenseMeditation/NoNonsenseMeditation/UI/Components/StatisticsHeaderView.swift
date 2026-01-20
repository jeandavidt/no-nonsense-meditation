//
//  StatisticsHeaderView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// Reusable header component displaying meditation statistics
/// Shows current streak, total sessions, total time, and weekly activity
struct StatisticsHeaderView: View {

    // MARK: - Properties

    /// Statistics to display
    let statistics: SessionStatistics

    /// Whether to show the weekly breakdown
    let showWeeklyBreakdown: Bool

    /// Color scheme from environment
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    /// Animation trigger for statistic appearance
    @State private var isAnimated = false

    // MARK: - Initialization

    /// Initialize with statistics
    /// - Parameters:
    ///   - statistics: Session statistics to display
    ///   - showWeeklyBreakdown: Whether to show weekly activity breakdown (default: true)
    init(
        statistics: SessionStatistics,
        showWeeklyBreakdown: Bool = true
    ) {
        self.statistics = statistics
        self.showWeeklyBreakdown = showWeeklyBreakdown
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // Section header with title
            sectionHeader
            
            // Main statistics grid
            mainStatisticsGrid

            // Weekly breakdown (if enabled)
            if showWeeklyBreakdown {
                weeklyActivitySection
            }
        }
        .padding(Constants.Layout.cardPadding)
        .glassCard(tint: .green.opacity(0.15), cornerRadius: Constants.Layout.cardCornerRadius)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimated = true
            }
        }
    }

    // MARK: - Subviews

    /// Section header with title
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.orange)
            Text("Meditation Sessions")
                .font(.headline)
            Spacer()
        }
    }

    /// Main statistics grid with three key metrics
    private var mainStatisticsGrid: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // Current streak
            StatisticCard(
                icon: "flame.fill",
                value: "\(statistics.currentStreak)",
                label: "Day Streak",
                iconColor: statistics.hasActiveStreak ? .orange : .gray,
                isAnimated: isAnimated
            )

            // Total sessions
            StatisticCard(
                icon: "checkmark.circle.fill",
                value: "\(statistics.totalSessions)",
                label: "Sessions",
                iconColor: Constants.Colors.accent(for: colorScheme),
                isAnimated: isAnimated
            )

            // Total time
            StatisticCard(
                icon: "clock.fill",
                value: formatTotalTime(statistics.totalMinutes),
                label: "Total Time",
                iconColor: Constants.Colors.success(for: colorScheme),
                isAnimated: isAnimated
            )
        }
    }

    /// Weekly activity breakdown section
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Section header
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatWeeklyTime(statistics.thisWeekMinutes))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            // Weekly progress bar
            weeklyProgressBar
        }
        .padding(.top, Constants.Spacing.small)
    }

    /// Weekly progress bar showing activity
    private var weeklyProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Constants.Colors.accent(for: colorScheme),
                                Constants.Colors.success(for: colorScheme)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: isAnimated ? weeklyProgressWidth(totalWidth: geometry.size.width) : 0,
                        height: 8
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: isAnimated)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Helper Methods

    /// Format total time for display
    /// - Parameter minutes: Total minutes
    /// - Returns: Formatted string (e.g., "5h", "45m")
    private func formatTotalTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let remainingMinutes = Int(minutes) % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(Int(minutes))m"
        }
    }

    /// Format weekly time for display
    /// - Parameter minutes: Weekly minutes
    /// - Returns: Formatted string
    private func formatWeeklyTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let remainingMinutes = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(Int(minutes)) min"
        }
    }

    /// Calculate weekly progress bar width
    /// - Parameter totalWidth: Available width
    /// - Returns: Width for progress bar
    private func weeklyProgressWidth(totalWidth: CGFloat) -> CGFloat {
        // Target: 150 minutes per week (about 21 minutes/day)
        let targetWeeklyMinutes: Double = 150
        let progress = min(statistics.thisWeekMinutes / targetWeeklyMinutes, 1.0)
        return totalWidth * CGFloat(progress)
    }
}

// MARK: - Statistic Card Subview

/// Individual statistic card displaying an icon, value, and label with glass effect
private struct StatisticCard: View {

    // MARK: - Properties

    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    let isAnimated: Bool

    // MARK: - View Body

    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(height: 28)
                .scaleEffect(isAnimated ? 1.0 : 0.5)
                .opacity(isAnimated ? 1.0 : 0.0)

            // Value
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .offset(y: isAnimated ? 0 : 10)
                .opacity(isAnimated ? 1.0 : 0.0)

            // Label
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: isAnimated ? 0 : 10)
                .opacity(isAnimated ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.small)
        .glassStatCard(accentColor: iconColor)
    }
}

// MARK: - Preview

#Preview("Default Statistics") {
    StatisticsHeaderView(
        statistics: SessionStatistics(
            todayMinutes: 20,
            thisWeekMinutes: 95,
            currentStreak: 7,
            totalMinutes: 1250,
            totalSessions: 42,
            averageSessionDuration: 15,
            longestSessionDuration: 30,
            lastSessionDate: Date()
        )
    )
    .padding()
}

#Preview("Zero State") {
    StatisticsHeaderView(
        statistics: SessionStatistics.empty
    )
    .padding()
}

#Preview("High Numbers") {
    StatisticsHeaderView(
        statistics: SessionStatistics(
            todayMinutes: 45,
            thisWeekMinutes: 180,
            currentStreak: 365,
            totalMinutes: 12500,
            totalSessions: 487,
            averageSessionDuration: 25,
            longestSessionDuration: 60,
            lastSessionDate: Date()
        )
    )
    .padding()
}

#Preview("Without Weekly Breakdown") {
    StatisticsHeaderView(
        statistics: SessionStatistics(
            todayMinutes: 20,
            thisWeekMinutes: 95,
            currentStreak: 12,
            totalMinutes: 450,
            totalSessions: 28,
            averageSessionDuration: 16,
            longestSessionDuration: 25,
            lastSessionDate: Date()
        ),
        showWeeklyBreakdown: false
    )
    .padding()
}

#Preview("Dark Mode") {
    StatisticsHeaderView(
        statistics: SessionStatistics(
            todayMinutes: 30,
            thisWeekMinutes: 120,
            currentStreak: 15,
            totalMinutes: 2400,
            totalSessions: 96,
            averageSessionDuration: 20,
            longestSessionDuration: 45,
            lastSessionDate: Date()
        )
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
