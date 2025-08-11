import SwiftUI

struct ServerConnectionView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var showConnectionDetails = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "server.rack")
                        .font(.monospacedSystem(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Connect to Navidrome")
                        .font(.monospacedTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect to your music server to access your library")
                        .font(.monospacedSubheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Connection Form
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.monospacedHeadline)
                            .foregroundColor(.primary)
                        
                        TextField("e.g., navidrome.example.com", text: $serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.monospacedHeadline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.monospacedHeadline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                // Connection Status
                if dataManager.navidromeConnectionStatus != .disconnected {
                    VStack(spacing: 10) {
                        HStack {
                            switch dataManager.navidromeConnectionStatus {
                            case .connecting:
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                                    .foregroundColor(.orange)
                            case .connected:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connected!")
                                    .foregroundColor(.green)
                            case .failed:
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Connection Failed")
                                    .foregroundColor(.red)
                            default:
                                EmptyView()
                            }
                        }
                        .font(.monospacedSubheadline)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: connectToServer) {
                        HStack {
                            if isConnecting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "link")
                            }
                            Text(isConnecting ? "Connecting..." : "Connect to Server")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                    
                    if dataManager.isNavidromeConnected {
                        Button(action: {
                            showConnectionDetails = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("View Connection Details")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: disconnectFromServer) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Server Connection")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showConnectionDetails) {
            ConnectionDetailsView()
                .environmentObject(dataManager)
        }
    }
    
    private func connectToServer() {
        isConnecting = true
        
        Task {
            await dataManager.connectToNavidrome(
                url: serverURL,
                username: username,
                password: password
            )
            
            await MainActor.run {
                isConnecting = false
            }
        }
    }
    
    private func disconnectFromServer() {
        dataManager.disconnectFromNavidrome()
    }
}

struct ConnectionDetailsView: View {
    @EnvironmentObject var dataManager: UnifiedDataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if dataManager.isNavidromeConnected {
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(title: "Data Source", value: "Navidrome Server")
                        DetailRow(title: "Status", value: "Connected")
                        DetailRow(title: "Tracks", value: "\(dataManager.tracks.count)")
                        DetailRow(title: "Albums", value: "\(dataManager.albums.count)")
                        DetailRow(title: "Artists", value: "\(dataManager.artists.count)")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Connection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.monospacedHeadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.monospacedBody)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ServerConnectionView()
}
