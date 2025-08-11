import SwiftUI
import UIKit

// Custom button style for responsive tab buttons
struct ResponsiveTabButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct LibraryView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Y2KColors.neon)
                        Text("Loading music library...")
                            .font(.monospacedCaption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else if dataManager.albums.isEmpty && dataManager.artists.isEmpty {
                    EmptyLibraryView()
                } else {
                    LibraryListView()
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                        .environmentObject(downloadManager)
                }
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
}



struct EmptyLibraryView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.monospacedSystem(size: 80))
                .foregroundColor(Y2KColors.neon.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("No Library Available")
                    .font(.monospacedTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Connect to your Navidrome server or import local music files")
                    .font(.monospacedBody)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    NavigationLink(destination: ServerConnectionView().environmentObject(UnifiedDataManager())) {
                        HStack {
                            Image(systemName: "server.rack")
                            Text("Connect to Server")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.neon)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.glow, lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Import Local Files")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Create a test track for background audio testing
                        let testTrack = Track(
                            title: "Background Audio Test",
                            artist: "Test Artist",
                            album: "Test Album",
                            duration: 30.0
                        )
                        musicPlayer.loadTrack(testTrack)
                        musicPlayer.play()
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.3")
                            Text("Test Background Audio")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.neon.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.glow.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Load sample data for testing offline functionality
                        dataManager.switchToLocal()
                    }) {
                        HStack {
                            Image(systemName: "music.note.list")
                            Text("Load Sample Music")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.glow.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.neon.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(dataManager)
        }
    }
}



struct AlbumCard: View {
    let album: Album
    @EnvironmentObject var downloadManager: DownloadManager
    
    private var downloadStatus: String {
        let downloadedCount = album.tracks.filter { downloadManager.isDownloaded($0) }.count
        let downloadingCount = album.tracks.filter { downloadManager.isDownloading($0) }.count
        
        print("🎵 Album: \(album.title) - Downloaded: \(downloadedCount), Downloading: \(downloadingCount)")
        
        if downloadedCount > 0 {
            return "✅ \(downloadedCount) downloaded"
        } else if downloadingCount > 0 {
            return "🔄 \(downloadingCount) downloading"
        } else {
            return "📥 Not downloaded"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = album.artworkURL {
                // Handle both web URLs and local file paths
                if artworkURL.hasPrefix("http") {
                    // Web URL
                    AsyncImage(url: URL(string: artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Y2KColors.neon, Y2KColors.glow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.monospacedLargeTitle)
                                        .foregroundColor(.white)
                                )
                    }
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Local file path
                    if let image = UIImage(contentsOfFile: artworkURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    } else {
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
                                Image(systemName: "music.note")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            } else {
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
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(album.artist)
                    .font(.monospacedSubheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                HStack {
                    if let year = album.year {
                        Text("\(year)")
                            .font(.monospacedCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Download status indicator - make it more prominent
                    if !album.tracks.isEmpty {
                        let downloadedCount = album.tracks.filter { downloadManager.isDownloaded($0) }.count
                        let downloadingCount = album.tracks.filter { downloadManager.isDownloading($0) }.count
                        
                        if downloadedCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("\(downloadedCount)")
                                    .font(.monospacedCaption)
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                    )
                            )
                        } else if downloadingCount > 0 {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Y2KColors.neon)
                                Text("\(downloadingCount)")
                                    .font(.monospacedCaption)
                                    .foregroundColor(Y2KColors.neon)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Y2KColors.neon.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Y2KColors.neon.opacity(0.5), lineWidth: 2)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .frame(width: 150)
        .overlay(
            // Debug overlay to show download status
            VStack {
                HStack {
                    Spacer()
                    Text(downloadStatus)
                        .font(.monospacedCaption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.7))
                        )
                }
                Spacer()
            }
            .padding(4)
        )
    }
}

struct LibraryListView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        ScrollView {
            if dataManager.libraryViewMode == .grid {
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
                            .contextMenu {
                                ArtistDownloadContextMenu(artist: artist)
                            }
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dataManager.artists) { artist in
                        ArtistListRow(artist: artist)
                            .onTapGesture {
                                let allTracks = artist.albums.flatMap { $0.tracks }
                                if !allTracks.isEmpty {
                                    musicPlayer.setQueue(allTracks)
                                }
                            }
                            .contextMenu {
                                ArtistDownloadContextMenu(artist: artist)
                            }
                    }
                }
                .padding()
            }
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artworkURL = artist.artworkURL {
                // Handle both web URLs and local file paths
                if artworkURL.hasPrefix("http") {
                    // Web URL
                    AsyncImage(url: URL(string: artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Y2KColors.neon, Y2KColors.glow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "person.3.fill")
                                        .font(.monospacedLargeTitle)
                                        .foregroundColor(.white)
                                )
                    }
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Local file path
                    if let image = UIImage(contentsOfFile: artworkURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Y2KColors.neon, Y2KColors.glow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Y2KColors.neon, Y2KColors.glow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("\(artist.albums.count) albums")
                        .font(.monospacedSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Download status indicator
                    ArtistDownloadStatus(artist: artist)
                }
            }
        }
        .frame(width: 120)
    }
}

struct ArtistListRow: View {
    let artist: Artist
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        HStack(spacing: 12) {
            if let artworkURL = artist.artworkURL {
                // Handle both web URLs and local file paths
                if artworkURL.hasPrefix("http") {
                    // Web URL
                    AsyncImage(url: URL(string: artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Y2KColors.neon, Y2KColors.glow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "person.3.fill")
                                        .font(.monospacedTitle2)
                                        .foregroundColor(.white)
                                )
                    }
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Local file path
                    if let image = UIImage(contentsOfFile: artworkURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Y2KColors.neon, Y2KColors.glow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Y2KColors.neon, Y2KColors.glow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text("\(artist.albums.count) albums")
                        .font(.monospacedSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Download status indicator
                    ArtistDownloadStatus(artist: artist)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
                .font(.monospacedSystem(size: 14, weight: .medium))
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



#Preview {
    LibraryView()
        .environmentObject(UnifiedDataManager())
        .environmentObject(MusicPlayerManager())
}
