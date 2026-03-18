import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var selectedTab = 0
    @State private var isSyncing = false
    @State private var currentStreak = 12

    var body: some View {
        ZStack {
            Color.strideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        statsRow
                        streakCalendar
                        tabSelector
                        tabContent
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            loadProfile()
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String((authManager.userName ?? authManager.userEmail ?? "A").prefix(1)).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.strideText)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.userName ?? "User")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.strideText)

                Text("@\(authManager.userName?.lowercased() ?? "athlete")")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)

                Text(authManager.userEmail ?? "")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.strideTertiary)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.strideText)
                        .frame(width: 40, height: 40)
                        .background(Color.strideCard)
                        .cornerRadius(10)
                }

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.strideText)
                        .frame(width: 40, height: 40)
                        .background(Color.strideCard)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(icon: "dumbbell.fill", label: "Workouts", value: "42", color: .stridePrimary)
            statCard(icon: "figure.walk", label: "Activities", value: "156", color: .strideBlue)
            statCard(icon: "flame.fill", label: "Streak", value: "\(currentStreak)", color: .red)
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.strideSecondary)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.strideText)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.strideCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.strideBorder, lineWidth: 1)
        )
    }

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Streak Calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.strideText)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.strideCard)
                        .frame(width: 8, height: 8)

                    Text("Inactive")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    Circle()
                        .fill(Color.strideAccent)
                        .frame(width: 8, height: 8)

                    Text("Active")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            calendarGrid
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

            ForEach(0..<5, id: \.self) { week in
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        let dayNumber = week * 7 + day + 1
                        if dayNumber <= 30 {
                            let isActive = Int.random(in: 0..<10) > 3

                            ZStack {
                                Circle()
                                    .fill(isActive ? Color.strideAccent : Color.strideCard)

                                Text("\(dayNumber)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(isActive ? Color.strideBackground : Color.strideText)
                            }
                            .frame(height: 32)
                        } else {
                            Color.clear
                                .frame(height: 32)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.strideCard)
        .cornerRadius(12)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Achievements", "Stats", "Settings"].enumerated(), id: \.offset) { index, title in
                Button(action: { selectedTab = index }) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTab == index ? .strideText : .strideSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? Color.clear : Color.clear)
                        .overlay(alignment: .bottom) {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.stridePrimary)
                                    .frame(height: 3)
                            }
                        }
                }
            }
        }
        .background(Color.strideCard)
        .cornerRadius(10)
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                achievementsTab
            case 1:
                statsTab
            case 2:
                settingsTab
            default:
                achievementsTab
            }
        }
    }

    private var achievementsTab: some View {
        VStack(spacing: 12) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    achievementBadge(
                        icon: ["🏃", "💪", "🎯", "🔥", "⚡", "🏆"][index],
                        title: ["Speedster", "Strength", "Goal Crusher", "On Fire", "Power Up", "Legend"][index],
                        isEarned: index < 4
                    )
                }
            }

            Text("\(4) / \(6) Unlocked")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.strideSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    private func achievementBadge(icon: String, title: String, isEarned: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.stridePrimary.opacity(0.2) : Color.strideCard)

                Text(icon)
                    .font(.system(size: 28))
                    .opacity(isEarned ? 1 : 0.4)
            }
            .frame(width: 60, height: 60)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.strideText)
                .lineLimit(1)
        }
        .padding(10)
        .background(Color.strideCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEarned ? Color.stridePrimary : Color.strideBorder, lineWidth: 1)
        )
        .opacity(isEarned ? 1 : 0.6)
    }

    private var statsTab: some View {
        VStack(spacing: 12) {
            statsItem(label: "Total Steps", value: "245,680", color: .strideBlue)
            statsItem(label: "Total Distance", value: "342.5 km", color: .strideAccent)
            statsItem(label: "Total Workouts", value: "42", color: .stridePrimary)
            statsItem(label: "Total Active Minutes", value: "2,450 min", color: Color(hex: "FF9500"))
            statsItem(label: "Total Calories", value: "18,420 kcal", color: .red)
            statsItem(label: "Longest Streak", value: "25 days", color: Color(hex: "34C759"))
        }
    }

    private func statsItem(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.strideText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.strideSecondary)
        }
        .padding(12)
        .background(Color.strideCard)
        .cornerRadius(10)
    }

    private var settingsTab: some View {
        VStack(spacing: 12) {
            settingsButton(icon: "person.fill", label: "Edit Profile", action: {})
            settingsButton(icon: "target", label: "Set Goals", action: {})
            settingsButton(icon: "heart.fill", label: "Health Data", action: {})
            settingsButton(icon: "bell.fill", label: "Notifications", action: {})
            settingsButton(icon: "lock.fill", label: "Privacy & Security", action: {})

            Divider()
                .background(Color.strideBorder)

            Button(action: {
                isSyncing = true
                healthKitManager.syncToSupabase(token: authManager.accessToken ?? "", userId: authManager.userId ?? "") { success, error in
                    isSyncing = false
                }
            }) {
                HStack(spacing: 12) {
                    if isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .strideAccent))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.strideAccent)
                    }

                    Text("Sync HealthKit Data")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.strideAccent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.strideSecondary)
                }
                .padding(12)
                .background(Color.strideCard)
                .cornerRadius(10)
            }
            .disabled(isSyncing)

            Divider()
                .background(Color.strideBorder)

            Button(action: signOut) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)

                    Text("Sign Out")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    private func settingsButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.stridePrimary)
                    .frame(width: 24)

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.strideText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.strideSecondary)
            }
            .padding(12)
            .background(Color.strideCard)
            .cornerRadius(10)
        }
    }

    private func signOut() {
        authManager.signOut()
    }

    private func loadProfile() {
        supabaseManager.fetchUserProfile(userId: authManager.userId ?? "") {
            if let profile = supabaseManager.userProfile {
                authManager.userName = profile["username"] as? String
                if let streak = profile["current_streak"] as? Int {
                    currentStreak = streak
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
        .preferredColorScheme(.dark)
}
