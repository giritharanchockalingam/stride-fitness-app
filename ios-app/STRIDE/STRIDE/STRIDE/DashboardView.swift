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

    @State private var recentActivities: [[String: Any]] = []
    @State private var userStreak: Int = 0
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    streakSection
                    ringSection
                    statsSection
                    chartSection
                    activitiesSection
                }
                .padding(16)
            }
            .refreshable {
                isRefreshing = true
                healthKitManager.fetchTodayStats()
                healthKitManager.fetchWeeklyStats()
                await loadRecentActivities()
                isRefreshing = false
            }
        }
        .onAppear {
            Task {
                await loadRecentActivities()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting())
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Text(authManager.userEmail ?? "User")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakSection: some View {
        Group {
            if userStreak > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "FF6B35"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)

                            Text("\(userStreak) days")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text("Keep it going!")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "FF6B35"))
                    }
                    .padding(16)
                    .background(Color(hex: "141414"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var ringSection: some View {
        VStack(spacing: 16) {
            ActivityRingView(
                moveProgress: min(Double(healthKitManager.todayCalories) / 600.0, 1.0),
                exerciseProgress: 0.75,
                stepsProgress: min(Double(healthKitManager.todaySteps) / 10000.0, 1.0),
                size: 200
            )
            .frame(maxWidth: .infinity)
            .frame(height: 240)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCardView(
                    icon: "figure.walk",
                    value: String(healthKitManager.todaySteps),
                    unit: "steps",
                    label: "Steps",
                    color: Color(hex: "007AFF")
                )

                StatCardView(
                    icon: "flame.fill",
                    value: String(Int(healthKitManager.todayCalories)),
                    unit: "kcal",
                    label: "Calories",
                    color: Color(hex: "FF6B35")
                )
            }

            HStack(spacing: 16) {
                StatCardView(
                    icon: "heart.fill",
                    value: String(Int(healthKitManager.todayHeartRate)),
                    unit: "bpm",
                    label: "Heart Rate",
                    color: Color(hex: "FF3B30")
                )

                StatCardView(
                    icon: "location.fill",
                    value: String(format: "%.1f", healthKitManager.todayDistance / 1000),
                    unit: "km",
                    label: "Distance",
                    color: Color(hex: "34C759")
                )
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Steps")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Chart {
                ForEach(Array(healthKitManager.weeklySteps.enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Day", getDayLabel(index)),
                        y: .value("Steps", value)
                    )
                    .foregroundStyle(Color(hex: "007AFF"))
                }
            }
            .frame(height: 200)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color(hex: "141414"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if recentActivities.isEmpty {
                Text("No activities yet")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(32)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recentActivities.prefix(5).enumerated()), id: \.offset) { _, activity in
                        if let title = activity["title"] as? String,
                           let duration = activity["duration"] as? Int,
                           let distance = activity["distance"] as? Double {
                            ActivityRowView(
                                title: title,
                                duration: duration,
                                distance: distance,
                                icon: "figure.run"
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

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }

    private func getDayLabel(_ index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let dayIndex = calendar.component(.weekday, from: date) - 1
        return days[dayIndex]
    }

    private func loadRecentActivities() async {
        guard let token = authManager.accessToken else { return }
        recentActivities = await supabaseManager.query(
            table: "activities",
            token: token,
            order: "created_at.desc",
            limit: 10
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
}
