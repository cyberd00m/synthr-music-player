import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var searchText = ""
    @State private var searchResults: [Track] = []
    @State private var showPlaylistSheet = false
    @State private var selectedTrack: Track?
    @State private var selectedTracks: [Track] = []
    @State private var selectedAlbum: Album?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.monospacedSystem(size: 16, weight: .medium))
                    
                    TextField("Search songs, albums, artists...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.monospacedSystem(size: 16))
                        .foregroundColor(.white)
                        .onChange(of: searchText) { newValue in
                            searchResults = dataManager.searchTracks(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.monospacedSystem(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Y2KColors.cosmic)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Search results
                if searchText.isEmpty {
                    RecentSearchesView(onAddAlbumToPlaylist: { album in
                        selectedTracks = album.tracks
                        selectedAlbum = album
                        showPlaylistSheet = true
                    })
                } else if searchResults.isEmpty {
                    NoResultsView()
                } else {
                    SearchResultsView(results: searchResults, onAddTrackToPlaylist: { track in
                        selectedTracks = [track]
                        selectedAlbum = nil
                        showPlaylistSheet = true
                    })
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                        .environmentObject(downloadManager)
                }
            }
            .sheet(isPresented: $showPlaylistSheet) {
                PlaylistSelectionSheet(tracks: selectedTracks, album: selectedAlbum)
                    .environmentObject(dataManager)
            }
        }
        .background(
            LinearGradient(
                colors: [Y2KColors.deepSpace, Y2KColors.midnight],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func createAddToPlaylistClosure(for album: Album) -> () -> Void {
        return {
            self.selectedTracks = album.tracks
            self.selectedAlbum = album
            self.showPlaylistSheet = true
        }
    }
}

struct RecentSearchesView: View {
    let onAddAlbumToPlaylist: (Album) -> Void
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Searches")
                .font(.monospacedTitle3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(dataManager.albums.prefix(3)) { album in
                        RecentSearchCard(album: album, onAddToPlaylist: { onAddAlbumToPlaylist(album) })
                            .onTapGesture {
                                musicPlayer.setQueue(album.tracks)
                            }
                            .contextMenu {
                                AlbumDownloadContextMenu(album: album)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct RecentSearchCard: View {
    let album: Album
    let onAddToPlaylist: () -> Void
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Compact album artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Y2KColors.neon, Y2KColors.glow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.monospacedSystem(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.monospacedSystem(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(.monospacedSystem(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                Text("\(album.tracks.count) tracks")
                    .font(.monospacedSystem(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.monospacedSystem(size: 14, weight: .medium))
                
                // Download status indicator
                AlbumDownloadStatus(album: album)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Y2KColors.cosmic)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SearchResultsView: View {
    let results: [Track]
    let onAddTrackToPlaylist: (Track) -> Void
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    
    var body: some View {
        if dataManager.searchViewMode == .grid {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(results) { track in
                        TrackGridCard(track: track, onAddToPlaylist: { onAddTrackToPlaylist(track) })
                            .onTapGesture {
                                musicPlayer.setQueue([track])
                                musicPlayer.play()
                            }
                            .contextMenu {
                                DownloadContextMenu(track: track)
                            }
                    }
                }
                .padding()
            }
        } else {
            List(results) { track in
                TrackRowView(track: track, onAddToPlaylist: { onAddTrackToPlaylist(track) })
                    .onTapGesture {
                        musicPlayer.setQueue([track])
                        musicPlayer.play()
                    }
                    .contextMenu {
                        DownloadContextMenu(track: track)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
        }
    }
}

struct TrackRowView: View {
    let track: Track
    let onAddToPlaylist: () -> Void
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Compact track artwork
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Y2KColors.neon, Y2KColors.glow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.monospacedSystem(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.monospacedSystem(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.monospacedSystem(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(track.duration))
                    .font(.monospacedSystem(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                // Download status indicator
                DownloadStatusBadge(track: track)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TrackGridCard: View {
    let track: Track
    let onAddToPlaylist: () -> Void
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Track artwork
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Y2KColors.neon, Y2KColors.glow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.monospacedLargeTitle)
                            .foregroundColor(.white)
                        
                        Image(systemName: "play.circle.fill")
                            .font(.monospacedTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(track.artist)
                    .font(.monospacedSubheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                HStack {
                    Text(track.album)
                        .font(.monospacedCaption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Download status indicator
                    DownloadStatusBadge(track: track)
                }
            }
        }
        .frame(width: 150)
    }
}

struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.monospacedSystem(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No Results Found")
                .font(.monospacedSystem(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Try searching for something else or check your spelling.")
                .font(.monospacedSystem(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchView()
        .environmentObject(UnifiedDataManager())
        .environmentObject(MusicPlayerManager())
}
