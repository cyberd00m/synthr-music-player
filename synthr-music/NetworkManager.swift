import Foundation
import Network
import SwiftUI

class NetworkManager: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    // Method to manually test connectivity (useful for testing)
    func testConnectivity() {
        let testURL = URL(string: "https://www.apple.com")!
        let task = URLSession.shared.dataTask(with: testURL) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self?.isConnected = true
                } else {
                    self?.isConnected = false
                }
            }
        }
        task.resume()
    }
}
