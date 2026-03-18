import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var userEmail: String?
    @Published var userId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tokenKey = "stride_access_token"
    private let emailKey = "stride_user_email"
    private let userIdKey = "stride_user_id"
    private let refreshTokenKey = "stride_refresh_token"

    init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let email = UserDefaults.standard.string(forKey: emailKey),
           let uid = UserDefaults.standard.string(forKey: userIdKey) {
            self.accessToken = token
            self.userEmail = email
            self.userId = uid
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            var request = URLRequest(url: URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=password")!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if let error = json["error_description"] as? String ?? (json["error"] as? [String: Any])?["message"] as? String {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error])
            }

            guard let token = json["access_token"] as? String,
                  let user = json["user"] as? [String: Any],
                  let uid = user["id"] as? String else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            let refreshToken = json["refresh_token"] as? String ?? ""

            await MainActor.run {
                self.accessToken = token
                self.userEmail = email
                self.userId = uid
                self.isAuthenticated = true
                UserDefaults.standard.set(token, forKey: tokenKey)
                UserDefaults.standard.set(email, forKey: emailKey)
                UserDefaults.standard.set(uid, forKey: userIdKey)
                UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }

        await MainActor.run { isLoading = false }
    }

    func signOut() {
        accessToken = nil
        userEmail = nil
        userId = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
