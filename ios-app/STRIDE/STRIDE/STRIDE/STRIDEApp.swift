//
//  STRIDEApp.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

@main
struct STRIDEApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var supabaseManager = SupabaseManager()

    @Environment(\.scenePhase) var scenePhase

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
                            Label("Activity", systemImage: "figure.run")
                        }

                    WorkoutView()
                        .tabItem {
                            Label("Workout", systemImage: "dumbbell.fill")
                        }

                    LeaderboardView()
                        .tabItem {
                            Label("Leaderboard", systemImage: "trophy.fill")
                        }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .accentColor(Color(hex: "FC4C02"))
                .environmentObject(authManager)
                .environmentObject(healthKitManager)
                .environmentObject(supabaseManager)
                .onAppear {
                    healthKitManager.requestAuthorization()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        Task {
                            await healthKitManager.syncToSupabase(
                                token: authManager.accessToken ?? "",
                                userId: authManager.userId ?? ""
                            )
                        }
                    }
                }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
