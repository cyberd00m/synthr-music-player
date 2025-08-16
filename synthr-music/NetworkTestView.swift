import SwiftUI

struct NetworkTestView: View {
    @StateObject private var networkManager = NetworkManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Network Status Test")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Current Status: \(networkManager.isConnected ? "Connected" : "Disconnected")")
                .foregroundColor(networkManager.isConnected ? .green : .red)
                .font(.headline)
            
            Button("Test Connectivity") {
                networkManager.testConnectivity()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .overlay(
            VStack {
                OfflineBanner(networkManager: networkManager)
                Spacer()
            }
        )
    }
}

#Preview {
    NetworkTestView()
}
