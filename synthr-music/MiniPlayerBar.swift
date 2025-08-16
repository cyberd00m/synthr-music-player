import SwiftUI

struct MiniPlayerBar: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var networkManager: NetworkManager
    @State private var showFullPlayer = false
    
    var body: some View {
        if musicPlayer.currentTrack != nil {
            // Mini player content
            HStack(spacing: 16) {
                // Album artwork
                if let currentTrack = musicPlayer.currentTrack, let artworkURL = currentTrack.artworkURL {
                    // Handle both web URLs and local file paths
                    if artworkURL.hasPrefix("http") {
                        // Web URL
                        AsyncImage(url: URL(string: artworkURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 40, height: 40)
                        .clipped()
                    } else {
                        // Local file path
                        if let image = UIImage(contentsOfFile: artworkURL) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                } else {
                    // No artwork available - show placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(musicPlayer.currentTrack?.title ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(musicPlayer.currentTrack?.artist ?? "")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Playback controls
                HStack(spacing: 16) {
                    // Play/pause button
                    Button(action: {
                        if musicPlayer.playbackState == .playing {
                            musicPlayer.pause()
                        } else {
                            musicPlayer.play()
                        }
                    }) {
                        Image(systemName: musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Next track button
                    Button(action: musicPlayer.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: 400, maxHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 35)
                    .fill(Y2KColors.cosmic)
            )
            .onTapGesture {
                showFullPlayer = true
            }
            .sheet(isPresented: $showFullPlayer) {
                NowPlayingView()
                    .environmentObject(musicPlayer)
                    .environmentObject(dataManager)
            }
        }
    }
}

#Preview {
    MiniPlayerBar()
        .environmentObject(MusicPlayerManager())
}
