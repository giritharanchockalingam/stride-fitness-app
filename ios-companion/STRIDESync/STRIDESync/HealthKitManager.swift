import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncResult: String?
    @Published var todaySteps: Int = 0
    @Published var todayCalories: Int = 0
    @Published var todayDistance: Double = 0
    @Published var currentHeartRate: Int = 0

    private let lastSyncKey = "stride_last_sync"

    init() {
        if let date = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = date
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { isAuthorized = true }
            await fetchTodayStats()
        } catch {
            print("HealthKit auth error: \(error)")
        }
    }

    // MARK: - Fetch Today's Stats (for display in app)

    func fetchTodayStats() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        async let steps = fetchSum(type: .stepCount, unit: .count(), start: startOfDay)
        async let cals = fetchSum(type: .activeEnergyBurned, unit: .kilocalorie(), start: startOfDay)
        async let dist = fetchSum(type: .distanceWalkingRunning, unit: .meter(), start: startOfDay)
        async let hr = fetchLatest(type: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()))

        let (s, c, d, h) = await (steps, cals, dist, hr)
        await MainActor.run {
            todaySteps = Int(s)
            todayCalories = Int(c)
            todayDistance = d
            currentHeartRate = Int(h)
        }
    }

    // MARK: - Full Sync to Supabase

    func syncToSupabase(token: String, userId: String? = nil) async {
        await MainActor.run { isSyncing = true; syncResult = nil }

        do {
            let calendar = Calendar.current
            let now = Date()
            var dailyStats: [[String: Any]] = []
            var activities: [[String: Any]] = []
            var heartRates: [[String: Any]] = []

            // Sync last 14 days of daily stats
            for dayOffset in 0..<14 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                let dateStr = ISO8601DateFormatter().string(from: startOfDay).prefix(10)

                let steps = await fetchSum(type: .stepCount, unit: .count(), start: startOfDay, end: endOfDay)
                let cals = await fetchSum(type: .activeEnergyBurned, unit: .kilocalorie(), start: startOfDay, end: endOfDay)
                let dist = await fetchSum(type: .distanceWalkingRunning, unit: .meter(), start: startOfDay, end: endOfDay)
                let exercise = await fetchSum(type: .appleExerciseTime, unit: .minute(), start: startOfDay, end: endOfDay)
                let avgHR = await fetchAvg(type: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: startOfDay, end: endOfDay)
                let restHR = await fetchAvg(type: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: startOfDay, end: endOfDay)

                if steps > 0 || cals > 0 {
                    var stat: [String: Any] = [
                        "date": String(dateStr),
                        "total_steps": Int(steps),
                        "total_calories": Int(cals),
                        "total_distance_meters": Int(dist),
                        "active_minutes": Int(exercise),
                        "move_ring_progress": min(cals / 500.0, 1.0),
                        "exercise_ring_progress": min(exercise / 30.0, 1.0),
                        "stand_ring_progress": min(steps / 10000.0, 1.0)
                    ]
                    if avgHR > 0 { stat["avg_heart_rate"] = Int(avgHR) }
                    if restHR > 0 { stat["resting_heart_rate"] = Int(restHR) }
                    dailyStats.append(stat)
                }
            }

            // Sync workouts from last 14 days
            let workoutType = HKObjectType.workoutType()
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!
            let predicate = HKQuery.predicateForSamples(withStart: twoWeeksAgo, end: now, options: .strictStartDate)

            let workouts = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKWorkout], Error>) in
                let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                    if let error = error { cont.resume(throwing: error); return }
                    cont.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
                healthStore.execute(query)
            }

            for workout in workouts {
                let typeMap: [HKWorkoutActivityType: String] = [
                    .running: "run", .walking: "walk", .cycling: "cycle",
                    .swimming: "swim", .hiking: "hike", .yoga: "yoga"
                ]
                let actType = typeMap[workout.workoutActivityType] ?? "other"
                let duration = Int(workout.duration)
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0

                activities.append([
                    "provider_activity_id": "apple_\(Int(workout.startDate.timeIntervalSince1970 * 1000))",
                    "activity_type": actType,
                    "title": workout.workoutActivityType.name,
                    "started_at": ISO8601DateFormatter().string(from: workout.startDate),
                    "ended_at": ISO8601DateFormatter().string(from: workout.endDate),
                    "duration_seconds": duration,
                    "distance_meters": Int(distance),
                    "calories_burned": Int(calories),
                    "is_public": true
                ])
            }

            // Sync today's heart rate readings
            let startOfToday = calendar.startOfDay(for: now)
            let hrSamples = try await fetchSamples(type: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: startOfToday, end: now, limit: 100)
            for (value, date) in hrSamples {
                heartRates.append([
                    "bpm": Int(value),
                    "recorded_at": ISO8601DateFormatter().string(from: date)
                ])
            }

            // Send to Supabase Edge Function
            var payload: [String: Any] = [
                "type": "full_sync",
                "device_info": UIDevice.current.model,
                "data": [
                    "daily_stats": dailyStats,
                    "activities": activities,
                    "heart_rate": heartRates
                ]
            ]

            if let uid = userId { payload["user_id"] = uid }

            var request = URLRequest(url: URL(string: Config.healthKitSyncEndpoint)!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            if httpResponse?.statusCode == 200 {
                let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let synced = result?["synced"] as? [String: Any] ?? [:]

                await MainActor.run {
                    lastSyncDate = Date()
                    UserDefaults.standard.set(Date(), forKey: lastSyncKey)
                    syncResult = "Synced \(dailyStats.count) days, \(activities.count) workouts, \(heartRates.count) HR readings"
                }
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "", code: httpResponse?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorBody])
            }
        } catch {
            await MainActor.run { syncResult = "Error: \(error.localizedDescription)" }
        }

        await MainActor.run { isSyncing = false }
        await fetchTodayStats()
    }

    // MARK: - HealthKit Query Helpers

    private func fetchSum(type: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date? = nil) async -> Double {
        let end = end ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let quantityType = HKQuantityType(type)

        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                cont.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }

    private func fetchAvg(type: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date? = nil) async -> Double {
        let end = end ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let quantityType = HKQuantityType(type)

        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                cont.resume(returning: result?.averageQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatest(type: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let quantityType = HKQuantityType(type)

        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                cont.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchSamples(type: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date, limit: Int) async throws -> [(Double, Date)] {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: limit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let results = (samples as? [HKQuantitySample])?.map { ($0.quantity.doubleValue(for: unit), $0.startDate) } ?? []
                cont.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Workout Activity Type Name Extension
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .dance: return "Dance"
        case .cooldown: return "Cooldown"
        default: return "Workout"
        }
    }
}
