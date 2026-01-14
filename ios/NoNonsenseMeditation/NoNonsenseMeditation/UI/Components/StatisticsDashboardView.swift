//
//  StatisticsDashboardView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//  Updated on 2026-01-14 - Added focus session statistics
//

import SwiftUI

/// Dashboard view that displays meditation statistics with data source toggle
struct StatisticsDashboardView: View {

    @State private var viewModel = StatisticsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Data source picker (if HealthKit available)
                if viewModel.isHealthKitAvailable {
                    dataSourcePicker
                        .padding(.horizontal)
                }

                // Statistics display
                if viewModel.isLoading {
                    ProgressView("Loading statistics...")
                        .padding()
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    StatisticsHeaderView(
                        statistics: viewModel.statistics,
                        showWeeklyBreakdown: true
                    )

                    // Focus session statistics
                    FocusStatisticsCardView(statistics: viewModel.statistics)
                }

                // Achievements Gallery
                AchievementsGalleryView()
            }
        }
        .task {
            await viewModel.checkHealthKitAvailability()
            await viewModel.loadStatistics()
            await viewModel.loadFocusStatistics()
        }
    }

    // MARK: - Subviews

    private var dataSourcePicker: some View {
        Picker("Data Source", selection: Binding(
            get: { viewModel.dataSourceMode },
            set: { newMode in
                Task {
                    await viewModel.setDataSourceMode(newMode)
                }
            }
        )) {
            ForEach(StatisticsViewModel.DataSourceMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Failed to load statistics")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await viewModel.loadStatistics()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Focus Statistics Card

/// Card view displaying focus session statistics with meditation-style UI
struct FocusStatisticsCardView: View {

    let statistics: SessionStatistics

    @State private var isAnimated = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Section header with title
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.orange)
                Text("Focus Sessions")
                    .font(.headline)
                Spacer()
            }

            // Main metrics grid
            HStack(spacing: 12) {
                // Today's focus time
                FocusStatCard(
                    icon: "sun.max.fill",
                    iconColor: .orange,
                    value: formatMinutes(statistics.focusTodayMinutes),
                    label: "Today",
                    isAnimated: isAnimated
                )

                // This week focus time
                FocusStatCard(
                    icon: "calendar",
                    iconColor: .blue,
                    value: formatMinutes(statistics.focusThisWeekMinutes),
                    label: "This Week",
                    isAnimated: isAnimated
                )

                // Focus streak
                FocusStatCard(
                    icon: "flame.fill",
                    iconColor: statistics.focusCurrentStreak > 0 ? .orange : .gray,
                    value: "\(statistics.focusCurrentStreak)",
                    label: "Streak",
                    isAnimated: isAnimated,
                    isCompact: true
                )
            }

            // Focus sessions count
            HStack {
                Text("Total Focus Sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(statistics.focusTotalSessions)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(backgroundGradient)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimated = true
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color(white: 0.15)
                    : Color(white: 0.98),
                colorScheme == .dark
                    ? Color(white: 0.12)
                    : Color(white: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

/// Individual focus statistic card
private struct FocusStatCard: View {

    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let isAnimated: Bool
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(height: 22)
                .scaleEffect(isAnimated ? 1.0 : 0.5)
                .opacity(isAnimated ? 1.0 : 0.0)

            Text(value)
                .font(isCompact ? .title3 : .title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .offset(y: isAnimated ? 0 : 10)
                .opacity(isAnimated ? 1.0 : 0.0)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
                .offset(y: isAnimated ? 0 : 10)
                .opacity(isAnimated ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

#Preview {
    StatisticsDashboardView()
}
