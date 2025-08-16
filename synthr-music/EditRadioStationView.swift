import SwiftUI

struct EditRadioStationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: UnifiedDataManager
    
    let station: RadioStation
    
    @State private var stationName: String
    @State private var stationURL: String
    @State private var stationGenre: String
    @State private var stationDescription: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(station: RadioStation) {
        self.station = station
        self._stationName = State(initialValue: station.name)
        self._stationURL = State(initialValue: station.url)
        self._stationGenre = State(initialValue: station.genre ?? "")
        self._stationDescription = State(initialValue: station.description ?? "")
    }
    
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
                        // Header
                        VStack(spacing: 8) {
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
                                
                                Image(systemName: "radio")
                                    .font(.system(size: 30))
                                    .foregroundColor(Y2KColors.neon)
                            }
                            
                            Text("Edit Radio Station")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Update the details for your radio station")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Form fields
                        VStack(spacing: 16) {
                            // Station name
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "radio")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Station Name")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                TextField("Enter station name", text: $stationName)
                                    .textFieldStyle(Y2KTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            // Station URL
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Stream URL")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                TextField("https://example.com/stream", text: $stationURL)
                                    .textFieldStyle(Y2KTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .keyboardType(.URL)
                            }
                            
                            // Station Genre (optional)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Genre (optional)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                TextField("e.g., Rock, Jazz, Electronic", text: $stationGenre)
                                    .textFieldStyle(Y2KTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            // Station Description (optional)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(Y2KColors.neon)
                                        .frame(width: 16)
                                        .font(.system(size: 14))
                                    
                                    Text("Description (optional)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                TextField("Brief description of the station", text: $stationDescription)
                                    .textFieldStyle(Y2KTextFieldStyle())
                                    .autocapitalization(.sentences)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: updateStation) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Update Station")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(stationName.isEmpty || stationURL.isEmpty ? Y2KColors.nebula : Y2KColors.neon)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(stationName.isEmpty || stationURL.isEmpty ? Y2KColors.nebula.opacity(0.3) : Y2KColors.glow, lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(stationName.isEmpty || stationURL.isEmpty)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Y2KColors.cosmic)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Y2KColors.nebula.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Radio Station")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateStation() {
        // Validate inputs
        guard !stationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a station name"
            showError = true
            return
        }
        
        guard !stationURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a stream URL"
            showError = true
            return
        }
        
        // Validate URL format
        guard let url = URL(string: stationURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme != nil else {
            errorMessage = "Please enter a valid URL (e.g., https://example.com/stream)"
            showError = true
            return
        }
        
        // Check for duplicate URLs (excluding the current station)
        let trimmedURL = stationURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let otherStations = dataManager.radioStations.filter { $0.id != station.id }
        if otherStations.contains(where: { $0.url == trimmedURL }) {
            errorMessage = "A station with this URL already exists"
            showError = true
            return
        }
        
        // Update the station
        dataManager.updateRadioStation(
            station,
            name: stationName.trimmingCharacters(in: .whitespacesAndNewlines),
            url: trimmedURL,
            genre: stationGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : stationGenre.trimmingCharacters(in: .whitespacesAndNewlines),
            description: stationDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : stationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Dismiss the view
        dismiss()
    }
}

#Preview {
    EditRadioStationView(station: RadioStation(name: "Test Station", url: "https://example.com/stream"))
        .environmentObject(UnifiedDataManager())
}
