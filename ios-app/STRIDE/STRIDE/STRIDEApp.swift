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

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    mainTabView
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var mainTabView: some View {
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
                    Label("Ranks", systemImage: "trophy.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Config.Colors.primaryOrange)
        .environmentObject(authManager)
        .environmentObject(healthKitManager)
        .environmentObject(supabaseManager)
        .onAppear {
            healthKitManager.requestAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await healthKitManager.fetchAllData()
                    await healthKitManager.syncToSupabase(
                        token: authManager.accessToken ?? "",
                        userId: authManager.userId ?? ""
                    )
                }
            }
        }
    }

    private func configureAppearance() {
        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Config.Colors.darkBackground)
        tabBarAppearance.shadowColor = .clear

        // Unselected tab items
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .gray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]

        // Selected tab items
        let orangeUI = UIColor(Config.Colors.primaryOrange)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = orangeUI
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: orangeUI]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Config.Colors.darkBackground)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}
