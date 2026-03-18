import Foundation

class SupabaseManager: NSObject, ObservableObject {
    @Published var userProfile: [String: Any]?
    @Published var activities: [[String: Any]] = []
    @Published var workoutPlans: [[String: Any]] = []
    @Published var workoutSessions: [[String: Any]] = []
    @Published var achievements: [[String: Any]] = []
    @Published var userAchievements: [[String: Any]] = []
    @Published var notifications: [[String: Any]] = []
    @Published var leaderboardEntries: [[String: Any]] = []
    @Published var dailyStats: [[String: Any]] = []

    private var accessToken: String?

    func setAccessToken(_ token: String) {
        self.accessToken = token
    }

    func query(table: String, filters: [String: String]? = nil, order: String? = nil, limit: Int? = nil, completion: @escaping ([[String: Any]]) -> Void) {
        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        var queryItems: [URLQueryItem] = []

        if let filters = filters {
            for (key, value) in filters {
                queryItems.append(URLQueryItem(name: key, value: "eq.\(value)"))
            }
        }

        if let order = order {
            queryItems.append(URLQueryItem(name: "order", value: order))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)!
            components.queryItems = queryItems
            urlString = components.url?.absoluteString ?? urlString
        }

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion([])
                    return
                }

                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        completion(jsonArray)
                    } else {
                        completion([])
                    }
                } catch {
                    completion([])
                }
            }
        }.resume()
    }

    func insert(table: String, data: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void) {
        let urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        guard let url = URL(string: urlString) else {
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")

        request.httpBody = try? JSONSerialization.data(withJSONObject: data)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(false, nil)
                    return
                }

                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]], let first = jsonArray.first {
                        completion(true, first)
                    } else if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        completion(true, jsonObject)
                    } else {
                        completion(false, nil)
                    }
                } catch {
                    completion(false, nil)
                }
            }
        }.resume()
    }

    func update(table: String, data: [String: Any], filters: [String: String], completion: @escaping (Bool) -> Void) {
        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        var queryItems: [URLQueryItem] = []

        for (key, value) in filters {
            queryItems.append(URLQueryItem(name: key, value: "eq.\(value)"))
        }

        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)!
            components.queryItems = queryItems
            urlString = components.url?.absoluteString ?? urlString
        }

        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: data)

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204, error == nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }

    func fetchUserProfile(userId: String, completion: @escaping () -> Void) {
        query(table: "profiles", filters: ["id": userId]) { [weak self] results in
            self?.userProfile = results.first
            completion()
        }
    }

    func fetchActivities(userId: String, completion: @escaping () -> Void) {
        query(table: "activities", filters: ["user_id": userId], order: "created_at.desc", limit: 50) { [weak self] results in
            self?.activities = results
            completion()
        }
    }

    func fetchWorkoutPlans(completion: @escaping () -> Void) {
        query(table: "workout_plans", limit: 20) { [weak self] results in
            self?.workoutPlans = results
            completion()
        }
    }

    func fetchWorkoutSessions(userId: String, completion: @escaping () -> Void) {
        query(table: "workout_sessions", filters: ["user_id": userId], order: "created_at.desc") { [weak self] results in
            self?.workoutSessions = results
            completion()
        }
    }

    func fetchAchievements(completion: @escaping () -> Void) {
        query(table: "achievements") { [weak self] results in
            self?.achievements = results
            completion()
        }
    }

    func fetchUserAchievements(userId: String, completion: @escaping () -> Void) {
        query(table: "user_achievements", filters: ["user_id": userId]) { [weak self] results in
            self?.userAchievements = results
            completion()
        }
    }

    func fetchNotifications(userId: String, completion: @escaping () -> Void) {
        query(table: "notifications", filters: ["user_id": userId], order: "created_at.desc") { [weak self] results in
            self?.notifications = results
            completion()
        }
    }

    func fetchLeaderboard(metric: String = "steps", period: String = "weekly", completion: @escaping () -> Void) {
        var filters = ["metric": metric, "period": period]
        query(table: "leaderboard_entries", filters: filters, order: "rank.asc", limit: 100) { [weak self] results in
            self?.leaderboardEntries = results
            completion()
        }
    }

    func fetchDailyStats(userId: String, completion: @escaping () -> Void) {
        query(table: "daily_stats", filters: ["user_id": userId], order: "date.desc", limit: 30) { [weak self] results in
            self?.dailyStats = results
            completion()
        }
    }

    func saveWorkoutSession(userId: String, workoutData: [String: Any], completion: @escaping (Bool) -> Void) {
        var data = workoutData
        data["user_id"] = userId
        data["created_at"] = ISO8601DateFormatter().string(from: Date())

        insert(table: "workout_sessions", data: data) { success, _ in
            completion(success)
        }
    }
}
