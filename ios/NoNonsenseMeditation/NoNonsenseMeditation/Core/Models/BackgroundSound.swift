//
//  BackgroundSound.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-06.
//

import Foundation

/// Available background sounds for meditation sessions
/// Provides options for ambient audio during meditation
enum BackgroundSound: String, CaseIterable, Identifiable, Codable, Sendable {
    case none = "none"
    case brownNoise = "brown_noise"
    case libraryAmbience = "library_noise"
    case windChimes = "wind_chimes"

    // MARK: - Identifiable Conformance

    var id: String { rawValue }

    // MARK: - Display Properties

    /// User-facing display name for the sound
    var displayName: String {
        switch self {
        case .none:
            return "No Background Sound"
        case .brownNoise:
            return "Brown Noise"
        case .libraryAmbience:
            return "Library Ambience"
        case .windChimes:
            return "Wind Chimes"
        }
    }

    /// SF Symbol icon name for the sound
    var iconName: String {
        switch self {
        case .none:
            return "speaker.slash"
        case .brownNoise:
            return "waveform"
        case .libraryAmbience:
            return "building.2"
        case .windChimes:
            return "wind"
        }
    }

    /// Short description of the sound
    var description: String {
        switch self {
        case .none:
            return "Silence"
        case .brownNoise:
            return "Deep ambient noise"
        case .libraryAmbience:
            return "Quiet study atmosphere"
        case .windChimes:
            return "Gentle chimes"
        }
    }

    // MARK: - Audio Properties

    /// Filename for the audio resource (without extension)
    var filename: String? {
        switch self {
        case .none:
            return nil
        case .brownNoise, .libraryAmbience, .windChimes:
            return rawValue
        }
    }

    /// File extension for the audio resource
    var fileExtension: String {
        return "m4a"
    }

    /// Whether this sound requires an audio file
    var requiresFile: Bool {
        return self != .none
    }
}

// MARK: - UserDefaults Persistence

extension BackgroundSound {
    /// UserDefaults key for storing selected background sound
    private static let userDefaultsKey = "selectedBackgroundSound"

    /// Save the background sound preference to UserDefaults
    func saveToUserDefaults() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }

    /// Load the background sound preference from UserDefaults
    /// - Returns: The saved background sound, or .none if not found
    static func loadFromUserDefaults() -> BackgroundSound {
        guard let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
              let sound = BackgroundSound(rawValue: rawValue) else {
            return .none
        }
        return sound
    }
}
