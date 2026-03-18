//
//  ProfileView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var selectedTab: ProfileTab = .achievements
    @State private var userStats: [String: Any] = [:]
    @State private var streak: Int = 0

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    profileHeader()

                    statsRow()

                    if streak > 0 {
                        streakCalendar()
                    }

                    tabSelector()

                    Group {
                        switch selectedTab {
                        case .achievements:
                            achievementsGrid()
                        case .stats:
                            statsSection()
                        case .settings:
                            settingsSection()
                        }
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
    }

    private func profileHeader() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FC4C02"),
                                Color(hex: "FF6B35")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(String(authManager.userEmail?.prefix(1) ?? "U").uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(authManager.userEmail ?? "User")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("@username")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }

            Text("Fitness enthusiast pushing limits daily")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func statsRow() -> some View {
        HStack(spacing: 16) {
            statBox(value: "12", label: "Workouts")
            statBox(value: "47", label: "Activities")
            statBox(value: String(streak), label: "Streak Days")
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "FC4C02"))

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(hex: "141414"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }

    private func streakCalendar() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { week in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { day in
                            Circle()
                                .fill(
                                    day < 4 + week ?
                                    Color(hex: "FC4C02") :
                                    Color(hex: "141414")
                                )
                                .frame(height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "141414"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }

    private func tabSelector() -> some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Text(tab.label).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color(hex: "FC4C02"))
    }

    private func achievementsGrid() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(spacing: 8) {
                        Text("🏆")
                            .font(.system(size: 32))

                        Text("Earned")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color(hex: "141414"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func statsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifetime Stats")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                statItem(label: "Total Steps", value: "2.4M")
                statItem(label: "Total Distance", value: "1,200km")
                statItem(label: "Total Calories", value: "185,400 kcal")
                statItem(label: "Total Workouts", value: "145")
                statItem(label: "Avg Daily Steps", value: "8,450")
            }
        }
        .padding(16)
        .background(Color(hex: "141414"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }

    private func statItem(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color(hex: "0a0a0a"))
        .cornerRadius(6)
    }

    private func settingsSection() -> some View {
        VStack(spacing: 12) {
            SettingsButton(label: "Edit Profile", icon: "pencil")
            SettingsButton(label: "Goals", icon: "target")

            Button(action: {
                Task {
                    await syncToSupabase()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Sync to STRIDE")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(Color(hex: "FC4C02"))
                .background(Color(hex: "141414"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "FC4C02"), lineWidth: 1)
                )
            }

            Button(action: {
                authManager.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Sign Out")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.red)
                .background(Color(hex: "141414"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.red, lineWidth: 1)
                )
            }
        }
    }

    private func loadUserProfile() async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }

        let results = await supabaseManager.query(
            table: "user_profiles",
            token: token,
            filters: ["id": userId]
        )

        if let profile = results.first {
            userStats = profile
            if let streakValue = profile["streak"] as? Int {
                streak = streakValue
            }
        }
    }

    private func syncToSupabase() async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }
        await healthKitManager.syncToSupabase(token: token, userId: userId)
    }
}

enum ProfileTab: CaseIterable {
    case achievements
    case stats
    case settings

    var label: String {
        switch self {
        case .achievements: return "Achievements"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }
}

struct SettingsButton: View {
    let label: String
    let icon: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(label)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(Color(hex: "141414"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
}
