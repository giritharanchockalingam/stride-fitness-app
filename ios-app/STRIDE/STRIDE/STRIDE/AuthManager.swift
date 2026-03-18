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
    @Published var accessToken: String?
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var errorMessage: String?

    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        loadStoredToken()
    }

    private func loadStoredToken() {
        if let token = UserDefaults.standard.string(forKey: "accessToken"),
           let userId = UserDefaults.standard.string(forKey: "userId") {
            self.accessToken = token
            self.userId = userId
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async {
        let loginURL = "\(Config.supabaseURL)/auth/v1/token?grant_type=password"

        guard let url = URL(string: loginURL) else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Authentication failed"
                return
            }

            let result = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.accessToken = result.access_token
            self.userId = result.user.id
            self.userEmail = result.user.email

            UserDefaults.standard.set(result.access_token, forKey: "accessToken")
            UserDefaults.standard.set(result.user.id, forKey: "userId")
            UserDefaults.standard.set(result.user.email, forKey: "userEmail")

            self.isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    func startGoogleOAuth() {
        let redirectURL = "\(Config.oauthCallbackScheme)://auth-callback"
        let authURL = "\(Config.supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(redirectURL)"

        guard let url = URL(string: authURL) else { return }

        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Config.oauthCallbackScheme,
            completionHandler: { callbackURL, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }

                if let url = callbackURL {
                    self.handleOAuthCallback(url)
                }
            }
        )

        webAuthSession?.presentationContextProvider = self
        webAuthSession?.start()
    }

    func handleOAuthCallback(_ url: URL) {
        guard let fragment = url.fragment else { return }

        let components = fragment.split(separator: "&").map { String($0) }
        var accessToken: String?

        for component in components {
            let parts = component.split(separator: "=")
            if parts.count == 2, parts[0] == "access_token" {
                accessToken = String(parts[1])
                break
            }
        }

        if let token = accessToken {
            Task {
                await fetchUserWithToken(token)
            }
        }
    }

    func fetchUserWithToken(_ token: String) async {
        let url = URL(string: "\(Config.supabaseURL)/auth/v1/user")!
        var request = URLRequest(url: url)
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let user = try JSONDecoder().decode(User.self, from: data)

            self.accessToken = token
            self.userId = user.id
            self.userEmail = user.email

            UserDefaults.standard.set(token, forKey: "accessToken")
            UserDefaults.standard.set(user.id, forKey: "userId")
            UserDefaults.standard.set(user.email, forKey: "userEmail")

            self.isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch user"
        }
    }

    func signOut() {
        accessToken = nil
        userId = nil
        userEmail = nil
        userName = nil
        isAuthenticated = false

        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

struct AuthResponse: Codable {
    let access_token: String
    let user: User
}

struct User: Codable {
    let id: String
    let email: String
}
