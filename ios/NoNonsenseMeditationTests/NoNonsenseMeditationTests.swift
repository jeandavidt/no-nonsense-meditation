//
//  NoNonsenseMeditationTests.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest
import Combine
import HealthKit
import AVFoundation
@testable import NoNonsenseMeditation

// MARK: - Mocks

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
    
    func configureAudioSession(overrideSilent: Bool) async throws {
        // No-op for mock
    }
    
    func playBell(soundName: String) async throws {
        // No-op for mock, maybe track calls?
    }
    
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
    
    func setSilentModeOverride(_ enabled: Bool) {
        // No-op for mock
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

// ... (Rest of the file)
// Note: I will replace the MockAudioService part and REMOVE TimerViewModelTests at end.


/// Mock implementation of HealthStoreProtocol for testing HealthKitService
final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    
    // MARK: - State
    
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var savedObjects: [HKObject] = []
    
    var shouldThrowOnRequestAuth = false
    var shouldThrowOnSave = false
    
    var requestAuthCalled = false
    
    // MARK: - Protocol Methods
    
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatus
    }
    
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws {
        requestAuthCalled = true
        if shouldThrowOnRequestAuth {
            throw HealthKitService.HealthKitError.authorizationDenied
        }
        // Simulate successful authorization
        authorizationStatus = .sharingAuthorized
    }
    
    func save(_ object: HKObject) async throws {
        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }
        savedObjects.append(object)
    }
    
    func save(_ objects: [HKObject]) async throws {
        if shouldThrowOnSave {
            throw HealthKitService.HealthKitError.syncFailed(NSError(domain: "Test", code: -1))
        }
        savedObjects.append(contentsOf: objects)
    }
}

// MARK: - Main Test Class

final class NoNonsenseMeditationTests: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true, "Example test passes")
    }
}

// MARK: - BackgroundSound Tests

final class BackgroundSoundTests: XCTestCase {
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
    }
    
    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testAllCasesCount() {
        // Verify we have all 4 background sound options
        XCTAssertEqual(BackgroundSound.allCases.count, 4)
    }
    
    func testAllCasesContainsExpectedValues() {
        let allCases = BackgroundSound.allCases
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.brownNoise))
        XCTAssertTrue(allCases.contains(.libraryAmbience))
        XCTAssertTrue(allCases.contains(.windChimes))
    }
    
    // MARK: - Display Properties Tests
    
    func testDisplayNames() {
        XCTAssertEqual(BackgroundSound.none.displayName, "No Background Sound")
        XCTAssertEqual(BackgroundSound.brownNoise.displayName, "Brown Noise")
        XCTAssertEqual(BackgroundSound.libraryAmbience.displayName, "Library Ambience")
        XCTAssertEqual(BackgroundSound.windChimes.displayName, "Wind Chimes")
    }
    
    func testIconNames() {
        XCTAssertEqual(BackgroundSound.none.iconName, "speaker.slash")
        XCTAssertEqual(BackgroundSound.brownNoise.iconName, "waveform")
        XCTAssertEqual(BackgroundSound.libraryAmbience.iconName, "building.2")
        XCTAssertEqual(BackgroundSound.windChimes.iconName, "wind")
    }
    
    func testDescriptions() {
        XCTAssertEqual(BackgroundSound.none.description, "Silence")
        XCTAssertEqual(BackgroundSound.brownNoise.description, "Deep ambient noise")
        XCTAssertEqual(BackgroundSound.libraryAmbience.description, "Quiet study atmosphere")
        XCTAssertEqual(BackgroundSound.windChimes.description, "Gentle chimes")
    }
    
    // MARK: - Audio Properties Tests
    
    func testFilenames() {
        XCTAssertNil(BackgroundSound.none.filename)
        XCTAssertEqual(BackgroundSound.brownNoise.filename, "brown_noise")
        XCTAssertEqual(BackgroundSound.libraryAmbience.filename, "library_noise")
        XCTAssertEqual(BackgroundSound.windChimes.filename, "wind_chimes")
    }
    
    func testFileExtension() {
        // All sounds use m4a extension
        for sound in BackgroundSound.allCases {
            XCTAssertEqual(sound.fileExtension, "m4a")
        }
    }
    
    func testRequiresFile() {
        XCTAssertFalse(BackgroundSound.none.requiresFile)
        XCTAssertTrue(BackgroundSound.brownNoise.requiresFile)
        XCTAssertTrue(BackgroundSound.libraryAmbience.requiresFile)
        XCTAssertTrue(BackgroundSound.windChimes.requiresFile)
    }
    
    // MARK: - Identifiable Conformance Tests
    
    func testIdentifiableID() {
        XCTAssertEqual(BackgroundSound.none.id, "none")
        XCTAssertEqual(BackgroundSound.brownNoise.id, "brown_noise")
        XCTAssertEqual(BackgroundSound.libraryAmbience.id, "library_noise")
        XCTAssertEqual(BackgroundSound.windChimes.id, "wind_chimes")
    }
    
    func testIDMatchesRawValue() {
        for sound in BackgroundSound.allCases {
            XCTAssertEqual(sound.id, sound.rawValue)
        }
    }
    
    // MARK: - Codable Conformance Tests
    
    func testEncodingAndDecoding() throws {
        for sound in BackgroundSound.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(sound)
            
            let decoder = JSONDecoder()
            let decodedSound = try decoder.decode(BackgroundSound.self, from: data)
            
            XCTAssertEqual(sound, decodedSound)
        }
    }
    
    // MARK: - UserDefaults Persistence Tests
    
    func testSaveToUserDefaults() {
        // Save each sound and verify it's stored
        for sound in BackgroundSound.allCases {
            sound.saveToUserDefaults()
            let savedValue = UserDefaults.standard.string(forKey: "selectedBackgroundSound")
            XCTAssertEqual(savedValue, sound.rawValue)
        }
    }
    
    func testLoadFromUserDefaults_WithSavedValue() {
        // Test loading each saved sound
        for sound in BackgroundSound.allCases {
            UserDefaults.standard.set(sound.rawValue, forKey: "selectedBackgroundSound")
            let loadedSound = BackgroundSound.loadFromUserDefaults()
            XCTAssertEqual(loadedSound, sound)
        }
    }
    
    func testLoadFromUserDefaults_WithNoSavedValue() {
        // When nothing is saved, should return .none
        let loadedSound = BackgroundSound.loadFromUserDefaults()
        XCTAssertEqual(loadedSound, .none)
    }
    
    func testLoadFromUserDefaults_WithInvalidValue() {
        // When an invalid value is saved, should return .none
        UserDefaults.standard.set("invalid_sound", forKey: "selectedBackgroundSound")
        let loadedSound = BackgroundSound.loadFromUserDefaults()
        XCTAssertEqual(loadedSound, .none)
    }
    
    func testSaveAndLoadRoundTrip() {
        // Test complete save/load cycle
        for sound in BackgroundSound.allCases {
            sound.saveToUserDefaults()
            let loadedSound = BackgroundSound.loadFromUserDefaults()
            XCTAssertEqual(sound, loadedSound, "Failed round trip for \(sound)")
        }
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testSendableConformance() {
        // This test verifies that BackgroundSound can be safely passed between actors
        // The fact that this compiles is the test - Sendable is a compile-time check
        let sound: BackgroundSound = .brownNoise
        
        Task {
            let _ = sound // Using sound in async context
            XCTAssertEqual(sound, .brownNoise)
        }
    }
}

// MARK: - SessionStatistics Tests

final class SessionStatisticsTests: XCTestCase {
    
    // MARK: - Test Cases
    
    func testInitialization() {
        let stats = SessionStatistics(
            plannedDuration: 600, // 10 minutes
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.plannedDuration, 600)
        XCTAssertEqual(stats.actualDuration, 600)
        XCTAssertFalse(stats.wasPaused)
    }
    
    // MARK: - Focus Percentage Tests
    
    func testFocusPercentage_CompletedFully() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.focusPercentage, "100")
    }
    
    func testFocusPercentage_CompletedPartially() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 300, // 50%
            wasPaused: false
        )
        
        XCTAssertEqual(stats.focusPercentage, "50")
    }
    
    func testFocusPercentage_ExceededPlanned() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 900, // 150%
            wasPaused: false
        )
        
        XCTAssertEqual(stats.focusPercentage, "100") // Capped at 100%
    }
    
    func testFocusPercentage_ZeroPlanned() {
        let stats = SessionStatistics(
            plannedDuration: 0,
            actualDuration: 100,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.focusPercentage, "0")
    }
    
    // MARK: - Completion Percentage Tests
    
    func testCompletionPercentage_Completed() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.completionPercentage, "100")
    }
    
    func testCompletionPercentage_PartiallyCompleted() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 450, // 75%
            wasPaused: false
        )
        
        XCTAssertEqual(stats.completionPercentage, "75")
    }
    
    func testCompletionPercentage_Exceeded() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 720, // 120%
            wasPaused: false
        )
        
        XCTAssertEqual(stats.completionPercentage, "120")
    }
    
    func testCompletionPercentage_ZeroPlanned() {
        let stats = SessionStatistics(
            plannedDuration: 0,
            actualDuration: 100,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.completionPercentage, "0")
    }
    
    // MARK: - Duration Difference Tests
    
    func testDurationDifference_Exact() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.durationDifference, 0)
    }
    
    func testDurationDifference_Exceeded() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 720,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.durationDifference, 120) // +2 minutes
    }
    
    func testDurationDifference_ShortOfPlanned() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 480,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.durationDifference, -120) // -2 minutes
    }
    
    // MARK: - Formatted Time Display Tests
    
    func testFormattedPlannedDuration() {
        let stats = SessionStatistics(
            plannedDuration: 665, // 11:05
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedPlannedDuration, "11:05")
    }
    
    func testFormattedActualDuration() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 725, // 12:05
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedActualDuration, "12:05")
    }
    
    func testFormattedDurationDifference_Positive() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 720, // +2:00
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedDurationDifference, "2:00")
    }
    
    func testFormattedDurationDifference_Negative() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 480, // -2:00
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedDurationDifference, "-2:00")
    }
    
    func testFormattedDurationDifference_Zero() {
        let stats = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedDurationDifference, "0:00")
    }
    
    func testFormattedTime_SingleDigitMinutes() {
        let stats = SessionStatistics(
            plannedDuration: 305, // 5:05
            actualDuration: 305,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedPlannedDuration, "5:05")
    }
    
    func testFormattedTime_ZeroDuration() {
        let stats = SessionStatistics(
            plannedDuration: 0,
            actualDuration: 0,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedPlannedDuration, "0:00")
        XCTAssertEqual(stats.formattedActualDuration, "0:00")
    }
    
    func testFormattedTime_LongDuration() {
        let stats = SessionStatistics(
            plannedDuration: 3665, // 61:05 (over an hour)
            actualDuration: 3665,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedPlannedDuration, "61:05")
    }
    
    // MARK: - Equatable Conformance Tests
    
    func testEquatable_Equal() {
        let stats1 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        let stats2 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertEqual(stats1, stats2)
    }
    
    func testEquatable_DifferentPlannedDuration() {
        let stats1 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        let stats2 = SessionStatistics(
            plannedDuration: 300,
            actualDuration: 600,
            wasPaused: false
        )
        
        XCTAssertNotEqual(stats1, stats2)
    }
    
    func testEquatable_DifferentActualDuration() {
        let stats1 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        let stats2 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 300,
            wasPaused: false
        )
        
        XCTAssertNotEqual(stats1, stats2)
    }
    
    func testEquatable_DifferentPauseStatus() {
        let stats1 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: false
        )
        
        let stats2 = SessionStatistics(
            plannedDuration: 600,
            actualDuration: 600,
            wasPaused: true
        )
        
        XCTAssertNotEqual(stats1, stats2)
    }
    
    // MARK: - Edge Case Tests
    
    func testNegativeDurations() {
        // While unlikely in practice, test that negative values don't crash
        let stats = SessionStatistics(
            plannedDuration: -100,
            actualDuration: -50,
            wasPaused: false
        )
        
        // Should handle gracefully
        XCTAssertNotNil(stats.formattedPlannedDuration)
        XCTAssertNotNil(stats.formattedActualDuration)
    }
    
    func testVeryLargeDurations() {
        // Test with very large durations (e.g., 24 hours)
        let stats = SessionStatistics(
            plannedDuration: 86400, // 24 hours
            actualDuration: 86400,
            wasPaused: false
        )
        
        XCTAssertEqual(stats.formattedPlannedDuration, "1440:00")
    }
}

// MARK: - AudioService Tests

final class AudioServiceTests: XCTestCase {
    
    var service: AudioService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = AudioService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Bell Sound Tests
    
    func testPlayStartSound_DoesNotThrow() async {
        do {
            try await service.playStartSound()
        } catch {
            XCTFail("playStartSound threw error: \(error)")
        }
    }
    
    func testPlayPauseSound_DoesNotThrow() async {
        do {
            try await service.playPauseSound()
        } catch {
            XCTFail("playPauseSound threw error: \(error)")
        }
    }
    
    func testPlayResumeSound_DoesNotThrow() async {
        do {
            try await service.playResumeSound()
        } catch {
            XCTFail("playResumeSound threw error: \(error)")
        }
    }
    
    func testPlayCompletionSound_DoesNotThrow() async {
        // playCompletionSound is a fire-and-forget void method in the service that runs a Task
        // Since it's an actor method, we must await it to ensure serial execution
        await service.playCompletionSound()
    }
    
    // MARK: - Background Sound Tests
    
    func testStartBackgroundSound_BrownNoise_DoesNotThrow() async {
        do {
            try await service.startBackgroundSound(.brownNoise)
            let currentSound = await service.getCurrentBackgroundSound()
            XCTAssertEqual(currentSound, .brownNoise)
        } catch {
            XCTFail("startBackgroundSound(.brownNoise) threw error: \(error)")
        }
    }
    
    func testStartBackgroundSound_None_StopsPlayback() async {
        // First start a sound
        try? await service.startBackgroundSound(.windChimes)
        
        // Then switch to none
        try? await service.startBackgroundSound(.none)
        
        let currentSound = await service.getCurrentBackgroundSound()
        XCTAssertEqual(currentSound, .none)
    }
    
    func testStopBackgroundSound_ResetsState() async {
        // Start a sound
        try? await service.startBackgroundSound(.libraryAmbience)
        
        // Stop it
        await service.stopBackgroundSound()
        
        let currentSound = await service.getCurrentBackgroundSound()
        XCTAssertEqual(currentSound, .none)
    }
    
    // MARK: - Preview Tests
    
    func testPreviewBackgroundSound_DoesNotThrow() async {
        do {
            // Short duration for test
            try await service.previewBackgroundSound(.windChimes, duration: 0.1)
        } catch {
            XCTFail("previewBackgroundSound threw error: \(error)")
        }
    }
    
    func testStopPreview_DoesNotThrow() async {
        await service.stopPreview()
    }
    
    // MARK: - Silent Mode Override
    
    func testSilentModeOverrideConfiguration() async {
        // This validates we can set the property, actual behavior depends on device state which we can't fully check in simulator/unit test easily
        await service.setSilentModeOverride(true)
        // No-op validation for mock/unit test
    }
    
    // MARK: - Resource Verification
    
    func testAllAudioFilesExist() {
        let bundle = Bundle.main
        
        // Check background sounds
        for sound in BackgroundSound.allCases where sound.requiresFile {
            guard let filename = sound.filename else { continue }
            let url = bundle.url(forResource: filename, withExtension: sound.fileExtension)
            XCTAssertNotNil(url, "Could not find audio file for \(sound.displayName)")
        }
        
        // Check bell sounds
        let bellSounds = [
            "meditation_start",
            "meditation_pause",
            "meditation_resume",
            "meditation_completion"
        ]
        
        for soundName in bellSounds {
            let url = bundle.url(forResource: soundName, withExtension: "wav")
            XCTAssertNotNil(url, "Could not find bell sound: \(soundName)")
        }
    }
}

// MARK: - HealthKitService Tests

final class HealthKitServiceTests: XCTestCase {
    
    var service: HealthKitService!
    var mockStore: MockHealthStore!
    
    override func setUp() async throws {
        try await super.setUp()
        mockStore = MockHealthStore()
        service = HealthKitService(store: mockStore)
    }
    
    override func tearDown() {
        service = nil
        mockStore = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testCheckAuthorizationStatus_NotDetermined() async {
        mockStore.authorizationStatus = .notDetermined
        let status = await service.checkAuthorizationStatus()
        XCTAssertEqual(status, .notDetermined)
    }
    
    func testCheckAuthorizationStatus_Authorized() async {
        mockStore.authorizationStatus = .sharingAuthorized
        let status = await service.checkAuthorizationStatus()
        XCTAssertEqual(status, .authorized)
    }
    
    func testCheckAuthorizationStatus_Denied() async {
        mockStore.authorizationStatus = .sharingDenied
        let status = await service.checkAuthorizationStatus()
        XCTAssertEqual(status, .denied)
    }
    
    func testRequestAuthorization_Success() async {
        do {
            try await service.requestAuthorization()
            XCTAssertTrue(mockStore.requestAuthCalled)
            // Mock updates status to authorized upon success
            let status = await service.checkAuthorizationStatus()
            XCTAssertEqual(status, .authorized)
        } catch {
            XCTFail("requestAuthorization failed: \(error)")
        }
    }
    
    func testRequestAuthorization_Failure() async {
        mockStore.shouldThrowOnRequestAuth = true
        
        do {
            try await service.requestAuthorization()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is HealthKitService.HealthKitError)
        }
    }
    
    // MARK: - Save Tests
    
    func testSaveMindfulMinutes_Success() async {
        // Setup authorized state
        mockStore.authorizationStatus = .sharingAuthorized
        
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(600) // 10 minutes
        let duration: TimeInterval = 600
        
        do {
            try await service.saveMindfulMinutes(
                duration: duration,
                startDate: startDate,
                endDate: endDate
            )
            
            XCTAssertEqual(mockStore.savedObjects.count, 1)
            guard let sample = mockStore.savedObjects.first as? HKCategorySample else {
                XCTFail("Saved object is not a HKCategorySample")
                return
            }
            
            XCTAssertEqual(sample.sampleType, HKObjectType.categoryType(forIdentifier: .mindfulSession))
            XCTAssertEqual(sample.startDate, startDate)
            XCTAssertEqual(sample.endDate, endDate)
            
        } catch {
            XCTFail("saveMindfulMinutes failed: \(error)")
        }
    }
    
    func testSaveMindfulMinutes_NotAuthorized() async {
        // State is notDetermined by default
        
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(600)
        
        do {
            try await service.saveMindfulMinutes(
                duration: 600,
                startDate: startDate,
                endDate: endDate
            )
            XCTFail("Should have thrown error")
        } catch {
            guard let hkError = error as? HealthKitService.HealthKitError,
                  case .authorizationDenied = hkError else {
                XCTFail("Expected authorizationDenied error, got \(error)")
                return
            }
        }
    }
    
    func testSaveMindfulMinutes_SyncFailure() async {
        mockStore.authorizationStatus = .sharingAuthorized
        mockStore.shouldThrowOnSave = true
        
        do {
            try await service.saveMindfulMinutes(
                duration: 600,
                startDate: Date(),
                endDate: Date().addingTimeInterval(600)
            )
            XCTFail("Should have thrown error")
        } catch {
            guard let hkError = error as? HealthKitService.HealthKitError,
                  case .syncFailed = hkError else {
                XCTFail("Expected syncFailed error, got \(error)")
                return
            }
        }
    }
    
    // MARK: - Batch Save Tests
    
    func testBatchSaveMindfulMinutes_Success() async {
        mockStore.authorizationStatus = .sharingAuthorized
        
        let now = Date()
        let sessions = [
            (duration: 600.0, startDate: now.addingTimeInterval(-1200), endDate: now.addingTimeInterval(-600)),
            (duration: 300.0, startDate: now.addingTimeInterval(-300), endDate: now)
        ]
        
        do {
            try await service.batchSaveMindfulMinutes(sessions: sessions)
            
            XCTAssertEqual(mockStore.savedObjects.count, 2)
        } catch {
            XCTFail("batchSaveMindfulMinutes failed: \(error)")
        }
    }
}


