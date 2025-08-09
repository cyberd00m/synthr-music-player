import Foundation
import SwiftUI

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
        self.isFavorite = false
    }
}

struct Album: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: String?
    let tracks: [Track]
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
    let albums: [Album]
    let artworkURL: String?
    
    init(id: String = UUID().uuidString, name: String, albums: [Album] = [], artworkURL: String? = nil) {
        self.id = id
        self.name = name
        self.albums = albums
        self.artworkURL = artworkURL
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
