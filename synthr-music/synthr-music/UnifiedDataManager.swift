import Foundation
import SwiftUI

class UnifiedDataManager: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var isLoading = false
    @Published var dataSource: DataSource = .local
    
    private let navidromeManager = NavidromeManager()
    
    enum DataSource {
        case local
        case navidrome
    }
    
    init() {
        // Start with empty data - user must connect to a server
        tracks = []
        albums = []
        artists = []
    }
    
    // MARK: - Data Source Management
    
    func switchToNavidrome() {
        dataSource = .navidrome
        loadNavidromeData()
    }
    
    func switchToLocal() {
        dataSource = .local
        // Clear data when switching to local (no sample data)
        tracks = []
        albums = []
        artists = []
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
                    self.tracks = navidromeTracks.map { navidromeTrack in
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
                    
                    self.albums = navidromeAlbums.map { navidromeAlbum in
                        let albumTracks = tracks.filter { $0.album == navidromeAlbum.name }
                        return Album(
                            id: navidromeAlbum.id,
                            title: navidromeAlbum.name,
                            artist: navidromeAlbum.artist,
                            artworkURL: navidromeAlbum.coverArt != nil ? navidromeManager.getArtworkURL(for: navidromeAlbum.id) : nil,
                            tracks: albumTracks,
                            year: navidromeAlbum.year
                        )
                    }
                    
                    self.artists = navidromeArtists.map { navidromeArtist in
                        let artistAlbums = albums.filter { $0.artist == navidromeArtist.name }
                        return Artist(
                            id: navidromeArtist.id,
                            name: navidromeArtist.name,
                            albums: artistAlbums,
                            artworkURL: navidromeArtist.coverArt != nil ? navidromeManager.getArtworkURL(for: navidromeArtist.id) : nil
                        )
                    }
                    
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
    
    // MARK: - Refresh Data
    
    func refreshData() {
        if dataSource == .navidrome {
            loadNavidromeData()
        }
        // No local data to refresh
    }
}
