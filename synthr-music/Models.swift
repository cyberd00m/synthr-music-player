import Foundation
import SwiftUI
import MediaPlayer

// MARK: - Music Models
struct Track: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: String?
    let streamURL: String?
    let isFavorite: Bool
    
    init(id: String = UUID().uuidString, title: String, artist: String, album: String, duration: TimeInterval, artworkURL: String? = nil, streamURL: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.streamURL = streamURL
        self.isFavorite = isFavorite
    }
    
    var artwork: MPMediaItemArtwork? {
        // For now, return nil since we don't have actual artwork data
        // This can be enhanced later to load actual artwork from artworkURL
        return nil
    }
}

struct Album: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: String?
    var tracks: [Track]
    let year: Int?
    
    init(id: String = UUID().uuidString, title: String, artist: String, artworkURL: String? = nil, tracks: [Track] = [], year: Int? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.year = year
    }
}

struct Artist: Identifiable, Codable {
    let id: String
    let name: String
    var albums: [Album]
    let artworkURL: String?
    
    init(id: String = UUID().uuidString, name: String, albums: [Album] = [], artworkURL: String? = nil) {
        self.id = id
        self.name = name
        self.albums = albums
        self.artworkURL = artworkURL
    }
}

struct Playlist: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let createdAt: Date
    var tracks: [Track]
    let artworkURL: String?
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, tracks: [Track] = [], artworkURL: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.tracks = tracks
        self.artworkURL = artworkURL
    }
    
    var duration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    var trackCount: Int {
        tracks.count
    }
}

// MARK: - Radio Models
struct RadioStation: Identifiable, Codable {
    let id: String
    let name: String
    let url: String
    let genre: String?
    let description: String?
    let isFavorite: Bool
    
    init(id: String = UUID().uuidString, name: String, url: String, genre: String? = nil, description: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.url = url
        self.genre = genre
        self.description = description
        self.isFavorite = isFavorite
    }
}

// MARK: - Player State
enum PlaybackState {
    case playing
    case paused
    case stopped
    case loading
}

enum RepeatMode {
    case none
    case one
    case all
}

enum ShuffleMode {
    case off
    case on
}
