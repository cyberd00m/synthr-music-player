import Foundation
import SwiftUI

class DownloadManager: ObservableObject {
    @Published var downloadedTracks: Set<String> = []
    @Published var downloadingTracks: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]
    
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let downloadsFolder = "Downloads"
    
    init() {
        loadDownloadedTracks()
        createDownloadsDirectory()
    }
    
    // MARK: - Directory Management
    
    private func createDownloadsDirectory() {
        let downloadsURL = documentsPath.appendingPathComponent(downloadsFolder)
        if !FileManager.default.fileExists(atPath: downloadsURL.path) {
            do {
                try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
                print("Created downloads directory at: \(downloadsURL.path)")
            } catch {
                print("Failed to create downloads directory: \(error)")
            }
        }
    }
    
    private func getDownloadsDirectory() -> URL {
        return documentsPath.appendingPathComponent(downloadsFolder)
    }
    
    // MARK: - Download Management
    
    func downloadTrack(_ track: Track) async {
        // Check if already downloaded or downloading
        guard !downloadedTracks.contains(track.id),
              !downloadingTracks.contains(track.id) else {
            return
        }
        
        // For demo purposes, create a mock download if no stream URL
        if track.streamURL == nil {
            await mockDownloadTrack(track)
            return
        }
        
        guard let streamURL = track.streamURL else {
            print("No stream URL available for track: \(track.title)")
            return
        }
        
        await MainActor.run {
            downloadingTracks.insert(track.id)
            downloadProgress[track.id] = 0.0
        }
        
        do {
            let url = URL(string: streamURL)!
            let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw DownloadError.invalidResponse
            }
            
            let contentLength = httpResponse.expectedContentLength
            let fileName = "\(track.id).mp3"
            let fileURL = getDownloadsDirectory().appendingPathComponent(fileName)
            
            var downloadedBytes: Int64 = 0
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            
            for try await byte in asyncBytes {
                try fileHandle.write(contentsOf: [byte])
                downloadedBytes += 1
                
                if contentLength > 0 {
                    let progress = Double(downloadedBytes) / Double(contentLength)
                    await MainActor.run {
                        downloadProgress[track.id] = progress
                    }
                }
            }
            
            try fileHandle.close()
            
            await MainActor.run {
                downloadedTracks.insert(track.id)
                downloadingTracks.remove(track.id)
                downloadProgress.removeValue(forKey: track.id)
                saveDownloadedTracks()
                print("✅ Download completed for: \(track.title) - Total downloaded: \(downloadedTracks.count)")
            }
            
            print("Successfully downloaded track: \(track.title)")
            
        } catch {
            await MainActor.run {
                downloadingTracks.remove(track.id)
                downloadProgress.removeValue(forKey: track.id)
            }
            print("Failed to download track \(track.title): \(error)")
        }
    }
    
    func downloadAlbum(_ album: Album) async {
        for track in album.tracks {
            await downloadTrack(track)
        }
    }
    
    func downloadArtist(_ artist: Artist) async {
        for album in artist.albums {
            await downloadAlbum(album)
        }
    }
    
    // MARK: - Mock Download for Demo
    
    private func mockDownloadTrack(_ track: Track) async {
        await MainActor.run {
            downloadingTracks.insert(track.id)
            downloadProgress[track.id] = 0.0
            print("🔄 Starting mock download for: \(track.title) - Total downloading: \(downloadingTracks.count)")
        }
        
        // Simulate download progress
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                downloadProgress[track.id] = Double(i) / 10.0
            }
        }
        
        // Create a mock local file
        let fileName = "\(track.id).mp3"
        let fileURL = getDownloadsDirectory().appendingPathComponent(fileName)
        
        // Create a simple text file as a placeholder for the audio
        let mockContent = "Mock audio file for: \(track.title) by \(track.artist)"
        do {
            try mockContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                downloadedTracks.insert(track.id)
                downloadingTracks.remove(track.id)
                downloadProgress.removeValue(forKey: track.id)
                saveDownloadedTracks()
                print("✅ Mock download completed for: \(track.title) - Total downloaded: \(downloadedTracks.count)")
            }
            
            print("Successfully created mock download for track: \(track.title)")
        } catch {
            await MainActor.run {
                downloadingTracks.remove(track.id)
                downloadProgress.removeValue(forKey: track.id)
            }
            print("Failed to create mock download for track \(track.title): \(error)")
        }
    }
    
    // MARK: - Offline Access
    
    func getLocalURL(for track: Track) -> URL? {
        guard downloadedTracks.contains(track.id) else { return nil }
        let fileName = "\(track.id).mp3"
        let fileURL = getDownloadsDirectory().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func isDownloaded(_ track: Track) -> Bool {
        return downloadedTracks.contains(track.id)
    }
    
    func isDownloading(_ track: Track) -> Bool {
        return downloadingTracks.contains(track.id)
    }
    
    func getDownloadProgress(for track: Track) -> Double {
        return downloadProgress[track.id] ?? 0.0
    }
    
    // MARK: - Storage Management
    
    func deleteDownloadedTrack(_ track: Track) {
        guard downloadedTracks.contains(track.id) else { return }
        
        let fileName = "\(track.id).mp3"
        let fileURL = getDownloadsDirectory().appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            downloadedTracks.remove(track.id)
            saveDownloadedTracks()
            print("Deleted downloaded track: \(track.title)")
        } catch {
            print("Failed to delete track \(track.title): \(error)")
        }
    }
    
    func getDownloadedSize() -> Int64 {
        let downloadsURL = getDownloadsDirectory()
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: [.fileSizeKey])
            return try contents.reduce(0) { total, url in
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                return total + Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            print("Failed to calculate downloaded size: \(error)")
            return 0
        }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Persistence
    
    private func saveDownloadedTracks() {
        UserDefaults.standard.set(Array(downloadedTracks), forKey: "downloadedTracks")
    }
    
    private func loadDownloadedTracks() {
        if let savedTracks = UserDefaults.standard.array(forKey: "downloadedTracks") as? [String] {
            downloadedTracks = Set(savedTracks)
        }
    }
}

// MARK: - Errors

enum DownloadError: Error, LocalizedError {
    case invalidResponse
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .downloadFailed:
            return "Download failed"
        }
    }
}
