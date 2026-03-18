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
    @Published var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    @Published var weeklyCalories: [Double] = Array(repeating: 0.0, count: 7)
    @Published var activities: [Activity] = []
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined

    private let healthStore = HKHealthStore()

    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.fetchTodayStats()
                    self.fetchWeeklyStats()
                }
            }
        }
    }

    func fetchTodayStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        fetchStepCount(startDate: startOfDay, endDate: endOfDay) { steps in
            self.todaySteps = steps
        }

        fetchActiveEnergyBurned(startDate: startOfDay, endDate: endOfDay) { calories in
            self.todayCalories = calories
        }

        fetchHeartRate(startDate: startOfDay, endDate: endOfDay) { hr in
            self.todayHeartRate = hr
        }

        fetchDistance(startDate: startOfDay, endDate: endOfDay) { distance in
            self.todayDistance = distance
        }
    }

    func fetchWeeklyStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var stepsArray: [Int] = []
        var caloriesArray: [Double] = []

        for i in (0..<7).reversed() {
            if let startDate = calendar.date(byAdding: .day, value: -i, to: today),
               let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) {

                let semaphore = DispatchSemaphore(value: 0)
                var steps = 0

                fetchStepCount(startDate: startDate, endDate: endDate) { s in
                    steps = s
                    semaphore.signal()
                }

                semaphore.wait()
                stepsArray.append(steps)
            }
        }

        for i in (0..<7).reversed() {
            if let startDate = calendar.date(byAdding: .day, value: -i, to: today),
               let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) {

                let semaphore = DispatchSemaphore(value: 0)
                var calories = 0.0

                fetchActiveEnergyBurned(startDate: startDate, endDate: endDate) { c in
                    calories = c
                    semaphore.signal()
                }

                semaphore.wait()
                caloriesArray.append(calories)
            }
        }

        self.weeklySteps = stepsArray
        self.weeklyCalories = caloriesArray
    }

    private func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(steps)
        }

        healthStore.execute(query)
    }

    private func fetchActiveEnergyBurned(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(calories)
        }

        healthStore.execute(query)
    }

    private func fetchHeartRate(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            guard let result = result, let average = result.averageQuantity() else {
                completion(0)
                return
            }
            let hr = average.doubleValue(for: HKUnit(from: "count/min"))
            completion(hr)
        }

        healthStore.execute(query)
    }

    private func fetchDistance(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            let distance = sum.doubleValue(for: HKUnit.meter())
            completion(distance)
        }

        healthStore.execute(query)
    }

    func syncToSupabase(token: String, userId: String) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var dailyStats: [[String: Any]] = []
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startDate = date
                let endDate = calendar.date(byAdding: .day, value: 1, to: date)!

                let semaphore = DispatchSemaphore(value: 0)
                var steps = 0
                var calories = 0.0

                fetchStepCount(startDate: startDate, endDate: endDate) { s in
                    steps = s
                    semaphore.signal()
                }
                semaphore.wait()

                fetchActiveEnergyBurned(startDate: startDate, endDate: endDate) { c in
                    calories = c
                }

                dailyStats.append([
                    "date": ISO8601DateFormatter().string(from: date),
                    "steps": steps,
                    "calories": calories
                ])
            }
        }

        let syncPayload: [String: Any] = [
            "user_id": userId,
            "daily_stats": dailyStats,
            "activities": activities.map { $0.toDictionary() },
            "heart_rate": todayHeartRate
        ]

        guard let url = URL(string: Config.healthKitSyncEndpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: syncPayload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Sync response: \(httpResponse.statusCode)")
            }
        } catch {
            print("Sync error: \(error)")
        }
    }
}

struct Activity: Codable {
    let id: String
    let type: String
    let title: String
    let duration: Int
    let distance: Double
    let calories: Double
    let timestamp: Date

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type,
            "title": title,
            "duration": duration,
            "distance": distance,
            "calories": calories,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]
    }
}
