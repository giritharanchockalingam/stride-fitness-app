import Foundation

enum Config {
    static let supabaseURL = "https://ecylmwvutlxgqivhrxdc.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjeWxtd3Z1dGx4Z3FpdmhyeGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjM2MTYsImV4cCI6MjA4ODYzOTYxNn0.PPa9l51-S35-lMYvtQi_0MP-s41WeN1y686BuBBX-GE"
    static let healthKitSyncEndpoint = "\(supabaseURL)/functions/v1/healthkit-sync"
    static let syncIntervalMinutes = 15.0
    static let oauthCallbackScheme = "com.stride.stridesync"
}
