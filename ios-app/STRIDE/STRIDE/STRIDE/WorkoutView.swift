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

    @State private var workoutPlans: [[String: Any]] = []
    @State private var selectedCategory: String = "All"
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Int = 0
    @State private var workoutCalories: Double = 0
    @State private var selectedFeeling: WorkoutFeeling?
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            if isWorkoutActive {
                workoutActiveView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        quickStartCard()

                        categoryFilter()

                        workoutsList()
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            Task {
                await loadWorkoutPlans()
            }
        }
    }

    private func quickStartCard() -> some View {
        Button(action: { startWorkout() }) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Start")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Begin your workout in seconds")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FC4C02"),
                            Color(hex: "FF6B35")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }

    private func categoryFilter() -> some View {
        HStack(spacing: 12) {
            ForEach(["All", "Running", "Cycling", "Strength"], id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedCategory == category ? .white : .gray
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category ?
                            Color(hex: "FC4C02") :
                            Color(hex: "141414")
                        )
                        .cornerRadius(8)
                }
            }
            Spacer()
        }
    }

    private func workoutsList() -> some View {
        VStack(spacing: 12) {
            ForEach(Array(workoutPlans.enumerated()), id: \.offset) { _, plan in
                if let title = plan["title"] as? String,
                   let duration = plan["duration"] as? Int,
                   let category = plan["category"] as? String {

                    Button(action: { startWorkout() }) {
                        HStack(spacing: 16) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "FC4C02"))
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "141414"))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(category)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text("\(duration)m")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "FC4C02"))
                        }
                        .padding(12)
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
    }

    private func workoutActiveView() -> some View {
        VStack(spacing: 40) {
            HStack {
                Button(action: { finishWorkout() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(16)

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Workout Time")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)

                    Text(String(format: "%02d:%02d", workoutTimer / 60, workoutTimer % 60))
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(Color(hex: "FC4C02"))
                        .monospacedDigit()
                }

                HStack(spacing: 16) {
                    Button(action: { toggleWorkoutTimer() }) {
                        Image(systemName: timer == nil ? "play.fill" : "pause.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "FC4C02"))
                            .cornerRadius(30)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calories Burned")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)

                        Text(String(Int(workoutCalories)))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg HR")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)

                        Text("125")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
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

            Spacer()

            Button(action: { showFeelingPicker() }) {
                Text("Finish Workout")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(Color(hex: "FC4C02"))
                    .cornerRadius(8)
            }
            .padding(16)
        }
    }

    private func startWorkout() {
        withAnimation {
            isWorkoutActive = true
            workoutTimer = 0
            workoutCalories = 0
            toggleWorkoutTimer()
        }
    }

    private func finishWorkout() {
        timer?.invalidate()
        timer = nil
        withAnimation {
            isWorkoutActive = false
        }
    }

    private func toggleWorkoutTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                workoutTimer += 1
                workoutCalories += 0.15
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func showFeelingPicker() {
        selectedFeeling = .good
    }

    private func loadWorkoutPlans() async {
        guard let token = authManager.accessToken else { return }
        workoutPlans = await supabaseManager.query(
            table: "workouts",
            token: token
        )
    }
}

enum WorkoutFeeling: String {
    case amazing = "Amazing"
    case good = "Good"
    case okay = "Okay"
    case tough = "Tough"
    case exhausted = "Exhausted"

    var emoji: String {
        switch self {
        case .amazing: return "🤩"
        case .good: return "😊"
        case .okay: return "😐"
        case .tough: return "😤"
        case .exhausted: return "😫"
        }
    }
}

#Preview {
    WorkoutView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
}
