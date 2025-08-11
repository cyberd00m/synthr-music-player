import SwiftUI
import UIKit

struct DownloadContextMenu: View {
    let track: Track
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        Group {
            if downloadManager.isDownloaded(track) {
                // Track is already downloaded
                Button(action: {
                    // Play the track
                    musicPlayer.setQueue([track])
                    musicPlayer.play()
                }) {
                    Label("Play", systemImage: "play.fill")
                }
                
                Button(action: {
                    // Remove download
                    downloadManager.deleteDownloadedTrack(track)
                }) {
                    Label("Remove Download", systemImage: "trash")
                }
                .foregroundColor(.red)
                
            } else if downloadManager.isDownloading(track) {
                // Track is currently downloading
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Downloading...")
                        .font(.monospacedCaption)
                }
                .disabled(true)
                
            } else {
                // Track is not downloaded
                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    Task {
                        await downloadManager.downloadTrack(track)
                    }
                }) {
                    Label("Download for Offline", systemImage: "arrow.down.circle")
                }
                
                Button(action: {
                    // Play the track (streaming)
                    musicPlayer.setQueue([track])
                    musicPlayer.play()
                }) {
                    Label("Play Now", systemImage: "play.fill")
                }
            }
        }
    }
}

struct AlbumDownloadContextMenu: View {
    let album: Album
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        Group {
            Button(action: {
                // Play the entire album
                musicPlayer.setQueue(album.tracks)
                musicPlayer.play()
            }) {
                Label("Play Album", systemImage: "play.fill")
            }
            
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                Task {
                    await downloadManager.downloadAlbum(album)
                }
            }) {
                Label("Download Album for Offline", systemImage: "arrow.down.circle")
            }
            
            // Show download status for album tracks
            if !album.tracks.isEmpty {
                let downloadedCount = album.tracks.filter { downloadManager.isDownloaded($0) }.count
                let downloadingCount = album.tracks.filter { downloadManager.isDownloading($0) }.count
                
                if downloadedCount > 0 || downloadingCount > 0 {
                    HStack {
                        Text("\(downloadedCount) downloaded")
                            .font(.monospacedCaption)
                            .foregroundColor(.green)
                        
                        if downloadingCount > 0 {
                            Text("• \(downloadingCount) downloading")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .disabled(true)
                }
            }
        }
    }
}

struct ArtistDownloadContextMenu: View {
    let artist: Artist
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        Group {
            Button(action: {
                // Play all tracks by the artist
                let allTracks = artist.albums.flatMap { $0.tracks }
                musicPlayer.setQueue(allTracks)
                musicPlayer.play()
            }) {
                Label("Play All", systemImage: "play.fill")
            }
            
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                Task {
                    await downloadManager.downloadArtist(artist)
                }
            }) {
                Label("Download All for Offline", systemImage: "arrow.down.circle")
            }
            
            // Show download status for artist tracks
            let allTracks = artist.albums.flatMap { $0.tracks }
            let downloadedCount = allTracks.filter { downloadManager.isDownloaded($0) }.count
            let downloadingCount = allTracks.filter { downloadManager.isDownloading($0) }.count
            
            if downloadedCount > 0 || downloadingCount > 0 {
                HStack {
                    Text("\(downloadedCount) downloaded")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if downloadingCount > 0 {
                        Text("• \(downloadingCount) downloading")
                            .font(.monospacedCaption)
                            .foregroundColor(.orange)
                    }
                }
                .disabled(true)
            }
        }
    }
}

struct DownloadProgressView: View {
    let track: Track
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        if downloadManager.isDownloading(track) {
            VStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: Y2KColors.neon))
                    .scaleEffect(0.8)
                
                Text("Downloading...")
                    .font(.monospacedCaption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Y2KColors.cosmic.opacity(0.8))
            )
        } else if downloadManager.isDownloaded(track) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.monospacedCaption)
                
                Text("Downloaded")
                    .font(.monospacedCaption2)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Y2KColors.cosmic.opacity(0.8))
            )
        }
    }
}

// MARK: - Download Status Badge
struct DownloadStatusBadge: View {
    let track: Track
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        if downloadManager.isDownloaded(track) {
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .font(.monospacedCaption)
                Text("✓")
                    .foregroundColor(.green)
                    .font(.monospacedCaption2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        } else if downloadManager.isDownloading(track) {
            HStack(spacing: 2) {
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(Y2KColors.neon)
                Text("↓")
                    .foregroundColor(Y2KColors.neon)
                    .font(.monospacedCaption2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Y2KColors.neon.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Album Download Status
struct AlbumDownloadStatus: View {
    let album: Album
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        if !album.tracks.isEmpty {
            let downloadedCount = album.tracks.filter { downloadManager.isDownloaded($0) }.count
            let downloadingCount = album.tracks.filter { downloadManager.isDownloading($0) }.count
            
            if downloadedCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.monospacedCaption)
                    Text("\(downloadedCount)")
                        .font(.monospacedCaption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            } else if downloadingCount > 0 {
                HStack(spacing: 2) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(Y2KColors.neon)
                    Text("\(downloadingCount)")
                        .font(.monospacedCaption)
                        .foregroundColor(Y2KColors.neon)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Y2KColors.neon.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Artist Download Status
struct ArtistDownloadStatus: View {
    let artist: Artist
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        let allTracks = artist.albums.flatMap { $0.tracks }
        let downloadedCount = allTracks.filter { downloadManager.isDownloaded($0) }.count
        let downloadingCount = allTracks.filter { downloadManager.isDownloading($0) }.count
        
        if downloadedCount > 0 {
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .font(.monospacedCaption)
                Text("\(downloadedCount)")
                    .font(.monospacedCaption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        } else if downloadingCount > 0 {
            HStack(spacing: 2) {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Y2KColors.neon)
                Text("\(downloadingCount)")
                    .font(.monospacedCaption)
                    .foregroundColor(Y2KColors.neon)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Y2KColors.neon.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
