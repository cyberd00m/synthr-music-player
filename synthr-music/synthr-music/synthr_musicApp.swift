//
//  synthr_musicApp.swift
//  synthr-music
//
//  Created by David Morais on 09/08/2025.
//

import SwiftUI
import AVFoundation

// Y2K Dark Blue Color Scheme
struct Y2KColors {
    static let deepSpace = Color(hex: "#000b3c") // Main dark blue #000b3c
    static let midnight = Color(hex: "#001a5c") // Slightly lighter dark blue
    static let cosmic = Color(hex: "#002a7c") // Medium dark blue
    static let nebula = Color(hex: "#003a9c") // Lighter blue for accents
    static let stardust = Color(hex: "#004abc") // Bright blue for highlights
    static let aurora = Color(hex: "#005adc") // Light blue for text
    static let neon = Color(hex: "#006afc") // Neon blue for active elements
    static let glow = Color(hex: "#007aff") // Glowing blue for special elements
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct synthr_musicApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .background(
                    LinearGradient(
                        colors: [Y2KColors.deepSpace, Y2KColors.midnight],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .preferredColorScheme(.dark)
                .monospacedFont()
                .onAppear {
                    // Ensure audio session is configured early
                    do {
                        let audioSession = AVAudioSession.sharedInstance()
                        try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay, .defaultToSpeaker])
                        try audioSession.setActive(true, options: [])
                    } catch {
                        print("Failed to configure audio session at app launch: \(error)")
                    }
                }
        }
    }
}
