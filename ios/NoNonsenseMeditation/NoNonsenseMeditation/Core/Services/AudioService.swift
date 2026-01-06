//
//  AudioService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//

import Foundation
import AVFoundation

/// Actor responsible for playing meditation bell sounds
/// Manages audio session configuration and sound playback
actor AudioService {

    // MARK: - Types

    /// Audio service errors
    enum AudioError: Error, LocalizedError {
        case soundNotFound
        case playbackFailed(Error)

        var errorDescription: String? {
            switch self {
            case .soundNotFound:
                return "Bell sound file not found"
            case .playbackFailed(let error):
                return "Failed to play sound: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    /// Audio player instance
    private var audioPlayer: AVAudioPlayer?

    /// Whether to override silent mode
    private var overrideSilentMode: Bool = false

    // MARK: - Configuration

    /// Configure audio session settings
    /// - Parameter overrideSilent: Whether to play sound even in silent mode
    func configureAudioSession(overrideSilent: Bool) async throws {
        self.overrideSilentMode = overrideSilent

        let session = AVAudioSession.sharedInstance()

        do {
            // Set category based on silent mode override preference
            if overrideSilent {
                // Playback category plays even in silent mode
                try session.setCategory(.playback, mode: .default)
            } else {
                // Ambient category respects silent mode
                try session.setCategory(.ambient, mode: .default)
            }

            try session.setActive(true)
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    // MARK: - Playback

    /// Play the meditation bell sound
    /// - Parameter soundName: Name of the sound file (without extension)
    /// - Throws: AudioError if playback fails
    func playBell(soundName: String = "meditation_bell") async throws {
        // Configure audio session
        try await configureAudioSession(overrideSilent: overrideSilentMode)

        // Locate sound file in bundle
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            throw AudioError.soundNotFound
        }

        do {
            // Create and configure audio player
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            player.play()

            self.audioPlayer = player
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    /// Stop any currently playing sound
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    /// Set whether to override silent mode
    /// - Parameter override: True to play sound even in silent mode
    func setSilentModeOverride(_ override: Bool) {
        self.overrideSilentMode = override
    }

    // MARK: - Convenience Methods for Timer Events

    /// Play start sound when timer begins
    func playStartSound() {
        Task {
            try? await playBell(soundName: "meditation_start")
        }
    }

    /// Play pause sound when timer is paused
    func playPauseSound() {
        Task {
            try? await playBell(soundName: "meditation_pause")
        }
    }

    /// Play resume sound when timer is resumed
    func playResumeSound() {
        Task {
            try? await playBell(soundName: "meditation_resume")
        }
    }

    /// Play completion sound when timer finishes
    func playCompletionSound() {
        Task {
            try? await playBell(soundName: "meditation_completion")
        }
    }
}
