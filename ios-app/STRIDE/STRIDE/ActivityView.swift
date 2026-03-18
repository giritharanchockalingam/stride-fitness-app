//
//  ActivityView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI
import Charts

struct ActivityView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedMetric: ActivityMetric = .steps
    @State private var activities: [ActivityRecord] = []
    @State private var showLogActivity = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    progressRingSection
                    metricPills
                    chartSection
                    activityListSection
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showLogActivity) {
            LogActivitySheet(onSave: { activity in
                Task { await saveActivity(activity) }
            })
        }
        .task { await loadActivities() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Track your daily progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: { showLogActivity = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Config.Colors.primaryOrange)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRingSection: some View {
        VStack(spacing: 20) {
            ZStack {
                ActivityRingView(
                    moveProgress: healthKitManager.moveProgress,
                    exerciseProgress: healthKitManager.exerciseProgress,
                    stepsProgress: healthKitManager.stepsProgress,
                    size: 160,
                    lineWidth: 14
                )

                VStack(spacing: 2) {
                    Text("\(Int(healthKitManager.overallProgress * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 200)

            HStack(spacing: 0) {
                ringLegend(color: Config.Colors.moveRing, label: "Move", value: "\(Int(healthKitManager.todayCalories))/500")
                Spacer()
                ringLegend(color: Config.Colors.exerciseRing, label: "Exercise", value: "\(healthKitManager.todayActiveMinutes)/30")
                Spacer()
                ringLegend(color: Config.Colors.stepsRing, label: "Steps", value: "\(formatK(healthKitManager.todaySteps))/10K")
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

    private func ringLegend(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
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

    // MARK: - Metric Pills

    private var metricPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityMetric.allCases, id: \.self) { metric in
                    Button(action: { withAnimation { selectedMetric = metric } }) {
                        Text(metric.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedMetric == metric ? .white : .gray)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selectedMetric == metric ? Config.Colors.primaryOrange : Config.Colors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedMetric == metric ? Color.clear : Config.Colors.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(selectedMetric.label) Trend")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(selectedMetric.weeklyTotal(healthKitManager: healthKitManager))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedMetric.color)
            }

            Group {
                switch selectedMetric {
                case .steps:
                    barChart(data: healthKitManager.weeklySteps.map { Double($0) }, color: Config.Colors.stepsRing)
                case .calories:
                    barChart(data: healthKitManager.weeklyCalories, color: Config.Colors.orangeGradient)
                case .heartRate:
                    lineChart(data: healthKitManager.weeklyHeartRate, color: Config.Colors.heartRed)
                case .distance:
                    lineChart(data: healthKitManager.weeklyDistance, color: Config.Colors.distanceGreen)
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

    private func barChart(data: [Double], color: Color) -> some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                BarMark(x: .value("Day", dayLabel(index)), y: .value("Val", value))
                    .foregroundStyle(
                        LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(4)
            }
        }
    }

    private func lineChart(data: [Double], color: Color) -> some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Day", dayLabel(index)), y: .value("Val", value))
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Day", dayLabel(index)), y: .value("Val", value))
                    .foregroundStyle(
                        LinearGradient(colors: [color.opacity(0.3), color.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Day", dayLabel(index)), y: .value("Val", value))
                    .foregroundStyle(color)
                    .symbolSize(24)
            }
        }
    }

    // MARK: - Activity List

    private var activityListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Activities (\(activities.count))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            if activities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))

                    VStack(spacing: 4) {
                        Text("No activities yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("Tap + to log your first activity")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.6))
                    }

                    Button(action: { showLogActivity = true }) {
                        Text("Log Activity")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Config.Colors.primaryOrange)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(activities) { activity in
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

    // MARK: - Data

    private func loadActivities() async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }
        activities = await supabaseManager.fetchActivities(userId: userId, token: token)
        isLoading = false
    }

    private func saveActivity(_ activity: NewActivity) async {
        guard let token = authManager.accessToken, let userId = authManager.userId else { return }

        let record = InsertActivity(
            userId: userId,
            activityType: activity.type,
            title: activity.title,
            startedAt: ISO8601DateFormatter().string(from: Date()),
            durationSeconds: activity.durationSeconds,
            distanceMeters: activity.distanceMeters,
            caloriesBurned: activity.calories,
            provider: "manual"
        )

        do {
            try await supabaseManager.insert(table: "activities", data: record, token: token)
            await loadActivities()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }

    // MARK: - Helpers

    private func dayLabel(_ index: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: index - 6, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatK(_ val: Int) -> String {
        if val >= 1000 { return String(format: "%.1fK", Double(val) / 1000.0) }
        return String(val)
    }
}

// MARK: - Activity Metric Enum

enum ActivityMetric: CaseIterable {
    case steps, calories, heartRate, distance

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .calories: return "Calories"
        case .heartRate: return "Heart Rate"
        case .distance: return "Distance"
        }
    }

    var color: Color {
        switch self {
        case .steps: return Config.Colors.stepsRing
        case .calories: return Config.Colors.orangeGradient
        case .heartRate: return Config.Colors.heartRed
        case .distance: return Config.Colors.distanceGreen
        }
    }

    @MainActor
    func weeklyTotal(healthKitManager: HealthKitManager) -> String {
        switch self {
        case .steps:
            let total = healthKitManager.weeklySteps.reduce(0, +)
            return "\(total / 1000)K total"
        case .calories:
            let total = Int(healthKitManager.weeklyCalories.reduce(0, +))
            return "\(total) kcal"
        case .heartRate:
            let avg = healthKitManager.weeklyHeartRate.filter { $0 > 0 }
            if avg.isEmpty { return "--" }
            return "\(Int(avg.reduce(0, +) / Double(avg.count))) avg"
        case .distance:
            let total = healthKitManager.weeklyDistance.reduce(0, +)
            return String(format: "%.1f km", total)
        }
    }
}

// MARK: - Log Activity Sheet

struct NewActivity {
    var type: String = "run"
    var title: String = "Morning Run"
    var durationSeconds: Int = 1800
    var distanceMeters: Double = 5000
    var calories: Double = 300
}

struct InsertActivity: Codable {
    let userId: String
    let activityType: String
    let title: String
    let startedAt: String
    let durationSeconds: Int
    let distanceMeters: Double
    let caloriesBurned: Double
    let provider: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case activityType = "activity_type"
        case title
        case startedAt = "started_at"
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case caloriesBurned = "calories_burned"
        case provider
    }
}

struct LogActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var activity = NewActivity()
    var onSave: (NewActivity) -> Void

    private let types = [
        ("Run", "run", "figure.run"),
        ("Walk", "walk", "figure.walk"),
        ("Cycle", "cycle", "figure.outdoor.cycle"),
        ("Swim", "swim", "figure.pool.swim"),
        ("Hike", "hike", "figure.hiking"),
        ("Yoga", "yoga", "figure.yoga")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Config.Colors.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activity Type")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(types, id: \.1) { name, type, icon in
                                    Button(action: {
                                        activity.type = type
                                        activity.title = "Morning \(name)"
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                            Text(name)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 70)
                                        .foregroundColor(activity.type == type ? .white : .gray)
                                        .background(activity.type == type ? Config.Colors.primaryOrange : Config.Colors.cardBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    activity.type == type ? Config.Colors.primaryOrange : Config.Colors.borderColor,
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // Fields
                        inputField(label: "Title", text: $activity.title)

                        numberField(label: "Duration (seconds)", value: Binding(
                            get: { Double(activity.durationSeconds) },
                            set: { activity.durationSeconds = Int($0) }
                        ))

                        numberField(label: "Distance (meters)", value: $activity.distanceMeters)

                        numberField(label: "Calories", value: $activity.calories)

                        // Save Button
                        Button(action: {
                            onSave(activity)
                            dismiss()
                        }) {
                            Text("Save Activity")
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
            .navigationTitle("Log Activity")
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
        .presentationDetents([.large])
    }

    private func inputField(label: String, text: Binding<String>) -> some View {
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

    private func numberField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            TextField(label, value: value, format: .number)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Config.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Config.Colors.borderColor, lineWidth: 1))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ActivityView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
}
