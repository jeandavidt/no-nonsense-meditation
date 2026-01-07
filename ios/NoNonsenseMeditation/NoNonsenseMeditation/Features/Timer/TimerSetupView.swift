//
//  TimerSetupView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Updated on 2026-01-06 - Added background sound selection
//

import SwiftUI

/// View for setting up meditation timer duration and background sound
/// Allows users to select meditation duration and optional background audio before starting
struct TimerSetupView: View {

    // MARK: - Properties

    /// ViewModel for timer state management
    @State private var viewModel = TimerViewModel()

    /// Intent coordinator for handling App Intent actions
    @State private var intentCoordinator = IntentCoordinator.shared

    /// Selected duration in minutes (loaded from UserDefaults)
    @State private var selectedDuration: Int = {
        let savedDuration = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.defaultDuration)
        return savedDuration == 0 ? Constants.Timer.defaultDuration : savedDuration
    }()

    /// Navigation state for meditation
    @State private var isActive = false

    /// Navigation state for settings
    @State private var showSettings = false

    /// Available duration options
    private let durationOptions = [1, 5, 10, 15, 20, 30, 45, 60, 90, 120]

    // MARK: - Computed Properties

    /// Convert selected duration to seconds
    private var durationInSeconds: TimeInterval {
        return TimeInterval(selectedDuration * 60)
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.bottom, 20)

                // Duration Picker (scrollable)
                durationPickerSection
                    .padding(.bottom, 24)

                // Background Sound Picker (scrollable section)
                backgroundSoundSection
                    .padding(.bottom, 32)

                // Start Button (always visible)
                startButtonSection
            }
            .padding()
            .navigationTitle("Setup Meditation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationDestination(isPresented: $isActive) {
                ActiveMeditationView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsTabView()
            }
            .task {
                // Handle pending intent actions when view appears
                handlePendingIntentAction()
            }
            .onChange(of: intentCoordinator.pendingAction) { _, _ in
                // Handle new intent actions that arrive while view is visible
                handlePendingIntentAction()
            }
        }
    }

    // MARK: - Subviews

    /// Header section with app icon and title
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.accentColor)
                .padding(10)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            Text("No Nonsense Meditation")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    /// Duration picker section
    private var durationPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)
                .padding(.horizontal, 4)

            Picker("Duration", selection: $selectedDuration) {
                ForEach(durationOptions, id: \.self) { minutes in
                    if minutes < 60 {
                        Text("\(minutes) minutes")
                            .tag(minutes)
                    } else {
                        let hours = minutes / 60
                        let remainingMins = minutes % 60
                        if remainingMins == 0 {
                            Text("\(hours) hour\(hours > 1 ? "s" : "")")
                                .tag(minutes)
                        } else {
                            Text("\(hours) hour\(hours > 1 ? "s" : "") \(remainingMins) min")
                                .tag(minutes)
                        }
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Background sound selection section
    private var backgroundSoundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Sound")
                .font(.headline)
                .padding(.horizontal, 4)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(BackgroundSound.allCases) { sound in
                        backgroundSoundRow(for: sound)

                        if sound != BackgroundSound.allCases.last {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Individual background sound row
    private func backgroundSoundRow(for sound: BackgroundSound) -> some View {
        Button(action: {
            selectBackgroundSound(sound)
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: sound.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(sound.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark
                if viewModel.selectedBackgroundSound == sound {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Start button section with enhanced visual separation
    private var startButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                startMeditation()
            }) {
                Text("Start Meditation")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedDuration <= 0)
        }
        .padding(.top, 8)
    }

    // MARK: - Methods

    /// Select a background sound
    private func selectBackgroundSound(_ sound: BackgroundSound) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        viewModel.setBackgroundSound(sound)

        // Play preview if not "none"
        if sound != .none {
            viewModel.previewBackgroundSound(sound)
        } else {
            viewModel.stopPreview()
        }
    }

    /// Start meditation with selected duration
    private func startMeditation() {
        // Validate duration
        guard selectedDuration > 0 else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Stop any preview playback
        viewModel.stopPreview()

        // Start timer
        viewModel.startTimer(duration: durationInSeconds)

        // Navigate to active meditation view
        isActive = true
    }

    /// Handle pending intent actions from App Intents (Shortcuts, Siri)
    private func handlePendingIntentAction() {
        guard let action = intentCoordinator.pendingAction else { return }

        switch action {
        case .startMeditation(let durationMinutes):
            // Set the duration from the intent
            selectedDuration = durationMinutes

            // Small delay to ensure view is ready
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Start meditation with intent duration
                viewModel.startTimer(duration: TimeInterval(durationMinutes * 60))

                // Navigate to active meditation view
                isActive = true

                // Clear the pending action
                intentCoordinator.clearPendingAction()
            }

        case .pauseMeditation, .resumeMeditation, .stopMeditation:
            // These actions should be handled by ActiveMeditationView
            // Not applicable in TimerSetupView
            break
        }
    }
}

// MARK: - Preview

#Preview {
    TimerSetupView()
}
