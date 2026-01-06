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

    /// Whether to show advanced settings
    @State private var showAdvancedSettings = false

    /// Custom duration input (for advanced mode)
    @State private var customDuration: String = ""

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

                    // Advanced Settings
                    if showAdvancedSettings {
                        advancedSettingsSection
                    }

                    // Start Button
                    startButton

                    // Quick Select
                    quickSelectSection

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
            .onChange(of: selectedDuration) { oldValue, newValue in
                // Update custom duration field when picker changes
                if !showAdvancedSettings {
                    customDuration = String(newValue)
                }
            }

            // Advanced settings toggle
            Button(action: {
                withAnimation {
                    showAdvancedSettings.toggle()
                }
            }) {
                HStack {
                    Text(showAdvancedSettings ? "Simple Mode" : "Advanced Settings")
                    Image(systemName: showAdvancedSettings ? "chevron.down" : "chevron.right")
                }
                .foregroundColor(.accentColor)
            }
        }
    }

    /// Advanced settings section
    private var advancedSettingsSection: some View {
        VStack(spacing: 16) {
            Text("Custom Duration")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                TextField("Enter minutes", text: $customDuration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: customDuration) { oldValue, newValue in
                        // Validate and update selected duration
                        if let minutes = Int(newValue), minutes > 0 {
                            selectedDuration = minutes
                        }
                    }

                Button("Apply") {
                    if let minutes = Int(customDuration), minutes > 0 {
                        selectedDuration = minutes
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .buttonStyle(.bordered)
            }

            // Validation message
            if let minutes = Int(customDuration), minutes <= 0 {
                Text("Please enter a positive number")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .transition(.opacity)
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

    /// Quick select section
    private var quickSelectSection: some View {
        VStack(spacing: 12) {
            Text("Quick Select")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach([5, 10, 15, 20, 30], id: \.self) { minutes in
                    Button(action: {
                        selectedDuration = minutes
                        customDuration = String(minutes)
                    }) {
                        Text("" + String(minutes) + " min")
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(selectedDuration == minutes ? Color.accentColor : Color.gray.opacity(0.1))
                            .foregroundColor(selectedDuration == minutes ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    /// Reset to default values
    private func resetToDefaults() {
        selectedDuration = 10
        customDuration = "10"
        showAdvancedSettings = false
    }
}

// MARK: - Preview

#Preview {
    TimerSetupView()
}