//
//  TimerViewModelTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
import Observation
@testable import NoNonsenseMeditation

final class TimerViewModelTests: XCTestCase {

    var viewModel: TimerViewModel!

    override func setUpWithError() throws {
        viewModel = TimerViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    func testInitialState() throws {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.remainingTime, 0)
        XCTAssertEqual(viewModel.totalDuration, 0)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertEqual(viewModel.progress, 0)
        XCTAssertEqual(viewModel.formattedTime, "00:00")
        XCTAssertTrue(viewModel.isIdle)
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertFalse(viewModel.isCompleted)
    }

    func testStartTimer() async throws {
        // Start a 60-second timer
        viewModel.startTimer(duration: 60)

        // Wait a moment for the timer to start
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.state, .running)
        XCTAssertEqual(viewModel.totalDuration, 60)
        XCTAssertGreaterThan(viewModel.remainingTime, 0)
        XCTAssertLessThanOrEqual(viewModel.remainingTime, 60)
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.isIdle)
    }

    func testPauseResumeTimer() async throws {
        // Start a 60-second timer
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Pause the timer
        viewModel.pauseTimer()
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertTrue(viewModel.isPaused)

        // Resume the timer
        viewModel.resumeTimer()
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.state, .running)
        XCTAssertTrue(viewModel.isRunning)
    }

    func testStopTimer() async throws {
        // Start a 60-second timer
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Stop the timer
        viewModel.stopTimer()
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertTrue(viewModel.isCompleted)
    }

    func testResetTimer() async throws {
        // Start a 60-second timer
        viewModel.startTimer(duration: 60)
        try await Task.sleep(for: .seconds(0.1))

        // Reset the timer
        viewModel.resetTimer()
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.remainingTime, 0)
        XCTAssertEqual(viewModel.totalDuration, 0)
        XCTAssertTrue(viewModel.isIdle)
    }

    func testFormattedTimeProperty() async throws {
        // Test that formatted time updates correctly when timer starts
        viewModel.startTimer(duration: 125)
        try await Task.sleep(for: .seconds(0.1))

        // formattedTime should show the remaining time
        XCTAssertNotEqual(viewModel.formattedTime, "00:00")
        XCTAssertTrue(viewModel.formattedTime.contains(":"))
    }

    func testConvenienceProperties() async throws {
        viewModel.startTimer(duration: 125)
        try await Task.sleep(for: .seconds(0.1))

        XCTAssertEqual(viewModel.formattedTotalDuration, "02:05")
        // Elapsed time starts near 0
        XCTAssertTrue(viewModel.formattedElapsedTime.hasPrefix("00:"))
    }
}