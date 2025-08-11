import Foundation
import SwiftUI

class NavidromeManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var serverInfo: NavidromeServerInfo?
    @Published var errorMessage: String?
    
    private var baseURL: String = ""
    private var username: String = ""
    private var password: String = ""
    private var session: URLSession
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
    }
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Management
    
    func connectToServer(url: String, username: String, password: String) async {
        await MainActor.run {
            self.connectionStatus = .connecting
            self.errorMessage = nil
        }
        
        self.baseURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        self.username = username
        self.password = password
        
        // Ensure URL has proper scheme
        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }
        
        // Remove trailing slash if present
        if baseURL.hasSuffix("/") {
            baseURL = String(baseURL.dropLast())
        }
        
        do {
            // First, try to get server info to test connection
            let serverInfo = try await fetchServerInfo()
            
            // Then try to authenticate
            let authSuccess = try await authenticate()
            
            if authSuccess {
                await MainActor.run {
                    self.serverInfo = serverInfo
                    self.isConnected = true
                    self.connectionStatus = .connected
                }
            } else {
                await MainActor.run {
                    self.connectionStatus = .failed
                    self.errorMessage = "Authentication failed. Please check your credentials."
                }
            }
        } catch {
            await MainActor.run {
                self.connectionStatus = .failed
                self.errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() {
        isConnected = false
        connectionStatus = .disconnected
        serverInfo = nil
        errorMessage = nil
        baseURL = ""
        username = ""
        password = ""
        // Clear the authentication token
        UserDefaults.standard.removeObject(forKey: "navidrome_token")
    }
    
    // MARK: - Authentication
    
    private func authenticate() async throws -> Bool {
        let loginURL = "\(baseURL)/api/login"
        
        var request = URLRequest(url: URL(string: loginURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NavidromeError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let loginResponse = try JSONDecoder().decode(NavidromeLoginResponse.self, from: data)
            // Store the token for future requests
            UserDefaults.standard.set(loginResponse.token, forKey: "navidrome_token")
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Server Information
    
    private func fetchServerInfo() async throws -> NavidromeServerInfo {
        let infoURL = "\(baseURL)/api/server/info"
        let request = URLRequest(url: URL(string: infoURL)!)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NavidromeError.invalidResponse
        }
        
        return try JSONDecoder().decode(NavidromeServerInfo.self, from: data)
    }
    
    // MARK: - Music Data Fetching
    
    func fetchAlbums(limit: Int = 100, offset: Int = 0) async throws -> [NavidromeAlbum] {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        let albumsURL = "\(baseURL)/api/album?limit=\(limit)&offset=\(offset)&t=\(token)"
        let request = URLRequest(url: URL(string: albumsURL)!)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NavidromeError.invalidResponse
        }
        
        let albumsResponse = try JSONDecoder().decode(NavidromeAlbumsResponse.self, from: data)
        return albumsResponse.subsonicResponse.data.album
    }
    
    func fetchTracks(limit: Int = 100, offset: Int = 0) async throws -> [NavidromeTrack] {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        let tracksURL = "\(baseURL)/api/song?limit=\(limit)&offset=\(offset)&t=\(token)"
        let request = URLRequest(url: URL(string: tracksURL)!)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NavidromeError.invalidResponse
        }
        
        let tracksResponse = try JSONDecoder().decode(NavidromeTracksResponse.self, from: data)
        return tracksResponse.subsonicResponse.data.song
    }
    
    func fetchArtists(limit: Int = 100, offset: Int = 0) async throws -> [NavidromeArtist] {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        let artistsURL = "\(baseURL)/api/artist?limit=\(limit)&offset=\(offset)&t=\(token)"
        let request = URLRequest(url: URL(string: artistsURL)!)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NavidromeError.invalidResponse
        }
        
        let artistsResponse = try JSONDecoder().decode(NavidromeArtistsResponse.self, from: data)
        return artistsResponse.subsonicResponse.data.artist
    }
    
    func searchMusic(query: String, limit: Int = 50) async throws -> NavidromeSearchResult {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        let searchURL = "\(baseURL)/api/search3?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&limit=\(limit)&t=\(token)"
        let request = URLRequest(url: URL(string: searchURL)!)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NavidromeError.invalidResponse
        }
        
        return try JSONDecoder().decode(NavidromeSearchResult.self, from: data)
    }
    
    // MARK: - Stream URL Generation
    
    func getStreamURL(for trackId: String) -> String {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        return "\(baseURL)/api/stream?id=\(trackId)&t=\(token)"
    }
    
    func getArtworkURL(for albumId: String) -> String {
        let token = UserDefaults.standard.string(forKey: "navidrome_token") ?? ""
        return "\(baseURL)/api/coverArt?id=\(albumId)&t=\(token)"
    }
}

// MARK: - Errors

enum NavidromeError: Error, LocalizedError {
    case invalidResponse
    case authenticationFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Navidrome API Models

struct NavidromeServerInfo: Codable {
    let version: String
    let serverName: String
    let serverVersion: String
    let openSubsonic: Bool
    
    enum CodingKeys: String, CodingKey {
        case version
        case serverName = "serverName"
        case serverVersion = "serverVersion"
        case openSubsonic = "openSubsonic"
    }
}

struct NavidromeLoginResponse: Codable {
    let token: String
    let status: String
}

struct NavidromeAlbumsResponse: Codable {
    let subsonicResponse: SubsonicResponse<AlbumsWrapper>
}

struct NavidromeTracksResponse: Codable {
    let subsonicResponse: SubsonicResponse<SongsWrapper>
}

struct NavidromeArtistsResponse: Codable {
    let subsonicResponse: SubsonicResponse<ArtistsWrapper>
}

struct NavidromeSearchResult: Codable {
    let subsonicResponse: SubsonicResponse<SearchWrapper>
}

struct SubsonicResponse<T: Codable>: Codable {
    let status: String
    let version: String
    let data: T
}

struct AlbumsWrapper: Codable {
    let album: [NavidromeAlbum]
}

struct SongsWrapper: Codable {
    let song: [NavidromeTrack]
}

struct ArtistsWrapper: Codable {
    let artist: [NavidromeArtist]
}

struct SearchWrapper: Codable {
    let album: [NavidromeAlbum]?
    let song: [NavidromeTrack]?
    let artist: [NavidromeArtist]?
}

struct NavidromeAlbum: Codable, Identifiable {
    let id: String
    let name: String
    let artist: String
    let artistId: String
    let songCount: Int
    let duration: Int
    let coverArt: String?
    let year: Int?
    let genre: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artist
        case artistId
        case songCount
        case duration
        case coverArt
        case year
        case genre
    }
}

struct NavidromeTrack: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let artistId: String
    let album: String
    let albumId: String
    let duration: Int
    let coverArt: String?
    let size: Int
    let contentType: String?
    let suffix: String?
    let bitRate: Int?
    let year: Int?
    let genre: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case artistId
        case album
        case albumId
        case duration
        case coverArt
        case size
        case contentType
        case suffix
        case bitRate
        case year
        case genre
    }
}

struct NavidromeArtist: Codable, Identifiable {
    let id: String
    let name: String
    let albumCount: Int
    let coverArt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case albumCount
        case coverArt
    }
}
