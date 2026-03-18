//
//  Config.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct Config {
    static let supabaseURL = "https://ecylmwvutlxgqivhrxdc.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjeWxtd3Z1dGx4Z3FpdmhyeGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjM2MTYsImV4cCI6MjA4ODYzOTYxNn0.PPa9l51-S35-lMYvtQi_0MP-s41WeN1y686BuBBX-GE"
    static let healthKitSyncEndpoint = "\(supabaseURL)/functions/v1/healthkit-sync"
    static let oauthCallbackScheme = "com.stride.stridesync"

    struct Colors {
        static let primaryOrange = Color(hex: "FC4C02")
        static let orangeGradient = Color(hex: "FF6B35")
        static let darkBackground = Color(hex: "0a0a0a")
        static let cardBackground = Color(hex: "141414")
        static let borderColor = Color(hex: "2C2C2E")
        static let moveRing = Color(hex: "FC4C02")
        static let exerciseRing = Color(hex: "2DD4BF")
        static let stepsRing = Color(hex: "007AFF")
        static let gold = Color(hex: "FFD700")
        static let silver = Color(hex: "C0C0C0")
        static let bronze = Color(hex: "CD7F32")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
