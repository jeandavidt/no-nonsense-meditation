//
//  MusicPickerView.swift
//  NoNonsenseMeditation
//
//  Created on 2026-01-12.
//  Updated on 2026-01-28 - Added Podcasts support
//

import SwiftUI
import MediaPlayer

/// View for browsing and selecting music/podcasts from the user's library
/// Supports songs, playlists, and podcasts with search functionality
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
    
    /// Initial tab to show when view appears
    var initialTab: Tab = .songs
    
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
    
    /// All podcast shows from library
    @State private var podcastShows: [MusicLibraryItem] = []
    
    /// All podcast episodes (for search results)
    @State private var allPodcastEpisodes: [MusicLibraryItem] = []
    
    /// Episodes for currently selected podcast show
    @State private var currentPodcastEpisodes: [MusicLibraryItem] = []
    
    /// Currently selected podcast show (for episode navigation)
    @State private var selectedPodcastShow: MusicLibraryItem?
    
    /// Whether we're viewing podcast episodes
    @State private var isViewingEpisodes = false
    
    /// Filtered songs based on search
    @State private var filteredSongs: [MusicLibraryItem] = []
    
    /// Filtered podcast episodes based on search
    @State private var filteredPodcastEpisodes: [MusicLibraryItem] = []
    
    /// Loading state
    @State private var isLoading = false
    
    /// Error message
    @State private var errorMessage: String?
    
    // MARK: - Types
    
    enum Tab: String, CaseIterable {
        case songs = "Songs"
        case playlists = "Playlists"
        case podcasts = "Podcasts"
    }
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            if providesNavigation {
                NavigationStack {
                    contentView
                        .navigationTitle(isViewingEpisodes ? selectedPodcastShow?.title ?? "Episodes" : "Choose Content")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if isViewingEpisodes {
                                    Button("Back") {
                                        withAnimation {
                                            isViewingEpisodes = false
                                            selectedPodcastShow = nil
                                            currentPodcastEpisodes = []
                                        }
                                    }
                                } else {
                                    Button("Cancel") {
                                        dismiss()
                                    }
                                }
                            }
                        }
                }
            } else {
                contentView
            }
        }
        .onAppear {
            selectedTab = initialTab
        }
        .onChange(of: initialTab) { _, newTab in
            selectedTab = newTab
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
            
            Text("Access Your Media")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To play music or podcasts from your library during meditation, we need permission to access your media.")
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
            
            Text("Media Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To use music or podcasts from your library, please enable access in Settings > Privacy & Security > Media & Apple Music.")
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
    @ViewBuilder
    private var musicBrowserView: some View {
        if isViewingEpisodes {
            podcastEpisodesList
        } else {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Category", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Search bar
                searchBarView
                    .padding(.bottom, 8)
                
                // Content
                contentArea
            }
            .onChange(of: searchText) { _, newValue in
                filterContent()
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab != .podcasts {
                    isViewingEpisodes = false
                    selectedPodcastShow = nil
                }
            }
        }
    }
    
    /// Search bar view
    @ViewBuilder
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(searchPlaceholderText, text: $searchText)
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
    }
    
    private var searchPlaceholderText: String {
        switch selectedTab {
        case .songs:
            return "Search songs..."
        case .playlists:
            return "Search playlists..."
        case .podcasts:
            return "Search podcasts..."
        }
    }
    
    /// Content area based on selected tab
    @ViewBuilder
    private var contentArea: some View {
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
                        await loadContent()
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
            case .podcasts:
                podcastShowsList
            }
        }
    }
    
    /// List of songs
    private var songsList: some View {
        let items = searchText.isEmpty ? allSongs : filteredSongs
        
        return Group {
            if items.isEmpty {
                emptyStateView(
                    icon: "music.note",
                    title: searchText.isEmpty ? "No songs found" : "No matching songs"
                )
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
                emptyStateView(
                    icon: "music.note.list",
                    title: "No playlists found"
                )
            } else {
                List(playlists, id: \.persistentID) { item in
                    musicItemRow(item: item)
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// List of podcast shows
    private var podcastShowsList: some View {
        let items = searchText.isEmpty ? podcastShows : filteredPodcastEpisodes
        
        return Group {
            if items.isEmpty {
                emptyStateView(
                    icon: "mic.fill",
                    title: searchText.isEmpty ? "No podcasts found" : "No matching podcasts"
                )
            } else {
                List(items, id: \.persistentID) { item in
                    if item.itemType == .podcastShow {
                        podcastShowRow(item: item)
                    } else {
                        musicItemRow(item: item)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// List of podcast episodes for a selected show
    private var podcastEpisodesList: some View {
        let items = searchText.isEmpty ? currentPodcastEpisodes : filteredPodcastEpisodes
        
        return Group {
            if items.isEmpty {
                emptyStateView(
                    icon: "antenna.radiowaves.left.and.right",
                    title: searchText.isEmpty ? "No episodes found" : "No matching episodes"
                )
            } else {
                List(items, id: \.persistentID) { item in
                    podcastEpisodeRow(item: item)
                }
                .listStyle(.plain)
            }
        }
    }
    
    /// Empty state view
    private func emptyStateView(icon: String, title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Individual music item row
    private func musicItemRow(item: MusicLibraryItem) -> some View {
        Button(action: {
            selectItem(item)
        }) {
            itemRowContent(item: item)
        }
        .buttonStyle(.plain)
    }
    
    /// Podcast show row (navigates to episodes)
    private func podcastShowRow(item: MusicLibraryItem) -> some View {
        Button(action: {
            selectPodcastShow(item)
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.iconName)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 40, height: 40)
                    .background(Color.purple.opacity(0.1))
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// Podcast episode row
    private func podcastEpisodeRow(item: MusicLibraryItem) -> some View {
        Button(action: {
            selectItem(item)
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.iconName)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 40, height: 40)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        if let duration = item.duration, duration > 0 {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    
    /// Shared item row content
    private func itemRowContent(item: MusicLibraryItem) -> some View {
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
    
    // MARK: - Methods
    
    /// Check current authorization status
    private func checkAuthorization() async {
        let status = await musicService.getAuthorizationStatus()
        await MainActor.run {
            self.authorizationStatus = status
            if status == .authorized {
                Task {
                    await loadContent()
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
                    await loadContent()
                }
            }
        }
    }
    
    /// Load content based on selected tab
    private func loadContent() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let songs = try await musicService.fetchSongs()
            let playlists = try await musicService.fetchPlaylists()
            let podcasts = try await musicService.fetchPodcastShows()
            let podcastEpisodes = try await musicService.fetchAllPodcastEpisodes()
            
            await MainActor.run {
                self.allSongs = songs
                self.filteredSongs = songs
                self.playlists = playlists
                self.podcastShows = podcasts
                self.allPodcastEpisodes = podcastEpisodes
                self.filteredPodcastEpisodes = podcastEpisodes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Filter content based on search query
    private func filterContent() {
        if searchText.isEmpty {
            filteredSongs = allSongs
            filteredPodcastEpisodes = allPodcastEpisodes
        } else {
            let lowercased = searchText.lowercased()
            
            filteredSongs = allSongs.filter { item in
                item.title.lowercased().contains(lowercased) ||
                (item.artist?.lowercased().contains(lowercased) ?? false) ||
                (item.album?.lowercased().contains(lowercased) ?? false)
            }
            
            filteredPodcastEpisodes = allPodcastEpisodes.filter { item in
                item.title.lowercased().contains(lowercased) ||
                (item.podcastShowTitle?.lowercased().contains(lowercased) ?? false)
            }
        }
    }
    
    /// Select a podcast show and load its episodes
    private func selectPodcastShow(_ show: MusicLibraryItem) {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let episodes = try await musicService.fetchPodcastEpisodes(for: show.persistentID)
                
                await MainActor.run {
                    self.currentPodcastEpisodes = episodes
                    self.selectedPodcastShow = show
                    self.searchText = ""
                    self.isLoading = false
                    withAnimation {
                        self.isViewingEpisodes = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Select a music/podcast item
    private func selectItem(_ item: MusicLibraryItem) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        selectedItem = item
        item.saveToUserDefaults()
        onSelection?(item)
        dismiss()
    }
    
    /// Format duration in minutes
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Preview

#Preview {
    MusicPickerView(selectedItem: .constant(nil))
}
