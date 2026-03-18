import SwiftUI

@main
struct STRIDESyncApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainView()
                    .environmentObject(authManager)
                    .environmentObject(healthKitManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
