//
//  MockAudioService.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-06.
//

import Foundation
@testable import NoNonsenseMeditation

/// Mock AudioService for testing
/// Tracks method calls without actually playing audio
actor MockAudioService: AudioServiceProtocol {
    
    // MARK: - Tracking Properties
    
    private(set) var startSoundPlayed = false
    private(set) var pauseSoundPlayed = false
    private(set) var resumeSoundPlayed = false
    private(set) var completionSoundPlayed = false
    
    private(set) var backgroundSoundStarted: BackgroundSound?
    private(set) var backgroundSoundPaused = false
    private(set) var backgroundSoundResumed = false
    private(set) var backgroundSoundStopped = false
    
    private(set) var previewSound: BackgroundSound?
    private(set) var previewDuration: TimeInterval?
    private(set) var previewStopped = false
    
    // MARK: - Mock Methods
    
    func playStartSound() {
        startSoundPlayed = true
    }
    
    func playPauseSound() {
        pauseSoundPlayed = true
    }
    
    func playResumeSound() {
        resumeSoundPlayed = true
    }
    
    func playCompletionSound() {
        completionSoundPlayed = true
    }
    
    func startBackgroundSound(_ sound: BackgroundSound) {
        backgroundSoundStarted = sound
    }
    
    func pauseBackgroundSound() {
        backgroundSoundPaused = true
    }
    
    func resumeBackgroundSound() {
        backgroundSoundResumed = true
    }
    
    func stopBackgroundSound() {
        backgroundSoundStopped = true
    }
    
    func previewBackgroundSound(_ sound: BackgroundSound, duration: TimeInterval = 3.0) {
        previewSound = sound
        previewDuration = duration
    }
    
    func stopPreview() {
        previewStopped = true
    }
    
    // MARK: - Reset
    
    func reset() {
        startSoundPlayed = false
        pauseSoundPlayed = false
        resumeSoundPlayed = false
        completionSoundPlayed = false
        
        backgroundSoundStarted = nil
        backgroundSoundPaused = false
        backgroundSoundResumed = false
        backgroundSoundStopped = false
        
        previewSound = nil
        previewDuration = nil
        previewStopped = false
    }
}
