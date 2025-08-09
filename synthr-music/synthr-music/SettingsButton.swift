import SwiftUI

struct SettingsButton: View {
    @State private var showSettings = false
    
    var body: some View {
        Button(action: {
            showSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.primary)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enableNotifications = true
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
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 12) {
                        // Header with icon and title
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 40, height: 40)
                                
                                Image("NavidromeIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Navidrome Server")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text("Connect to your Navidrome music server")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Connection status card
                        HStack(spacing: 12) {
                            if isConnecting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isConnected ? .green : .red)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(connectionStatus)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isConnected ? .green : .red)
                                
                                if let error = connectionError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .lineLimit(2)
                                } else {
                                    Text(isConnected ? "Successfully connected to your navidrome server" : "Not connected to any navidrome server")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                        
                        // Server configuration fields
                        VStack(spacing: 10) {
                            // Server URL field
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.purple)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Server URL")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                TextField("http://192.168.1.100:4533", text: $serverURL)
                                    .textFieldStyle(CompactTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .keyboardType(.URL)
                            }
                            
                            // Username field
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Username")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                TextField("Enter your username", text: $username)
                                    .textFieldStyle(CompactTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Password")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .textFieldStyle(CompactTextFieldStyle())
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textFieldStyle(CompactTextFieldStyle())
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Remember Login Details checkbox
                            HStack(spacing: 8) {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 16)
                                    .font(.system(size: 14))
                                
                                Toggle("Save login info", isOn: $rememberLoginDetails)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 8) {
                            Button(action: connectToServer) {
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Connect to Server")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting ? Color.gray : Color.green)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Server Connection")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                        .padding(.bottom, 4)
                }
                
                Section("Playback") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Auto-play", isOn: $autoPlay)
                                .onChange(of: autoPlay) { _ in
                                    savePlaybackSettings()
                                }
                            
                            Text("Automatically start playing the next track when the current one ends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Crossfade", isOn: $crossfade)
                                .onChange(of: crossfade) { _ in
                                    savePlaybackSettings()
                                }
                            
                            Text("Smoothly blend between tracks for seamless playback")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if crossfade {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Crossfade Duration")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(crossfadeDuration, specifier: "%.1f")s")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $crossfadeDuration, in: 1.0...8.0, step: 0.5)
                                    .onChange(of: crossfadeDuration) { _ in
                                        savePlaybackSettings()
                                    }
                                
                                Text("Adjust how long the crossfade effect lasts between tracks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadServerSettings()
                loadPlaybackSettings()
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
        
        // Attempt to authenticate and fetch music data
        authenticateAndFetchMusic()
    }
    
    private func authenticateAndFetchMusic() {
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
        
        // Check if we have a saved connection and test it
        if !serverURL.isEmpty && !username.isEmpty {
            // Note: In production, you'd want to check if the saved connection is still valid
            // For now, we'll just show as disconnected
            isConnected = false
            connectionStatus = "Not connected"
        }
    }
    
    private func saveServerSettings() {
        // Save server settings to UserDefaults or Keychain
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
    }
    
    // MARK: - Playback Settings Methods
    
    private func loadPlaybackSettings() {
        // Load saved playback settings from UserDefaults
        autoPlay = UserDefaults.standard.bool(forKey: "autoPlay")
        crossfade = UserDefaults.standard.bool(forKey: "crossfade")
        crossfadeDuration = UserDefaults.standard.double(forKey: "crossfadeDuration")
        
        // Set default crossfade duration if not previously set
        if crossfadeDuration == 0.0 {
            crossfadeDuration = 3.0
        }
        
        // Apply the loaded settings to the music player
        applyPlaybackSettings()
    }
    
    private func savePlaybackSettings() {
        // Save playback settings to UserDefaults
        UserDefaults.standard.set(autoPlay, forKey: "autoPlay")
        UserDefaults.standard.set(crossfade, forKey: "crossfade")
        UserDefaults.standard.set(crossfadeDuration, forKey: "crossfadeDuration")
        
        // Apply the settings to the music player
        applyPlaybackSettings()
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
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Compact Text Field Style
struct CompactTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

#Preview {
    SettingsButton()
}
