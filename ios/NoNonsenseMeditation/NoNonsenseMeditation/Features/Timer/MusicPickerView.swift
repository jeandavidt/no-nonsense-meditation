//
//  MusicPickerView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-12.
//

import SwiftUI
import MediaPlayer

/// View for browsing and selecting music from the user's library
/// Supports both songs and playlists with search functionality
struct MusicPickerView: View {
    
    // MARK: - Properties
    
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Currently selected music item (binding to parent)
    @Binding var selectedItem: MusicLibraryItem?
    
    /// Callback when selection is made
    var onSelection: ((MusicLibraryItem) -> Void)?
    
    /// Whether this view provides its own navigation (for standalone use)
    var providesNavigation: Bool = false
    
    /// Music library service
    private let musicService = MusicLibraryService.shared
    
    /// Authorization status
    @State private var authorizationStatus: MusicLibraryService.AuthorizationStatus = .notDetermined
    
    /// Whether authorization is being requested
    @State private var isRequestingAuthorization = false
    
    /// Current tab selection
    @State private var selectedTab: Tab = .songs
    
    /// Search text
    @State private var searchText = ""
    
    /// All songs from library
    @State private var allSongs: [MusicLibraryItem] = []
    
    /// All playlists from library
    @State private var playlists: [MusicLibraryItem] = []
    
    /// Filtered songs based on search
    @State private var filteredSongs: [MusicLibraryItem] = []
    
    /// Loading state
    @State private var isLoading = false
    
    /// Error message
    @State private var errorMessage: String?
    
    // MARK: - Types
    
    enum Tab: String, CaseIterable {
        case songs = "Songs"
        case playlists = "Playlists"
    }
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            if providesNavigation {
                NavigationStack {
                    contentView
                        .navigationTitle("Choose Music")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    dismiss()
                                }
                            }
                        }
                }
            } else {
                contentView
            }
        }
        .task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            switch authorizationStatus {
            case .notDetermined:
                authorizationRequestView
            case .authorized:
                musicBrowserView
            case .denied, .restricted:
                authorizationDeniedView
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Subviews
    
    /// View shown when authorization hasn't been requested yet
    private var authorizationRequestView: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Access Your Music")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To play music from your library during meditation, we need permission to access your music.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                Task {
                    await requestAuthorization()
                }
            }) {
                if isRequestingAuthorization {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Allow Access")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequestingAuthorization)
        }
        .padding()
    }
    
    /// View shown when authorization is denied
    private var authorizationDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Music Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To use music from your library, please enable access in Settings > Privacy & Security > Media & Apple Music.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    /// Main music browser view
    private var musicBrowserView: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Category", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Search bar (only for songs)
            if selectedTab == .songs {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search songs...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await loadMusic()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            } else {
                switch selectedTab {
                case .songs:
                    songsList
                case .playlists:
                    playlistsList
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            filterSongs(query: newValue)
        }
    }
    
    /// List of songs
    private var songsList: some View {
        let items = searchText.isEmpty ? allSongs : filteredSongs
        
        return Group {
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No songs found" : "No matching songs")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items, id: \.persistentID) { item in
                    musicItemRow(item: item)
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// List of playlists
    private var playlistsList: some View {
        Group {
            if playlists.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No playlists found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(playlists, id: \.persistentID) { item in
                    musicItemRow(item: item)
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// Individual music item row
    private func musicItemRow(item: MusicLibraryItem) -> some View {
        Button(action: {
            selectItem(item)
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Checkmark if selected
                if selectedItem?.persistentID == item.persistentID {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Methods
    
    /// Check current authorization status
    private func checkAuthorization() async {
        let status = await musicService.getAuthorizationStatus()
        await MainActor.run {
            self.authorizationStatus = status
            if status == .authorized {
                Task {
                    await loadMusic()
                }
            }
        }
    }
    
    /// Request authorization
    private func requestAuthorization() async {
        await MainActor.run {
            isRequestingAuthorization = true
        }
        
        let granted = await musicService.requestAuthorization()
        
        await MainActor.run {
            isRequestingAuthorization = false
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                Task {
                    await loadMusic()
                }
            }
        }
    }
    
    /// Load music from library
    private func loadMusic() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let songs = try await musicService.fetchSongs()
            let lists = try await musicService.fetchPlaylists()
            
            await MainActor.run {
                self.allSongs = songs
                self.filteredSongs = songs
                self.playlists = lists
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Filter songs based on search query
    private func filterSongs(query: String) {
        if query.isEmpty {
            filteredSongs = allSongs
        } else {
            let lowercased = query.lowercased()
            filteredSongs = allSongs.filter { item in
                item.title.lowercased().contains(lowercased) ||
                (item.artist?.lowercased().contains(lowercased) ?? false) ||
                (item.album?.lowercased().contains(lowercased) ?? false)
            }
        }
    }
    
    /// Select a music item
    private func selectItem(_ item: MusicLibraryItem) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        selectedItem = item
        item.saveToUserDefaults()
        onSelection?(item)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MusicPickerView(selectedItem: .constant(nil))
}
