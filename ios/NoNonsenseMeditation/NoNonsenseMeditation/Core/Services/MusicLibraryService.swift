//
//  MusicLibraryService.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-12.
//

import Foundation
import MediaPlayer
import AVFoundation

/// Actor responsible for accessing and playing music from the user's library
/// Handles authorization, fetching songs/playlists, and playback
actor MusicLibraryService {
    
    // MARK: - Types
    
    /// Authorization status for music library access
    enum AuthorizationStatus: Sendable {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    /// Errors that can occur during music library operations
    enum MusicLibraryError: Error, LocalizedError {
        case notAuthorized
        case itemNotFound
        case playbackFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Music library access not authorized"
            case .itemNotFound:
                return "Music item not found in library"
            case .playbackFailed(let error):
                return "Failed to play music: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Music player for playback
    private var musicPlayer: MPMusicPlayerController?
    
    /// Currently playing item
    private var currentItem: MusicLibraryItem?
    
    /// Whether playback was paused by user (vs stopped)
    private var wasPausedByUser: Bool = false
    
    /// Whether playback is currently active
    private var isPlaying: Bool = false
    
    // MARK: - Singleton
    
    static let shared = MusicLibraryService()
    
    private init() {}
    
    // MARK: - Authorization
    
    /// Get current authorization status
    /// - Returns: Current authorization status
    func getAuthorizationStatus() -> AuthorizationStatus {
        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    /// Request authorization to access the music library
    /// - Returns: Whether authorization was granted
    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        return status == .authorized
    }
    
    // MARK: - Fetching Music
    
    /// Fetch all songs from the user's library
    /// - Returns: Array of music library items representing songs
    func fetchSongs() async throws -> [MusicLibraryItem] {
        guard getAuthorizationStatus() == .authorized else {
            throw MusicLibraryError.notAuthorized
        }
        
        let query = MPMediaQuery.songs()
        let items = query.items ?? []
        
        return items.map { MusicLibraryItem(mediaItem: $0) }
    }
    
    /// Fetch all playlists from the user's library
    /// - Returns: Array of music library items representing playlists
    func fetchPlaylists() async throws -> [MusicLibraryItem] {
        guard getAuthorizationStatus() == .authorized else {
            throw MusicLibraryError.notAuthorized
        }
        
        let query = MPMediaQuery.playlists()
        let collections = query.collections ?? []
        
        return collections.compactMap { collection -> MusicLibraryItem? in
            guard let playlist = collection as? MPMediaPlaylist else { return nil }
            return MusicLibraryItem(playlist: playlist)
        }
    }
    
    /// Search songs by title or artist
    /// - Parameter searchText: Text to search for
    /// - Returns: Array of matching music library items
    func searchSongs(query searchText: String) async throws -> [MusicLibraryItem] {
        guard getAuthorizationStatus() == .authorized else {
            throw MusicLibraryError.notAuthorized
        }
        
        let query = MPMediaQuery.songs()
        let items = query.items ?? []
        
        let lowercasedSearch = searchText.lowercased()
        let filtered = items.filter { item in
            let titleMatch = item.title?.lowercased().contains(lowercasedSearch) ?? false
            let artistMatch = item.artist?.lowercased().contains(lowercasedSearch) ?? false
            let albumMatch = item.albumTitle?.lowercased().contains(lowercasedSearch) ?? false
            return titleMatch || artistMatch || albumMatch
        }
        
        return filtered.map { MusicLibraryItem(mediaItem: $0) }
    }
    
    // MARK: - Playback
    
    /// Start playing a music library item
    /// - Parameter item: The item to play
    func startPlayback(item: MusicLibraryItem) async throws {
        guard getAuthorizationStatus() == .authorized else {
            throw MusicLibraryError.notAuthorized
        }
        
        // Stop any current playback
        stopPlayback()
        
        // Get the application music player
        let player = MPMusicPlayerController.applicationMusicPlayer
        
        // Create query based on item type
        switch item.itemType {
        case .song:
            let query = MPMediaQuery.songs()
            query.addFilterPredicate(
                MPMediaPropertyPredicate(
                    value: item.persistentID,
                    forProperty: MPMediaItemPropertyPersistentID
                )
            )
            
            guard let mediaItem = query.items?.first else {
                throw MusicLibraryError.itemNotFound
            }
            
            let collection = MPMediaItemCollection(items: [mediaItem])
            player.setQueue(with: collection)
            
        case .playlist:
            let query = MPMediaQuery.playlists()
            query.addFilterPredicate(
                MPMediaPropertyPredicate(
                    value: item.persistentID,
                    forProperty: MPMediaPlaylistPropertyPersistentID
                )
            )
            
            guard let playlist = query.collections?.first as? MPMediaPlaylist else {
                throw MusicLibraryError.itemNotFound
            }
            
            player.setQueue(with: playlist)
        }
        
        // Configure for looping
        player.repeatMode = .all
        player.shuffleMode = .off
        
        // Start playback
        try await player.prepareToPlay()
        player.play()
        
        self.musicPlayer = player
        self.currentItem = item
        self.isPlaying = true
    }
    
    /// Pause current playback
    func pausePlayback() {
        guard musicPlayer != nil else { return }
        musicPlayer?.pause()
        isPlaying = false
        wasPausedByUser = true
    }
    
    /// Resume current playback
    func resumePlayback() {
        musicPlayer?.play()
        isPlaying = true
        wasPausedByUser = false
    }
    
    /// Stop current playback
    func stopPlayback() {
        musicPlayer?.stop()
        // Don't destroy the player - keep it for potential resume
        // Just reset the tracking flags
        isPlaying = false
        wasPausedByUser = false
    }
    
    /// Get the currently playing item
    /// - Returns: The current music library item, or nil if not playing
    func getCurrentItem() -> MusicLibraryItem? {
        return currentItem
    }
    
    /// Check if music is currently playing
    /// - Returns: Whether music is playing
    func getIsPlaying() -> Bool {
        return isPlaying
    }
    
    /// Check if playback was paused by user (vs stopped)
    /// - Returns: Whether playback is in paused state
    func getWasPausedByUser() -> Bool {
        return wasPausedByUser
    }
    
    /// Set the playback volume
    /// - Parameter volume: Volume level from 0.0 to 1.0
    func setVolume(_ volume: Float) {
        // Note: MPMusicPlayerController doesn't have direct volume control
        // Volume is controlled by the system
    }
}

