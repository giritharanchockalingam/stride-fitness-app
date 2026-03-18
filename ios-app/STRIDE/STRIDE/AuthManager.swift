//
//  AuthManager.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import Foundation
import Combine
import AuthenticationServices

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var avatarUrl: String?
    @Published var errorMessage: String?

    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        loadStoredSession()
    }

    // MARK: - Session Persistence

    private func loadStoredSession() {
        guard let token = UserDefaults.standard.string(forKey: "stride_access_token"),
              let userId = UserDefaults.standard.string(forKey: "stride_user_id") else {
            return
        }
        self.accessToken = token
        self.refreshToken = UserDefaults.standard.string(forKey: "stride_refresh_token")
        self.userId = userId
        self.userEmail = UserDefaults.standard.string(forKey: "stride_user_email")
        self.userName = UserDefaults.standard.string(forKey: "stride_user_name")
        self.avatarUrl = UserDefaults.standard.string(forKey: "stride_avatar_url")
        self.isAuthenticated = true
    }

    private func saveSession(_ response: AuthResponse) {
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.userId = response.user.id
        self.userEmail = response.user.email
        self.userName = response.user.userMetadata?.fullName

        UserDefaults.standard.set(response.accessToken, forKey: "stride_access_token")
        UserDefaults.standard.set(response.refreshToken, forKey: "stride_refresh_token")
        UserDefaults.standard.set(response.user.id, forKey: "stride_user_id")
        UserDefaults.standard.set(response.user.email, forKey: "stride_user_email")
        if let name = response.user.userMetadata?.fullName {
            UserDefaults.standard.set(name, forKey: "stride_user_name")
        }

        self.isAuthenticated = true
        self.errorMessage = nil
    }

    private func clearSession() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        userEmail = nil
        userName = nil
        avatarUrl = nil
        isAuthenticated = false

        let keys = ["stride_access_token", "stride_refresh_token", "stride_user_id",
                     "stride_user_email", "stride_user_name", "stride_avatar_url"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=password") else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["email": email, "password": password]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                saveSession(result)
            } else if httpResponse.statusCode == 400 {
                errorMessage = "Invalid email or password"
            } else {
                errorMessage = "Authentication failed (HTTP \(httpResponse.statusCode))"
            }
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(Config.supabaseURL)/auth/v1/signup") else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                saveSession(result)
                self.userName = fullName
                UserDefaults.standard.set(fullName, forKey: "stride_user_name")
            } else if httpResponse.statusCode == 422 {
                errorMessage = "Account already exists"
            } else {
                let responseBody = String(data: data, encoding: .utf8) ?? ""
                if responseBody.contains("already registered") {
                    errorMessage = "This email is already registered"
                } else {
                    errorMessage = "Sign up failed"
                }
            }
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Google OAuth

    func startGoogleOAuth() {
        errorMessage = nil
        let redirectURL = "\(Config.oauthCallbackScheme)://auth-callback"
        let authURL = "\(Config.supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(redirectURL)"

        guard let url = URL(string: authURL) else {
            errorMessage = "Invalid OAuth URL"
            return
        }

        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Config.oauthCallbackScheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error as? ASWebAuthenticationSessionError,
               error.code == .canceledLogin {
                return
            }

            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            if let url = callbackURL {
                Task { @MainActor in
                    await self.handleOAuthCallback(url)
                }
            }
        }

        webAuthSession?.presentationContextProvider = self
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.start()
    }

    private func handleOAuthCallback(_ url: URL) async {
        // Try URL fragment first (Supabase default), then query params
        let tokenString: String?
        if let fragment = url.fragment {
            tokenString = fragment
        } else if let query = url.query {
            tokenString = query
        } else {
            errorMessage = "No authentication data received"
            return
        }

        guard let tokenString = tokenString else { return }

        var params: [String: String] = [:]
        for component in tokenString.split(separator: "&") {
            let parts = component.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                params[String(parts[0])] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            }
        }

        guard let token = params["access_token"] else {
            errorMessage = "No access token in callback"
            return
        }

        await fetchUserWithToken(token, refreshToken: params["refresh_token"])
    }

    private func fetchUserWithToken(_ token: String, refreshToken: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(Config.supabaseURL)/auth/v1/user") else { return }

        var request = URLRequest(url: url)
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to fetch user info"
                return
            }

            let user = try JSONDecoder().decode(AuthUser.self, from: data)

            self.accessToken = token
            self.refreshToken = refreshToken
            self.userId = user.id
            self.userEmail = user.email
            self.userName = user.userMetadata?.fullName
            self.avatarUrl = user.userMetadata?.avatarUrl

            UserDefaults.standard.set(token, forKey: "stride_access_token")
            if let rt = refreshToken { UserDefaults.standard.set(rt, forKey: "stride_refresh_token") }
            UserDefaults.standard.set(user.id, forKey: "stride_user_id")
            UserDefaults.standard.set(user.email, forKey: "stride_user_email")
            if let name = user.userMetadata?.fullName {
                UserDefaults.standard.set(name, forKey: "stride_user_name")
            }

            self.isAuthenticated = true
            self.errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch user: \(error.localizedDescription)"
        }
    }

    // MARK: - Token Refresh

    func refreshSession() async -> Bool {
        guard let rt = refreshToken else { return false }

        guard let url = URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["refresh_token": rt]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }

            let result = try JSONDecoder().decode(AuthResponse.self, from: data)
            saveSession(result)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        // Fire and forget server-side logout
        if let token = accessToken, let url = URL(string: "\(Config.supabaseURL)/auth/v1/logout") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request).resume()
        }
        clearSession()
    }

    // MARK: - Helpers

    var displayName: String {
        if let name = userName, !name.isEmpty { return name }
        if let email = userEmail { return email.components(separatedBy: "@").first ?? email }
        return "Athlete"
    }

    var initials: String {
        let name = displayName
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
