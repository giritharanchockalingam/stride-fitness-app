import SwiftUI
import HealthKit

@main
struct STRIDEApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var supabaseManager = SupabaseManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }

                    ActivityView()
                        .tabItem {
                            Label("Activity", systemImage: "chart.bar.fill")
                        }

                    WorkoutView()
                        .tabItem {
                            Label("Workout", systemImage: "dumbbell.fill")
                        }

                    LeaderboardView()
                        .tabItem {
                            Label("Leaderboard", systemImage: "list.number")
                        }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .preferredColorScheme(.dark)
                .environmentObject(authManager)
                .environmentObject(healthKitManager)
                .environmentObject(supabaseManager)
                .onAppear {
                    requestHealthKitPermissions()
                    syncHealthDataOnAppear()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    syncHealthDataOnAppear()
                }
            } else {
                LoginView()
                    .preferredColorScheme(.dark)
                    .environmentObject(authManager)
            }
        }
    }

    private func requestHealthKitPermissions() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                print("HealthKit authorization granted")
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }

    private func syncHealthDataOnAppear() {
        guard authManager.isAuthenticated, let userId = authManager.userId, let token = authManager.accessToken else {
            return
        }

        healthKitManager.syncToSupabase(token: token, userId: userId) { success, error in
            if success {
                print("HealthKit data synced successfully")
            } else if let error = error {
                print("HealthKit sync failed: \(error.localizedDescription)")
            }
        }
    }
}
