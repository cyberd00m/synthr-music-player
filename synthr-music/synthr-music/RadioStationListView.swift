import SwiftUI

struct RadioStationListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: UnifiedDataManager
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var stationToDelete: RadioStation?
    
    var filteredStations: [RadioStation] {
        if searchText.isEmpty {
            return dataManager.radioStations.sorted { $0.name < $1.name }
        } else {
            return dataManager.radioStations.filter { station in
                station.name.localizedCaseInsensitiveContains(searchText) ||
                (station.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Y2KColors.deepSpace, Y2KColors.midnight], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Y2KColors.neon)
                        
                        TextField("Search stations...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Y2KColors.cosmic))
                    .padding()
                    
                    // Stations list
                    if filteredStations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "radio")
                                .font(.system(size: 48))
                                .foregroundColor(Y2KColors.neon.opacity(0.6))
                            
                            Text("No Stations Found")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredStations) { station in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [Y2KColors.neon.opacity(0.2), Y2KColors.glow.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "radio")
                                            .font(.system(size: 18))
                                            .foregroundColor(Y2KColors.neon)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(station.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            
                                            if station.isFavorite {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        if let genre = station.genre {
                                            Text(genre)
                                                .font(.caption)
                                                .foregroundColor(Y2KColors.neon)
                                        }
                                        
                                        Text(station.url)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                    
                                    Button(action: {
                                        stationToDelete = station
                                        showDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Radio Stations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Y2KColors.neon)
                }
            }
            .alert("Delete Station", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let station = stationToDelete {
                        dataManager.deleteRadioStation(station)
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(stationToDelete?.name ?? "")'?")
            }
        }
    }
}

#Preview {
    RadioStationListView()
        .environmentObject(UnifiedDataManager())
}
