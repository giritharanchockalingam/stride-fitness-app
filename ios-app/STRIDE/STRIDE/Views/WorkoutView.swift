import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var selectedCategory = "All"
    @State private var isActiveWorkout = false
    @State private var workoutTimer: Int = 0
    @State private var timerActive = false
    @State private var selectedWorkout: [String: Any]?
    @State private var caloriesBurned = 0
    @State private var exercisesCompleted = 0

    let categories = ["All", "Strength", "Cardio", "HIIT", "Flexibility"]

    var body: some View {
        ZStack {
            Color.strideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if isActiveWorkout {
                    activeWorkoutView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            headerSection
                            quickStartBanner
                            categoryFilter
                            workoutPlansSection
                        }
                        .padding(16)
                    }
                }
            }
        }
        .onAppear {
            loadWorkouts()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workouts")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.strideText)

            Text("Push your limits")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.strideSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStartBanner: some View {
        Button(action: { isActiveWorkout = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Start"
                    )
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.strideText)

                    Text("Get moving in seconds")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.strideText)
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.stridePrimary.opacity(0.8), Color.stridePrimaryLight.opacity(0.6)]),
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
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedCategory == category ? .strideText : .strideSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.stridePrimary : Color.strideCard)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
        }
    }

    private var workoutPlansSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Workout Plans")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.strideText)

                Spacer()

                Button(action: {}) {
                    Text("All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.stridePrimary)
                }
            }

            if supabaseManager.workoutPlans.isEmpty {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        workoutPlanSkeletonCard
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(supabaseManager.workoutPlans, id: \.self) { workout in
                        workoutPlanCard(workout)
                    }
                }
            }
        }
    }

    private func workoutPlanCard(_ workout: [String: Any]) -> some View {
        Button(action: { isActiveWorkout = true; selectedWorkout = workout }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout["name"] as? String ?? "Untitled")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.strideText)

                        Text(workout["description"] as? String ?? "")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.strideSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.strideSecondary)

                            Text(workout["duration"] as? String ?? "30 min")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.stridePrimary)

                            Text(workout["intensity"] as? String ?? "Medium")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }
                    }
                }

                HStack(spacing: 8) {
                    ForEach(["Lower Body", "Strength", "30 min"] as [String], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.strideSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.strideBorder)
                            .cornerRadius(6)
                    }

                    Spacer()
                }
            }
            .padding(14)
            .background(Color.strideCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.strideBorder, lineWidth: 1)
            )
        }
    }

    private var workoutPlanSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 120, height: 12)
                        .foregroundColor(.strideBorder)

                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 180, height: 8)
                        .foregroundColor(.strideBorder)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .frame(height: 20)
                        .foregroundColor(.strideBorder)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color.strideCard)
        .cornerRadius(12)
    }

    private var activeWorkoutView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { isActiveWorkout = false }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Exit")
                    }
                    .foregroundColor(.strideText)
                }

                Spacer()

                Text("Active Workout")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.strideText)

                Spacer()

                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.stridePrimary)
            }
            .padding(16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    timerSection
                    caloriesSection
                    exercisesSection
                    feelingSection
                    finishButton
                }
                .padding(16)
            }
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Elapsed Time")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)

                HStack(alignment: .center, spacing: 0) {
                    let hours = workoutTimer / 3600
                    let minutes = (workoutTimer % 3600) / 60
                    let seconds = workoutTimer % 60

                    Text(String(format: "%02d", hours))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.strideText)

                    Text(":")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.strideSecondary)

                    Text(String(format: "%02d", minutes))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.strideText)

                    Text(":")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.strideSecondary)

                    Text(String(format: "%02d", seconds))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.strideText)
                }

                HStack(spacing: 12) {
                    Button(action: { timerActive.toggle() }) {
                        Image(systemName: timerActive ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.strideText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.strideCard)
                            .cornerRadius(10)
                    }

                    Button(action: { workoutTimer = 0 }) {
                        Text("Reset")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.strideSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.strideCard)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(16)
            .background(Color.strideCard)
            .cornerRadius(12)
        }
        .onReceive(Timer.publish(every: 1).autoconnect()) { _ in
            if timerActive {
                workoutTimer += 1
            }
        }
    }

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories Burned")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.strideText)

            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.stridePrimary)

                    Text(String(caloriesBurned))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.strideText)

                    Text("kcal")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    Spacer()
                }
                .padding(12)
                .background(Color.strideCard)
                .cornerRadius(10)

                VStack(spacing: 4) {
                    Button(action: { caloriesBurned += 10 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.strideAccent)
                    }

                    Button(action: { if caloriesBurned > 0 { caloriesBurned -= 10 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.strideAccent)
                    }
                }
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.strideText)

            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: exercisesCompleted > index ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(exercisesCompleted > index ? .strideAccent : .strideSecondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(["Push-ups", "Squats", "Lunges"][index])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.strideText)

                            Text("3 sets of 12 reps")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }

                        Spacer()

                        Button(action: { if exercisesCompleted == index { exercisesCompleted += 1 } }) {
                            Text("Done")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.strideText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.strideCard)
                                .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(exercisesCompleted > index ? Color.strideCard.opacity(0.5) : Color.strideCard)
                    .cornerRadius(10)
                }
            }
        }
    }

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.strideText)

            HStack(spacing: 12) {
                ForEach([(emoji: "🤩", label: "Amazing"), (emoji: "😊", label: "Good"), (emoji: "😐", label: "Okay"), (emoji: "😫", label: "Tough")], id: \.label) { feeling in
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Text(feeling.emoji)
                                .font(.system(size: 24))

                            Text(feeling.label)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.strideSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.strideCard)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var finishButton: some View {
        Button(action: saveWorkout) {
            Text("Finish Workout")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.strideText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.strideAccent, Color.strideAccent.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
        }
    }

    private func saveWorkout() {
        let workoutData: [String: Any] = [
            "title": selectedWorkout?["name"] as? String ?? "Quick Workout",
            "type": "strength",
            "duration": workoutTimer,
            "calories": caloriesBurned,
            "distance": 0,
            "exercises_completed": exercisesCompleted
        ]

        supabaseManager.saveWorkoutSession(userId: authManager.userId ?? "", workoutData: workoutData) { success in
            if success {
                isActiveWorkout = false
                workoutTimer = 0
                caloriesBurned = 0
                exercisesCompleted = 0
            }
        }
    }

    private func loadWorkouts() {
        supabaseManager.fetchWorkoutPlans {
            print("Workouts loaded")
        }
    }
}

#Preview {
    WorkoutView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
        .environmentObject(HealthKitManager())
        .preferredColorScheme(.dark)
}
