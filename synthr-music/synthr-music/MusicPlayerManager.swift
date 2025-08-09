import Foundation
import SwiftUI
import AVFoundation

class MusicPlayerManager: ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .none
    @Published var shuffleMode: ShuffleMode = .off
    @Published var queue: [Track] = []
    @Published var currentQueueIndex: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    init() {
        setupAudioSession()
        setupTimer()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    // MARK: - Playback Controls
    func play() {
        guard let player = audioPlayer else { return }
        player.play()
        playbackState = .playing
    }
    
    func pause() {
        guard let player = audioPlayer else { return }
        player.pause()
        playbackState = .paused
    }
    
    func stop() {
        guard let player = audioPlayer else { return }
        player.stop()
        playbackState = .stopped
        currentTime = 0
    }
    
    func nextTrack() {
        guard !queue.isEmpty else { return }
        
        if currentQueueIndex < queue.count - 1 {
            currentQueueIndex += 1
        } else if repeatMode == .all {
            currentQueueIndex = 0
        } else {
            stop()
            return
        }
        
        loadTrack(queue[currentQueueIndex])
    }
    
    func previousTrack() {
        guard !queue.isEmpty else { return }
        
        if currentQueueIndex > 0 {
            currentQueueIndex -= 1
        } else if repeatMode == .all {
            currentQueueIndex = queue.count - 1
        } else {
            stop()
            return
        }
        
        loadTrack(queue[currentQueueIndex])
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
    }
    
    // MARK: - Queue Management
    func loadTrack(_ track: Track) {
        currentTrack = track
        duration = track.duration
        currentTime = 0
        playbackState = .loading
        
        // In a real app, you would load the audio from the streamURL
        // For now, we'll simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playbackState = .paused
        }
    }
    
    func setQueue(_ tracks: [Track], startIndex: Int = 0) {
        queue = tracks
        currentQueueIndex = startIndex
        
        if !tracks.isEmpty {
            loadTrack(tracks[startIndex])
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .none:
            repeatMode = .one
        case .one:
            repeatMode = .all
        case .all:
            repeatMode = .none
        }
    }
    
    func toggleShuffle() {
        shuffleMode = shuffleMode == .off ? .on : .off
        if shuffleMode == .on && !queue.isEmpty {
            let shuffledQueue = queue.shuffled()
            let currentTrack = queue[currentQueueIndex]
            if let newIndex = shuffledQueue.firstIndex(where: { $0.id == currentTrack.id }) {
                queue = shuffledQueue
                currentQueueIndex = newIndex
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        timer?.invalidate()
        audioPlayer?.stop()
    }
}
