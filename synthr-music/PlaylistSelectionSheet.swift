import SwiftUI

// MARK: - Playlist Selection Sheet
struct PlaylistSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: UnifiedDataManager
    let tracks: [Track]
    let album: Album?
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Y2KColors.deepSpace, Y2KColors.midnight], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Y2KColors.neon)
                        
                        Text("Add to Playlist")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let album = album {
                            Text("\(album.title) by \(album.artist)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else if tracks.count == 1 {
                            Text("\(tracks[0].title) by \(tracks[0].artist)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("\(tracks.count) tracks")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 20)
                    
                    Button(action: { showCreatePlaylist = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Playlist")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.neon)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Y2KColors.glow, lineWidth: 1))
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add to Existing Playlist")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        if dataManager.playlists.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("No playlists yet")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(dataManager.playlists) { playlist in
                                        PlaylistRow(playlist: playlist, tracks: tracks)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Y2KColors.neon)
                }
            }
        }
        .alert("Create New Playlist", isPresented: $showCreatePlaylist) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    let newPlaylist = dataManager.createPlaylist(name: newPlaylistName)
                    for track in tracks {
                        dataManager.addTrackToPlaylist(track, playlist: newPlaylist)
                    }
                    newPlaylistName = ""
                    dismiss()
                }
            }
        } message: {
            Text("Enter a name for your new playlist")
        }
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let tracks: [Track]
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var isAdding = false
    @State private var showSuccess = false
    
    var body: some View {
        Button(action: { addToPlaylist() }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Y2KColors.neon, Y2KColors.glow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("\(playlist.tracks.count) songs")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isAdding {
                    ProgressView().scaleEffect(0.8).tint(Y2KColors.neon)
                } else if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Y2KColors.neon)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Y2KColors.cosmic)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAdding || showSuccess)
    }
    
    private func addToPlaylist() {
        isAdding = true
        
        for track in tracks {
            dataManager.addTrackToPlaylist(track, playlist: playlist)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSuccess = true
            isAdding = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSuccess = false
            }
        }
    }
}
