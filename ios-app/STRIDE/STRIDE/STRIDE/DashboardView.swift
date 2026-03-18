//
//  DashboardView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    @State private var recentActivities: [ActivityRecord] = []
    @State private var featuredPlans: [WorkoutPlan] = []
    @State private var profile: Profile?
    @State private var isRefreshing = false
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    streakBanner
                    todayProgressCard
                    statsGrid
                    weeklyChart
                    recentActivitiesSection
                    featuredWorkoutsSection
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .refreshable {
                await refreshData()
            }
        }
        .task { await loadData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text("\(authManager.displayName) \u{1F44B}")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: { showNotifications = true }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Config.Colors.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Config.Colors.borderColor, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        Group {
            let streak = profile?.currentStreak ?? 0
            if streak > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Config.Colors.orangeGradient)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak) Day Streak")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Keep up the momentum!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Config.Colors.orangeGradient)
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Config.Colors.primaryOrange.opacity(0.15), Config.Colors.cardBackground],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Config.Colors.primaryOrange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Today's Progress Card

    private var todayProgressCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Details")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Config.Colors.primaryOrange)
            }

            ZStack {
                ActivityRingView(
                    moveProgress: healthKitManager.moveProgress,
                    exerciseProgress: healthKitManager.exerciseProgress,
                    stepsProgress: healthKitManager.stepsProgress,
                    size: 180,
                    lineWidth: 14
                )

                VStack(spacing: 2) {
                    Text("\(Int(healthKitManager.overallProgress * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 220)

            // Ring Legend
            HStack(spacing: 0) {
                ringLegendItem(
                    color: Config.Colors.moveRing,
                    label: "Move",
                    value: "\(Int(healthKitManager.todayCalories))/500"
                )
                Spacer()
                ringLegendItem(
                    color: Config.Colors.exerciseRing,
                    label: "Exercise",
                    value: "\(healthKitManager.todayActiveMinutes)/30"
                )
                Spacer()
                ringLegendItem(
                    color: Config.Colors.stepsRing,
                    label: "Steps",
                    value: formatSteps(healthKitManager.todaySteps) + "/10K"
                )
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

    private func ringLegendItem(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCardView(
                    icon: "figure.walk",
                    value: formatNumber(healthKitManager.todaySteps),
                    unit: "steps",
                    label: "Steps",
                    color: Config.Colors.stepsRing
                )
                StatCardView(
                    icon: "flame.fill",
                    value: formatNumber(Int(healthKitManager.todayCalories)),
                    unit: "kcal",
                    label: "Calories",
                    color: Config.Colors.orangeGradient
                )
            }
            HStack(spacing: 12) {
                StatCardView(
                    icon: "heart.fill",
                    value: healthKitManager.todayHeartRate > 0 ? String(Int(healthKitManager.todayHeartRate)) : "--",
                    unit: "bpm",
                    label: "Avg HR",
                    color: Config.Colors.heartRed
                )
                StatCardView(
                    icon: "location.fill",
                    value: String(format: "%.1f", healthKitManager.todayDistance / 1000),
                    unit: "km",
                    label: "Distance",
                    color: Config.Colors.distanceGreen
                )
            }
        }
    }

    // MARK: - Weekly Steps Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Steps")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Chart {
                ForEach(Array(healthKitManager.weeklySteps.enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Day", dayLabel(index)),
                        y: .value("Steps", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Config.Colors.stepsRing, Config.Colors.stepsRing.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
            }
            .frame(height: 180)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray)
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

    // MARK: - Recent Activities

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activities")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("View All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Config.Colors.primaryOrange)
            }

            if recentActivities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No activities yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Text("Start tracking to see your activity here")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentActivities.prefix(5)) { activity in
                        ActivityRowView(activity: activity)
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

    // MARK: - Featured Workouts

    private var featuredWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Workouts")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Browse All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Config.Colors.primaryOrange)
            }

            if featuredPlans.isEmpty {
                Text("No featured workouts available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredPlans) { plan in
                            WorkoutPlanCard(plan: plan)
                        }
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

    // MARK: - Data Loading

    private func loadData() async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }
        async let activities = supabaseManager.fetchActivities(userId: userId, token: token, limit: 5)
        async let plans: [WorkoutPlan] = (try? supabaseManager.fetch(
            table: "workout_plans",
            token: token,
            filters: [("is_featured", "eq", "true")],
            limit: 5
        )) ?? []
        async let prof = supabaseManager.fetchProfile(userId: userId, token: token)

        let (a, p, pr) = await (activities, plans, prof)
        recentActivities = a
        featuredPlans = p
        profile = pr
    }

    private func refreshData() async {
        await healthKitManager.fetchAllData()
        await loadData()
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private func dayLabel(_ index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        }
        return String(steps)
    }

    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? String(num)
    }
}

// MARK: - Workout Plan Card

struct WorkoutPlanCard: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: plan.categoryIcon)
                .font(.system(size: 24))
                .foregroundColor(Config.Colors.primaryOrange)
                .frame(width: 44, height: 44)
                .background(Config.Colors.primaryOrange.opacity(0.15))
                .cornerRadius(10)

            Text(plan.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let duration = plan.estimatedDurationMinutes {
                    Text("\(duration)m")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                }
                if let difficulty = plan.difficulty {
                    Text(difficulty)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: plan.difficultyColor))
                }
            }
        }
        .frame(width: 150)
        .padding(14)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
}
