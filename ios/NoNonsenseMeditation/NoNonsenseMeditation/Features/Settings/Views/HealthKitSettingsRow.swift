//
//  HealthKitSettingsRow.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// Settings row for HealthKit integration
/// Displays current status and allows user to manage HealthKit permissions
struct HealthKitSettingsRow: View {

    // MARK: - Properties

    @Bindable var viewModel: HealthKitViewModel
    @State private var showPermissionSheet = false

    // MARK: - Body

    var body: some View {
        Button {
            showPermissionSheet = true
        } label: {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundStyle(.red.gradient)
                    .frame(width: 32, height: 32)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status indicator
                statusIndicator
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPermissionSheet) {
            HealthKitPermissionView(viewModel: viewModel)
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var statusIndicator: some View {
        switch viewModel.authState {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .denied:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)

        case .notDetermined:
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)

        case .notAvailable:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.secondary)

        case .requesting:
            ProgressView()

        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch viewModel.authState {
        case .authorized:
            return "Connected - Syncing meditation sessions"
        case .denied:
            return "Access denied - Tap to enable"
        case .notDetermined:
            return "Not connected - Tap to enable"
        case .notAvailable:
            return "Not available on this device"
        case .requesting:
            return "Requesting permission..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Preview

#Preview("Authorized") {
    @Previewable @State var viewModel = HealthKitViewModel()
    List {
        HealthKitSettingsRow(viewModel: viewModel)
    }
    .task {
        viewModel.setAuthState(.authorized)
    }
}

#Preview("Not Determined") {
    @Previewable @State var viewModel = HealthKitViewModel()
    List {
        HealthKitSettingsRow(viewModel: viewModel)
    }
    .task {
        viewModel.setAuthState(.notDetermined)
    }
}

#Preview("Denied") {
    @Previewable @State var viewModel = HealthKitViewModel()
    List {
        HealthKitSettingsRow(viewModel: viewModel)
    }
    .task {
        viewModel.setAuthState(.denied)
    }
}
