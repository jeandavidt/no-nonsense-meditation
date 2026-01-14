//
//  MusicLibraryItem.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-12.
//

import Foundation
import MediaPlayer

/// Represents a music item selected from the user's library
/// Can be either a single song or a playlist
struct MusicLibraryItem: Codable, Equatable, Sendable {
    
    // MARK: - Types
    
    /// Type of music library item
    enum ItemType: String, Codable, Sendable {
        case song
        case playlist
    }
    
    // MARK: - Properties
    
    /// Unique identifier for the item
    let persistentID: UInt64
    
    /// Type of item (song or playlist)
    let itemType: ItemType
    
    /// Display title of the item
    let title: String
    
    /// Artist name (for songs) or empty for playlists
    let artist: String?
    
    /// Album name (for songs) or empty for playlists
    let album: String?
    
    /// Duration in seconds (for songs, nil for playlists)
    let duration: TimeInterval?
    
    /// Number of items (for playlists)
    let itemCount: Int?
    
    // MARK: - Initialization
    
    /// Initialize from a media item (song)
    init(mediaItem: MPMediaItem) {
        self.persistentID = mediaItem.persistentID
        self.itemType = .song
        self.title = mediaItem.title ?? "Unknown Title"
        self.artist = mediaItem.artist
        self.album = mediaItem.albumTitle
        self.duration = mediaItem.playbackDuration
        self.itemCount = nil
    }
    
    /// Initialize from a playlist
    init(playlist: MPMediaPlaylist) {
        self.persistentID = playlist.persistentID
        self.itemType = .playlist
        self.title = playlist.name ?? "Unknown Playlist"
        self.artist = nil
        self.album = nil
        self.duration = nil
        self.itemCount = playlist.items.count
    }
    
    /// Initialize with explicit values (for persistence)
    init(
        persistentID: UInt64,
        itemType: ItemType,
        title: String,
        artist: String?,
        album: String?,
        duration: TimeInterval?,
        itemCount: Int?
    ) {
        self.persistentID = persistentID
        self.itemType = itemType
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.itemCount = itemCount
    }
    
    // MARK: - Display Properties
    
    /// Formatted subtitle for display
    var subtitle: String {
        switch itemType {
        case .song:
            if let artist = artist {
                return artist
            }
            return "Unknown Artist"
        case .playlist:
            if let count = itemCount {
                return "\(count) song\(count == 1 ? "" : "s")"
            }
            return "Playlist"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch itemType {
        case .song:
            return "music.note"
        case .playlist:
            return "music.note.list"
        }
    }
}

// MARK: - UserDefaults Persistence

extension MusicLibraryItem {
    /// UserDefaults key for storing selected music library item
    private static let userDefaultsKey = "selectedMusicLibraryItem"
    
    /// Save the music library item to UserDefaults
    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }
    
    /// Load the music library item from UserDefaults
    /// - Returns: The saved music library item, or nil if not found
    static func loadFromUserDefaults() -> MusicLibraryItem? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let item = try? JSONDecoder().decode(MusicLibraryItem.self, from: data) else {
            return nil
        }
        return item
    }
    
    /// Clear the saved music library item from UserDefaults
    static func clearFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
