//
//  TimerSetupView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import SwiftUI

/// View for setting up meditation timer duration
/// Allows users to select meditation duration before starting
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

    /// Start meditation with selected duration
    private func startMeditation() {
        // Validate duration
        guard selectedDuration > 0 else { return }

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
