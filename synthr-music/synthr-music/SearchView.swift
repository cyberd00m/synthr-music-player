import SwiftUI

struct SearchView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var searchText = ""
    @State private var searchResults: [Track] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for songs, albums, or artists...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            searchResults = dataManager.searchTracks(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Search results
                if searchText.isEmpty {
                    RecentSearchesView()
                } else if searchResults.isEmpty {
                    NoResultsView()
                } else {
                    SearchResultsView(results: searchResults)
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}

struct RecentSearchesView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Searches")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(dataManager.albums.prefix(3)) { album in
                        RecentSearchCard(album: album)
                            .onTapGesture {
                                musicPlayer.setQueue(album.tracks)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecentSearchCard: View {
    let album: Album
    
    var body: some View {
        HStack(spacing: 16) {
            // Album artwork
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(album.tracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SearchResultsView: View {
    let results: [Track]
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        List(results) { track in
            TrackRowView(track: track)
                .onTapGesture {
                    musicPlayer.setQueue([track])
                    musicPlayer.play()
                }
        }
        .listStyle(PlainListStyle())
    }
}

struct TrackRowView: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 16) {
            // Track artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatDuration(track.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try searching for something else or check your spelling.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchView()
        .environmentObject(UnifiedDataManager())
        .environmentObject(MusicPlayerManager())
}
