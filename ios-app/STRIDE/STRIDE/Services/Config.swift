import SwiftUI

struct Config {
    static let supabaseURL = "https://ecylmwvutlxgqivhrxdc.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjeWxtd3Z1dGx4Z3FpdmhyeGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjM2MTYsImV4cCI6MjA4ODYzOTYxNn0.PPa9l51-S35-lMYvtQi_0MP-s41WeN1y686BuBBX-GE"
    static let healthKitSyncEndpoint = "/functions/v1/healthkit-sync"
    static let oauthCallbackScheme = "com.stride.stridesync"
}

extension Color {
    static let strideBackground = Color(hex: "0a0a0a")
    static let strideCard = Color(hex: "141414")
    static let strideBorder = Color(hex: "2C2C2E")
    static let stridePrimary = Color(hex: "FC4C02")
    static let stridePrimaryLight = Color(hex: "FF6B35")
    static let strideAccent = Color(hex: "00D4AA")
    static let strideBlue = Color(hex: "007AFF")
    static let strideText = Color.white
    static let strideSecondary = Color(hex: "8E8E93")
    static let strideTertiary = Color(hex: "636366")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 15) * 17, (int & 15) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 255, int & 255)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 255, int >> 8 & 255, int & 255)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
