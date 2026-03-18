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
    @State private var activities: [[String: Any]] = []

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    ringAndMetricSection
                    metricButtonsSection
                    chartSection
                    activitiesSection
                }
                .padding(16)
            }
        }
        .onAppear {
            Task {
                await loadActivities()
            }
        }
    }

    private var ringAndMetricSection: some View {
        VStack(spacing: 24) {
            ActivityRingView(
                moveProgress: min(Double(healthKitManager.todayCalories) / 600.0, 1.0),
                exerciseProgress: 0.75,
                stepsProgress: min(Double(healthKitManager.todaySteps) / 10000.0, 1.0),
                size: 160
            )
            .frame(maxWidth: .infinity)
            .frame(height: 200)

            VStack(spacing: 4) {
                Text(String(Int(getMetricValue())))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(hex: "FC4C02"))

                Text(selectedMetric.label)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
    }

    private var metricButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(ActivityMetric.allCases, id: \.self) { metric in
                    Button(action: { selectedMetric = metric }) {
                        Text(metric.shortLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(
                                selectedMetric == metric ? .white : .gray
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedMetric == metric ?
                                Color(hex: "FC4C02") :
                                Color(hex: "141414")
                            )
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trend")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            chartContent
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

    @ViewBuilder
    private var chartContent: some View {
        switch selectedMetric {
        case .steps:
            Chart {
                ForEach(Array(healthKitManager.weeklySteps.enumerated()), id: \.offset) { index, value in
                    BarMark(x: .value("Day", getDayLabel(index)), y: .value("Steps", value))
                        .foregroundStyle(Color(hex: "007AFF"))
                }
            }
        case .calories:
            Chart {
                ForEach(Array(healthKitManager.weeklyCalories.enumerated()), id: \.offset) { index, value in
                    BarMark(x: .value("Day", getDayLabel(index)), y: .value("Calories", value))
                        .foregroundStyle(Color(hex: "FF6B35"))
                }
            }
        case .heartRate:
            Chart {
                ForEach([70.0, 75.0, 73.0, 76.0, 72.0, 74.0, 71.0].indices, id: \.self) { index in
                    LineMark(x: .value("Day", getDayLabel(index)), y: .value("HR", [70.0, 75.0, 73.0, 76.0, 72.0, 74.0, 71.0][index]))
                        .foregroundStyle(Color(hex: "FF3B30"))
                }
            }
        case .distance:
            Chart {
                ForEach([5.2, 6.1, 4.8, 7.2, 5.9, 6.5, 5.3].indices, id: \.self) { index in
                    LineMark(x: .value("Day", getDayLabel(index)), y: .value("Distance", [5.2, 6.1, 4.8, 7.2, 5.9, 6.5, 5.3][index]))
                        .foregroundStyle(Color(hex: "34C759"))
                }
            }
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity List")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if activities.isEmpty {
                Text("No activities recorded")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(32)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(activities.enumerated()), id: \.offset) { _, activity in
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

    private func getMetricValue() -> Double {
        switch selectedMetric {
        case .steps:
            return Double(healthKitManager.todaySteps)
        case .calories:
            return healthKitManager.todayCalories
        case .heartRate:
            return healthKitManager.todayHeartRate
        case .distance:
            return healthKitManager.todayDistance / 1000
        }
    }

    private func getDayLabel(_ index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let dayIndex = calendar.component(.weekday, from: date) - 1
        return days[dayIndex]
    }

    private func loadActivities() async {
        guard let token = authManager.accessToken else { return }
        activities = await supabaseManager.query(
            table: "activities",
            token: token,
            order: "created_at.desc"
        )
    }
}

enum ActivityMetric: CaseIterable {
    case steps
    case calories
    case heartRate
    case distance

    var label: String {
        switch self {
        case .steps:
            return "Steps"
        case .calories:
            return "Calories"
        case .heartRate:
            return "Heart Rate"
        case .distance:
            return "Distance"
        }
    }

    var shortLabel: String {
        switch self {
        case .steps:
            return "Steps"
        case .calories:
            return "Calories"
        case .heartRate:
            return "HR"
        case .distance:
            return "Distance"
        }
    }
}

#Preview {
    ActivityView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
}
