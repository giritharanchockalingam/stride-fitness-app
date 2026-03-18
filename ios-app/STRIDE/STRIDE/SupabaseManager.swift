//
//  SupabaseManager.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import Foundation
import Combine

@MainActor
class SupabaseManager: ObservableObject {
    @Published var isLoading = false

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Generic Typed Queries

    func fetch<T: Decodable>(
        table: String,
        token: String,
        select: String? = nil,
        filters: [(String, String, String)] = [],
        order: String? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        var queryParams: [String] = []

        if let select = select {
            queryParams.append("select=\(select)")
        }

        for (column, op, value) in filters {
            queryParams.append("\(column)=\(op).\(value)")
        }

        if let order = order {
            queryParams.append("order=\(order)")
        }

        if let limit = limit {
            queryParams.append("limit=\(limit)")
        }

        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.httpError(httpResponse.statusCode, body)
        }

        return try decoder.decode([T].self, from: data)
    }

    func fetchOne<T: Decodable>(
        table: String,
        token: String,
        filters: [(String, String, String)] = []
    ) async throws -> T? {
        let results: [T] = try await fetch(
            table: table,
            token: token,
            filters: filters,
            limit: 1
        )
        return results.first
    }

    // MARK: - Insert

    func insert<T: Encodable>(
        table: String,
        data: T,
        token: String
    ) async throws {
        let urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SupabaseError.httpError(code, body)
        }
    }

    func insertReturning<T: Encodable, R: Decodable>(
        table: String,
        data: T,
        token: String
    ) async throws -> R {
        let urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SupabaseError.httpError(code, body)
        }

        let results = try decoder.decode([R].self, from: responseData)
        guard let first = results.first else { throw SupabaseError.noData }
        return first
    }

    // MARK: - Update

    func update<T: Encodable>(
        table: String,
        data: T,
        filters: [(String, String, String)],
        token: String
    ) async throws {
        var queryParams: [String] = []
        for (column, op, value) in filters {
            queryParams.append("\(column)=\(op).\(value)")
        }

        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(data)

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SupabaseError.httpError(code, body)
        }
    }

    // MARK: - Delete

    func delete(
        table: String,
        filters: [(String, String, String)],
        token: String
    ) async throws {
        var queryParams: [String] = []
        for (column, op, value) in filters {
            queryParams.append("\(column)=\(op).\(value)")
        }

        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SupabaseError.httpError(code, body)
        }
    }

    // MARK: - RPC / Edge Functions

    func callEdgeFunction(
        name: String,
        body: [String: Any],
        token: String
    ) async throws -> Data {
        let urlString = "\(Config.supabaseURL)/functions/v1/\(name)"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw SupabaseError.httpError(code, body)
        }

        return data
    }
}

// MARK: - Convenience Methods

extension SupabaseManager {

    func fetchProfile(userId: String, token: String) async -> Profile? {
        try? await fetchOne(
            table: "profiles",
            token: token,
            filters: [("id", "eq", userId)]
        )
    }

    func fetchActivities(userId: String, token: String, limit: Int = 20) async -> [ActivityRecord] {
        (try? await fetch(
            table: "activities",
            token: token,
            filters: [("user_id", "eq", userId)],
            order: "started_at.desc",
            limit: limit
        )) ?? []
    }

    func fetchDailyStats(userId: String, token: String, days: Int = 7) async -> [DailyStats] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: startDate)

        return (try? await fetch(
            table: "daily_stats",
            token: token,
            filters: [
                ("user_id", "eq", userId),
                ("date", "gte", dateStr)
            ],
            order: "date.asc"
        )) ?? []
    }

    func fetchWorkoutPlans(token: String) async -> [WorkoutPlan] {
        (try? await fetch(
            table: "workout_plans",
            token: token,
            order: "created_at.desc"
        )) ?? []
    }

    func fetchWorkoutExercises(planId: String, token: String) async -> [WorkoutExercise] {
        (try? await fetch(
            table: "workout_exercises",
            token: token,
            filters: [("plan_id", "eq", planId)],
            order: "sort_order.asc"
        )) ?? []
    }

    func fetchAchievements(token: String) async -> [Achievement] {
        (try? await fetch(
            table: "achievements",
            token: token,
            order: "name.asc"
        )) ?? []
    }

    func fetchUserAchievements(userId: String, token: String) async -> [UserAchievement] {
        (try? await fetch(
            table: "user_achievements",
            token: token,
            filters: [("user_id", "eq", userId)]
        )) ?? []
    }

    func fetchLeaderboard(periodType: String, token: String, limit: Int = 50) async -> [LeaderboardEntry] {
        (try? await fetch(
            table: "leaderboard_entries",
            token: token,
            filters: [("period_type", "eq", periodType)],
            order: "total_steps.desc",
            limit: limit
        )) ?? []
    }

    func fetchNotifications(userId: String, token: String) async -> [AppNotification] {
        (try? await fetch(
            table: "notifications",
            token: token,
            filters: [("user_id", "eq", userId)],
            order: "created_at.desc",
            limit: 20
        )) ?? []
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case noData
    case encodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .noData: return "No data returned"
        case .encodingError: return "Encoding error"
        }
    }
}
