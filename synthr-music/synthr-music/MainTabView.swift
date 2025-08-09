import SwiftUI

struct MainTabView: View {
    @StateObject private var musicPlayer = MusicPlayerManager()
    @StateObject private var dataManager = UnifiedDataManager()
    @State private var showServerConnection = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                LibraryView()
                    .environmentObject(musicPlayer)
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Library")
                    }
                
                SearchView()
                    .environmentObject(musicPlayer)
                    .environmentObject(dataManager)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
            .background(Color(red: 0.106, green: 0.078, blue: 0.176)) // #1b142d
            .accentColor(.purple)
            .onAppear {
                // Set the tab bar appearance for the bottom tab bar
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 0.106, green: 0.078, blue: 0.176, alpha: 1.0)
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Mini player bar
            MiniPlayerBar()
                .environmentObject(musicPlayer)
        }
        .overlay(
            // Connection status indicator
            VStack {
                if dataManager.dataSource == .navidrome {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.green)
                        Text("Connected to Navidrome")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(15)
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
