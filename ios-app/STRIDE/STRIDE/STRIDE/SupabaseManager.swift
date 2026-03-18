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

    func query(
        table: String,
        token: String,
        filters: [String: String] = [:],
        order: String? = nil,
        limit: Int? = nil
    ) async -> [[String: Any]] {
        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"

        var queryParams: [String] = []
        for (key, value) in filters {
            queryParams.append("\(key)=eq.\(value)")
        }

        if let order = order {
            queryParams.append("order=\(order)")
        }

        if let limit = limit {
            queryParams.append("limit=\(limit)")
        }

        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray
            }
            return []
        } catch {
            print("Query error: \(error)")
            return []
        }
    }

    func insert(
        table: String,
        data: [String: Any],
        token: String
    ) async -> Bool {
        let urlString = "\(Config.supabaseURL)/rest/v1/\(table)"
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 201
            }
            return false
        } catch {
            print("Insert error: \(error)")
            return false
        }
    }

    func update(
        table: String,
        data: [String: Any],
        filters: [String: String],
        token: String
    ) async -> Bool {
        var urlString = "\(Config.supabaseURL)/rest/v1/\(table)"

        var queryParams: [String] = []
        for (key, value) in filters {
            queryParams.append("\(key)=eq.\(value)")
        }

        if !queryParams.isEmpty {
            urlString += "?" + queryParams.joined(separator: "&")
        }

        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 204
            }
            return false
        } catch {
            print("Update error: \(error)")
            return false
        }
    }
}
