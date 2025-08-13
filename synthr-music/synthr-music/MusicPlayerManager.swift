import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

class MusicPlayerManager: NSObject, ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .none
    @Published var shuffleMode: ShuffleMode = .off
    @Published var queue: [Track] = []
    @Published var currentQueueIndex: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    private var timer: Timer?
    private weak var dataManager: UnifiedDataManager?
    private weak var downloadManager: DownloadManager?
    
    override init() {
        super.init()
        setupAudioSession()
        setupTimer()
        
        // Ensure audio session is properly configured for background playback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.ensureAudioSessionForBackground()
        }
    }
    
    func setDataManager(_ manager: UnifiedDataManager) {
        self.dataManager = manager
    }
    
    func setDownloadManager(_ manager: DownloadManager) {
        self.downloadManager = manager
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // First, deactivate the session to avoid conflicts
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // Configure audio session for background playback with more comprehensive options
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try audioSession.setActive(true, options: [])
            
            // Setup remote control events for lock screen controls
            setupRemoteControlEvents()
            
            // Add notification observers for audio interruptions
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: audioSession,
                queue: .main
            ) { [weak self] notification in
                self?.handleAudioSessionInterruption(notification: notification)
            }
            
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: audioSession,
                queue: .main
            ) { [weak self] notification in
                self?.handleRouteChange(notification: notification)
            }
            
            // Add app lifecycle notifications for background audio
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            
            // Add notification for when app becomes active
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            
            // Add notification for when app will resign active
            NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
            // Try a simpler configuration as fallback
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback)
                try audioSession.setActive(true)
            } catch {
                print("Failed to setup audio session with fallback: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session interrupted, pause playback
            print("🔇 Audio session interrupted")
            pause()
        case .ended:
            // Audio session interruption ended, resume if appropriate
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                print("🔊 Audio session interruption ended, resuming playback")
                // For radio streams, we need to reconfigure the audio session
                if avPlayer != nil {
                    do {
                        let audioSession = AVAudioSession.sharedInstance()
                        try audioSession.setActive(true, options: [])
                    } catch {
                        print("❌ Failed to reactivate audio session: \(error)")
                    }
                }
                play()
            }
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones disconnected, pause playback
            pause()
        default:
            break
        }
    }
    
    private func handleAppDidEnterBackground() {
        // Ensure audio session is still active when app goes to background
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
            
            // Update now playing info to ensure it's visible in control center
            updateNowPlayingInfo()
        } catch {
            print("Failed to keep audio session active in background: \(error.localizedDescription)")
        }
    }
    
    private func handleAppWillEnterForeground() {
        // Update now playing info when app comes back to foreground
        updateNowPlayingInfo()
        
        // Ensure audio session is properly configured
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to reconfigure audio session when entering foreground: \(error.localizedDescription)")
        }
    }
    
    private func handleAppDidBecomeActive() {
        // Ensure audio session is properly configured when app becomes active
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to reconfigure audio session: \(error.localizedDescription)")
        }
    }
    
    private func handleAppWillResignActive() {
        // Ensure audio session remains active when app goes to background
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true, options: [])
        } catch {
            print("Failed to keep audio session active: \(error.localizedDescription)")
        }
    }
    
    private func setupRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Next track command
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        // Seek command
        commandCenter.seekForwardCommand.addTarget { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            let newTime = min(player.currentTime + 15, player.duration)
            self.seek(to: newTime)
            return .success
        }
        
        commandCenter.seekBackwardCommand.addTarget { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            let newTime = max(player.currentTime - 15, 0)
            self.seek(to: newTime)
            return .success
        }
        
        // Skip forward/backward commands
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            let skipEvent = event as! MPSkipIntervalCommandEvent
            let newTime = min(player.currentTime + skipEvent.interval, player.duration)
            self.seek(to: newTime)
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            let skipEvent = event as! MPSkipIntervalCommandEvent
            let newTime = max(player.currentTime - skipEvent.interval, 0)
            self.seek(to: newTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        
        // Basic track info
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
        
        // Duration and current time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        // Playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackState == .playing ? 1.0 : 0.0
        
        // Additional metadata for better lock screen display
        nowPlayingInfo[MPMediaItemPropertyGenre] = "Unknown Genre"
        nowPlayingInfo[MPMediaItemPropertyComposer] = track.artist
        nowPlayingInfo[MPMediaItemPropertyPlayCount] = 1
        
        // Set default artwork if available
        if let artwork = track.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        } else {
            // Create a default artwork if none is available
            let defaultArtwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
                UIImage(systemName: "music.note") ?? UIImage()
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = defaultArtwork
        }
        
        // Enable seeking
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            let newTime = player.currentTime
            // Validate the time value to avoid NaN
            if newTime >= 0 && !newTime.isNaN && !newTime.isInfinite {
                self.currentTime = newTime
            }
            self.updateNowPlayingInfo()
        }
    }
    
    private func ensureAudioSessionForBackground() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to ensure audio session for background: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    func play() {
        // Ensure audio session is properly configured for background playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to configure audio session for playback: \(error)")
            // Continue with playback even if audio session setup fails
        }
        
        // Check if we have an AVPlayer (radio stream)
        if let avPlayer = avPlayer {
            print("🎵 Playing radio stream with AVPlayer")
            print("🎵 Player status before play: \(avPlayer.status.rawValue)")
            print("🎵 Player time control status before play: \(avPlayer.timeControlStatus.rawValue)")
            print("🎵 Player rate before play: \(avPlayer.rate)")
            
            avPlayer.play()
            
            print("🎵 Player status after play: \(avPlayer.status.rawValue)")
            print("🎵 Player time control status after play: \(avPlayer.timeControlStatus.rawValue)")
            print("🎵 Player rate after play: \(avPlayer.rate)")
            
            playbackState = .playing
            updateNowPlayingInfo()
            return
        }
        
        // Check if we have an AVAudioPlayer (regular audio)
        guard let player = audioPlayer else { 
            // If no player exists, try to load the current track
            if let track = currentTrack {
                loadTrack(track)
            }
            return 
        }
        
        // Check if player is ready to play
        guard player.prepareToPlay() else {
            return
        }
        
        let success = player.play()
        if success {
            playbackState = .playing
            updateNowPlayingInfo()
        } else {
            playbackState = .paused
        }
    }
    
    func pause() {
        if let avPlayer = avPlayer {
            avPlayer.pause()
            playbackState = .paused
            updateNowPlayingInfo()
            return
        }
        
        guard let player = audioPlayer else { return }
        player.pause()
        playbackState = .paused
        updateNowPlayingInfo()
    }
    
    func stop() {
        if let avPlayer = avPlayer {
            avPlayer.pause()
            avPlayer.seek(to: .zero)
            playbackState = .stopped
            currentTime = 0
            updateNowPlayingInfo()
            return
        }
        
        guard let player = audioPlayer else { return }
        player.stop()
        playbackState = .stopped
        currentTime = 0
        updateNowPlayingInfo()
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
        // Validate the time value to avoid NaN
        guard time >= 0 && !time.isNaN && !time.isInfinite else { return }
        player.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }
    
    // MARK: - Queue Management
    func loadTrack(_ track: Track) {
        // Ensure audio session is properly configured
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already configured correctly
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
            }
        } catch {
            print("Failed to configure audio session for track loading: \(error)")
            // Continue with track loading even if audio session setup fails
        }
        
        currentTrack = track
        duration = track.duration
        currentTime = 0
        playbackState = .loading
        updateNowPlayingInfo()
        
        // Stop current player if exists
        audioPlayer?.stop()
        audioPlayer = nil
        
        // First, check if we have a local copy of this track (offline mode)
        if let downloadManager = downloadManager,
           let localURL = downloadManager.getLocalURL(for: track) {
            print("🎵 Playing from offline storage: \(track.title)")
            loadAudioFromURL(localURL)
        } else if let streamURL = track.streamURL, let url = URL(string: streamURL) {
            // Fall back to streaming from URL
            print("🌐 Streaming from URL: \(track.title)")
            loadAudioFromURL(url)
        } else if let dataManager = dataManager {
            // If we have a Navidrome manager, try to get the stream URL
            let streamURL = dataManager.getStreamURL(for: track.id)
            if let url = URL(string: streamURL) {
                print("🌐 Streaming from Navidrome: \(track.title)")
                loadAudioFromURL(url)
            } else {
                print("❌ No audio source available for: \(track.title)")
                playbackState = .paused
            }
        } else {
            // Create a silent audio buffer for testing background audio
            print("🎵 Demo mode - creating silent audio for: \(track.title)")
            createSilentAudioBuffer(for: track)
        }
    }
    
    private func createSilentAudioBuffer(for track: Track) {
        // Create a silent audio buffer with proper WAV format
        let sampleRate: Double = 44100
        let duration: Double = track.duration > 0 ? track.duration : 30.0 // Use track duration or 30 seconds default
        let frameCount = Int(sampleRate * duration)
        
        // Create WAV header
        var wavData = Data()
        
        // WAV file header (44 bytes)
        wavData.append("RIFF".data(using: .ascii)!) // Chunk ID
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(36 + frameCount * 2).littleEndian) { Data($0) }) // Chunk size
        wavData.append("WAVE".data(using: .ascii)!) // Format
        wavData.append("fmt ".data(using: .ascii)!) // Subchunk1 ID
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // Subchunk1 size
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // Audio format (PCM)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // Num channels (mono)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // Sample rate
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) }) // Byte rate
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // Block align
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // Bits per sample
        wavData.append("data".data(using: .ascii)!) // Subchunk2 ID
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(frameCount * 2).littleEndian) { Data($0) }) // Subchunk2 size
        
        // Add silent PCM data (16-bit, mono)
        for _ in 0..<frameCount {
            // 16-bit silence (0)
            wavData.append(contentsOf: [0, 0])
        }
        
        do {
            // Create audio player with the WAV data
            let player = try AVAudioPlayer(data: wavData)
            player.delegate = self
            player.prepareToPlay()
            
            // Set the player
            self.audioPlayer = player
            self.duration = duration
            self.playbackState = .paused
            self.updateNowPlayingInfo()
        } catch {
            print("Error creating silent audio buffer: \(error)")
            self.playbackState = .paused
        }
    }
    
    private func loadAudioFromURL(_ url: URL) {
        // Check if this is a local file path
        if url.scheme == nil || url.scheme == "file" {
            // Handle local file
            loadLocalAudioFile(url)
        } else {
            // Handle remote URL
            loadRemoteAudioFile(url)
        }
    }
    
    private func loadLocalAudioFile(_ url: URL) {
        do {
            // Create audio player directly from the local file
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            
            // Update duration if available
            if player.duration > 0 {
                self.duration = player.duration
            }
            
            // Set the player after successful creation
            self.audioPlayer = player
            self.playbackState = .paused
            self.updateNowPlayingInfo()
        } catch {
            print("Error creating local audio player: \(error)")
            self.playbackState = .paused
        }
    }
    
    private func loadRemoteAudioFile(_ url: URL) {
        // Check if this is a radio stream - smarter detection
        let urlString = url.absoluteString.lowercased()
        
        // Common radio streaming indicators
        let streamingKeywords = ["stream", "radio", "live", "broadcast", "icecast", "shoutcast"]
        let streamingProtocols = ["rtsp", "rtmp", "hls", "m3u8"]
        let playlistFormats = ["pls", "m3u", "asx", "ram"]
        
        // Check for streaming keywords in URL
        let hasStreamingKeyword = streamingKeywords.contains { urlString.contains($0) }
        let hasStreamingProtocol = streamingProtocols.contains { urlString.contains($0) }
        let hasPlaylistFormat = playlistFormats.contains { urlString.contains($0) }
        
        // Check if it's a direct audio stream (common radio formats)
        let audioExtensions = ["mp3", "aac", "ogg", "wav", "flac"]
        let hasAudioExtension = audioExtensions.contains(url.pathExtension.lowercased())
        
        // If it has streaming indicators OR is a direct audio stream, treat as radio
        let isRadioStream = hasStreamingKeyword || hasStreamingProtocol || hasPlaylistFormat || hasAudioExtension
        
        print("🎵 URL: \(url)")
        print("🎵 Path extension: \(url.pathExtension)")
        print("🎵 Has streaming keyword: \(hasStreamingKeyword)")
        print("🎵 Has streaming protocol: \(hasStreamingProtocol)")
        print("🎵 Has playlist format: \(hasPlaylistFormat)")
        print("🎵 Has audio extension: \(hasAudioExtension)")
        print("🎵 Detected as radio stream: \(isRadioStream)")
        
        if isRadioStream {
            // For radio streams, use AVPlayer which handles streaming better
            loadRadioStream(url)
        } else {
            // For regular audio files, download as data
            loadRemoteAudioFileAsData(url)
        }
    }
    
    private func loadRemoteAudioFileAsData(_ url: URL) {
        // Create a data task to download the audio data
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading audio: \(error)")
                    self.playbackState = .paused
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        print("HTTP error: \(httpResponse.statusCode)")
                        self.playbackState = .paused
                        return
                    }
                }
                
                guard let data = data, !data.isEmpty else {
                    print("No audio data received")
                    self.playbackState = .paused
                    return
                }
                
                do {
                    // Create audio player with the downloaded data
                    let player = try AVAudioPlayer(data: data)
                    player.delegate = self
                    player.prepareToPlay()
                    
                    // Update duration if available
                    if player.duration > 0 {
                        self.duration = player.duration
                    }
                    
                    // Set the player after successful creation
                    self.audioPlayer = player
                    self.playbackState = .paused
                    self.updateNowPlayingInfo()
                } catch {
                    print("Error creating audio player: \(error)")
                    self.playbackState = .paused
                }
            }
        }
        
        task.resume()
    }
    
    private func loadRadioStream(_ url: URL) {
        print("🎵 Starting to load radio stream: \(url)")
        
        // Ensure audio session is properly configured for streaming
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Deactivate first to avoid conflicts
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // Configure for streaming with more permissive options
            try audioSession.setCategory(.playback, mode: .default, options: [
                .allowBluetooth, 
                .allowBluetoothA2DP, 
                .allowAirPlay, 
                .mixWithOthers
            ])
            
            // Activate the session
            try audioSession.setActive(true, options: [])
            
            print("🎵 Audio session configured for radio streaming")
            print("🎵 Audio session category: \(audioSession.category)")
            print("🎵 Audio session mode: \(audioSession.mode)")
            print("🎵 Audio session is active: \(audioSession.isOtherAudioPlaying)")
        } catch {
            print("❌ Failed to configure audio session for radio: \(error)")
        }
        
        // Stop any existing players
        audioPlayer?.stop()
        audioPlayer = nil
        avPlayer?.pause()
        avPlayer = nil
        
        // Create AVPlayer for radio stream with better configuration
        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        
        // Configure player for streaming
        if #available(iOS 10.0, *) {
            player.automaticallyWaitsToMinimizeStalling = false
        }
        
        // Add observer for player status
        player.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Add observer for time control status
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .old], context: nil)
        
        // Add observer for player item status
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Add observer for player rate
        player.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
        
        // Set the player
        self.avPlayer = player
        self.duration = 0 // Radio streams are continuous
        self.playbackState = .loading
        self.updateNowPlayingInfo()
        
        // Set volume to ensure audio is audible
        player.volume = 1.0
        
        print("🎵 Radio stream loaded with AVPlayer: \(url)")
        print("🎵 Player status: \(player.status.rawValue)")
        print("🎵 Player time control status: \(player.timeControlStatus.rawValue)")
        print("🎵 Player rate: \(player.rate)")
        print("🎵 Player volume: \(player.volume)")
        
        // Check audio session status
        let audioSession = AVAudioSession.sharedInstance()
        print("🎵 Audio session category: \(audioSession.category)")
        print("🎵 Audio session mode: \(audioSession.mode)")
        print("🎵 Audio session is active: \(audioSession.isOtherAudioPlaying)")
        print("🎵 Audio session output volume: \(audioSession.outputVolume)")
        
        // Try to play immediately to test if it works
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let player = self?.avPlayer {
                print("🎵 Testing radio stream playback...")
                player.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    if let player = self?.avPlayer {
                        print("🎵 Radio stream test results:")
                        print("🎵 Player status: \(player.status.rawValue)")
                        print("🎵 Player time control status: \(player.timeControlStatus.rawValue)")
                        print("🎵 Player rate: \(player.rate)")
                        
                        if player.rate == 0 {
                            print("❌ Radio stream not playing, trying AVAudioPlayer fallback...")
                            self?.tryAVAudioPlayerFallback(url: url)
                        }
                    }
                }
            }
        }
    }
    
    private func tryAVAudioPlayerFallback(url: URL) {
        print("🎵 Trying AVAudioPlayer fallback for radio stream")
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            
            self.audioPlayer = player
            self.avPlayer?.pause()
            self.avPlayer = nil
            self.duration = 0
            self.playbackState = .paused
            self.updateNowPlayingInfo()
            
            print("🎵 AVAudioPlayer fallback created successfully")
        } catch {
            print("❌ AVAudioPlayer fallback also failed: \(error)")
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
    

    
    // MARK: - KVO Observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let player = object as? AVPlayer {
            if keyPath == "status" {
                DispatchQueue.main.async {
                    switch player.status {
                    case .readyToPlay:
                        print("🎵 AVPlayer ready to play")
                        self.playbackState = .paused
                        self.updateNowPlayingInfo()
                    case .failed:
                        print("❌ AVPlayer failed: \(player.error?.localizedDescription ?? "Unknown error")")
                        if let error = player.error {
                            print("❌ Player error details: \(error)")
                        }
                        self.playbackState = .paused
                    case .unknown:
                        print("⏳ AVPlayer status unknown")
                    @unknown default:
                        break
                    }
                }
            } else if keyPath == "timeControlStatus" {
                DispatchQueue.main.async {
                    switch player.timeControlStatus {
                    case .playing:
                        print("🎵 AVPlayer time control: playing")
                        self.playbackState = .playing
                    case .paused:
                        print("🎵 AVPlayer time control: paused")
                        self.playbackState = .paused
                    case .waitingToPlayAtSpecifiedRate:
                        print("🎵 AVPlayer time control: waiting to play")
                        self.playbackState = .loading
                    @unknown default:
                        break
                    }
                }
            } else if keyPath == "rate" {
                DispatchQueue.main.async {
                    print("🎵 AVPlayer rate changed to: \(player.rate)")
                    if player.rate > 0 {
                        print("🎵 Player is actually playing audio")
                    } else {
                        print("🎵 Player is not playing audio")
                    }
                }
            }
        } else if let playerItem = object as? AVPlayerItem {
            if keyPath == "status" {
                DispatchQueue.main.async {
                    switch playerItem.status {
                    case .readyToPlay:
                        print("🎵 AVPlayerItem ready to play")
                    case .failed:
                        print("❌ AVPlayerItem failed: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                        if let error = playerItem.error {
                            print("❌ PlayerItem error details: \(error)")
                        }
                        self.playbackState = .paused
                    case .unknown:
                        print("⏳ AVPlayerItem status unknown")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        timer?.invalidate()
        audioPlayer?.stop()
        avPlayer?.pause()
        
        // Remove AVPlayer observers
        avPlayer?.removeObserver(self, forKeyPath: "status")
        avPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
        avPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clear remote control events
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        
        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            if flag {
                // Handle repeat modes
                switch self.repeatMode {
                case .one:
                    // Repeat current track
                    player.currentTime = 0
                    player.play()
                case .all:
                    // Go to next track or loop back to first
                    self.nextTrack()
                    if self.playbackState != .stopped {
                        self.play()
                    }
                case .none:
                    // Go to next track or stop
                    self.nextTrack()
                    if self.playbackState != .stopped {
                        self.play()
                    }
                }
            } else {
                self.playbackState = .stopped
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
            self.playbackState = .stopped
        }
    }
}
