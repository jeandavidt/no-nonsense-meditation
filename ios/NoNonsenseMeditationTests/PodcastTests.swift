//
//  PodcastTests.swift
//  NoNonsenseMeditationTests
//
//  Tests for podcast-related functionality
//

import XCTest
@testable import NoNonsenseMeditation

/// Tests for MusicLibraryItem podcast types
final class MusicLibraryItemTests: XCTestCase {
    
    func testPodcastEpisodeItemType() {
        // Given
        let item = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastEpisode,
            title: "Test Episode",
            artist: "Test Artist",
            album: nil,
            duration: 3600,
            itemCount: nil,
            podcastShowTitle: "Test Podcast"
        )
        
        // Then
        XCTAssertEqual(item.itemType, .podcastEpisode)
        XCTAssertEqual(item.title, "Test Episode")
        XCTAssertEqual(item.persistentID, 12345)
    }
    
    func testPodcastShowItemType() {
        // Given
        let item = MusicLibraryItem(
            persistentID: 67890,
            itemType: .podcastShow,
            title: "Test Podcast",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: 10,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(item.itemType, .podcastShow)
        XCTAssertEqual(item.title, "Test Podcast")
        XCTAssertEqual(item.itemCount, 10)
    }
    
    func testPodcastEpisodeIconName() {
        // Given
        let item = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastEpisode,
            title: "Episode",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: nil,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(item.iconName, "antenna.radiowaves.left.and.right")
    }
    
    func testPodcastShowIconName() {
        // Given
        let item = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastShow,
            title: "Podcast",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: nil,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(item.iconName, "mic.fill")
    }
    
    func testPodcastEpisodeSubtitle() {
        // Given - episode with show title
        let itemWithShow = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastEpisode,
            title: "Episode 1",
            artist: "Host",
            album: nil,
            duration: 1800,
            itemCount: nil,
            podcastShowTitle: "My Podcast"
        )
        
        // Given - episode without show title
        let itemWithoutShow = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastEpisode,
            title: "Episode 1",
            artist: "Host",
            album: nil,
            duration: 1800,
            itemCount: nil,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(itemWithShow.subtitle, "My Podcast")
        XCTAssertEqual(itemWithoutShow.subtitle, "Host")
    }
    
    func testPodcastShowSubtitle() {
        // Given - show with episodes
        let itemWithEpisodes = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastShow,
            title: "My Podcast",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: 5,
            podcastShowTitle: nil
        )
        
        // Given - show without episode count
        let itemWithoutEpisodes = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastShow,
            title: "My Podcast",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: nil,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(itemWithEpisodes.subtitle, "5 episodes")
        XCTAssertEqual(itemWithoutEpisodes.subtitle, "Podcast")
    }
    
    func testPodcastEpisodeSubtitlePluralization() {
        // Given - single episode
        let singleItem = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastShow,
            title: "Podcast",
            artist: nil,
            album: nil,
            duration: nil,
            itemCount: 1,
            podcastShowTitle: nil
        )
        
        // Then
        XCTAssertEqual(singleItem.subtitle, "1 episode")
    }
    
    func testMusicLibraryItemCodable() throws {
        // Given
        let original = MusicLibraryItem(
            persistentID: 12345,
            itemType: .podcastEpisode,
            title: "Test Episode",
            artist: "Host",
            album: nil,
            duration: 3600,
            itemCount: nil,
            podcastShowTitle: "Test Podcast"
        )
        
        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MusicLibraryItem.self, from: encoded)
        
        // Then
        XCTAssertEqual(original.persistentID, decoded.persistentID)
        XCTAssertEqual(original.itemType, decoded.itemType)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.artist, decoded.artist)
        XCTAssertEqual(original.podcastShowTitle, decoded.podcastShowTitle)
    }
}

/// Tests for AmbianceSound podcast library support
final class AmbianceSoundTests: XCTestCase {
    
    func testPodcastLibraryExists() {
        // Then
        XCTAssertNotNil(AmbianceSoundLoader.podcastLibrary)
    }
    
    func testPodcastLibraryProperties() {
        // Given
        guard let podcastLibrary = AmbianceSoundLoader.podcastLibrary else {
            XCTFail("Podcast library should exist")
            return
        }
        
        // Then
        XCTAssertEqual(podcastLibrary.id, "podcasts")
        XCTAssertEqual(podcastLibrary.displayName, "Podcasts")
        XCTAssertEqual(podcastLibrary.iconName, "mic.fill")
        XCTAssertTrue(podcastLibrary.usesPodcastLibrary)
        XCTAssertFalse(podcastLibrary.usesUserLibrary)
        XCTAssertFalse(podcastLibrary.requiresFile)
    }
    
    func testSoundWithIdFindsPodcastLibrary() {
        // When
        let found = AmbianceSoundLoader.sound(withId: "podcasts")
        
        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, "podcasts")
        XCTAssertTrue(found?.usesPodcastLibrary ?? false)
    }
    
    func testAllSoundsContainsPodcastLibrary() {
        // Then
        XCTAssertTrue(AmbianceSoundLoader.allSounds.contains { $0.id == "podcasts" })
    }
    
    func testPodcastLibraryNotUserLibrary() {
        // Then
        XCTAssertFalse(AmbianceSoundLoader.userLibrary?.id == "podcasts")
    }
}

/// Tests for AmbianceSound UserDefaults persistence with podcasts
final class AmbianceSoundPersistenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
    }
    
    override func tearDown() {
        super.tearDown()
        // Clear UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "selectedBackgroundSound")
    }
    
    func testSaveAndLoadPodcastLibrary() {
        // Given
        guard let podcastLibrary = AmbianceSoundLoader.podcastLibrary else {
            XCTFail("Podcast library should exist")
            return
        }
        
        // When
        podcastLibrary.saveToUserDefaults()
        let loaded = AmbianceSound.loadFromUserDefaults()
        
        // Then
        XCTAssertEqual(loaded.id, "podcasts")
        XCTAssertTrue(loaded.usesPodcastLibrary)
    }
    
    func testLoadNonexistentSoundDefaultsToNone() {
        // Given - UserDefaults has an invalid value
        UserDefaults.standard.set("nonexistent_sound", forKey: "selectedBackgroundSound")
        
        // When
        let loaded = AmbianceSound.loadFromUserDefaults()
        
        // Then
        XCTAssertEqual(loaded.id, "none")
    }
}
