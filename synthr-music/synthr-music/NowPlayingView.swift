import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentTrack = musicPlayer.currentTrack {
                    TrackInfoView(track: currentTrack)
                    
                    ProgressView()
                    
                    PlayerControlsView()
                    
                    QueueView()
                    
                    Spacer()
                } else {
                    NoTrackPlayingView()
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}

struct TrackInfoView: View {
    let track: Track
    
    var body: some View {
        VStack(spacing: 24) {
            // Album artwork
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 280, height: 280)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                )
                .shadow(radius: 20)
            
            VStack(spacing: 8) {
                Text(track.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(track.artist)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(track.album)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
    }
}

struct ProgressView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress slider
            Slider(
                value: Binding(
                    get: { musicPlayer.currentTime },
                    set: { musicPlayer.seek(to: $0) }
                ),
                in: 0...max(musicPlayer.duration, 1)
            )
            .accentColor(.purple)
            .padding(.horizontal)
            
            // Time labels
            HStack {
                Text(formatTime(musicPlayer.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(musicPlayer.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlayerControlsView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Main controls
            HStack(spacing: 40) {
                Button(action: musicPlayer.previousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    if musicPlayer.playbackState == .playing {
                        musicPlayer.pause()
                    } else {
                        musicPlayer.play()
                    }
                }) {
                    Image(systemName: musicPlayer.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                }
                
                Button(action: musicPlayer.nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                }
            }
            
            // Secondary controls
            HStack(spacing: 40) {
                Button(action: musicPlayer.toggleShuffle) {
                    Image(systemName: musicPlayer.shuffleMode == .on ? "shuffle" : "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(musicPlayer.shuffleMode == .on ? .purple : .secondary)
                }
                
                Button(action: musicPlayer.toggleRepeat) {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 20))
                        .foregroundColor(musicPlayer.repeatMode == .none ? .secondary : .purple)
                }
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    private var repeatIcon: String {
        switch musicPlayer.repeatMode {
        case .none:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
}

struct QueueView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Up Next")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(musicPlayer.queue.count) tracks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if !musicPlayer.queue.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(musicPlayer.queue.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                isCurrent: index == musicPlayer.currentQueueIndex
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            } else {
                Text("No tracks in queue")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
}

struct QueueTrackRow: View {
    let track: Track
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Track artwork
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline)
                    .foregroundColor(isCurrent ? .purple : .primary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isCurrent ? Color.purple.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct NoTrackPlayingView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("No Track Playing")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a track from your library to start listening")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NowPlayingView()
        .environmentObject(MusicPlayerManager())
}
