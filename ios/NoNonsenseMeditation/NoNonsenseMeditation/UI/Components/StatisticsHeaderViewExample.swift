//
//  StatisticsHeaderViewExample.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//
//  Example usage of StatisticsHeaderView component

import SwiftUI

/// Example view demonstrating various use cases of StatisticsHeaderView
struct StatisticsHeaderViewExample: View {

    // MARK: - State

    @State private var selectedTab = 0

    // MARK: - Sample Data

    private let sampleStatistics = SessionStatistics(
        todayMinutes: 20,
        thisWeekMinutes: 95,
        currentStreak: 7,
        totalMinutes: 1250,
        totalSessions: 42,
        averageSessionDuration: 15,
        longestSessionDuration: 30,
        lastSessionDate: Date()
    )

    private let emptyStatistics = SessionStatistics.empty

    private let impressiveStatistics = SessionStatistics(
        todayMinutes: 45,
        thisWeekMinutes: 180,
        currentStreak: 365,
        totalMinutes: 12500,
        totalSessions: 487,
        averageSessionDuration: 25,
        longestSessionDuration: 60,
        lastSessionDate: Date()
    )

    // MARK: - View Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Standard usage with full breakdown
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Standard Usage")
                            .font(.headline)
                            .padding(.horizontal)

                        StatisticsHeaderView(
                            statistics: sampleStatistics,
                            showWeeklyBreakdown: true
                        )
                        .padding(.horizontal)
                    }

                    Divider()

                    // Without weekly breakdown
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Without Weekly Breakdown")
                            .font(.headline)
                            .padding(.horizontal)

                        StatisticsHeaderView(
                            statistics: sampleStatistics,
                            showWeeklyBreakdown: false
                        )
                        .padding(.horizontal)
                    }

                    Divider()

                    // Zero state (new user)
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Zero State (New User)")
                            .font(.headline)
                            .padding(.horizontal)

                        StatisticsHeaderView(
                            statistics: emptyStatistics
                        )
                        .padding(.horizontal)

                        Text("Great for showing new users what to expect")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    Divider()

                    // Impressive stats
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Impressive Stats (Long-time User)")
                            .font(.headline)
                            .padding(.horizontal)

                        StatisticsHeaderView(
                            statistics: impressiveStatistics
                        )
                        .padding(.horizontal)

                        Text("365-day streak milestone!")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                    }

                    Divider()

                    // In a card/list context
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("In a List Context")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: Constants.Spacing.medium) {
                            StatisticsHeaderView(statistics: sampleStatistics)

                            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                                Text("Recent Sessions")
                                    .font(.headline)

                                ForEach(0..<3) { index in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading) {
                                            Text("Session \(index + 1)")
                                                .font(.subheadline)
                                            Text("15 minutes")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("Today")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(white: 0.95))
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(white: 0.98))
                            .cornerRadius(Constants.Layout.cardCornerRadius)
                        }
                        .padding(.horizontal)
                    }

                    Divider()

                    // Integration example
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Integration Example")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Use in your main view like this:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        codeExample
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics Header Examples")
        }
    }

    // MARK: - Subviews

    /// Code example view
    private var codeExample: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("""
            @StateObject private var sessionManager = SessionManager()

            var body: some View {
                ScrollView {
                    VStack(spacing: 24) {
                        // Statistics at the top
                        StatisticsHeaderView(
                            statistics: sessionManager.statistics
                        )

                        // Rest of your content...
                    }
                    .padding()
                }
            }
            """)
            .font(.system(.caption, design: .monospaced))
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    StatisticsHeaderViewExample()
}

#Preview("Dark Mode") {
    StatisticsHeaderViewExample()
        .preferredColorScheme(.dark)
}
