import SwiftUI
import AVFoundation

struct RadioView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var selectedGenre: String? = nil
    @State private var showFavoritesOnly = false
    
    var filteredStations: [RadioStation] {
        var stations = dataManager.radioStations
        
        // Filter by favorites if enabled
        if showFavoritesOnly {
            stations = stations.filter { $0.isFavorite }
        }
        
        // Filter by genre if selected
        if let genre = selectedGenre {
            stations = stations.filter { $0.genre == genre }
        }
        
        return stations
    }
    
    var availableGenres: [String] {
        Array(Set(dataManager.radioStations.compactMap { $0.genre })).sorted()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter bar
                    VStack(spacing: 12) {
                        // Favorites toggle
                        HStack {
                            Button(action: {
                                showFavoritesOnly.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                        .font(.system(size: 14))
                                    Text("Favorites")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(showFavoritesOnly ? Y2KColors.neon : Y2KColors.cosmic)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(showFavoritesOnly ? Y2KColors.glow : Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(showFavoritesOnly ? .black : .white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Genre filter
                        if !availableGenres.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        selectedGenre = nil
                                    }) {
                                        Text("All")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(selectedGenre == nil ? Y2KColors.neon : Y2KColors.cosmic)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .stroke(selectedGenre == nil ? Y2KColors.glow : Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                            .foregroundColor(selectedGenre == nil ? .black : .white)
                                    }
                                    
                                    ForEach(availableGenres, id: \.self) { genre in
                                        Button(action: {
                                            selectedGenre = selectedGenre == genre ? nil : genre
                                        }) {
                                            Text(genre)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .fill(selectedGenre == genre ? Y2KColors.neon : Y2KColors.cosmic)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 15)
                                                                .stroke(selectedGenre == genre ? Y2KColors.glow : Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                                .foregroundColor(selectedGenre == genre ? .black : .white)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                    
                    // Radio stations grid
                    if filteredStations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "radio")
                                .font(.system(size: 48))
                                .foregroundColor(Y2KColors.neon.opacity(0.6))
                            
                            Text("No Radio Stations")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Add some radio stations using the + button in Settings to get started")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(filteredStations) { station in
                                    RadioStationCard(station: station)
                                        .environmentObject(musicPlayer)
                                        .environmentObject(dataManager)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Radio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                        .environmentObject(dataManager)
                }
            }
        }
    }
}

struct RadioStationCard: View {
    let station: RadioStation
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var isPlaying = false
    @State private var showEditSheet = false
    
    var body: some View {
        Button(action: {
            playStation()
        }) {
            VStack(spacing: 12) {
                // Radio icon with playing indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Y2KColors.neon.opacity(0.2), Y2KColors.glow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "radio")
                        .font(.system(size: 24))
                        .foregroundColor(Y2KColors.neon)
                    
                    // Playing indicator
                    if isPlaying {
                        Circle()
                            .fill(Y2KColors.neon)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Y2KColors.deepSpace, lineWidth: 2)
                            )
                            .offset(x: 20, y: -20)
                    }
                }
                
                // Station info
                VStack(spacing: 4) {
                    Text(station.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let genre = station.genre {
                        Text(genre)
                            .font(.caption)
                            .foregroundColor(Y2KColors.neon)
                            .lineLimit(1)
                    }
                    
                    if let description = station.description {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Favorite button
                Button(action: {
                    dataManager.toggleRadioStationFavorite(station)
                }) {
                    Image(systemName: station.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(station.isFavorite ? .red : .white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
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
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                showEditSheet = true
            }) {
                Label("Edit Station", systemImage: "pencil")
            }
            
            Button(action: {
                dataManager.toggleRadioStationFavorite(station)
            }) {
                Label(station.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                      systemImage: station.isFavorite ? "heart.slash" : "heart")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                dataManager.deleteRadioStation(station)
            }) {
                Label("Delete Station", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditRadioStationView(station: station)
                .environmentObject(dataManager)
        }
        .onReceive(musicPlayer.$currentTrack) { track in
            // Check if this station is currently playing
            if let currentTrack = track, currentTrack.streamURL == station.url {
                isPlaying = true
            } else {
                isPlaying = false
            }
        }
    }
    
    private func playStation() {
        // Create a track from the radio station
        let radioTrack = Track(
            title: station.name,
            artist: "Radio Station",
            album: station.genre ?? "Radio",
            duration: 0, // Radio streams don't have a fixed duration
            streamURL: station.url,
            isFavorite: station.isFavorite
        )
        
        // Load and play the radio station
        musicPlayer.loadTrack(radioTrack)
        musicPlayer.play()
    }
}

#Preview {
    RadioView()
        .environmentObject(MusicPlayerManager())
        .environmentObject(UnifiedDataManager())
}
