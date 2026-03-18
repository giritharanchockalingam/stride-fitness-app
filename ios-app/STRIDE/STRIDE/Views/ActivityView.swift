import SwiftUI
import Charts

struct ActivityView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    @State private var timeRange = 0
    @State private var selectedMetric = 0
    @State private var isLoading = false

    let timeRanges = ["Day", "Week", "Month"]
    let metrics = ["Steps", "Calories", "Heart Rate", "Distance"]

    var body: some View {
        ZStack {
            Color.strideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        timeRangeSelector
                        activityRingLarge
                        metricTabs
                        chartSection
                        activitiesListSection
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.strideText)

            Text("Track your progress")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.strideSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(Array(timeRanges.enumerated()), id: \.offset) { index, range in
                Button(action: {
                    timeRange = index
                    loadData()
                }) {
                    Text(range)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(timeRange == index ? .strideText : .strideSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(timeRange == index ? Color.strideCard : Color.clear)
                        .cornerRadius(10)
                        .overlay(
                            timeRange == index ?
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.stridePrimary, lineWidth: 2) : nil
                        )
                }
            }

            Spacer()
        }
    }

    private var activityRingLarge: some View {
        VStack(spacing: 24) {
            Text("Today's Progress")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.strideText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.strideBorder, lineWidth: 12)

                        Circle()
                            .trim(from: 0, to: min(healthKitManager.todayCalories / 500, 1.0))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Color.stridePrimary.opacity(0.5), radius: 10)

                        VStack(spacing: 4) {
                            Text("\(Int(min(healthKitManager.todayCalories / 5, 100)))%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.strideText)
                            Text("Move")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", healthKitManager.todayCalories))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.strideText)
                        Text("kcal")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.strideSecondary)
                    }
                }

                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.strideBlue)
                                Text("Steps")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.strideSecondary)
                            }

                            Text(String(format: "%.0f", healthKitManager.todaySteps))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.strideText)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(Color.strideBorder, lineWidth: 6)

                            Circle()
                                .trim(from: 0, to: min(healthKitManager.todaySteps / 10000, 1.0))
                                .stroke(Color.strideBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 50, height: 50)
                    }
                    .padding(12)
                    .background(Color.strideCard)
                    .cornerRadius(12)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.red)
                                Text("Heart Rate")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.strideSecondary)
                            }

                            Text(String(format: "%.0f", healthKitManager.todayHeartRate))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.strideText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("bpm")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }
                    }
                    .padding(12)
                    .background(Color.strideCard)
                    .cornerRadius(12)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.strideAccent)
                                Text("Distance")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.strideSecondary)
                            }

                            Text(String(format: "%.1f", healthKitManager.todayDistance))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.strideText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("km")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }
                    }
                    .padding(12)
                    .background(Color.strideCard)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var metricTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    Button(action: { selectedMetric = index }) {
                        Text(metric)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedMetric == index ? .strideText : .strideSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedMetric == index ? Color.stridePrimary : Color.strideCard)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
        }
    }

    private var chartSection: some View {
        VStack(spacing: 12) {
            Chart {
                ForEach(Array(healthKitManager.weeklySteps.enumerated()), id: \.offset) { index, value in
                    switch selectedMetric {
                    case 0:
                        BarMark(
                            x: .value("Day", dayLabel(index)),
                            y: .value("Steps", value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.strideBlue, Color.strideBlue.opacity(0.6)]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6, style: .continuous)

                    default:
                        BarMark(
                            x: .value("Day", dayLabel(index)),
                            y: .value("Value", value / 1000)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6, style: .continuous)
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 240)
            .padding(.horizontal, -12)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    Text(String(format: "%.0f", healthKitManager.weeklySteps.reduce(0, +) / Double(healthKitManager.weeklySteps.count)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.strideText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    Text(String(format: "%.0f", healthKitManager.weeklySteps.reduce(0, +)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.stridePrimary)
                }
            }
            .padding(12)
            .background(Color.strideCard)
            .cornerRadius(12)
        }
    }

    private var activitiesListSection: some View {
        VStack(spacing: 12) {
            Text("All Activities")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.strideText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if supabaseManager.activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.strideSecondary)

                    Text("No activities yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.strideSecondary)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(supabaseManager.activities, id: \.self) { activity in
                        if let type = activity["type"] as? String,
                           let title = activity["title"] as? String,
                           let duration = activity["duration"] as? Int {
                            ActivityRowView(
                                type: type,
                                title: title,
                                timeAgo: "2 hours ago",
                                distance: activity["distance"] as? Double,
                                duration: duration,
                                calories: activity["calories"] as? Int
                            )
                        }
                    }
                }
            }
        }
    }

    private func dayLabel(_ index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let dayIndex = calendar.component(.weekday, from: date) - 1
        return days[dayIndex]
    }

    private func loadData() {
        isLoading = true
        healthKitManager.fetchTodayStats {
            healthKitManager.fetchWeeklyStats {
                supabaseManager.fetchActivities(userId: authManager.userId ?? "") {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ActivityView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
        .preferredColorScheme(.dark)
}
