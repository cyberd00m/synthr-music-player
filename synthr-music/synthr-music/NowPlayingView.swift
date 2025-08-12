import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient matching the image's dark brown theme
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1), // Dark brown
                    Color(red: 0.3, green: 0.2, blue: 0.15), // Medium brown
                    Color(red: 0.25, green: 0.18, blue: 0.12) // Slightly lighter brown
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator only
                HStack {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 40, height: 5)
                        .padding(.leading, 20)
                        .padding(.top, 10)
                    
                    Spacer()
                }
                
                Spacer()
                
                if let currentTrack = musicPlayer.currentTrack {
                    // Album Art Section
                    VStack(spacing: 30) {
                        // Large album artwork
                        ZStack {
                            if let artworkURL = currentTrack.artworkURL {
                                // Handle both web URLs and local file paths
                                if artworkURL.hasPrefix("http") {
                                    // Web URL
                                    AsyncImage(url: URL(string: artworkURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 300, height: 300)
                                            .clipped()
                                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.8, green: 0.6, blue: 0.4), // Light peach/orange
                                                        Color(red: 0.9, green: 0.7, blue: 0.5)  // Lighter peach
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 300, height: 300)
                                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .font(.system(size: 60, weight: .light))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                } else {
                                    // Local file path
                                    if let image = UIImage(contentsOfFile: artworkURL) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 300, height: 300)
                                            .clipped()
                                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    } else {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.8, green: 0.6, blue: 0.4), // Light peach/orange
                                                        Color(red: 0.9, green: 0.7, blue: 0.5)  // Lighter peach
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 300, height: 300)
                                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .font(.system(size: 60, weight: .light))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            } else {
                                // No artwork available - show placeholder
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.8, green: 0.6, blue: 0.4), // Light peach/orange
                                                Color(red: 0.9, green: 0.7, blue: 0.5)  // Lighter peach
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 300, height: 300)
                                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 60, weight: .light))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // Song Information
                        VStack(spacing: 8) {
                            Text(currentTrack.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text(currentTrack.artist)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Progress Section
                    VStack(spacing: 15) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * CGFloat(musicPlayer.currentTime / max(musicPlayer.duration, 1)), height: 3)
                                    .cornerRadius(1.5)
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 20)
                        
                        // Time labels
                        HStack {
                            Text(formatTime(musicPlayer.currentTime))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("-\(formatTime(musicPlayer.duration - musicPlayer.currentTime))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Action buttons (like, download, more)
                    HStack(spacing: 20) {
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "heart")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Main Playback Controls
                    HStack(spacing: 40) {
                        Button(action: musicPlayer.previousTrack) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            if musicPlayer.playbackState == .playing {
                                musicPlayer.pause()
                            } else {
                                musicPlayer.play()
                            }
                        }) {
                            Image(systemName: musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: musicPlayer.nextTrack) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 30)
                    
                    // Bottom navigation
                    HStack(spacing: 40) {
                        Button(action: {}) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "airplayaudio")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 30)
                } else {
                    // No track playing
                    VStack(spacing: 30) {
                        Image(systemName: "music.note")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                        
                        VStack(spacing: 16) {
                            Text("No Track Playing")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Select a track from your library to start listening")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Dismiss if user drags down more than 100 points
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TrackInfoView: View {
    let track: Track
    
    var body: some View {
        VStack(spacing: 24) {
            // Album artwork
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Y2KColors.neon, Y2KColors.glow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.monospacedSystem(size: 80, weight: .light))
                        .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Y2KColors.neon.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 8) {
                Text(track.title)
                    .font(.monospacedTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(track.artist)
                    .font(.monospacedTitle2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(track.album)
                    .font(.monospacedBody)
                    .foregroundColor(.white.opacity(0.6))
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
            .accentColor(Y2KColors.neon)
            .padding(.horizontal)
            
            // Time labels
            HStack {
                Text(formatTime(musicPlayer.currentTime))
                    .font(.monospacedCaption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatTime(musicPlayer.duration))
                    .font(.monospacedCaption)
                    .foregroundColor(.white.opacity(0.8))
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
                        .font(.monospacedSystem(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    if musicPlayer.playbackState == .playing {
                        musicPlayer.pause()
                    } else {
                        musicPlayer.play()
                    }
                }) {
                    Image(systemName: musicPlayer.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.monospacedSystem(size: 60, weight: .light))
                        .foregroundColor(Y2KColors.neon)
                }
                
                Button(action: musicPlayer.nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.monospacedSystem(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // Secondary controls
            HStack(spacing: 40) {
                Button(action: musicPlayer.toggleShuffle) {
                    Image(systemName: musicPlayer.shuffleMode == .on ? "shuffle" : "shuffle")
                        .font(.monospacedSystem(size: 20, weight: .medium))
                        .foregroundColor(musicPlayer.shuffleMode == .on ? Y2KColors.neon : .white.opacity(0.6))
                }
                
                Button(action: musicPlayer.toggleRepeat) {
                    Image(systemName: repeatIcon)
                        .font(.monospacedSystem(size: 20, weight: .medium))
                        .foregroundColor(musicPlayer.repeatMode == .none ? .white.opacity(0.6) : Y2KColors.neon)
                }
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.monospacedSystem(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.monospacedSystem(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
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
                    .font(.monospacedHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(musicPlayer.queue.count) tracks")
                    .font(.monospacedCaption)
                    .foregroundColor(.white.opacity(0.8))
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
                    .font(.monospacedBody)
                    .foregroundColor(.white.opacity(0.8))
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
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.monospacedSubheadline)
                    .foregroundColor(isCurrent ? Y2KColors.neon : .white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.monospacedCaption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(Y2KColors.neon)
                    .font(.monospacedCaption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Y2KColors.neon.opacity(0.2) : Y2KColors.cosmic.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrent ? Y2KColors.neon.opacity(0.3) : Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct NoTrackPlayingView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.monospacedSystem(size: 80, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("No Track Playing")
                    .font(.monospacedTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select a track from your library to start listening")
                    .font(.monospacedBody)
                    .foregroundColor(.white.opacity(0.8))
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
