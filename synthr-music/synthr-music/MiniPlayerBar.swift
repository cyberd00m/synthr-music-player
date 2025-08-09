import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var showFullPlayer = false
    
    var body: some View {
        if musicPlayer.currentTrack != nil {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * progressPercentage, height: 2)
                }
                .frame(height: 2)
                
                // Mini player content
                HStack(spacing: 16) {
                    // Album artwork
                    RoundedRectangle(cornerRadius: 8)
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
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(musicPlayer.currentTrack?.title ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(musicPlayer.currentTrack?.artist ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/pause button
                    Button(action: {
                        if musicPlayer.playbackState == .playing {
                            musicPlayer.pause()
                        } else {
                            musicPlayer.play()
                        }
                    }) {
                        Image(systemName: musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                    
                    // Next track button
                    Button(action: musicPlayer.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .onTapGesture {
                    showFullPlayer = true
                }
            }
            .sheet(isPresented: $showFullPlayer) {
                NowPlayingView()
                    .environmentObject(musicPlayer)
            }
        }
    }
    
    private var progressPercentage: Double {
        guard musicPlayer.duration > 0 else { return 0 }
        return musicPlayer.currentTime / musicPlayer.duration
    }
}

#Preview {
    MiniPlayerBar()
        .environmentObject(MusicPlayerManager())
}
