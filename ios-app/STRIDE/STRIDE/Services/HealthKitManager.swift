import Foundation
import HealthKit

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var todaySteps: Double = 0
    @Published var todayCalories: Double = 0
    @Published var todayDistance: Double = 0
    @Published var todayHeartRate: Double = 0
    @Published var todayActiveMinutes: Double = 0
    @Published var weeklySteps: [Double] = Array(repeating: 0, count: 7)
    @Published var heartRateReadings: [(date: Date, value: Double)] = []

    override init() {
        super.init()
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"]))
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success, error)
        }
    }

    func fetchTodayStats(completion: @escaping () -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        fetchSteps(predicate: predicate)
        fetchCalories(predicate: predicate)
        fetchDistance(predicate: predicate)
        fetchHeartRate(predicate: predicate)
        fetchActiveMinutes(predicate: predicate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }

    func fetchWeeklyStats(completion: @escaping () -> Void) {
        let calendar = Calendar.current
        var dailySteps: [Double] = Array(repeating: 0, count: 7)

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let sum = result?.sumQuantity() {
                    let steps = sum.doubleValue(for: HKUnit.count())
                    DispatchQueue.main.async {
                        dailySteps[6 - dayOffset] = steps
                    }
                }
            }
            healthStore.execute(query)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.weeklySteps = dailySteps
            completion()
        }
    }

    func fetchHeartRateReadings(completion: @escaping () -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKQuantitySample] {
                    self.heartRateReadings = samples.map { ($0.startDate, $0.quantity.doubleValue(for: HKUnit(from: "count/min"))) }
                }
                completion()
            }
        }

        healthStore.execute(query)
    }

    func syncToSupabase(token: String, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        var dailyStats: [[String: Any]] = []
        var activities: [[String: Any]] = []
        var heartRateData: [[String: Any]] = []

        let group = DispatchGroup()

        group.enter()
        fetchLast14DaysStats { stats in
            dailyStats = stats
            group.leave()
        }

        group.enter()
        fetchActivities { act in
            activities = act
            group.leave()
        }

        group.enter()
        fetchLast14DaysHeartRate { hr in
            heartRateData = hr
            group.leave()
        }

        group.notify(queue: .main) {
            let syncPayload: [String: Any] = [
                "user_id": userId,
                "daily_stats": dailyStats,
                "activities": activities,
                "heart_rate": heartRateData
            ]

            let url = URL(string: "\(Config.supabaseURL)\(Config.healthKitSyncEndpoint)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

            request.httpBody = try? JSONSerialization.data(withJSONObject: syncPayload)

            URLSession.shared.dataTask(with: request) { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, error)
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        completion(true, nil)
                    } else {
                        completion(false, NSError(domain: "Sync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync failed"]))
                    }
                }
            }.resume()
        }
    }

    private func fetchSteps(predicate: NSPredicate) {
        let query = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todaySteps = sum.doubleValue(for: HKUnit.count())
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchCalories(predicate: NSPredicate) {
        let query = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todayCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchDistance(predicate: NSPredicate) {
        let walkingQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                self.todayDistance += sum.doubleValue(for: HKUnit.meter()) / 1000.0
            }
        }

        let cyclingQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .distanceCycling)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todayDistance += sum.doubleValue(for: HKUnit.meter()) / 1000.0
                }
            }
        }

        healthStore.execute(walkingQuery)
        healthStore.execute(cyclingQuery)
    }

    private func fetchHeartRate(predicate: NSPredicate) {
        let query = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .heartRate)!, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            DispatchQueue.main.async {
                if let average = result?.averageQuantity() {
                    self.todayHeartRate = average.doubleValue(for: HKUnit(from: "count/min"))
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchActiveMinutes(predicate: NSPredicate) {
        let query = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                if let sum = result?.sumQuantity() {
                    self.todayActiveMinutes = sum.doubleValue(for: HKUnit.minute())
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchLast14DaysStats(completion: @escaping ([[String: Any]]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        var stats: [[String: Any]] = []
        let group = DispatchGroup()

        for dayOffset in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

            group.enter()
            let stepsQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .stepCount)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                var dailyStat: [String: Any] = [
                    "date": ISO8601DateFormatter().string(from: startOfDay),
                    "steps": result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0,
                    "calories": 0,
                    "distance": 0,
                    "active_minutes": 0
                ]

                let caloriesQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, caloriesResult, _ in
                    dailyStat["calories"] = caloriesResult?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0

                    let distanceQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, distanceResult, _ in
                        var totalDistance = distanceResult?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0

                        let cyclingQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .distanceCycling)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, cyclingResult, _ in
                            totalDistance += cyclingResult?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                            dailyStat["distance"] = totalDistance / 1000.0

                            let activeQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, activeResult, _ in
                                dailyStat["active_minutes"] = activeResult?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                                DispatchQueue.main.async {
                                    stats.append(dailyStat)
                                    group.leave()
                                }
                            }
                            self.healthStore.execute(activeQuery)
                        }
                        self.healthStore.execute(cyclingQuery)
                    }
                    self.healthStore.execute(distanceQuery)
                }
                self.healthStore.execute(caloriesQuery)
            }
            healthStore.execute(stepsQuery)
        }

        group.notify(queue: .main) {
            completion(stats)
        }
    }

    private func fetchActivities(completion: @escaping ([[String: Any]]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -14, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 100, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            DispatchQueue.main.async {
                guard let workouts = samples as? [HKWorkout] else {
                    completion([])
                    return
                }

                let activities = workouts.map { workout -> [String: Any] in
                    [
                        "id": UUID().uuidString,
                        "type": self.activityTypeString(workout.workoutActivityType),
                        "duration": Int(workout.duration * 60),
                        "distance": workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0,
                        "calories": Int(workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0),
                        "started_at": ISO8601DateFormatter().string(from: workout.startDate),
                        "ended_at": ISO8601DateFormatter().string(from: workout.endDate)
                    ]
                }
                completion(activities)
            }
        }

        healthStore.execute(query)
    }

    private func fetchLast14DaysHeartRate(completion: @escaping ([[String: Any]]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -14, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1000, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            DispatchQueue.main.async {
                guard let samples = samples as? [HKQuantitySample] else {
                    completion([])
                    return
                }

                let hrReadings = samples.map { sample -> [String: Any] in
                    [
                        "timestamp": ISO8601DateFormatter().string(from: sample.startDate),
                        "heart_rate": Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    ]
                }
                completion(hrReadings)
            }
        }

        healthStore.execute(query)
    }

    private func activityTypeString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:
            return "running"
        case .cycling:
            return "cycling"
        case .walking:
            return "walking"
        case .swimming:
            return "swimming"
        case .hiit:
            return "hiit"
        case .functionalStrengthTraining:
            return "strength"
        case .yoga:
            return "yoga"
        default:
            return "other"
        }
    }
}
