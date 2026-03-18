//
//  WorkoutView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var workoutPlans: [WorkoutPlan] = []
    @State private var selectedCategory: String = "All"
    @State private var isWorkoutActive = false
    @State private var activeSession: ActiveWorkoutState?
    @State private var showPlanDetail = false
    @State private var selectedPlan: WorkoutPlan?
    @State private var exercises: [WorkoutExercise] = []

    private let categories = ["All", "Strength", "Cardio", "HIIT", "Flexibility"]

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            if let session = activeSession, isWorkoutActive {
                ActiveWorkoutView(session: session) { feeling in
                    Task { await finishWorkout(feeling: feeling) }
                } onCancel: {
                    withAnimation { isWorkoutActive = false; activeSession = nil }
                }
            } else {
                workoutBrowser
            }
        }
        .task { await loadWorkoutPlans() }
    }

    // MARK: - Workout Browser

    private var workoutBrowser: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                quickStartCard
                categoryFilter
                plansList
            }
            .padding(16)
            .padding(.bottom, 20)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workouts")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("Plans, sessions & exercises")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStartCard: some View {
        Button(action: { startQuickWorkout() }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Start")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Start a workout & track as you go")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Config.Colors.primaryOrange, Config.Colors.orangeGradient],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Config.Colors.primaryOrange.opacity(0.3), radius: 16, y: 8)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(action: { withAnimation { selectedCategory = category } }) {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedCategory == category ? .white : .gray)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? Config.Colors.primaryOrange : Config.Colors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCategory == category ? Color.clear : Config.Colors.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var plansList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured Plans (\(filteredPlans.count))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if filteredPlans.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No workout plans found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredPlans) { plan in
                        WorkoutPlanRow(plan: plan) {
                            startPlanWorkout(plan)
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

    private var filteredPlans: [WorkoutPlan] {
        if selectedCategory == "All" { return workoutPlans }
        return workoutPlans.filter { ($0.category ?? "").lowercased() == selectedCategory.lowercased() }
    }

    // MARK: - Workout Actions

    private func startQuickWorkout() {
        activeSession = ActiveWorkoutState(title: "Quick Workout", exercises: [])
        withAnimation { isWorkoutActive = true }
    }

    private func startPlanWorkout(_ plan: WorkoutPlan) {
        activeSession = ActiveWorkoutState(
            title: plan.title,
            planId: plan.id,
            exercises: plan.exercises ?? []
        )
        withAnimation { isWorkoutActive = true }
    }

    private func finishWorkout(feeling: String) async {
        guard let session = activeSession,
              let token = authManager.accessToken,
              let userId = authManager.userId else { return }

        let workoutSession = InsertWorkoutSession(
            userId: userId,
            planId: session.planId,
            title: session.title,
            startedAt: ISO8601DateFormatter().string(from: session.startTime),
            endedAt: ISO8601DateFormatter().string(from: Date()),
            durationSeconds: Int(Date().timeIntervalSince(session.startTime)),
            caloriesBurned: session.caloriesBurned,
            feeling: feeling
        )

        try? await supabaseManager.insert(table: "workout_sessions", data: workoutSession, token: token)

        withAnimation {
            isWorkoutActive = false
            activeSession = nil
        }
    }

    private func loadWorkoutPlans() async {
        guard let token = authManager.accessToken else { return }
        workoutPlans = await supabaseManager.fetchWorkoutPlans(token: token)
    }
}

// MARK: - Active Workout State

class ActiveWorkoutState: ObservableObject {
    let title: String
    let planId: String?
    let exercises: [WorkoutExercise]
    let startTime = Date()
    @Published var caloriesBurned: Double = 0
    @Published var completedExercises: Set<String> = []

    init(title: String, planId: String? = nil, exercises: [WorkoutExercise]) {
        self.title = title
        self.planId = planId
        self.exercises = exercises
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @ObservedObject var session: ActiveWorkoutState
    var onFinish: (String) -> Void
    var onCancel: () -> Void

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var isPaused = false
    @State private var showFeelingPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 36, height: 36)
                        .background(Config.Colors.cardBackground)
                        .cornerRadius(8)
                }
                Spacer()
                Text(session.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(16)

            Spacer()

            // Timer
            VStack(spacing: 12) {
                Text("Workout Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text(timerString)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(Config.Colors.primaryOrange)
                    .monospacedDigit()

                // Play/Pause
                HStack(spacing: 24) {
                    Button(action: { toggleTimer() }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Config.Colors.primaryOrange)
                            .cornerRadius(32)
                    }
                }
            }

            Spacer()

            // Stats Row
            HStack(spacing: 16) {
                workoutStat(label: "Calories", value: String(Int(session.caloriesBurned)), unit: "kcal")
                workoutStat(label: "Avg HR", value: "--", unit: "bpm")
            }
            .padding(16)

            // Exercises (if from a plan)
            if !session.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(session.exercises) { exercise in
                        HStack(spacing: 12) {
                            Button(action: {
                                if session.completedExercises.contains(exercise.id) {
                                    session.completedExercises.remove(exercise.id)
                                } else {
                                    session.completedExercises.insert(exercise.id)
                                }
                            }) {
                                Image(systemName: session.completedExercises.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(session.completedExercises.contains(exercise.id) ? Config.Colors.distanceGreen : .gray)
                                    .font(.system(size: 20))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.exerciseName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(session.completedExercises.contains(exercise.id) ? .gray : .white)
                                    .strikethrough(session.completedExercises.contains(exercise.id))

                                HStack(spacing: 8) {
                                    if let sets = exercise.sets, let reps = exercise.reps {
                                        Text("\(sets) x \(reps)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    if let weight = exercise.weightKg, weight > 0 {
                                        Text("\(Int(weight))kg")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(Config.Colors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            // Finish button
            Button(action: { showFeelingPicker = true }) {
                Text("Finish Workout")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Config.Colors.primaryOrange)
                    .cornerRadius(14)
            }
            .padding(16)
        }
        .background(Config.Colors.darkBackground.ignoresSafeArea())
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showFeelingPicker) {
            FeelingPickerSheet { feeling in
                timer?.invalidate()
                onFinish(feeling)
            }
            .presentationDetents([.medium])
        }
    }

    private var timerString: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                elapsedSeconds += 1
                session.caloriesBurned += 0.15
            }
        }
    }

    private func toggleTimer() {
        isPaused.toggle()
    }

    private func workoutStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Config.Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Feeling Picker

struct FeelingPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (String) -> Void

    private let feelings = [
        ("Amazing", "\u{1F929}"),
        ("Good", "\u{1F60A}"),
        ("Okay", "\u{1F610}"),
        ("Tough", "\u{1F624}"),
        ("Exhausted", "\u{1F62B}")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("How was your workout?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(feelings, id: \.0) { name, emoji in
                    Button(action: {
                        onSelect(name.lowercased())
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Text(emoji)
                                .font(.system(size: 36))
                            Text(name)
                                .font(.system(size: 11, weight: .semibold))
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
                }
            }
        }
        .padding(24)
        .background(Config.Colors.darkBackground.ignoresSafeArea())
    }
}

// MARK: - Workout Plan Row

struct WorkoutPlanRow: View {
    let plan: WorkoutPlan
    var onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 14) {
                Image(systemName: plan.categoryIcon)
                    .font(.system(size: 20))
                    .foregroundColor(Config.Colors.primaryOrange)
                    .frame(width: 44, height: 44)
                    .background(Config.Colors.primaryOrange.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        if let category = plan.category {
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        if let difficulty = plan.difficulty {
                            Text(difficulty)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: plan.difficultyColor))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: plan.difficultyColor).opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                if let duration = plan.estimatedDurationMinutes {
                    Text("\(duration)m")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Config.Colors.primaryOrange)
                }
            }
            .padding(14)
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Config.Colors.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Insert Model

struct InsertWorkoutSession: Codable {
    let userId: String
    let planId: String?
    let title: String
    let startedAt: String
    let endedAt: String
    let durationSeconds: Int
    let caloriesBurned: Double
    let feeling: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case planId = "plan_id"
        case title
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case caloriesBurned = "calories_burned"
        case feeling
    }
}

#Preview {
    WorkoutView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
}
