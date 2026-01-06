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

    /// Selected duration in minutes
    @State private var selectedDuration: Int = 10

    /// Navigation state
    @State private var isActive = false

    /// Available duration options
    private let durationOptions = [1, 5, 10, 15, 20, 30, 45, 60, 90, 120]

    // MARK: - Computed Properties

    /// Convert selected duration to seconds
    private var durationInSeconds: TimeInterval {
        return TimeInterval(selectedDuration * 60)
    }

    /// Formatted duration string
    private var formattedDuration: String {
        if selectedDuration < 60 {
            return "" + String(selectedDuration) + " minutes"
        } else {
            let hours = selectedDuration / 60
            let minutes = selectedDuration % 60
            if minutes == 0 {
                return "" + String(hours) + " hour" + (hours > 1 ? "s" : "")
            } else {
                return "" + String(hours) + " hour" + (hours > 1 ? "s" : "") + " " + String(minutes) + " minutes"
            }
        }
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Duration Picker
                    durationPickerSection

                    // Background Sound Picker
                    backgroundSoundSection

                    // Start Button
                    startButton

                    Spacer()
                }
                .padding()
                .navigationTitle("Setup Meditation")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $isActive) {
                    ActiveMeditationView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Subviews

    /// Header section with app icon and title
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
                .padding(12)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            Text("No Nonsense Meditation")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Set your meditation duration")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    /// Duration picker section
    private var durationPickerSection: some View {
        VStack(spacing: 16) {
            // Duration display
            Text(formattedDuration)
                .font(.system(size: 48, weight: .bold))
                .contentTransition(.numericText())
                .id("duration-display")

            // Picker
            Picker("Duration", selection: $selectedDuration) {
                ForEach(durationOptions, id: \.self) { minutes in
                    Text("" + String(minutes) + " min")
                        .tag(minutes)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()
        }
    }

    /// Background sound selection section
    private var backgroundSoundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Sound")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(BackgroundSound.allCases) { sound in
                    backgroundSoundRow(for: sound)

                    if sound != BackgroundSound.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
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

    /// Start button
    private var startButton: some View {
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

    // MARK: - Methods

    /// Select a background sound
    private func selectBackgroundSound(_ sound: BackgroundSound) {
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

        // Stop any preview playback
        viewModel.stopPreview()

        // Start timer
        viewModel.startTimer(duration: durationInSeconds)

        // Navigate to active meditation view
        isActive = true
    }
}

// MARK: - Preview

#Preview {
    TimerSetupView()
}
