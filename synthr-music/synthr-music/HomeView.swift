import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showCreatePlaylist = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    } else if dataManager.playlists.isEmpty {
                        EmptyPlaylistsView()
                    } else {
                        PlaylistsListView()
                    }
                }
                
                // Create Playlist Button - Bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreatePlaylist = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.monospacedTitle)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Y2KColors.neon)
                                        .overlay(
                                            Circle()
                                                .stroke(Y2KColors.glow, lineWidth: 1)
                                        )
                                )
                                .shadow(color: Y2KColors.neon.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Home")
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
        .sheet(isPresented: $showCreatePlaylist) {
            CreatePlaylistView()
                .environmentObject(dataManager)
        }
    }
}

struct EmptyPlaylistsView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.monospacedSystem(size: 80))
                .foregroundColor(Y2KColors.neon.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("No Playlists Available")
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

struct PlaylistsListView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        VStack {
            if dataManager.playlists.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "music.note.list")
                        .font(.monospacedSystem(size: 60))
                        .foregroundColor(Y2KColors.neon.opacity(0.6))
                    
                    Text("No Playlists Yet")
                        .font(.monospacedTitle2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Create your first playlist to get started")
                        .font(.monospacedBody)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    if dataManager.homeViewMode == .grid {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(dataManager.playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                                    .environmentObject(musicPlayer)
                                    .environmentObject(dataManager)
                                    .environmentObject(downloadManager)) {
                                    PlaylistCard(playlist: playlist)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    PlaylistContextMenu(playlist: playlist)
                                }
                            }
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(dataManager.playlists) { playlist in
                                NavigationLink(destination: PlaylistDetailView(playlist: playlist)
                                    .environmentObject(musicPlayer)
                                    .environmentObject(dataManager)
                                    .environmentObject(downloadManager)) {
                                    PlaylistListRow(playlist: playlist)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    PlaylistContextMenu(playlist: playlist)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Playlist Components

struct PlaylistCard: View {
    let playlist: Playlist
    
    private var defaultPlaylistArtwork: some View {
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
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.monospacedLargeTitle)
                        .foregroundColor(.white)
                    
                    if playlist.trackCount > 0 {
                        Text("\(playlist.trackCount)")
                            .font(.monospacedTitle2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
            )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Playlist artwork
            if let artworkURL = playlist.artworkURL {
                // Handle both web URLs and local file paths
                if artworkURL.hasPrefix("http") {
                    // Web URL
                    AsyncImage(url: URL(string: artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultPlaylistArtwork
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
                        defaultPlaylistArtwork
                    }
                }
            } else {
                defaultPlaylistArtwork
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("\(playlist.trackCount) tracks")
                        .font(.monospacedSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if playlist.trackCount > 0 {
                        Text(formatDuration(playlist.duration))
                            .font(.monospacedCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .frame(width: 150)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlaylistListRow: View {
    let playlist: Playlist
    
    private var defaultPlaylistArtwork: some View {
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
                VStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .font(.monospacedTitle3)
                        .foregroundColor(.white)
                    
                    if playlist.trackCount > 0 {
                        Text("\(playlist.trackCount)")
                            .font(.monospacedCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
            )
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Playlist artwork
            if let artworkURL = playlist.artworkURL {
                // Handle both web URLs and local file paths
                if artworkURL.hasPrefix("http") {
                    // Web URL
                    AsyncImage(url: URL(string: artworkURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultPlaylistArtwork
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
                        defaultPlaylistArtwork
                    }
                }
            } else {
                defaultPlaylistArtwork
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.monospacedHeadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text("\(playlist.trackCount) tracks")
                        .font(.monospacedSubheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if playlist.trackCount > 0 {
                        Text(formatDuration(playlist.duration))
                            .font(.monospacedCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlaylistContextMenu: View {
    let playlist: Playlist
    @EnvironmentObject var dataManager: UnifiedDataManager
    
    var body: some View {
        Button("Delete Playlist") {
            dataManager.deletePlaylist(playlist)
        }
        .foregroundColor(.red)
    }
}

struct CreatePlaylistView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Playlist Image Section
                VStack(alignment: .center, spacing: 12) {
                    Text("Playlist Image")
                        .font(.monospacedHeadline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 180)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Y2KColors.neon.opacity(0.3), Y2KColors.glow.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.monospacedTitle)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("Add Image")
                                            .font(.monospacedCaption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlist Name")
                        .font(.monospacedHeadline)
                        .foregroundColor(.white)
                    
                    TextField("Enter playlist name", text: $playlistName)
                        .textFieldStyle(Y2KTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.monospacedHeadline)
                        .foregroundColor(.white)
                    
                    TextField("Enter description", text: $playlistDescription)
                        .textFieldStyle(Y2KTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Y2KColors.deepSpace, Y2KColors.midnight],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Create Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // Save the selected image to documents directory and get the path
                            var artworkURL: String? = nil
                            if let selectedImage = selectedImage {
                                artworkURL = saveImageToDocuments(selectedImage, playlistName: playlistName)
                            }
                            
                            dataManager.createPlaylist(
                                name: playlistName.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: playlistDescription.isEmpty ? nil : playlistDescription,
                                artworkURL: artworkURL
                            )
                            dismiss()
                        }
                    }
                    .foregroundColor(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Y2KColors.neon)
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func saveImageToDocuments(_ image: UIImage, playlistName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let playlistImagesPath = documentsPath.appendingPathComponent("PlaylistImages")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: playlistImagesPath, withIntermediateDirectories: true)
        
        let fileName = "\(playlistName.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).jpg"
        let fileURL = playlistImagesPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UnifiedDataManager())
        .environmentObject(MusicPlayerManager())
}
