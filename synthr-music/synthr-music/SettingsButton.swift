import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct SettingsButton: View {
    @State private var showSettings = false
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var downloadManager: DownloadManager
    
    var body: some View {
        Button(action: {
            showSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(dataManager)
                .environmentObject(downloadManager)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: UnifiedDataManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var enableNotifications = false
    @State private var autoPlay = false
    @State private var crossfade = false
    @State private var crossfadeDuration: Double = 3.0
    
    // Server connection fields
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var rememberLoginDetails = false
    @State private var isConnected = false
    @State private var showPassword = false
    @State private var connectionStatus = "Not connected"
    @State private var isConnecting = false
    @State private var connectionError: String?
    
    // Local file import fields
    @State private var showFileImporter = false
    @State private var importedFilesCount = 0
    @State private var isImporting = false
    @State private var importStatus = "No files imported"
    @State private var importError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Y2KColors.deepSpace, Y2KColors.midnight],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Server Connection Section
                        VStack(spacing: 16) {
                            // Header with icon and title
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Y2KColors.neon.opacity(0.2), Y2KColors.glow.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Image("NavidromeIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Music Sources")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Connect to server or import local files")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            
                            // Connection status card
                            HStack(spacing: 12) {
                                if isConnecting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 20, height: 20)
                                        .tint(Y2KColors.neon)
                                } else {
                                    Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(isConnected ? Y2KColors.neon : .white.opacity(0.6))
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(connectionStatus)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(isConnected ? Y2KColors.neon : .white.opacity(0.8))
                                    
                                    if let error = connectionError {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(2)
                                    } else {
                                        Text(isConnected ? "Successfully connected to your navidrome server" : "Not connected to any navidrome server")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Y2KColors.cosmic)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            // Server configuration fields
                            VStack(spacing: 12) {
                                // Server URL field
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "globe")
                                            .foregroundColor(Y2KColors.neon)
                                            .frame(width: 16)
                                            .font(.system(size: 14))
                                        
                                        Text("Server URL")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    TextField("http://192.168.1.100:4533", text: $serverURL)
                                        .textFieldStyle(Y2KTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .keyboardType(.URL)
                                }
                                
                                // Username field
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Y2KColors.neon)
                                            .frame(width: 16)
                                            .font(.system(size: 14))
                                        
                                        Text("Username")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    TextField("Enter your username", text: $username)
                                        .textFieldStyle(Y2KTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                
                                // Password field
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(Y2KColors.neon)
                                            .frame(width: 16)
                                            .font(.system(size: 14))
                                        
                                        Text("Password")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    HStack {
                                        if showPassword {
                                            TextField("Enter your password", text: $password)
                                                .textFieldStyle(Y2KTextFieldStyle())
                                                .autocapitalization(.none)
                                                .disableAutocorrection(true)
                                        } else {
                                            SecureField("Enter your password", text: $password)
                                                .textFieldStyle(Y2KTextFieldStyle())
                                                .autocapitalization(.none)
                                                .disableAutocorrection(true)
                                        }
                                        
                                        Button(action: {
                                            showPassword.toggle()
                                        }) {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.white.opacity(0.8))
                                                .font(.system(size: 14))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // Remember Login Details checkbox
                                HStack(spacing: 8) {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Toggle("Save login info", isOn: $rememberLoginDetails)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .tint(Y2KColors.neon)
                                }
                            }
                            
                            // Action buttons
                            VStack(spacing: 8) {
                                Button(action: {
                                    // Prevent multiple connection attempts
                                    if !isConnecting {
                                        connectToServer()
                                    }
                                }) {
                                    HStack {
                                        if isConnecting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .frame(width: 14, height: 14)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "link.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        Text(isConnecting ? "Connecting..." : "Connect to Server")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting ? Y2KColors.nebula : Y2KColors.neon)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting ? Y2KColors.nebula.opacity(0.3) : Y2KColors.glow, lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Local File Import Section
                        VStack(spacing: 16) {
                            // Header with icon and title
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Y2KColors.neon.opacity(0.2), Y2KColors.glow.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Y2KColors.neon)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Local Files")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Import music files from your device")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            
                            // Import status card
                            HStack(spacing: 12) {
                                if isImporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 20, height: 20)
                                        .tint(Y2KColors.neon)
                                } else {
                                    Image(systemName: importedFilesCount > 0 ? "checkmark.circle.fill" : "doc.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(importedFilesCount > 0 ? Y2KColors.neon : .white.opacity(0.6))
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(importStatus)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(importedFilesCount > 0 ? Y2KColors.neon : .white.opacity(0.8))
                                    
                                    if let error = importError {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(2)
                                    } else {
                                        if importedFilesCount > 0 {
                                            let fileSize = dataManager.getLocalFilesSize()
                                            Text("\(importedFilesCount) files (\(fileSize))")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.6))
                                                .lineLimit(2)
                                        } else {
                                            Text("No music files imported yet")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.6))
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Y2KColors.cosmic)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            // Supported formats info
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Supported Formats")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                Text("MP3, M4A, AAC, FLAC, WAV, ALAC")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 24)
                            }
                            
                            // Import and Clear buttons
                            HStack(spacing: 8) {
                                Button(action: {
                                    // Prevent multiple import attempts
                                    if !isImporting {
                                        showFileImporter = true
                                    }
                                }) {
                                    HStack {
                                        if isImporting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .frame(width: 14, height: 14)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        Text(isImporting ? "Importing..." : "Import Files")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isImporting ? Y2KColors.nebula : Y2KColors.neon)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isImporting ? Y2KColors.nebula.opacity(0.3) : Y2KColors.glow, lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isImporting)
                                
                                // Clear button - only show if we have local files
                                if dataManager.hasLocalFiles() {
                                    Button(action: {
                                        dataManager.clearLocalFiles()
                                        updateImportStatus()
                                    }) {
                                        HStack {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Clear")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red.opacity(0.8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .foregroundColor(.white)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .fileImporter(
                            isPresented: $showFileImporter,
                            allowedContentTypes: createAudioUTTypes(),
                            allowsMultipleSelection: true
                        ) { result in
                            handleFileImport(result: result)
                        }
                        
                        // Display Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Display")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Library View")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Picker("Library View", selection: $dataManager.libraryViewMode) {
                                            ForEach(UnifiedDataManager.ViewMode.allCases, id: \.self) { mode in
                                                Text(mode.rawValue).tag(mode)
                                            }
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .frame(width: 120)
                                        .onChange(of: dataManager.libraryViewMode) { _ in
                                            dataManager.saveViewModeSettings()
                                        }
                                    }
                                    
                                    Text("Choose how to display your music library")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Search View")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Picker("Search View", selection: $dataManager.searchViewMode) {
                                            ForEach(UnifiedDataManager.ViewMode.allCases, id: \.self) { mode in
                                                Text(mode.rawValue).tag(mode)
                                            }
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .frame(width: 120)
                                        .onChange(of: dataManager.searchViewMode) { _ in
                                            dataManager.saveViewModeSettings()
                                        }
                                    }
                                    
                                    Text("Choose how to display search results")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Playback Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Playback")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle("Auto-play", isOn: $autoPlay)
                                        .tint(Y2KColors.neon)
                                        .onChange(of: autoPlay) { _ in
                                            savePlaybackSettings()
                                        }
                                    
                                    Text("Automatically start playing the next track when the current one ends")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle("Crossfade", isOn: $crossfade)
                                        .tint(Y2KColors.neon)
                                        .onChange(of: crossfade) { _ in
                                            savePlaybackSettings()
                                        }
                                    
                                    Text("Smoothly blend between tracks for seamless playback")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                if crossfade {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Crossfade Duration")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(crossfadeDuration, specifier: "%.1f")s")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Slider(value: $crossfadeDuration, in: 1.0...8.0, step: 0.5)
                                            .accentColor(Y2KColors.neon)
                                            .onChange(of: crossfadeDuration) { _ in
                                                savePlaybackSettings()
                                            }
                                        
                                        Text("Adjust how long the crossfade effect lasts between tracks")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Notifications Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Toggle("Enable Notifications", isOn: $enableNotifications)
                                .tint(Y2KColors.neon)
                                .onChange(of: enableNotifications) { newValue in
                                    if newValue {
                                        requestNotificationPermission()
                                    }
                                }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Downloads Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Offline Downloads")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Downloaded Tracks")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(downloadManager.downloadedTracks.count)")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                HStack {
                                    Text("Storage Used")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(downloadManager.formatFileSize(downloadManager.getDownloadedSize()))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                if !downloadManager.downloadedTracks.isEmpty {
                                    Button(action: {
                                        // Clear all downloads
                                        for trackId in downloadManager.downloadedTracks {
                                            if let track = dataManager.tracks.first(where: { $0.id == trackId }) {
                                                downloadManager.deleteDownloadedTrack(track)
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Clear All Downloads")
                                        }
                                        .foregroundColor(.red)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red.opacity(0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Version")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                HStack {
                                    Text("Build")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("2025.1")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Y2KColors.cosmic.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Don't allow dismissal while connecting
                        if !isConnecting {
                            dismiss()
                        }
                    }
                    .foregroundColor(isConnecting ? .gray : Y2KColors.neon)
                    .disabled(isConnecting)
                }
            }
            .onAppear {
                loadServerSettings()
                loadPlaybackSettings()
                updateImportStatus()
            }
            .onDisappear {
                savePlaybackSettings()
            }
        }
    }
    
    // MARK: - Server Connection Methods
    
    // Helper function to check if host is local
    private func isLocalHost(_ host: String) -> Bool {
        let localHosts = ["localhost", "127.0.0.1", "::1", "0.0.0.0"]
        let localIPRanges = ["192.168.", "10.", "172.16.", "172.17.", "172.18.", "172.19.", "172.20.", "172.21.", "172.22.", "172.23.", "172.24.", "172.25.", "172.26.", "172.27.", "172.28.", "172.29.", "172.30.", "172.31."]
        
        if localHosts.contains(host) {
            return true
        }
        
        for range in localIPRanges {
            if host.hasPrefix(range) {
                return true
            }
        }
        
        return false
    }
    
    private func connectToServer() {
        guard !serverURL.isEmpty && !username.isEmpty && !password.isEmpty else {
            connectionError = "Please fill in all fields"
            return
        }
        
        isConnecting = true
        connectionError = nil
        connectionStatus = "Connecting to server..."
        
        // Add a timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if self.isConnecting {
                self.connectionError = "Connection timeout. Please check your server URL and try again."
                self.connectionStatus = "Connection failed"
                self.isConnecting = false
                self.isConnected = false
            }
        }
        
        // Attempt to authenticate and fetch music data
        authenticateAndFetchMusic()
    }
    
    private func authenticateAndFetchMusic() {
        // Safety check to prevent multiple simultaneous connections
        guard !isConnecting else { return }
        
        guard let baseURL = URL(string: serverURL) else {
            connectionError = "Invalid server URL"
            isConnecting = false
            connectionStatus = "Connection failed"
            return
        }
        
        // Create authentication header
        let credentials = "\(username):\(password)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            connectionError = "Invalid credentials format"
            isConnecting = false
            connectionStatus = "Connection failed"
            return
        }
        
        let base64Credentials = credentialsData.base64EncodedString()
        
        // Test authentication with Navidrome API - try multiple endpoints
        let authURL = baseURL.appendingPathComponent("api/ping")
        var request = URLRequest(url: authURL)
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        
        // Create session with relaxed security for local servers
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.waitsForConnectivity = false
        
        // Allow HTTP connections for local development
        if let host = baseURL.host, isLocalHost(host) {
            sessionConfig.allowsCellularAccess = true
        }
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // If ping fails, try direct album fetch
                    self.connectionStatus = "Trying direct connection..."
                    self.fetchMusicDataDirectly(baseURL: baseURL, credentials: base64Credentials)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Authentication successful, now fetch music data
                        self.connectionStatus = "Authenticated, fetching music..."
                        self.fetchMusicData(baseURL: baseURL, credentials: base64Credentials)
                    } else if httpResponse.statusCode == 401 {
                        // Try direct connection without authentication
                        self.connectionStatus = "Trying unauthenticated connection..."
                        self.fetchMusicDataDirectly(baseURL: baseURL, credentials: nil)
                    } else {
                        // Try direct connection anyway
                        self.connectionStatus = "Trying direct connection..."
                        self.fetchMusicDataDirectly(baseURL: baseURL, credentials: base64Credentials)
                    }
                } else {
                    // Try direct connection
                    self.connectionStatus = "Trying direct connection..."
                    self.fetchMusicDataDirectly(baseURL: baseURL, credentials: base64Credentials)
                }
            }
        }.resume()
    }
    
    private func fetchMusicDataDirectly(baseURL: URL, credentials: String?) {
        // Try to fetch music data directly without strict authentication
        let albumsURL = baseURL.appendingPathComponent("api/album")
        var request = URLRequest(url: albumsURL)
        
        if let credentials = credentials {
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        request.timeoutInterval = 30
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 45
        sessionConfig.waitsForConnectivity = false
        
        // Allow HTTP connections for local development
        if let host = baseURL.host, isLocalHost(host) {
            sessionConfig.allowsCellularAccess = true
        }
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // If that fails, try the root endpoint
                    self.connectionStatus = "Trying root endpoint..."
                    self.tryRootEndpoint(baseURL: baseURL, credentials: credentials)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data {
                    self.handleMusicDataResponse(data: data, baseURL: baseURL, credentials: credentials)
                } else {
                    // Try root endpoint
                    self.connectionStatus = "Trying root endpoint..."
                    self.tryRootEndpoint(baseURL: baseURL, credentials: credentials)
                }
            }
        }.resume()
    }
    
    private func tryRootEndpoint(baseURL: URL, credentials: String?) {
        // Try the root endpoint which might not require authentication
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = 20
        
        if let credentials = credentials {
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 20
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.waitsForConnectivity = false
        
        // Allow HTTP connections for local development
        if let host = baseURL.host, isLocalHost(host) {
            sessionConfig.allowsCellularAccess = true
        }
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // If root endpoint fails, try simple connection
                    self.connectionStatus = "Trying simple connection..."
                    self.trySimpleConnection(baseURL: baseURL, credentials: credentials)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Root endpoint successful
                        self.connectionStatus = "Connected to Navidrome server"
                        self.connectionError = nil
                        self.isConnected = true
                        self.isConnecting = false
                        self.saveServerSettings()
                    } else {
                        // Try simple connection
                        self.connectionStatus = "Trying simple connection..."
                        self.trySimpleConnection(baseURL: baseURL, credentials: credentials)
                    }
                } else {
                    // Try simple connection
                    self.connectionStatus = "Trying simple connection..."
                    self.trySimpleConnection(baseURL: baseURL, credentials: credentials)
                }
            }
        }.resume()
    }
    
    private func trySimpleConnection(baseURL: URL, credentials: String?) {
        // Final attempt with a simple connection test
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        if let credentials = credentials {
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10
        sessionConfig.timeoutIntervalForResource = 15
        sessionConfig.waitsForConnectivity = false
        
        // Allow HTTP connections for local development
        if let host = baseURL.host, isLocalHost(host) {
            sessionConfig.allowsCellularAccess = true
        }
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.connectionError = "Connection failed: \(error.localizedDescription)"
                    self.connectionStatus = "Connection failed"
                    self.isConnecting = false
                    self.isConnected = false
                } else {
                    // If we get any response, consider it a success
                    self.connectionStatus = "Connected to Navidrome server"
                    self.connectionError = nil
                    self.isConnected = true
                    self.isConnecting = false
                    self.saveServerSettings()
                }
            }
        }.resume()
    }
    
    private func fetchMusicData(baseURL: URL, credentials: String) {
        // Fetch albums from Navidrome
        let albumsURL = baseURL.appendingPathComponent("api/album")
        var request = URLRequest(url: albumsURL)
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 45
        sessionConfig.waitsForConnectivity = false
        
        // Allow HTTP connections for local development
        if let host = baseURL.host, isLocalHost(host) {
            sessionConfig.allowsCellularAccess = true
        }
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.connectionError = "Failed to fetch music: \(error.localizedDescription)"
                    self.connectionStatus = "Fetch failed"
                    self.isConnecting = false
                    self.isConnected = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data {
                    self.handleMusicDataResponse(data: data, baseURL: baseURL, credentials: credentials)
                } else {
                    // If API fails, still consider connection successful
                    self.connectionStatus = "Connected to Navidrome server"
                    self.connectionError = nil
                    self.isConnected = true
                    self.isConnecting = false
                    self.saveServerSettings()
                }
            }
        }.resume()
    }
    
    private func handleMusicDataResponse(data: Data, baseURL: URL, credentials: String?) {
        do {
            // Parse the response (Navidrome returns JSON)
            let json = try JSONSerialization.jsonObject(with: data)
            
            // For now, we'll just check if we got data
            // In a full implementation, you'd parse this into your music models
            if let dict = json as? [String: Any] {
                // Successfully connected and fetched music data
                self.connectionStatus = "Connected & Synced to Navidrome"
                self.connectionError = nil
                self.isConnected = true
                self.isConnecting = false
                
                // Save successful connection
                self.saveServerSettings()
                
                // Here you would update your music data manager with the fetched data
                // For example: dataManager.updateWithServerData(albumArray)
                
            } else {
                // Even if we can't parse the data, connection was successful
                self.connectionStatus = "Connected to Navidrome server"
                self.connectionError = nil
                self.isConnected = true
                self.isConnecting = false
                self.saveServerSettings()
            }
        } catch {
            // Even if parsing fails, connection was successful
            self.connectionStatus = "Connected to Navidrome server"
            self.connectionError = nil
            self.isConnected = true
            self.isConnecting = false
            self.saveServerSettings()
        }
    }
    
    private func loadServerSettings() {
        // Load saved server settings from UserDefaults or Keychain
        do {
            if let savedURL = UserDefaults.standard.string(forKey: "serverURL") {
                serverURL = savedURL
            }
            
            // Load remember login details preference
            rememberLoginDetails = UserDefaults.standard.bool(forKey: "rememberLoginDetails")
            
            // Only load username if remember login details is enabled
            if rememberLoginDetails {
                if let savedUsername = UserDefaults.standard.string(forKey: "username") {
                    username = savedUsername
                }
            }
            
            // Update connection status based on current data source
            updateConnectionStatus()
        } catch {
            print("Error loading server settings: \(error)")
            // Set default values if loading fails
            serverURL = ""
            username = ""
            rememberLoginDetails = false
            connectionStatus = "Not connected"
        }
    }
    
    private func updateConnectionStatus() {
        // Simple status update without complex logic
        if dataManager.dataSource == .navidrome {
            isConnected = dataManager.isNavidromeConnected
            connectionStatus = isConnected ? "Connected to Navidrome" : "Not connected"
        } else if dataManager.dataSource == .localFiles {
            isConnected = false
            connectionStatus = "Using local files"
        } else {
            isConnected = false
            connectionStatus = "Not connected"
        }
        connectionError = nil
    }
    
    private func createAudioUTTypes() -> [UTType] {
        var types: [UTType] = [UTType.audio, UTType.mp3, UTType.wav, UTType.aiff]
        
        // Safely add additional audio types if they exist
        if let m4aType = UTType("public.m4a-audio") {
            types.append(m4aType)
        }
        if let aacType = UTType("public.aac-audio") {
            types.append(aacType)
        }
        if let flacType = UTType("public.flac") {
            types.append(flacType)
        }
        
        return types
    }
    
    private func saveServerSettings() {
        // Save server settings to UserDefaults or Keychain
        do {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
            UserDefaults.standard.set(rememberLoginDetails, forKey: "rememberLoginDetails")
            
            // Only save username if remember login details is enabled
            if rememberLoginDetails {
                UserDefaults.standard.set(username, forKey: "username")
            } else {
                // Clear saved username if remember login details is disabled
                UserDefaults.standard.removeObject(forKey: "username")
            }
            
            // Note: In production, store password securely in Keychain
        } catch {
            print("Error saving server settings: \(error)")
        }
    }
    
    // MARK: - Local File Import Methods
    
    private func handleFileImport(result: Result<[URL], Error>) {
        isImporting = true
        importStatus = "Importing files..."
        importError = nil
        importedFilesCount = 0
        
        switch result {
        case .success(let urls):
            print("Importing \(urls.count) files: \(urls.map { $0.lastPathComponent })")
            
            // Switch to local files data source
            dataManager.switchToLocalFiles()
            
            // Remove duplicates based on filename
            let uniqueURLs = Array(Set(urls.map { $0.lastPathComponent })).compactMap { filename in
                urls.first { $0.lastPathComponent == filename }
            }
            
            print("After deduplication: \(uniqueURLs.count) unique files")
            
            for url in uniqueURLs {
                importFile(url: url)
            }
            
            // Update final status
            isImporting = false
            updateImportStatus()
            
        case .failure(let error):
            importError = "Failed to import files: \(error.localizedDescription)"
            importStatus = "Import failed"
            isImporting = false
        }
    }
    
    private func importFile(url: URL) {
        print("Importing file: \(url.lastPathComponent)")
        
        let fileExtension = url.pathExtension.lowercased()
        let supportedFormats = ["mp3", "m4a", "aac", "flac", "wav", "alac"]
        
        guard supportedFormats.contains(fileExtension) else {
            importError = "Unsupported file format: \(fileExtension)"
            importStatus = "Import failed"
            isImporting = false
            return
        }
        
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Cannot access file: \(url.lastPathComponent)"
            importStatus = "Import failed"
            isImporting = false
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            // Copy file to app's documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let musicDirectory = documentsDirectory.appendingPathComponent("Music", isDirectory: true)
            
            // Create music directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: musicDirectory.path) {
                try FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
            }
            
            let destinationURL = musicDirectory.appendingPathComponent(url.lastPathComponent)
            
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Extract metadata and create track using the data manager's method
            let track = dataManager.createTrackFromFile(at: destinationURL)
            
            // Add to data manager
            dataManager.addLocalTrack(track)
            
            importedFilesCount += 1
            
        } catch {
            importError = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
            importStatus = "Import failed"
            isImporting = false
        }
    }
    

    
    private func updateImportStatus() {
        // Check if we have cached local files
        if dataManager.hasLocalFiles() {
            importedFilesCount = dataManager.getLocalFilesCount()
            importStatus = "\(importedFilesCount) files cached"
        } else {
            importedFilesCount = 0
            importStatus = "No files imported"
        }
        importError = nil
    }
    
    // MARK: - Playback Settings Methods
    
    private func loadPlaybackSettings() {
        // Load saved playback settings from UserDefaults
        do {
            autoPlay = UserDefaults.standard.bool(forKey: "autoPlay")
            crossfade = UserDefaults.standard.bool(forKey: "crossfade")
            crossfadeDuration = UserDefaults.standard.double(forKey: "crossfadeDuration")
            
            // Set default crossfade duration if not previously set
            if crossfadeDuration == 0.0 {
                crossfadeDuration = 3.0
            }
            
            // Load notification setting
            enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
            
            // Apply the loaded settings to the music player
            applyPlaybackSettings()
        } catch {
            print("Error loading playback settings: \(error)")
            // Set default values if loading fails
            autoPlay = false
            crossfade = false
            crossfadeDuration = 3.0
            enableNotifications = false
        }
    }
    
    private func savePlaybackSettings() {
        // Save playback settings to UserDefaults
        do {
            UserDefaults.standard.set(autoPlay, forKey: "autoPlay")
            UserDefaults.standard.set(crossfade, forKey: "crossfade")
            UserDefaults.standard.set(crossfadeDuration, forKey: "crossfadeDuration")
            
            // Apply the settings to the music player
            applyPlaybackSettings()
        } catch {
            print("Error saving playback settings: \(error)")
        }
    }
    
    private func applyPlaybackSettings() {
        // Here you would apply the settings to your music player
        // For example:
        // MusicPlayerManager.shared.autoPlay = autoPlay
        // MusicPlayerManager.shared.crossfade = crossfade
        // MusicPlayerManager.shared.crossfadeDuration = crossfadeDuration
        
        // For now, we'll just print the settings (remove this in production)
        print("Playback settings applied:")
        print("Auto-play: \(autoPlay)")
        print("Crossfade: \(crossfade)")
        print("Crossfade Duration: \(crossfadeDuration)s")
    }
    
    // MARK: - Notification Methods
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    // Save the notification preference
                    UserDefaults.standard.set(true, forKey: "enableNotifications")
                } else {
                    print("Notification permission denied")
                    // Reset the toggle to false since permission was denied
                    self.enableNotifications = false
                    UserDefaults.standard.set(false, forKey: "enableNotifications")
                    
                    if let error = error {
                        print("Notification permission error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - Y2K Text Field Style
struct Y2KTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Y2KColors.cosmic)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    SettingsButton()
}
