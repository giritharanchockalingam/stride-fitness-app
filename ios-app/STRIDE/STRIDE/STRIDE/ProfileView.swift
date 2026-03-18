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
    @State private var profile: Profile?
    @State private var achievements: [Achievement] = []
    @State private var earnedAchievementIds: Set<String> = []
    @State private var dailyStats: [DailyStats] = []
    @State private var isSyncing = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    profileHeader
                    statsRow
                    streakCalendar
                    tabSelector
                    tabContent
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .task { await loadAllData() }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(profile: profile) { updated in
                Task { await saveProfile(updated) }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Config.Colors.primaryOrange, Config.Colors.orangeGradient],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Config.Colors.primaryOrange.opacity(0.3), radius: 12, y: 4)

                Text(authManager.initials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(authManager.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                if let username = profile?.username {
                    Text("@\(username)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let level = profile?.fitnessLevel {
                Text(level.capitalized)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Config.Colors.primaryOrange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Config.Colors.primaryOrange.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            profileStatBox(value: "\(profile?.totalWorkouts ?? 0)", label: "Workouts")
            profileStatBox(value: "\(profile?.totalActivities ?? 0)", label: "Activities")
            profileStatBox(value: "\(profile?.currentStreak ?? 0)", label: "Streak")
        }
    }

    private func profileStatBox(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Config.Colors.primaryOrange)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Config.Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Streak Calendar

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            let calendar = Calendar.current
            let today = Date()
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
            let currentDay = calendar.component(.day, from: today)
            let activeDays = Set(dailyStats.compactMap { stat -> Int? in
                guard let date = dateFromString(stat.date) else { return nil }
                let steps = stat.totalSteps ?? 0
                return steps > 0 ? calendar.component(.day, from: date) : nil
            })

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    let isActive = activeDays.contains(day)
                    let isToday = day == currentDay
                    let isFuture = day > currentDay

                    Circle()
                        .fill(isActive ? Config.Colors.primaryOrange : Config.Colors.borderColor.opacity(0.4))
                        .frame(height: 28)
                        .opacity(isFuture ? 0.3 : 1.0)
                        .overlay(
                            Group {
                                if isToday {
                                    Circle().stroke(Config.Colors.primaryOrange, lineWidth: 2)
                                }
                            }
                        )
                }
            }
        }
        .padding(16)
        .background(Config.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation { selectedTab = tab } }) {
                    Text(tab.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(selectedTab == tab ? Config.Colors.primaryOrange : Color.clear)
                        .cornerRadius(10)
                }
            }
        }
        .padding(3)
        .background(Config.Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .achievements:
            achievementsGrid
        case .stats:
            lifetimeStats
        case .settings:
            settingsSection
        }
    }

    // MARK: - Achievements

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements (\(earnedAchievementIds.count)/\(achievements.count))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if achievements.isEmpty {
                Text("No achievements available")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(achievements) { achievement in
                        let isEarned = earnedAchievementIds.contains(achievement.id)
                        VStack(spacing: 8) {
                            Image(systemName: achievement.displayIcon)
                                .font(.system(size: 24))
                                .foregroundColor(isEarned ? Config.Colors.primaryOrange : .gray.opacity(0.4))
                                .frame(width: 48, height: 48)
                                .background(
                                    isEarned ? Config.Colors.primaryOrange.opacity(0.15) : Config.Colors.borderColor.opacity(0.3)
                                )
                                .cornerRadius(12)

                            Text(achievement.name)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isEarned ? .white : .gray.opacity(0.5))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                        .background(Config.Colors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isEarned ? Config.Colors.primaryOrange.opacity(0.3) : Config.Colors.borderColor, lineWidth: 1)
                        )
                        .opacity(isEarned ? 1.0 : 0.6)
                    }
                }
            }
        }
        .padding(20)
        .background(Config.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Lifetime Stats

    private var lifetimeStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lifetime Stats")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            let totalSteps = dailyStats.reduce(0) { $0 + ($1.totalSteps ?? 0) }
            let totalCalories = dailyStats.reduce(0.0) { $0 + ($1.totalCalories ?? 0) }
            let totalDistance = dailyStats.reduce(0.0) { $0 + ($1.totalDistanceMeters ?? 0) }
            let avgSteps = dailyStats.isEmpty ? 0 : totalSteps / dailyStats.count

            VStack(spacing: 6) {
                statRow(label: "Total Steps", value: formatLargeNumber(totalSteps))
                statRow(label: "Total Distance", value: String(format: "%.1f km", totalDistance / 1000.0))
                statRow(label: "Total Calories", value: "\(formatLargeNumber(Int(totalCalories))) kcal")
                statRow(label: "Total Workouts", value: "\(profile?.totalWorkouts ?? 0)")
                statRow(label: "Avg Daily Steps", value: formatLargeNumber(avgSteps))
                statRow(label: "Longest Streak", value: "\(profile?.longestStreak ?? 0) days")
            }
        }
        .padding(20)
        .background(Config.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Config.Colors.darkBackground)
        .cornerRadius(8)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 10) {
            settingsRow(icon: "pencil", label: "Edit Profile") {
                showEditProfile = true
            }

            settingsRow(icon: "target", label: "Goals") {
                // TODO: Goals editor
            }

            // HealthKit Sync
            Button(action: {
                Task {
                    isSyncing = true
                    await healthKitManager.syncToSupabase(
                        token: authManager.accessToken ?? "",
                        userId: authManager.userId ?? ""
                    )
                    isSyncing = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isSyncing ? "Syncing..." : "Sync Health Data")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Config.Colors.primaryOrange)
                    }
                }
                .foregroundColor(Config.Colors.primaryOrange)
                .padding(14)
                .background(Config.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Config.Colors.primaryOrange.opacity(0.4), lineWidth: 1)
                )
            }

            if let lastSync = healthKitManager.lastSyncDate {
                Text("Last synced: \(lastSync, style: .relative) ago")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Sign Out
            Button(action: { authManager.signOut() }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Sign Out")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(14)
                .background(Config.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Config.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Config.Colors.borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }

        async let prof = supabaseManager.fetchProfile(userId: userId, token: token)
        async let achieves = supabaseManager.fetchAchievements(token: token)
        async let userAchieves = supabaseManager.fetchUserAchievements(userId: userId, token: token)
        async let stats = supabaseManager.fetchDailyStats(userId: userId, token: token, days: 30)

        let (p, a, ua, s) = await (prof, achieves, userAchieves, stats)
        profile = p
        achievements = a
        earnedAchievementIds = Set(ua.map { $0.achievementId })
        dailyStats = s
    }

    private func saveProfile(_ updated: ProfileUpdate) async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }
        try? await supabaseManager.update(
            table: "profiles",
            data: updated,
            filters: [("id", "eq", userId)],
            token: token
        )
        profile = await supabaseManager.fetchProfile(userId: userId, token: token)
    }

    // MARK: - Helpers

    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }

    private func formatLargeNumber(_ num: Int) -> String {
        if num >= 1_000_000 { return String(format: "%.1fM", Double(num) / 1_000_000.0) }
        if num >= 1_000 { return String(format: "%.1fK", Double(num) / 1_000.0) }
        return "\(num)"
    }
}

// MARK: - Profile Tab

enum ProfileTab: CaseIterable {
    case achievements, stats, settings

    var label: String {
        switch self {
        case .achievements: return "Achievements"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Profile Update Model

struct ProfileUpdate: Codable {
    var fullName: String?
    var username: String?
    var bio: String?
    var fitnessLevel: String?
    var dailyStepGoal: Int?
    var dailyCalorieGoal: Int?
    var dailyActiveMinutesGoal: Int?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case username, bio
        case fitnessLevel = "fitness_level"
        case dailyStepGoal = "daily_step_goal"
        case dailyCalorieGoal = "daily_calorie_goal"
        case dailyActiveMinutesGoal = "daily_active_minutes_goal"
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    let profile: Profile?
    var onSave: (ProfileUpdate) -> Void

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var fitnessLevel: String = "beginner"

    private let levels = ["beginner", "intermediate", "advanced"]

    var body: some View {
        NavigationView {
            ZStack {
                Config.Colors.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        editField(label: "Full Name", text: $fullName)
                        editField(label: "Username", text: $username)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            TextEditor(text: $bio)
                                .frame(height: 80)
                                .padding(8)
                                .background(Config.Colors.cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Config.Colors.borderColor, lineWidth: 1))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fitness Level")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                ForEach(levels, id: \.self) { level in
                                    Button(action: { fitnessLevel = level }) {
                                        Text(level.capitalized)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(fitnessLevel == level ? .white : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(fitnessLevel == level ? Config.Colors.primaryOrange : Config.Colors.cardBackground)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        Button(action: {
                            let update = ProfileUpdate(
                                fullName: fullName.isEmpty ? nil : fullName,
                                username: username.isEmpty ? nil : username,
                                bio: bio.isEmpty ? nil : bio,
                                fitnessLevel: fitnessLevel
                            )
                            onSave(update)
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Config.Colors.primaryOrange)
                                .cornerRadius(14)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            fullName = profile?.fullName ?? ""
            username = profile?.username ?? ""
            bio = profile?.bio ?? ""
            fitnessLevel = profile?.fitnessLevel ?? "beginner"
        }
        .presentationDetents([.large])
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            TextField(label, text: text)
                .padding(14)
                .background(Config.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Config.Colors.borderColor, lineWidth: 1))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
}
