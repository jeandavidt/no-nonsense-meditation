//
//  SettingsTabView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// Main Settings view for the app
/// Displays all user preferences, statistics, and data management options
struct SettingsTabView: View {

    // MARK: - Properties

    @State private var viewModel = SettingsViewModel()
    @State private var healthKitViewModel = HealthKitViewModel()
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Statistics Overview Section
                statisticsSection

                // General Settings Section
                generalSettingsSection

                // Audio Settings Section
                audioSettingsSection

                // Notifications Section
                notificationsSection

                // Health Integration Section
                healthIntegrationSection

                // Data Management Section
                dataManagementSection

                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadStatistics()
                await healthKitViewModel.checkAuthorizationStatus()
            }
            .confirmationDialog(
                "Clear All Data",
                isPresented: Binding(
                    get: { viewModel.activeConfirmationDialog == .clearAllData },
                    set: { if !$0 { viewModel.activeConfirmationDialog = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Clear All Data", role: .destructive) {
                    Task {
                        await viewModel.clearAllData()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your meditation sessions. This action cannot be undone.")
            }
            .alert(
                viewModel.activeAlert?.title ?? "",
                isPresented: Binding(
                    get: { viewModel.activeAlert != nil },
                    set: { if !$0 { viewModel.activeAlert = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if let alert = viewModel.activeAlert {
                    Text(alert.message)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - View Components

    /// Statistics overview section
    @ViewBuilder
    private var statisticsSection: some View {
        Section {
            VStack(spacing: Constants.Spacing.medium) {
                StatisticRow(
                    title: "Current Streak",
                    value: "\(viewModel.currentStreak)",
                    unit: viewModel.currentStreak == 1 ? "day" : "days",
                    icon: "flame.fill",
                    iconColor: .orange
                )

                Divider()

                StatisticRow(
                    title: "Total Sessions",
                    value: "\(viewModel.totalSessions)",
                    unit: "sessions",
                    icon: "calendar",
                    iconColor: .blue
                )

                Divider()

                StatisticRow(
                    title: "Total Time",
                    value: viewModel.formattedTotalTime,
                    unit: "",
                    icon: "clock.fill",
                    iconColor: .green
                )

                if let stats = viewModel.statistics {
                    Divider()

                    StatisticRow(
                        title: "Average Duration",
                        value: String(format: "%.0f", stats.averageDuration),
                        unit: "min",
                        icon: "chart.bar.fill",
                        iconColor: .purple
                    )

                    if stats.longestSession > 0 {
                        Divider()

                        StatisticRow(
                            title: "Longest Session",
                            value: String(format: "%.0f", stats.longestSession),
                            unit: "min",
                            icon: "star.fill",
                            iconColor: .yellow
                        )
                    }
                }
            }
            .padding(.vertical, Constants.Spacing.small)
        } header: {
            Text("Statistics")
        }
    }

    /// General settings section
    @ViewBuilder
    private var generalSettingsSection: some View {
        Section {
            // Default Duration Picker
            Picker("Default Duration", selection: $viewModel.defaultDuration) {
                ForEach(viewModel.durationOptions, id: \.self) { duration in
                    Text("\(duration) min").tag(duration)
                }
            }

            // Keep Screen Awake Toggle
            Toggle(isOn: $viewModel.keepScreenAwake) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep Screen Awake")
                        Text("Prevents screen from dimming during meditation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.yellow)
                }
            }

            // Haptic Feedback Toggle
            Toggle(isOn: $viewModel.hapticFeedbackEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptic Feedback")
                        Text("Vibrate on timer events")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("General")
        }
    }

    /// Audio settings section
    @ViewBuilder
    private var audioSettingsSection: some View {
        Section {
            // Bell Sound Picker
            Picker("Bell Sound", selection: $viewModel.selectedBellSound) {
                ForEach(SettingsViewModel.BellSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }

            // Override Silent Mode Toggle
            if viewModel.selectedBellSound != .none {
                Toggle(isOn: $viewModel.overrideSilentMode) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Override Silent Mode")
                            Text("Play sounds even when device is on silent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        } header: {
            Text("Audio")
        } footer: {
            Text("Bell sounds play at the start and end of your meditation session.")
        }
    }

    /// Notifications section
    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            // Daily Reminder Toggle
            Toggle(isOn: $viewModel.dailyReminderEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                        Text("Get reminded to meditate every day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.red)
                }
            }
            .onChange(of: viewModel.dailyReminderEnabled) { oldValue, newValue in
                if newValue && !viewModel.notificationsEnabled {
                    Task {
                        await viewModel.requestNotificationPermissions()
                    }
                }
            }

            // Reminder Time Picker
            if viewModel.dailyReminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $viewModel.dailyReminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Notifications")
        } footer: {
            if viewModel.dailyReminderEnabled {
                Text("You'll receive a daily notification at your chosen time.")
            }
        }
    }

    /// Health integration section
    @ViewBuilder
    private var healthIntegrationSection: some View {
        Section {
            // HealthKit Settings Row
            HealthKitSettingsRow(viewModel: healthKitViewModel)

            // iCloud Sync Toggle
            Toggle(isOn: $viewModel.iCloudSyncEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                        Text("Sync data across your devices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("Integration")
        } footer: {
            Text("Sync your meditation sessions to Apple Health and across your devices with iCloud.")
        }
    }

    /// Data management section
    @ViewBuilder
    private var dataManagementSection: some View {
        Section {
            // Export Data Button
            Button {
                Task {
                    if let url = await viewModel.exportData() {
                        exportedFileURL = url
                        showShareSheet = true
                    }
                }
            } label: {
                Label {
                    if viewModel.isExporting {
                        HStack {
                            Text("Exporting...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Export Data")
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.blue)
                }
            }
            .disabled(viewModel.isExporting)

            // Clear All Data Button
            Button(role: .destructive) {
                viewModel.showClearDataConfirmation()
            } label: {
                Label {
                    if viewModel.isClearing {
                        HStack {
                            Text("Clearing...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Clear All Data")
                    }
                } icon: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
            .disabled(viewModel.isClearing)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your meditation data as JSON or permanently delete all sessions.")
        }
    }

    /// About section
    @ViewBuilder
    private var aboutSection: some View {
        Section {
            // Version Info
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(.secondary)
            }

            // Privacy Policy Link
            Link(destination: URL(string: "https://github.com/jeandavidt/no-nonsense-meditation")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            // Support Link
            Link(destination: URL(string: "https://github.com/jeandavidt/no-nonsense-meditation/issues")!) {
                Label("Support & Feedback", systemImage: "envelope.fill")
            }

            // Source Code Link
            Link(destination: URL(string: "https://github.com/jeandavidt/no-nonsense-meditation")!) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } header: {
            Text("About")
        } footer: {
            VStack(alignment: .center, spacing: Constants.Spacing.small) {
                Text("No Nonsense Meditation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("A simple, focused meditation timer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Constants.Spacing.medium)
        }
    }
}

// MARK: - Supporting Views

/// Statistic row component for displaying key metrics
private struct StatisticRow: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor.gradient)
                .frame(width: 40, height: 40)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
    }
}

/// Share sheet for exporting data
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Settings Tab") {
    SettingsTabView()
}

#Preview("Settings with Data") {
    @Previewable @State var viewModel = SettingsViewModel()
    NavigationStack {
        List {
            Section {
                VStack(spacing: Constants.Spacing.medium) {
                    StatisticRow(
                        title: "Current Streak",
                        value: "7",
                        unit: "days",
                        icon: "flame.fill",
                        iconColor: .orange
                    )

                    Divider()

                    StatisticRow(
                        title: "Total Sessions",
                        value: "42",
                        unit: "sessions",
                        icon: "calendar",
                        iconColor: .blue
                    )

                    Divider()

                    StatisticRow(
                        title: "Total Time",
                        value: "10h 30m",
                        unit: "",
                        icon: "clock.fill",
                        iconColor: .green
                    )
                }
                .padding(.vertical, Constants.Spacing.small)
            } header: {
                Text("Statistics")
            }
        }
        .navigationTitle("Settings")
    }
}
