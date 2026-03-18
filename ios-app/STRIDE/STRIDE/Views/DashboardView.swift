import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var supabaseManager: SupabaseManager

    @State private var isRefreshing = false
    @State private var currentStreak = 0
    @State private var showRefreshIndicator = false

    var body: some View {
        ZStack {
            Color.strideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        streakBanner
                        activityRingsSection
                        quickStatsGrid
                        weeklyStepsChart
                        recentActivitiesSection
                        featuredWorkoutsSection
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshDashboard()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingMessage)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.strideText)

                    Text(authManager.userName ?? authManager.userEmail ?? "Athlete")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }

                Spacer()

                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.stridePrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.strideCard)
                    .cornerRadius(10)
            }
        }
    }

    private var streakBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 24))

                    Text("\(currentStreak) Day Streak")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.strideText)
                }

                Text("Keep it up!")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Personal Record")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.strideSecondary)

                Text("25 Days")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.stridePrimary)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.stridePrimary.opacity(0.2), Color.stridePrimaryLight.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.strideBorder, lineWidth: 1)
        )
    }

    private var activityRingsSection: some View {
        VStack(spacing: 16) {
            Text("Activity Rings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.strideText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.strideBorder, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: min(healthKitManager.todayCalories / 500, 1.0))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(min(healthKitManager.todayCalories / 5, 100)))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.strideText)
                        Text("Move")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.strideSecondary)
                    }
                }
                .frame(width: 100, height: 100)

                ZStack {
                    Circle()
                        .stroke(Color.strideBorder, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: min(healthKitManager.todayActiveMinutes / 30, 1.0))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.strideAccent, Color.strideAccent.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(min(healthKitManager.todayActiveMinutes / 0.3, 100)))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.strideText)
                        Text("Exercise")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.strideSecondary)
                    }
                }
                .frame(width: 100, height: 100)

                ZStack {
                    Circle()
                        .stroke(Color.strideBorder, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: min(healthKitManager.todaySteps / 10000, 1.0))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.strideBlue, Color.strideBlue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(min(healthKitManager.todaySteps / 100, 100)))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.strideText)
                        Text("Steps")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.strideSecondary)
                    }
                }
                .frame(width: 100, height: 100)

                Spacer()
            }
        }
    }

    private var quickStatsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCardView(
                    icon: "figure.walk",
                    label: "Steps",
                    value: String(format: "%.0f", healthKitManager.todaySteps),
                    unit: "steps",
                    color: .strideBlue,
                    trend: "+340 from yesterday"
                )

                StatCardView(
                    icon: "flame.fill",
                    label: "Calories",
                    value: String(format: "%.0f", healthKitManager.todayCalories),
                    unit: "kcal",
                    color: .stridePrimary
                )
            }

            HStack(spacing: 12) {
                StatCardView(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: String(format: "%.0f", healthKitManager.todayHeartRate),
                    unit: "bpm",
                    color: .red
                )

                StatCardView(
                    icon: "location.fill",
                    label: "Distance",
                    value: String(format: "%.1f", healthKitManager.todayDistance),
                    unit: "km",
                    color: .strideAccent
                )
            }
        }
    }

    private var weeklyStepsChart: some View {
        VStack(spacing: 12) {
            Text("Weekly Steps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.strideText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Chart {
                ForEach(Array(healthKitManager.weeklySteps.enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Day", dayLabel(index)),
                        y: .value("Steps", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8, style: .continuous)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxisLabel(position: .bottom, alignment: .center)
            .frame(height: 200)
            .padding(.horizontal, -12)
        }
    }

    private var recentActivitiesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Activities")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.strideText)

                Spacer()

                Button(action: {}) {
                    Text("See All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.stridePrimary)
                }
            }

            if supabaseManager.activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.strideSecondary)

                    Text("No activities yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.strideSecondary)

                    Text("Start moving to see your activities here")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideTertiary)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(supabaseManager.activities.prefix(3), id: \.self) { activity in
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

    private var featuredWorkoutsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Featured Workouts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.strideText)

                Spacer()

                Button(action: {}) {
                    Text("Browse")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.stridePrimary)
                }
            }

            VStack(spacing: 12) {
                ForEach(supabaseManager.workoutPlans.prefix(2), id: \.self) { workout in
                    if let name = workout["name"] as? String,
                       let description = workout["description"] as? String {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.strideText)

                                Text(description)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.strideSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.strideSecondary)
                        }
                        .padding(12)
                        .background(Color.strideCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.strideBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    private func dayLabel(_ index: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let dayIndex = calendar.component(.weekday, from: date) - 1
        return days[dayIndex]
    }

    private func refreshDashboard() {
        isRefreshing = true
        healthKitManager.fetchTodayStats {
            healthKitManager.fetchWeeklyStats {
                supabaseManager.fetchActivities(userId: authManager.userId ?? "") {
                    supabaseManager.fetchWorkoutPlans {
                        isRefreshing = false
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(HealthKitManager())
        .environmentObject(SupabaseManager())
        .preferredColorScheme(.dark)
}
