import Foundation
import SwiftUI
import AVFoundation

class UnifiedDataManager: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    @Published var dataSource: DataSource = .local
    @Published var libraryViewMode: ViewMode = .grid
    @Published var searchViewMode: ViewMode = .grid
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
    }
    
    private let navidromeManager = NavidromeManager()
    
    enum DataSource {
        case local
        case navidrome
        case localFiles
    }
    
    init() {
        // Start with empty data - user must connect to a server
        tracks = []
        albums = []
        artists = []
        
        // Load cached local files on startup
        loadCachedLocalFiles()
        
        // Load saved playlists
        loadPlaylists()
        
        // Load view mode settings
        loadViewModeSettings()
    }
    
    // MARK: - Data Source Management
    
    func switchToNavidrome() {
        dataSource = .navidrome
        loadNavidromeData()
    }
    
    func switchToLocal() {
        dataSource = .local
        // Load sample data for testing offline functionality
        loadSampleData()
    }
    
    // MARK: - Sample Data for Testing
    
    private func loadSampleData() {
        // Create sample tracks
        let sampleTracks = [
            Track(
                title: "Synthwave Dreams",
                artist: "Neon Pulse",
                album: "Retro Future",
                duration: 180.0
            ),
            Track(
                title: "Digital Sunset",
                artist: "Neon Pulse",
                album: "Retro Future",
                duration: 210.0
            ),
            Track(
                title: "Cyber Love",
                artist: "Electric Dreams",
                album: "Neon Nights",
                duration: 195.0
            ),
            Track(
                title: "Midnight Drive",
                artist: "Electric Dreams",
                album: "Neon Nights",
                duration: 240.0
            ),
            Track(
                title: "Y2K Vibes",
                artist: "Digital Wave",
                album: "Millennium",
                duration: 165.0
            ),
            Track(
                title: "Future Past",
                artist: "Digital Wave",
                album: "Millennium",
                duration: 225.0
            )
        ]
        
        // Create sample albums
        let sampleAlbums = [
            Album(
                title: "Retro Future",
                artist: "Neon Pulse",
                tracks: [sampleTracks[0], sampleTracks[1]]
            ),
            Album(
                title: "Neon Nights",
                artist: "Electric Dreams",
                tracks: [sampleTracks[2], sampleTracks[3]]
            ),
            Album(
                title: "Millennium",
                artist: "Digital Wave",
                tracks: [sampleTracks[4], sampleTracks[5]]
            )
        ]
        
        // Create sample artists
        let sampleArtists = [
            Artist(
                name: "Neon Pulse",
                albums: [sampleAlbums[0]]
            ),
            Artist(
                name: "Electric Dreams",
                albums: [sampleAlbums[1]]
            ),
            Artist(
                name: "Digital Wave",
                albums: [sampleAlbums[2]]
            )
        ]
        
        // Set the data
        self.tracks = sampleTracks
        self.albums = sampleAlbums
        self.artists = sampleArtists
        
        print("Loaded \(sampleTracks.count) sample tracks for offline testing")
    }
    
    func switchToLocalFiles() {
        dataSource = .localFiles
        loadLocalFiles()
    }
    
    // MARK: - Local Files Caching
    
    private func loadCachedLocalFiles() {
        // Check if we have cached local files
        if let cachedFiles = UserDefaults.standard.array(forKey: "cachedLocalFiles") as? [String] {
            if !cachedFiles.isEmpty {
                print("Found \(cachedFiles.count) cached local files, loading...")
                switchToLocalFiles()
                // Clean up any invalid files after loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.cleanupInvalidFiles()
                }
            }
        }
    }
    
    private func saveCachedLocalFiles() {
        // Save list of imported file paths to UserDefaults
        let filePaths = tracks.compactMap { $0.streamURL }
        UserDefaults.standard.set(filePaths, forKey: "cachedLocalFiles")
        print("Saved \(filePaths.count) local files to cache")
    }
    
    private func clearCachedLocalFiles() {
        UserDefaults.standard.removeObject(forKey: "cachedLocalFiles")
        print("Cleared cached local files")
    }
    
    // MARK: - Navidrome Data
    
    private func loadNavidromeData() {
        guard navidromeManager.isConnected else {
            print("Navidrome not connected")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Fetch data in parallel
                async let albumsTask = navidromeManager.fetchAlbums(limit: 100)
                async let tracksTask = navidromeManager.fetchTracks(limit: 100)
                async let artistsTask = navidromeManager.fetchArtists(limit: 100)
                
                let (navidromeAlbums, navidromeTracks, navidromeArtists) = try await (albumsTask, tracksTask, artistsTask)
                
                await MainActor.run {
                    // Convert Navidrome models to local models
                    let convertedTracks = navidromeTracks.map { navidromeTrack in
                        Track(
                            id: navidromeTrack.id,
                            title: navidromeTrack.title,
                            artist: navidromeTrack.artist,
                            album: navidromeTrack.album,
                            duration: TimeInterval(navidromeTrack.duration),
                            artworkURL: navidromeTrack.coverArt != nil ? navidromeManager.getArtworkURL(for: navidromeTrack.albumId) : nil,
                            streamURL: navidromeManager.getStreamURL(for: navidromeTrack.id),
                            isFavorite: false
                        )
                    }
                    
                    let convertedAlbums = navidromeAlbums.map { navidromeAlbum in
                        let albumTracks = convertedTracks.filter { $0.album == navidromeAlbum.name }
                        return Album(
                            id: navidromeAlbum.id,
                            title: navidromeAlbum.name,
                            artist: navidromeAlbum.artist,
                            artworkURL: navidromeAlbum.coverArt != nil ? navidromeManager.getArtworkURL(for: navidromeAlbum.id) : nil,
                            tracks: albumTracks,
                            year: navidromeAlbum.year
                        )
                    }
                    
                    let convertedArtists = navidromeArtists.map { navidromeArtist in
                        let artistAlbums = convertedAlbums.filter { $0.artist == navidromeArtist.name }
                        return Artist(
                            id: navidromeArtist.id,
                            name: navidromeArtist.name,
                            albums: artistAlbums,
                            artworkURL: navidromeArtist.coverArt != nil ? navidromeManager.getArtworkURL(for: navidromeArtist.id) : nil
                        )
                    }
                    
                    // Set all data at once to avoid circular references
                    self.tracks = convertedTracks
                    self.albums = convertedAlbums
                    self.artists = convertedArtists
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading Navidrome data: \(error)")
                    self.isLoading = false
                    // Clear data on error
                    self.tracks = []
                    self.albums = []
                    self.artists = []
                }
            }
        }
    }
    
    // MARK: - Search and Filtering
    
    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query) ||
            track.artist.localizedCaseInsensitiveContains(query) ||
            track.album.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getTracksByAlbum(_ albumTitle: String) -> [Track] {
        return tracks.filter { $0.album == albumTitle }
    }
    
    func getTracksByArtist(_ artistName: String) -> [Track] {
        return tracks.filter { $0.artist == artistName }
    }
    
    // MARK: - Navidrome Manager Access
    
    var isNavidromeConnected: Bool {
        return navidromeManager.isConnected
    }
    
    var navidromeConnectionStatus: NavidromeManager.ConnectionStatus {
        return navidromeManager.connectionStatus
    }
    
    func connectToNavidrome(url: String, username: String, password: String) async {
        await navidromeManager.connectToServer(url: url, username: username, password: password)
        
        if navidromeManager.isConnected {
            await MainActor.run {
                switchToNavidrome()
            }
        }
    }
    
    func disconnectFromNavidrome() {
        navidromeManager.disconnect()
        switchToLocal()
    }
    
    // MARK: - Music Player Integration
    
    func setupMusicPlayerConnection(_ musicPlayer: MusicPlayerManager) {
        print("Setting up music player connection")
        musicPlayer.setDataManager(self)
        print("Music player connection setup complete")
    }
    
    func getNavidromeManager() -> NavidromeManager {
        return navidromeManager
    }
    
    func getStreamURL(for trackId: String) -> String {
        return navidromeManager.getStreamURL(for: trackId)
    }
    
    // MARK: - Local Files Management
    
    private func loadLocalFiles() {
        print("Loading local files...")
        isLoading = true
        
        // First try to load from cached file paths
        if let cachedFiles = UserDefaults.standard.array(forKey: "cachedLocalFiles") as? [String] {
            print("Loading from cache: \(cachedFiles.count) files")
            loadFromCachedPaths(cachedFiles)
            return
        }
        
        // Fallback to scanning documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let musicDirectory = documentsDirectory.appendingPathComponent("Music", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: musicDirectory.path) else {
            tracks = []
            albums = []
            artists = []
            isLoading = false
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: musicDirectory, includingPropertiesForKeys: nil)
            let audioFiles = fileURLs.filter { url in
                let supportedFormats = ["mp3", "m4a", "aac", "flac", "wav", "alac"]
                return supportedFormats.contains(url.pathExtension.lowercased())
            }
            
            print("Found \(audioFiles.count) audio files")
            let convertedTracks = audioFiles.map { url in
                createTrackFromFile(at: url)
            }
            print("Created \(convertedTracks.count) tracks")
            
            // Save to cache for future use
            saveCachedLocalFiles()
            
            // For local files, only create artists (Library tab), not albums (Playlists tab)
            // Group tracks by album first, then by artist
            let albumGroups = Dictionary(grouping: convertedTracks) { $0.album }
            let convertedAlbums = albumGroups.map { albumName, albumTracks in
                // Get the best available artwork for this album
                let albumArtwork = albumTracks.compactMap { $0.artworkURL }.first
                
                return Album(
                    title: albumName,
                    artist: albumTracks.first?.artist ?? "Unknown Artist",
                    artworkURL: albumArtwork,
                    tracks: albumTracks
                )
            }
            
            // Group albums by artist
            let artistGroups = Dictionary(grouping: convertedAlbums) { $0.artist }
            let convertedArtists = artistGroups.map { artistName, artistAlbums in
                // Get the best available artwork for this artist (from first album)
                let artistArtwork = artistAlbums.compactMap { $0.artworkURL }.first
                
                return Artist(
                    name: artistName,
                    albums: artistAlbums,
                    artworkURL: artistArtwork
                )
            }
            
            // Set all data at once to avoid circular references
            // For local files, only populate artists array, leave albums empty
            tracks = convertedTracks
            albums = [] // Empty for local files - they only show in Library tab
            artists = removeDuplicateAlbums(from: convertedArtists)
            print("Final result: \(tracks.count) tracks, \(artists.count) artists")
            isLoading = false
        } catch {
            print("Error loading local files: \(error)")
            tracks = []
            albums = []
            artists = []
            isLoading = false
        }
    }
    
    private func loadFromCachedPaths(_ cachedPaths: [String]) {
        var convertedTracks: [Track] = []
        var validPaths: [String] = []
        
        for path in cachedPaths {
            let url = URL(fileURLWithPath: path)
            
            // Check if file still exists
            guard FileManager.default.fileExists(atPath: path) else {
                print("Cached file no longer exists: \(path)")
                continue
            }
            
            // Check if it's a supported audio format
            let supportedFormats = ["mp3", "m4a", "aac", "flac", "wav", "alac"]
            guard supportedFormats.contains(url.pathExtension.lowercased()) else {
                print("Cached file has unsupported format: \(path)")
                continue
            }
            
            let track = createTrackFromFile(at: url)
            convertedTracks.append(track)
            validPaths.append(path)
        }
        
        print("Loaded \(convertedTracks.count) tracks from cache")
        
        // Update cache with only valid files
        if validPaths.count != cachedPaths.count {
            UserDefaults.standard.set(validPaths, forKey: "cachedLocalFiles")
            print("Updated cache: removed \(cachedPaths.count - validPaths.count) invalid files")
        }
        
        // For local files, only create artists (Library tab), not albums (Playlists tab)
        // Group tracks by album first, then by artist
        let albumGroups = Dictionary(grouping: convertedTracks) { $0.album }
        let convertedAlbums = albumGroups.map { albumName, albumTracks in
            // Get the best available artwork for this album
            let albumArtwork = albumTracks.compactMap { $0.artworkURL }.first
            
            return Album(
                title: albumName,
                artist: albumTracks.first?.artist ?? "Unknown Artist",
                artworkURL: albumArtwork,
                tracks: albumTracks
            )
        }
        
        // Group albums by artist
        let artistGroups = Dictionary(grouping: convertedAlbums) { $0.artist }
        let convertedArtists = artistGroups.map { artistName, artistAlbums in
            // Get the best available artwork for this artist (from first album)
            let artistArtwork = artistAlbums.compactMap { $0.artworkURL }.first
            
            return Artist(
                name: artistName,
                albums: artistAlbums,
                artworkURL: artistArtwork
            )
        }
        
        // Set all data at once to avoid circular references
        // For local files, only populate artists array, leave albums empty
        tracks = convertedTracks
        albums = [] // Empty for local files - they only show in Library tab
        artists = removeDuplicateAlbums(from: convertedArtists)
        print("Final result: \(tracks.count) tracks, \(artists.count) artists")
        isLoading = false
    }
    
    func addLocalTrack(_ track: Track) {
        print("Adding local track: \(track.title) by \(track.artist) from album \(track.album)")
        tracks.append(track)
        
        // Save to cache when adding local tracks
        if dataSource == .localFiles {
            saveCachedLocalFiles()
        }
        
        // For local files, only add to artists (Library tab), not albums (Playlists tab)
        if dataSource == .localFiles {
            // Update artists only
            if let existingArtistIndex = artists.firstIndex(where: { $0.name == track.artist }) {
                if let albumIndex = artists[existingArtistIndex].albums.firstIndex(where: { $0.title == track.album }) {
                    artists[existingArtistIndex].albums[albumIndex].tracks.append(track)
                    // Update artwork if the new track has artwork and the album doesn't
                    if artists[existingArtistIndex].albums[albumIndex].artworkURL == nil && track.artworkURL != nil {
                        artists[existingArtistIndex].albums[albumIndex] = Album(
                            id: artists[existingArtistIndex].albums[albumIndex].id,
                            title: artists[existingArtistIndex].albums[albumIndex].title,
                            artist: artists[existingArtistIndex].albums[albumIndex].artist,
                            artworkURL: track.artworkURL,
                            tracks: artists[existingArtistIndex].albums[albumIndex].tracks,
                            year: artists[existingArtistIndex].albums[albumIndex].year
                        )
                    }
                } else {
                    let newAlbum = Album(
                        title: track.album,
                        artist: track.artist,
                        artworkURL: track.artworkURL,
                        tracks: [track]
                    )
                    artists[existingArtistIndex].albums.append(newAlbum)
                }
                // Update artist artwork if needed
                if artists[existingArtistIndex].artworkURL == nil {
                    let artistArtwork = artists[existingArtistIndex].albums.compactMap { $0.artworkURL }.first
                    artists[existingArtistIndex] = Artist(
                        id: artists[existingArtistIndex].id,
                        name: artists[existingArtistIndex].name,
                        albums: artists[existingArtistIndex].albums,
                        artworkURL: artistArtwork
                    )
                }
            } else {
                let newAlbum = Album(
                    title: track.album,
                    artist: track.artist,
                    artworkURL: track.artworkURL,
                    tracks: [track]
                )
                let newArtist = Artist(
                    name: track.artist,
                    albums: [newAlbum],
                    artworkURL: track.artworkURL
                )
                artists.append(newArtist)
            }
        } else {
            // For Navidrome data, add to both albums and artists
            // Update albums
            if let existingAlbumIndex = albums.firstIndex(where: { $0.title == track.album }) {
                albums[existingAlbumIndex].tracks.append(track)
            } else {
                let newAlbum = Album(
                    title: track.album,
                    artist: track.artist,
                    tracks: [track]
                )
                albums.append(newAlbum)
            }
            
            // Update artists
            if let existingArtistIndex = artists.firstIndex(where: { $0.name == track.artist }) {
                if let albumIndex = artists[existingArtistIndex].albums.firstIndex(where: { $0.title == track.album }) {
                    artists[existingArtistIndex].albums[albumIndex].tracks.append(track)
                } else {
                    let newAlbum = Album(
                        title: track.album,
                        artist: track.artist,
                        tracks: [track]
                    )
                    artists[existingArtistIndex].albums.append(newAlbum)
                }
            } else {
                let newAlbum = Album(
                    title: track.album,
                    artist: track.artist,
                    tracks: [track]
                )
                let newArtist = Artist(
                    name: track.artist,
                    albums: [newAlbum]
                )
                artists.append(newArtist)
            }
        }
    }
    
    func createTrackFromFile(at url: URL) -> Track {
        // Default values from filename parsing
        let filename = url.deletingPathExtension().lastPathComponent
        let components = filename.components(separatedBy: " - ")
        var artist = components.count > 1 ? components[0] : "Unknown Artist"
        var title = components.count > 1 ? components[1] : filename
        var album = "Unknown Album"
        var duration: TimeInterval = 0
        var artworkURL: String? = nil
        
        // Create AVAsset for metadata extraction
        let asset = AVAsset(url: url)
        
        // Extract metadata synchronously
        let metadata = asset.metadata
        for item in metadata {
            switch item.commonKey?.rawValue {
            case "title":
                if let titleValue = item.value as? String, !titleValue.isEmpty {
                    title = titleValue
                }
            case "artist":
                if let artistValue = item.value as? String, !artistValue.isEmpty {
                    artist = artistValue
                }
            case "albumName":
                if let albumValue = item.value as? String, !albumValue.isEmpty {
                    album = albumValue
                }
            case "artwork":
                if let artworkData = item.value as? Data {
                    artworkURL = saveArtworkToDocuments(artworkData, for: url)
                }
            default:
                break
            }
        }
        
        // Try to get duration from metadata
        let durationItem = metadata.first { $0.commonKey?.rawValue == "duration" }
        if let durationValue = durationItem?.value as? Double {
            duration = durationValue
        }
        // Note: Getting duration from asset tracks requires async operations
        // For now, we'll use 0 as default and could implement async loading later if needed
        
        return Track(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkURL: artworkURL,
            streamURL: url.path,
            isFavorite: false
        )
    }
    
    private func saveArtworkToDocuments(_ artworkData: Data, for fileURL: URL) -> String? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let artworkDirectory = documentsDirectory.appendingPathComponent("Artwork", isDirectory: true)
        
        // Create artwork directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: artworkDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating artwork directory: \(error)")
                return nil
            }
        }
        
        // Generate unique filename for artwork
        let filename = fileURL.deletingPathExtension().lastPathComponent
        let artworkFilename = "\(filename)_artwork.jpg"
        let artworkURL = artworkDirectory.appendingPathComponent(artworkFilename)
        
        // Save artwork data
        do {
            try artworkData.write(to: artworkURL)
            return artworkURL.path
        } catch {
            print("Error saving artwork: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func removeDuplicateAlbums(from artists: [Artist]) -> [Artist] {
        return artists.map { artist in
            // Remove duplicate albums within each artist
            let uniqueAlbums = Array(Set(artist.albums.map { $0.title })).compactMap { albumTitle in
                artist.albums.first { $0.title == albumTitle }
            }
            
            // Get the best artwork for each unique album
            let albumsWithBestArtwork = uniqueAlbums.map { album in
                let allTracksForAlbum = tracks.filter { $0.album == album.title && $0.artist == album.artist }
                let bestArtwork = allTracksForAlbum.compactMap { $0.artworkURL }.first
                
                return Album(
                    id: album.id,
                    title: album.title,
                    artist: album.artist,
                    artworkURL: bestArtwork,
                    tracks: allTracksForAlbum,
                    year: album.year
                )
            }
            
            // Get the best artwork for the artist
            let artistArtwork = albumsWithBestArtwork.compactMap { $0.artworkURL }.first
            
            return Artist(
                id: artist.id,
                name: artist.name,
                albums: albumsWithBestArtwork,
                artworkURL: artistArtwork
            )
        }
    }
    
    // MARK: - Refresh Data
    
    func refreshData() {
        if dataSource == .navidrome {
            loadNavidromeData()
        } else if dataSource == .localFiles {
            loadLocalFiles()
        }
        // No local data to refresh
    }
    
    // MARK: - Local Files Management
    
    func clearLocalFiles() {
        tracks = []
        albums = []
        artists = []
        clearCachedLocalFiles()
        print("Cleared all local files and cache")
    }
    
    func removeLocalTrack(_ track: Track) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks.remove(at: index)
            
            // Update artists
            for artistIndex in artists.indices {
                for albumIndex in artists[artistIndex].albums.indices {
                    artists[artistIndex].albums[albumIndex].tracks.removeAll { $0.id == track.id }
                }
                // Remove empty albums
                artists[artistIndex].albums.removeAll { $0.tracks.isEmpty }
            }
            // Remove empty artists
            artists.removeAll { $0.albums.isEmpty }
            
            // Update cache
            if dataSource == .localFiles {
                saveCachedLocalFiles()
            }
            
            print("Removed track: \(track.title)")
        }
    }
    
    func getLocalFilesCount() -> Int {
        return tracks.count
    }
    
    func hasLocalFiles() -> Bool {
        return !tracks.isEmpty
    }
    
    func getLocalFilesSize() -> String {
        var totalSize: Int64 = 0
        
        for track in tracks {
            if let streamURL = track.streamURL {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: streamURL)
                    if let fileSize = attributes[.size] as? Int64 {
                        totalSize += fileSize
                    }
                } catch {
                    print("Error getting file size for \(streamURL): \(error)")
                }
            }
        }
        
        // Convert to human readable format
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    func cleanupInvalidFiles() {
        // Remove tracks whose files no longer exist
        let validTracks = tracks.filter { track in
            if let streamURL = track.streamURL {
                return FileManager.default.fileExists(atPath: streamURL)
            }
            return false
        }
        
        if validTracks.count != tracks.count {
            tracks = validTracks
            // Rebuild artists and albums from valid tracks
            rebuildCollectionsFromTracks()
            // Update cache
            saveCachedLocalFiles()
            print("Cleaned up \(tracks.count - validTracks.count) invalid files")
        }
    }
    
    private func rebuildCollectionsFromTracks() {
        // Rebuild albums and artists from current tracks
        let albumGroups = Dictionary(grouping: tracks) { $0.album }
        let convertedAlbums = albumGroups.map { albumName, albumTracks in
            let albumArtwork = albumTracks.compactMap { $0.artworkURL }.first
            return Album(
                title: albumName,
                artist: albumTracks.first?.artist ?? "Unknown Artist",
                artworkURL: albumArtwork,
                tracks: albumTracks
            )
        }
        
        let artistGroups = Dictionary(grouping: convertedAlbums) { $0.artist }
        let convertedArtists = artistGroups.map { artistName, artistAlbums in
            let artistArtwork = artistAlbums.compactMap { $0.artworkURL }.first
            return Artist(
                name: artistName,
                albums: artistAlbums,
                artworkURL: artistArtwork
            )
        }
        
        albums = []
        artists = removeDuplicateAlbums(from: convertedArtists)
    }
    
    // MARK: - Playlist Management
    
    func createPlaylist(name: String, description: String? = nil, artworkURL: String? = nil) -> Playlist {
        let newPlaylist = Playlist(name: name, description: description, artworkURL: artworkURL)
        playlists.append(newPlaylist)
        savePlaylists()
        return newPlaylist
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].tracks.append(track)
            savePlaylists()
        }
    }
    
    func removeTrackFromPlaylist(_ track: Track, playlist: Playlist) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[playlistIndex].tracks.removeAll { $0.id == track.id }
            savePlaylists()
        }
    }
    
    func moveTrackInPlaylist(from source: IndexSet, to destination: Int, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].tracks.move(fromOffsets: source, toOffset: destination)
            savePlaylists()
        }
    }
    
    private func savePlaylists() {
        // Save playlists to UserDefaults for persistence
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: "savedPlaylists")
        }
    }
    
    private func loadPlaylists() {
        // Load playlists from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedPlaylists"),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }
    
    // MARK: - View Mode Settings
    
    func saveViewModeSettings() {
        UserDefaults.standard.set(libraryViewMode.rawValue, forKey: "libraryViewMode")
        UserDefaults.standard.set(searchViewMode.rawValue, forKey: "searchViewMode")
    }
    
    func loadViewModeSettings() {
        if let libraryModeString = UserDefaults.standard.string(forKey: "libraryViewMode"),
           let libraryMode = ViewMode(rawValue: libraryModeString) {
            libraryViewMode = libraryMode
        }
        
        if let searchModeString = UserDefaults.standard.string(forKey: "searchViewMode"),
           let searchMode = ViewMode(rawValue: searchModeString) {
            searchViewMode = searchMode
        }
    }
}
