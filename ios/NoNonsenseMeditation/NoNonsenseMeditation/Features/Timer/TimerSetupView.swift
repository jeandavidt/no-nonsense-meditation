//
//  TimerSetupView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Redesigned on 2026-01-20 - Single-screen layout with timer dial preview
//

import SwiftUI

/// View for setting up meditation timer duration and background sound
/// Features a central timer dial preview with horizontal duration chips
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

    /// Navigation state for focus session
    @State private var isFocusActive = false

    /// Navigation state for settings
    @State private var showSettings = false

    /// Whether to show the sound picker sheet
    @State private var showSoundPicker = false

    /// Whether to show the music picker full screen cover
    @State private var showMusicPicker = false

    /// Currently highlighted session type for visual feedback
    @State private var highlightedSessionType: SessionType? = nil

    /// Available duration options
    private let durationOptions = [5, 10, 15, 20, 30, 45, 60, 90]

    // MARK: - Computed Properties

    /// Convert selected duration to seconds
    private var durationInSeconds: TimeInterval {
        return TimeInterval(selectedDuration * 60)
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    // Hero timer dial preview with swipe support
                    SetupTimerDialView(
                        durationMinutes: $selectedDuration,
                        sessionType: highlightedSessionType ?? .meditation
                    )
                    .padding(.bottom, 16)
                    .animation(.easeInOut(duration: 0.3), value: highlightedSessionType)

                    // Duration chips
                    durationChipsSection
                        .padding(.bottom, 16)

                    // Sound selector row
                    soundSelectorRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    Spacer(minLength: 10)

                    // Action buttons
                    startButtonSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16))
                }
            }
            .navigationTitle("No Nonsense")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
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
                ActiveMeditationView(viewModel: viewModel, sessionType: .meditation)
            }
            .navigationDestination(isPresented: $isFocusActive) {
                ActiveMeditationView(viewModel: viewModel, sessionType: .focus)
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsTabView()
            }
            .sheet(isPresented: $showSoundPicker) {
                BackgroundSoundPickerSheet(
                    selectedSound: viewModel.selectedBackgroundSound,
                    onSelect: { sound in
                        selectBackgroundSound(sound)
                    },
                    selectedMusicItem: $viewModel.selectedMusicLibraryItem,
                    onSelectMusic: { item in
                        viewModel.setMusicLibraryItem(item)
                    },
                    showMusicPicker: $showMusicPicker
                )
            }
            .fullScreenCover(isPresented: $showMusicPicker) {
                MusicPickerView(
                    selectedItem: $viewModel.selectedMusicLibraryItem,
                    onSelection: { item in
                        viewModel.setMusicLibraryItem(item)
                    },
                    providesNavigation: true
                )
            }
            .task {
                handlePendingIntentAction()
            }
            .onChange(of: intentCoordinator.pendingAction) { _, _ in
                handlePendingIntentAction()
            }
        }
    }

    // MARK: - Subviews

    /// Horizontal scrolling duration chips
    private var durationChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DURATION")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .tracking(1.2)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        DurationChip(
                            minutes: minutes,
                            isSelected: selectedDuration == minutes,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDuration = minutes
                                    // Save to UserDefaults
                                    UserDefaults.standard.set(minutes, forKey: Constants.UserDefaultsKeys.defaultDuration)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    /// Compact sound selector row
    private var soundSelectorRow: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showSoundPicker = true
        }) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: viewModel.selectedBackgroundSound.iconName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                // Label and value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Background Sound")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if viewModel.selectedBackgroundSound.usesUserLibrary,
                       let item = viewModel.selectedMusicLibraryItem {
                        Text(item.title)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text(viewModel.selectedBackgroundSound.displayName)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    /// Start buttons section
    private var startButtonSection: some View {
        VStack(spacing: 12) {
            // Meditation button - Primary
            Button(action: {
                startMeditation()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                    Text("Start Meditation")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.85)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(selectedDuration <= 0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in highlightedSessionType = .meditation }
                    .onEnded { _ in highlightedSessionType = nil }
            )

            // Focus button - Secondary
            Button(action: {
                startFocusSession()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                    Text("Start Focus Session")
                }
                .font(.headline)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.orange.opacity(0.08))
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedDuration <= 0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in highlightedSessionType = .focus }
                    .onEnded { _ in highlightedSessionType = nil }
            )
        }
    }

    // MARK: - Methods

    /// Select a background sound
    private func selectBackgroundSound(_ sound: AmbianceSound) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        viewModel.setBackgroundSound(sound)

        // Play preview if not "none"
        if sound.id != "none" {
            viewModel.previewBackgroundSound(sound)
        } else {
            viewModel.stopPreview()
        }
    }

    /// Start meditation with selected duration
    private func startMeditation() {
        guard selectedDuration > 0 else { return }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        viewModel.stopPreview()
        viewModel.startTimer(duration: durationInSeconds, sessionType: .meditation)
        isActive = true
    }

    /// Start focus session with selected duration
    private func startFocusSession() {
        guard selectedDuration > 0 else { return }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        viewModel.stopPreview()
        viewModel.startTimer(duration: durationInSeconds, sessionType: .focus)
        isFocusActive = true
    }

    /// Handle pending intent actions from App Intents (Shortcuts, Siri)
    private func handlePendingIntentAction() {
        guard let action = intentCoordinator.pendingAction else { return }

        switch action {
        case .startMeditation(let durationMinutes):
            selectedDuration = durationMinutes

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                viewModel.startTimer(duration: TimeInterval(durationMinutes * 60))
                isActive = true
                intentCoordinator.clearPendingAction()
            }

        case .pauseMeditation, .resumeMeditation, .stopMeditation:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    TimerSetupView()
}
