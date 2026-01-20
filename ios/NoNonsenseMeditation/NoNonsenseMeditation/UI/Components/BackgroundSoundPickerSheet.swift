//
//  BackgroundSoundPickerSheet.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-20.
//

import SwiftUI

/// Sheet view for selecting background sounds with navigation to music picker
struct BackgroundSoundPickerSheet: View {

    // MARK: - Properties

    /// Currently selected sound (read-only)
    let selectedSound: AmbianceSound

    /// Callback when a sound is selected
    var onSelect: (AmbianceSound) -> Void

    /// Currently selected music item
    @Binding var selectedMusicItem: MusicLibraryItem?

    /// Callback when music is selected
    var onSelectMusic: ((MusicLibraryItem) -> Void)?

    /// Whether to show music picker
    @Binding var showMusicPicker: Bool

    /// Environment dismiss
    @Environment(\.dismiss) private var dismiss

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            List {
                ForEach(AmbianceSoundLoader.allSounds) { sound in
                    Button(action: {
                        if sound.usesUserLibrary {
                            dismiss()
                            // Small delay to allow sheet to dismiss before showing fullScreenCover
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showMusicPicker = true
                            }
                        } else {
                            onSelect(sound)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Icon
                            Image(systemName: sound.iconName)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Circle())

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

                            // Chevron for music library
                            if sound.usesUserLibrary {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Checkmark for selected
                            if selectedSound.id == sound.id {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Background Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    BackgroundSoundPickerSheet(
        selectedSound: AmbianceSoundLoader.allSounds.first!,
        onSelect: { _ in },
        selectedMusicItem: .constant(nil),
        onSelectMusic: nil,
        showMusicPicker: .constant(false)
    )
}
