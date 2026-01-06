//
//  AudioService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-05.
//  Updated on 2026-01-06 - Added background sound support
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit
/// Protocol for AudioService to enable mocking
protocol AudioServiceProtocol: Actor {
    func configureAudioSession(overrideSilent: Bool) async throws
    func playBell(soundName: String) async throws
    func playStartSound() async throws
    func playPauseSound() async throws
    func playResumeSound() async throws
    func playCompletionSound()

    func startBackgroundSound(_ sound: BackgroundSound) async throws
    func pauseBackgroundSound()
    func resumeBackgroundSound()
    func stopBackgroundSound()

    func previewBackgroundSound(_ sound: BackgroundSound, duration: TimeInterval) async throws
    func stopPreview()

    func setSilentModeOverride(_ override: Bool)

    func updateNowPlayingInfo(title: String, artist: String, duration: TimeInterval?, elapsed: TimeInterval?, playbackRate: Float)
}

/// Actor responsible for playing meditation bell sounds and background audio
/// Manages audio session configuration and sound playback
actor AudioService: AudioServiceProtocol {

    // MARK: - Types

    /// Audio service errors
    enum AudioError: Error, LocalizedError {
        case soundNotFound
        case playbackFailed(Error)

        var errorDescription: String? {
            switch self {
            case .soundNotFound:
                return "Sound file not found"
            case .playbackFailed(let error):
                return "Failed to play sound: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    /// Audio player for bell sounds (one-shot playback)
    private var bellPlayer: AVAudioPlayer?

    /// Audio player for background sounds (looping playback)
    private var backgroundPlayer: AVAudioPlayer?

    /// Currently playing background sound
    private var currentBackgroundSound: BackgroundSound = .none

    /// Whether to override silent mode
    private var overrideSilentMode: Bool = false

    /// Preview player for sound selection
    private var previewPlayer: AVAudioPlayer?

    // MARK: - Remote Control Callbacks

    /// Callback for remote pause command from lockscreen
    private var onRemotePauseRequested: (() async -> Void)?

    /// Callback for remote play command from lockscreen
    private var onRemotePlayRequested: (() async -> Void)?

    /// Set the callbacks for remote control commands
    func setRemoteCommandCallbacks(
        onPause: @escaping () async -> Void,
        onPlay: @escaping () async -> Void
    ) {
        self.onRemotePauseRequested = onPause
        self.onRemotePlayRequested = onPlay
    }

    // MARK: - Singleton
    
    static let shared = AudioService()

    // MARK: - Initialization

    private init() {
        // Setup lockscreen controls once on initialization
        Task {
            await setupRemoteTransportControls()
        }
    }

    // MARK: - Configuration

    /// Configure audio session settings
    /// - Parameter overrideSilent: Whether to play sound even in silent mode
    func configureAudioSession(overrideSilent: Bool) async throws {
        self.overrideSilentMode = overrideSilent

        let session = AVAudioSession.sharedInstance()

        do {
            // Use .playback category to ensure lockscreen controls and background audio work
            // NO .mixWithOthers - we need to be the primary audio app for Now Playing controls
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    // MARK: - Bell Sound Playback

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

            self.bellPlayer = player
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    /// Stop any currently playing bell sound
    func stopBellPlayback() {
        bellPlayer?.stop()
        bellPlayer = nil
    }

    // MARK: - Background Sound Playback

    /// Start playing a background sound with infinite looping
    /// - Parameter sound: The background sound to play
    /// - Throws: AudioError if playback fails
    func startBackgroundSound(_ sound: BackgroundSound) async throws {
        // Stop any currently playing background sound
        stopBackgroundSound()

        // If "none" is selected, just return without playing sound
        guard sound.requiresFile, let filename = sound.filename else {
            currentBackgroundSound = .none
            return
        }

        // Configure audio session and ACTIVE it immediately before playing
        try await configureAudioSession(overrideSilent: overrideSilentMode)

        // Locate sound file in bundle
        guard let soundURL = Bundle.main.url(forResource: filename, withExtension: sound.fileExtension) else {
            throw AudioError.soundNotFound
        }

        do {
            // Create and configure audio player for looping
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.numberOfLoops = -1 // Infinite looping
            player.volume = 0.7 // Slightly quieter than bells
            player.prepareToPlay()
            player.play()

            self.backgroundPlayer = player
            self.currentBackgroundSound = sound
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    /// Stop the currently playing background sound
    func stopBackgroundSound() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
        currentBackgroundSound = .none
        clearNowPlayingInfo()
    }

    /// Pause the currently playing background sound
    func pauseBackgroundSound() {
        backgroundPlayer?.pause()
    }

    /// Resume the currently playing background sound
    func resumeBackgroundSound() {
        backgroundPlayer?.play()
    }

    /// Get the currently playing background sound
    /// - Returns: The current background sound, or .none if not playing
    func getCurrentBackgroundSound() -> BackgroundSound {
        return currentBackgroundSound
    }

    // MARK: - Preview Playback

    /// Preview a background sound (plays for a few seconds then stops)
    /// - Parameters:
    ///   - sound: The background sound to preview
    ///   - duration: How long to play the preview (default: 3 seconds)
    /// - Throws: AudioError if playback fails
    func previewBackgroundSound(_ sound: BackgroundSound, duration: TimeInterval = 3.0) async throws {
        // Stop any existing preview
        stopPreview()

        // If "none" is selected, just return
        guard sound.requiresFile, let filename = sound.filename else {
            return
        }

        // Locate sound file in bundle
        guard let soundURL = Bundle.main.url(forResource: filename, withExtension: sound.fileExtension) else {
            throw AudioError.soundNotFound
        }

        do {
            // Configure audio session
            try await configureAudioSession(overrideSilent: overrideSilentMode)

            // Create and configure audio player for preview
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = 0.5 // Quieter for preview
            player.prepareToPlay()
            player.play()

            self.previewPlayer = player

            // Schedule automatic stop after duration
            Task {
                try? await Task.sleep(for: .seconds(duration))
                await stopPreview()
            }
        } catch {
            throw AudioError.playbackFailed(error)
        }
    }

    /// Stop any preview playback
    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
    }

    // MARK: - General Controls

    /// Set whether to override silent mode
    /// - Parameter override: True to play sound even in silent mode
    func setSilentModeOverride(_ override: Bool) {
        self.overrideSilentMode = override
    }

    /// Stop all audio playback (bells, background, and preview)
    func stopAllPlayback() {
        stopBellPlayback()
        stopBackgroundSound()
        stopPreview()
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
    // MARK: - Lockscreen Controls

    /// Configure lockscreen media controls
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Clear existing targets to prevent duplicates/leaks
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)

        // Enable Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task {
                await self.onRemotePlayRequested?()
            }
            return .success
        }

        // Enable Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            Task {
                await self.onRemotePauseRequested?()
            }
            return .success
        }
    }

    /// Update lockscreen media info
    /// - Parameters:
    ///   - title: Title to display
    ///   - artist: Artist/Subtitle to display (default: "No Nonsense Meditation")
    /// Update lockscreen media info
    func updateNowPlayingInfo(title: String, artist: String = "No Nonsense Meditation", duration: TimeInterval? = nil, elapsed: TimeInterval? = nil, playbackRate: Float = 1.0) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate

        if let duration = duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if let elapsed = elapsed {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }

        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }

        // MPNowPlayingInfoCenter must be updated on main thread
        Task { @MainActor in
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    /// Clear lockscreen media info
    func clearNowPlayingInfo() {
        // MPNowPlayingInfoCenter must be updated on main thread
        Task { @MainActor in
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
}
