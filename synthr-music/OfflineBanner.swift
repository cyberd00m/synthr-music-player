import SwiftUI

struct OfflineBanner: View {
    @ObservedObject var networkManager: NetworkManager
    
    var body: some View {
        if !networkManager.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(Y2KColors.neon)
                    .font(.system(size: 14, weight: .medium))
                
                Text("No Internet Connection")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Y2KColors.neon)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Y2KColors.cosmic.opacity(0.9), Y2KColors.nebula.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Rectangle()
                    .stroke(Y2KColors.neon.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: networkManager.isConnected)
        }
    }
}

#Preview {
    OfflineBanner(networkManager: NetworkManager())
}
