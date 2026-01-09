//
//  StatisticsDashboardView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-08.
//

import SwiftUI

/// Dashboard view that displays meditation statistics with data source toggle
struct StatisticsDashboardView: View {

    @State private var viewModel = StatisticsViewModel()

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
                }

                // Achievements Gallery
                AchievementsGalleryView()
            }
        }
        .task {
            await viewModel.checkHealthKitAvailability()
            await viewModel.loadStatistics()
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

#Preview {
    StatisticsDashboardView()
}
