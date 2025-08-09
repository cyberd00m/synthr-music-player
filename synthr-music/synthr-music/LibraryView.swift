import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segmented control
                HStack(spacing: 0) {
                                    Button("Playlists") { 
                    selectedTab = 0
                }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == 0 ? Color.purple : Color.clear)
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .cornerRadius(8)
                    
                                    Button("Library") {
                    selectedTab = 1
                }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == 1 ? Color.purple : Color.clear)
                    .foregroundColor(selectedTab == 1 ? .white : .primary)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if dataManager.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading music library...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if dataManager.albums.isEmpty && dataManager.artists.isEmpty {
                    if selectedTab == 0 {
                        EmptyPlaylistsView()
                    } else {
                        EmptyLibraryView()
                    }
                } else {
                    if selectedTab == 0 {
                        PlaylistsListView()
                    } else {
                        LibraryListView()
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}

struct EmptyPlaylistsView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("No Playlists Available")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Connect to your Navidrome server to access your music library")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                NavigationLink(destination: ServerConnectionView().environmentObject(UnifiedDataManager())) {
                    HStack {
                        Image(systemName: "server.rack")
                        Text("Connect to Server")
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("No Library Available")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Connect to your Navidrome server to access your music library")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                NavigationLink(destination: ServerConnectionView().environmentObject(UnifiedDataManager())) {
                    HStack {
                        Image(systemName: "server.rack")
                        Text("Connect to Server")
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PlaylistsListView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(dataManager.albums) { album in
                    AlbumCard(album: album)
                        .onTapGesture {
                            if !album.tracks.isEmpty {
                                musicPlayer.setQueue(album.tracks)
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct AlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = album.artworkURL {
                AsyncImage(url: URL(string: artworkURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                        )
                }
                .frame(width: 150, height: 150)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                    )
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let year = album.year {
                    Text("\(year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 150)
    }
}

struct LibraryListView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(dataManager.artists) { artist in
                    ArtistCard(artist: artist)
                        .onTapGesture {
                            let allTracks = artist.albums.flatMap { $0.tracks }
                            if !allTracks.isEmpty {
                                musicPlayer.setQueue(allTracks)
                            }
                        }
                }
            }
            .padding()
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = artist.artworkURL {
                AsyncImage(url: URL(string: artworkURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                        )
                }
                .frame(width: 120, height: 120)
                .clipped()
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                    )
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("\(artist.albums.count) albums")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
    }
}

#Preview {
    LibraryView()
        .environmentObject(UnifiedDataManager())
        .environmentObject(MusicPlayerManager())
}
