//
//  HealthKitManager.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import HealthKit
import Foundation
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    @Published var todaySteps: Int = 0
    @Published var todayCalories: Double = 0.0
    @Published var todayHeartRate: Double = 0.0
    @Published var todayDistance: Double = 0.0
    @Published var todayActiveMinutes: Int = 0
    @Published var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    @Published var weeklyCalories: [Double] = Array(repeating: 0.0, count: 7)
    @Published var weeklyDistance: [Double] = Array(repeating: 0.0, count: 7)
    @Published var weeklyHeartRate: [Double] = Array(repeating: 0.0, count: 7)
    @Published var isAuthorized = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let healthStore = HKHealthStore()

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.workoutType()
    ]

    // MARK: - Authorization

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            Task { @MainActor in
                self.isAuthorized = success
                if success {
                    await self.fetchAllData()
                }
            }
        }
    }

    func fetchAllData() async {
        async let steps: () = fetchTodaySteps()
        async let calories: () = fetchTodayCalories()
        async let hr: () = fetchTodayHeartRate()
        async let dist: () = fetchTodayDistance()
        async let activeMin: () = fetchTodayActiveMinutes()
        async let weekly: () = fetchWeeklyData()
        _ = await (steps, calories, hr, dist, activeMin, weekly)
    }

    // MARK: - Today Stats

    private func fetchTodaySteps() async {
        let value = await fetchSum(identifier: .stepCount, unit: .count())
        todaySteps = Int(value)
    }

    private func fetchTodayCalories() async {
        todayCalories = await fetchSum(identifier: .activeEnergyBurned, unit: .kilocalorie())
    }

    private func fetchTodayHeartRate() async {
        todayHeartRate = await fetchAverage(identifier: .heartRate, unit: HKUnit(from: "count/min"))
    }

    private func fetchTodayDistance() async {
        todayDistance = await fetchSum(identifier: .distanceWalkingRunning, unit: .meter())
    }

    private func fetchTodayActiveMinutes() async {
        let value = await fetchSum(identifier: .appleExerciseTime, unit: .minute())
        todayActiveMinutes = Int(value)
    }

    // MARK: - Weekly Data

    private func fetchWeeklyData() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var steps: [Int] = []
        var calories: [Double] = []
        var distance: [Double] = []
        var heartRate: [Double] = []

        for i in (0..<7).reversed() {
            guard let start = calendar.date(byAdding: .day, value: -i, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                steps.append(0)
                calories.append(0)
                distance.append(0)
                heartRate.append(0)
                continue
            }

            async let s = fetchSumInRange(identifier: .stepCount, unit: .count(), start: start, end: end)
            async let c = fetchSumInRange(identifier: .activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
            async let d = fetchSumInRange(identifier: .distanceWalkingRunning, unit: .meter(), start: start, end: end)
            async let h = fetchAverageInRange(identifier: .heartRate, unit: HKUnit(from: "count/min"), start: start, end: end)

            let (sv, cv, dv, hv) = await (s, c, d, h)
            steps.append(Int(sv))
            calories.append(cv)
            distance.append(dv / 1000.0)
            heartRate.append(hv)
        }

        weeklySteps = steps
        weeklyCalories = calories
        weeklyDistance = distance
        weeklyHeartRate = heartRate
    }

    // MARK: - HealthKit Query Helpers

    private func fetchSum(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return await fetchSumInRange(identifier: identifier, unit: unit, start: start, end: end)
    }

    private func fetchSumInRange(identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchAverage(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return await fetchAverageInRange(identifier: identifier, unit: unit, start: start, end: end)
    }

    private func fetchAverageInRange(identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, _ in
                let value = result?.averageQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sync to Supabase

    func syncToSupabase(token: String, userId: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Build 14 days of daily stats
        var dailyStats: [[String: Any]] = []
        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today),
                  let endDate = calendar.date(byAdding: .day, value: 1, to: date) else { continue }

            async let steps = fetchSumInRange(identifier: .stepCount, unit: .count(), start: date, end: endDate)
            async let cals = fetchSumInRange(identifier: .activeEnergyBurned, unit: .kilocalorie(), start: date, end: endDate)
            async let dist = fetchSumInRange(identifier: .distanceWalkingRunning, unit: .meter(), start: date, end: endDate)
            async let exerciseMin = fetchSumInRange(identifier: .appleExerciseTime, unit: .minute(), start: date, end: endDate)
            async let avgHR = fetchAverageInRange(identifier: .heartRate, unit: HKUnit(from: "count/min"), start: date, end: endDate)

            let (s, c, d, e, h) = await (steps, cals, dist, exerciseMin, avgHR)

            dailyStats.append([
                "date": dateFormatter.string(from: date),
                "steps": Int(s),
                "calories": c,
                "distance_meters": d,
                "active_minutes": Int(e),
                "avg_heart_rate": Int(h)
            ])
        }

        // Fetch recent workouts from HealthKit
        let activities = await fetchRecentWorkouts(days: 14)

        // Fetch today's heart rate samples
        let hrSamples = await fetchHeartRateSamples(limit: 100)

        let syncPayload: [String: Any] = [
            "user_id": userId,
            "type": "healthkit_sync",
            "device_info": [
                "platform": "ios",
                "model": "iPhone",
                "os_version": ProcessInfo.processInfo.operatingSystemVersionString
            ],
            "data": [
                "daily_stats": dailyStats,
                "activities": activities,
                "heart_rate": hrSamples
            ]
        ]

        guard let url = URL(string: Config.healthKitSyncEndpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: syncPayload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                lastSyncDate = Date()
            }
        } catch {
            print("HealthKit sync error: \(error)")
        }
    }

    private func fetchRecentWorkouts(days: Int) async -> [[String: Any]] {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let start = calendar.date(byAdding: .day, value: -days, to: Date())!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                let activities = workouts.map { workout -> [String: Any] in
                    let type = Self.workoutTypeName(workout.workoutActivityType)
                    return [
                        "activity_type": type,
                        "title": "\(type.capitalized) Workout",
                        "started_at": ISO8601DateFormatter().string(from: workout.startDate),
                        "ended_at": ISO8601DateFormatter().string(from: workout.endDate),
                        "duration_seconds": Int(workout.duration),
                        "distance_meters": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                        "calories_burned": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        "is_public": true,
                        "provider": "healthkit"
                    ]
                }
                continuation.resume(returning: activities)
            }
            healthStore.execute(query)
        }
    }

    private func fetchHeartRateSamples(limit: Int) async -> [[String: Any]] {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }

        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let readings = samples.map { sample -> [String: Any] in
                    [
                        "bpm": Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min"))),
                        "recorded_at": ISO8601DateFormatter().string(from: sample.startDate)
                    ]
                }
                continuation.resume(returning: readings)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Progress Calculations

    var moveProgress: Double {
        min(todayCalories / 500.0, 1.0)
    }

    var exerciseProgress: Double {
        min(Double(todayActiveMinutes) / 30.0, 1.0)
    }

    var stepsProgress: Double {
        min(Double(todaySteps) / 10000.0, 1.0)
    }

    var overallProgress: Double {
        (moveProgress + exerciseProgress + stepsProgress) / 3.0
    }

    // MARK: - Workout Type Mapping

    static func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .hiking: return "hiking"
        case .yoga: return "yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "strength"
        case .highIntensityIntervalTraining: return "hiit"
        case .dance: return "dance"
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        default: return "workout"
        }
    }
}
