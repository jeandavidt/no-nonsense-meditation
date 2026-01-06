//
//  TimerViewModelTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
import Observation
@testable import NoNonsenseMeditation

@MainActor
final class TimerViewModelTests: XCTestCase {

    var viewModel: TimerViewModel!
    var mockAudioService: MockAudioService!

    // Use async setUp to be compatible with MainActor isolation if needed,
    // though XCTest runs setUp on main thread usually.
    // Explicitly creating actor-isolated instances.
    override func setUp() async throws {
        try await super.setUp()
        mockAudioService = MockAudioService()
        viewModel = TimerViewModel(audioService: mockAudioService)
        
        // Clear persistence
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
    }

    override func tearDown() async throws {
        viewModel = nil
        mockAudioService = nil
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
        try await super.tearDown()
    }

    func testInitialState() {
        let state = viewModel.state
        XCTAssertEqual(state, .idle)
        
        let remaining = viewModel.remainingTime
        XCTAssertEqual(remaining, 0)
        
        let total = viewModel.totalDuration
        XCTAssertEqual(total, 0)
        
        let elapsed = viewModel.elapsedTime
        XCTAssertEqual(elapsed, 0)
        
        let progress = viewModel.progress
        XCTAssertEqual(progress, 0)
        
        let formatted = viewModel.formattedTime
        XCTAssertEqual(formatted, "00:00")
        
        let isIdle = viewModel.isIdle
        XCTAssertTrue(isIdle)
        
        let isRunning = viewModel.isRunning
        XCTAssertFalse(isRunning)
        
        let isPaused = viewModel.isPaused
        XCTAssertFalse(isPaused)
        
        let isCompleted = viewModel.isCompleted
        XCTAssertFalse(isCompleted)
        
        let sound = viewModel.selectedBackgroundSound
        XCTAssertEqual(sound, .none)
    }

    func testStartTimer() async throws {
        // Start a 60-second timer
        viewModel.startTimer(duration: 60)

        // Wait a moment for the timer to start
        try await Task.sleep(for: .seconds(0.1))

        let state = viewModel.state
        XCTAssertEqual(state, .running)
        
        let total = viewModel.totalDuration
        XCTAssertEqual(total, 60)
        
        let remaining = viewModel.remainingTime
        XCTAssertGreaterThan(remaining, 0)
        XCTAssertLessThanOrEqual(remaining, 60)
        
        let isRunning = viewModel.isRunning
        XCTAssertTrue(isRunning)
        
        let isIdle = viewModel.isIdle
        XCTAssertFalse(isIdle)
        
        // Verify audio calls
        let startPlayed = await mockAudioService.startSoundPlayed
        XCTAssertTrue(startPlayed, "Start sound should be played")
    }
    
    func testStartTimer_WithBackgroundSound() async throws {
        // Select a sound
        viewModel.setBackgroundSound(.brownNoise)
        
        // Start timer
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))
        
        // Verify background sound started
        let bgSound = await mockAudioService.backgroundSoundStarted
        XCTAssertEqual(bgSound, .brownNoise, "Selected background sound should start")
    }

    func testPauseResumeTimer() async throws {
        viewModel.setBackgroundSound(.windChimes)
        
        // Start
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Pause
        viewModel.pauseTimer()
        try await Task.sleep(for: .seconds(0.1))

        let pausedState = viewModel.state
        XCTAssertEqual(pausedState, .paused)
        
        let isPaused = viewModel.isPaused
        XCTAssertTrue(isPaused)
        
        // Verify pause audio
        let pausePlayed = await mockAudioService.pauseSoundPlayed
        XCTAssertTrue(pausePlayed, "Pause sound should be played")
        
        let bgPaused = await mockAudioService.backgroundSoundPaused
        XCTAssertTrue(bgPaused, "Background sound should be paused")

        // Resume
        viewModel.resumeTimer()
        try await Task.sleep(for: .seconds(0.1))

        let runningState = viewModel.state
        XCTAssertEqual(runningState, .running)
        
        let isRunning = viewModel.isRunning
        XCTAssertTrue(isRunning)
        
        // Verify resume audio
        let resumePlayed = await mockAudioService.resumeSoundPlayed
        XCTAssertTrue(resumePlayed, "Resume sound should be played")
        
        let bgResumed = await mockAudioService.backgroundSoundResumed
        XCTAssertTrue(bgResumed, "Background sound should be resumed")
    }

    func testStopTimer() async throws {
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Stop
        viewModel.stopTimer()
        try await Task.sleep(for: .seconds(0.1))

        let state = viewModel.state
        XCTAssertEqual(state, .idle, "Stop timer should reset state to idle")
        
        let isIdle = viewModel.isIdle
        XCTAssertTrue(isIdle)
        
        // Verify stop audio
        let bgStopped = await mockAudioService.backgroundSoundStopped
        XCTAssertTrue(bgStopped, "Background sound should be stopped")
    }

    func testResetTimer() async throws {
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Reset
        viewModel.resetTimer()
        try await Task.sleep(for: .seconds(0.1))

        let state = viewModel.state
        XCTAssertEqual(state, .idle)
        
        let remaining = viewModel.remainingTime
        XCTAssertEqual(remaining, 0)
        
        let total = viewModel.totalDuration
        XCTAssertEqual(total, 0)
        
        let isIdle = viewModel.isIdle
        XCTAssertTrue(isIdle)
    }

    func testFormattedTimeProperty() async throws {
        viewModel.startTimer(duration: 125)
        try await Task.sleep(for: .seconds(0.1))

        let formatted = viewModel.formattedTime
        XCTAssertNotEqual(formatted, "00:00")
        XCTAssertTrue(formatted.contains(":"))
    }

    func testBackgroundSoundSelection() async {
        let initialSound = viewModel.selectedBackgroundSound
        XCTAssertEqual(initialSound, .none)
        
        viewModel.setBackgroundSound(.libraryAmbience)
        
        let selected = viewModel.selectedBackgroundSound
        XCTAssertEqual(selected, .libraryAmbience)
        
        // Verify persistence
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedBackgroundSound"), "library_noise")
    }
    
    func testPreviewBackgroundSound() async {
        viewModel.previewBackgroundSound(.brownNoise)
        
        // Wait for async call
        try? await Task.sleep(for: .seconds(0.1))
        
        let previewSound = await mockAudioService.previewSound
        XCTAssertEqual(previewSound, .brownNoise)
    }
    
    func testStopPreview() async {
        viewModel.stopPreview()
        
        try? await Task.sleep(for: .seconds(0.1))
        
        let previewStopped = await mockAudioService.previewStopped
        XCTAssertTrue(previewStopped)
    }
}