import SwiftUI

struct MainTabView: View {
    @StateObject private var musicPlayer = MusicPlayerManager()
    @StateObject private var dataManager = UnifiedDataManager()
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var networkManager = NetworkManager()
    @State private var showServerConnection = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background - simple black instead of blue gradient
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Offline banner at the top
                OfflineBanner(networkManager: networkManager)
                
                // Main content area - takes up available space
                TabView(selection: $selectedTab) {
                    HomeView()
                        .environmentObject(musicPlayer)
                        .environmentObject(dataManager)
                        .environmentObject(downloadManager)
                        .environmentObject(networkManager)
                        .tag(0)
                    
                    LibraryView()
                        .environmentObject(musicPlayer)
                        .environmentObject(dataManager)
                        .environmentObject(downloadManager)
                        .environmentObject(networkManager)
                        .tag(1)
                    
                    RadioView()
                        .environmentObject(musicPlayer)
                        .environmentObject(dataManager)
                        .environmentObject(downloadManager)
                        .environmentObject(networkManager)
                        .tag(2)
                    
                    SearchView()
                        .environmentObject(musicPlayer)
                        .environmentObject(dataManager)
                        .environmentObject(downloadManager)
                        .environmentObject(networkManager)
                        .tag(3)
                }
                .tabViewStyle(DefaultTabViewStyle())
                .onAppear {
                    // Connect MusicPlayerManager with UnifiedDataManager and DownloadManager
                    musicPlayer.setDataManager(dataManager)
                    musicPlayer.setDownloadManager(downloadManager)
                }
                
                // Mini player bar - positioned above the custom tab bar
                if musicPlayer.currentTrack != nil {
                    MiniPlayerBar()
                        .environmentObject(musicPlayer)
                        .environmentObject(dataManager)
                        .environmentObject(downloadManager)
                        .environmentObject(networkManager)
                        .padding(.bottom, 15)
                }
                
                // Custom tab bar
                HStack(spacing: 0) {
                    Button(action: { selectedTab = 0 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                            Text("Home")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: { selectedTab = 1 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 24))
                            Text("Library")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == 1 ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: { selectedTab = 2 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "radio")
                                .font(.system(size: 24))
                            Text("Radio")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == 2 ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: { selectedTab = 3 }) {
                        VStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                            Text("Search")
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == 3 ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .background(Y2KColors.cosmic)
                .overlay(
                    Rectangle()
                        .stroke(Y2KColors.nebula.opacity(0.2), lineWidth: 1)
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .overlay(
            // Connection status indicator
            VStack {
                if dataManager.dataSource == .navidrome {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(Y2KColors.neon)
                        Text("Connected to Navidrome")
                            .font(.caption)
                            .foregroundColor(Y2KColors.neon)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Y2KColors.neon.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        )
    }
}

#Preview {
    MainTabView()
}
