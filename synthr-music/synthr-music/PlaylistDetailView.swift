import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPlaylistSheet = false
    @State private var selectedTrack: Track?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Playlist Header Section
                VStack(spacing: 20) {
                    // Large Playlist Artwork
                    PlaylistArtworkView(playlist: playlist)
                        .frame(width: 280, height: 280)
                    
                    // Playlist Information
                    VStack(spacing: 8) {
                        Text(playlist.name)
                            .font(.monospacedTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(playlist.trackCount) songs • edited \(formatDate(playlist.createdAt))")
                            .font(.monospacedSubheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Playback Controls
                    HStack(spacing: 30) {
                        // Download Button
                        Button(action: {
                            // TODO: Implement download functionality
                        }) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.monospacedTitle)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                                )
                        }
                        
                        // Play Button
                        Button(action: {
                            if !playlist.tracks.isEmpty {
                                musicPlayer.setQueue(playlist.tracks)
                                musicPlayer.play()
                            }
                        }) {
                            Image(systemName: "play.fill")
                                .font(.monospacedTitle2)
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(.white)
                                )
                        }
                        .disabled(playlist.tracks.isEmpty)
                        
                        // Shuffle Button
                        Button(action: {
                            if !playlist.tracks.isEmpty {
                                musicPlayer.setQueue(playlist.tracks.shuffled())
                                musicPlayer.play()
                            }
                        }) {
                            Image(systemName: "shuffle")
                                .font(.monospacedTitle)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                                )
                        }
                        .disabled(playlist.tracks.isEmpty)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tracks List
                if playlist.tracks.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.monospacedSystem(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No tracks in this playlist")
                            .font(.monospacedTitle3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Add some tracks to get started")
                            .font(.monospacedBody)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                                TrackRow(
                                    track: track,
                                    index: index + 1,
                                    isCurrentTrack: musicPlayer.currentTrack?.id == track.id,
                                    onAddToPlaylist: {
                                        selectedTrack = track
                                        showPlaylistSheet = true
                                    }
                                )
                                .onTapGesture {
                                    musicPlayer.setQueue(playlist.tracks, startIndex: index)
                                    musicPlayer.play()
                                }
                                .contextMenu {
                                    TrackContextMenu(track: track)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.monospacedSystem(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Show playlist options menu
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.monospacedSystem(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Y2KColors.deepSpace, Y2KColors.midnight, Y2KColors.cosmic],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showPlaylistSheet) {
            if let track = selectedTrack {
                PlaylistSelectionSheet(tracks: [track], album: nil)
                    .environmentObject(dataManager)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    

}

struct PlaylistArtworkView: View {
    let playlist: Playlist
    
    var body: some View {
        if let artworkURL = playlist.artworkURL {
            if artworkURL.hasPrefix("http") {
                AsyncImage(url: URL(string: artworkURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultArtwork
                }
                .frame(width: 280, height: 280)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                )
            } else {
                if let image = UIImage(contentsOfFile: artworkURL) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 280)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    defaultArtwork
                }
            }
        } else {
            defaultArtwork
        }
    }
    
    private var defaultArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Y2KColors.neon, Y2KColors.glow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 280, height: 280)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.monospacedSystem(size: 80, weight: .light))
                        .foregroundColor(.white)
                    
                    if playlist.trackCount > 0 {
                        Text("\(playlist.trackCount)")
                            .font(.monospacedSystem(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
            )
    }
}

struct TrackRow: View {
    let track: Track
    let index: Int
    let isCurrentTrack: Bool
    let onAddToPlaylist: () -> Void
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        HStack(spacing: 12) {
            if isCurrentTrack {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.monospacedSystem(size: 16, weight: .medium))
                    .foregroundColor(Y2KColors.neon)
                    .frame(width: 24, height: 24)
            } else {
                Text("\(index)")
                    .font(.monospacedSystem(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 24, height: 24)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.monospacedSystem(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.monospacedSystem(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.monospacedSystem(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if downloadManager.isDownloaded(track) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.monospacedSystem(size: 16, weight: .medium))
                    .foregroundColor(.green)
            } else if downloadManager.isDownloading(track) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Y2KColors.neon)
            }
            
            Image(systemName: "ellipsis")
                .font(.monospacedSystem(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentTrack ? Y2KColors.neon.opacity(0.2) : Color.clear)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onAddToPlaylist) {
                Label("Add to Playlist", systemImage: "plus.circle")
            }
            .tint(Y2KColors.neon)
        }
    }
}

struct TrackContextMenu: View {
    let track: Track
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        if downloadManager.isDownloaded(track) {
            Button("Remove Download") {
                downloadManager.deleteDownloadedTrack(track)
            }
            .foregroundColor(.red)
        } else {
            Button("Download") {
                Task {
                    await downloadManager.downloadTrack(track)
                }
            }
            .foregroundColor(Y2KColors.neon)
        }
        
        Button("Add to Playlist") {
            // TODO: Implement add to playlist functionality
        }
        .foregroundColor(.white)
    }
}

#Preview {
    let samplePlaylist = Playlist(
        name: "Bine",
        description: "A great playlist",
        tracks: [
            Track(title: "Intro (Kaira)", artist: "Deflone", album: "Sample Album", duration: 180),
            Track(title: "You Need My Adidas (2017 VIP edit)", artist: "Dogz Nadz", album: "Sample Album", duration: 240)
        ]
    )
    
    PlaylistDetailView(playlist: samplePlaylist)
        .environmentObject(MusicPlayerManager())
        .environmentObject(DownloadManager())
}
