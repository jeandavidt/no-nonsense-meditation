//
//  HealthKitPermissionView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// View for requesting HealthKit permissions
/// Provides clear messaging and handles various authorization states
struct HealthKitPermissionView: View {

    // MARK: - Properties

    @Bindable var viewModel: HealthKitViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with icon
                headerSection

                // Main content based on state
                ScrollView {
                    VStack(spacing: 32) {
                        contentSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }

                // Bottom action buttons
                Spacer()
                actionSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not Now") {
                        viewModel.dismissPermissionView()
                        dismiss()
                    }
                    .disabled(viewModel.authState == .requesting)
                }
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Health icon
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.gradient)
                .padding(.top, 40)

            // Title
            Text("Health Integration")
                .font(.title2.bold())

            // Subtitle
            Text("Track your meditation practice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.authState {
        case .notDetermined:
            initialRequestContent
        case .requesting:
            requestingContent
        case .authorized:
            authorizedContent
        case .denied:
            deniedContent
        case .notAvailable:
            notAvailableContent
        case .error(let message):
            errorContent(message)
        }
    }

    private var initialRequestContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Benefits section
            VStack(alignment: .leading, spacing: 16) {
                Text("Why connect to Health?")
                    .font(.headline)

                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "See your meditation minutes in Apple Health alongside other wellness data"
                )

                benefitRow(
                    icon: "trophy.fill",
                    title: "Close Activity Rings",
                    description: "Mindful minutes contribute to your daily wellness goals"
                )

                benefitRow(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Your meditation data stays on your device. We never see it."
                )
            }

            // Privacy note
            privacyNote
        }
    }

    private var requestingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Requesting permission...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var authorizedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.title3.bold())

                Text("Your meditation sessions will now sync to Apple Health")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var deniedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Health Access Needed")
                    .font(.headline)

                Text("To sync your meditation sessions to Apple Health, you'll need to enable permissions in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Steps to enable
            VStack(alignment: .leading, spacing: 16) {
                Text("How to enable:")
                    .font(.headline)

                stepRow(number: 1, text: "Tap 'Open Settings' below")
                stepRow(number: 2, text: "Find 'Health' in the app settings")
                stepRow(number: 3, text: "Enable 'Mindful Minutes' sharing")
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Privacy reassurance
            privacyNote
        }
    }

    private var notAvailableContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Health Not Available")
                    .font(.title3.bold())

                Text("Apple Health is not available on this device. Your meditation sessions will still be saved locally.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3.bold())

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 12) {
            switch viewModel.authState {
            case .notDetermined:
                Button {
                    Task {
                        await viewModel.requestAuthorization()
                    }
                } label: {
                    Text("Enable Health Sync")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .requesting:
                EmptyView()

            case .authorized:
                Button {
                    viewModel.dismissPermissionView()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .denied:
                VStack(spacing: 12) {
                    Button {
                        viewModel.openSettings()
                    } label: {
                        Text("Open Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        viewModel.dismissPermissionView()
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

            case .notAvailable:
                Button {
                    viewModel.dismissPermissionView()
                    dismiss()
                } label: {
                    Text("Got It")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .error:
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.requestAuthorization()
                        }
                    } label: {
                        Text("Try Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        viewModel.dismissPermissionView()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Helper Views

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.tint))

            Text(text)
                .font(.subheadline)
        }
    }

    private var privacyNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.tint)

            Text("Your data stays private and secure on your device")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("Not Determined") {
    @Previewable @State var viewModel = HealthKitViewModel()
    HealthKitPermissionView(viewModel: viewModel)
        .task {
            viewModel.setAuthState(.notDetermined)
        }
}

#Preview("Authorized") {
    @Previewable @State var viewModel = HealthKitViewModel()
    HealthKitPermissionView(viewModel: viewModel)
        .task {
            viewModel.setAuthState(.authorized)
        }
}

#Preview("Denied") {
    @Previewable @State var viewModel = HealthKitViewModel()
    HealthKitPermissionView(viewModel: viewModel)
        .task {
            viewModel.setAuthState(.denied)
        }
}

#Preview("Not Available") {
    @Previewable @State var viewModel = HealthKitViewModel()
    HealthKitPermissionView(viewModel: viewModel)
        .task {
            viewModel.setAuthState(.notAvailable)
        }
}
