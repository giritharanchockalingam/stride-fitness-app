import Foundation
import AuthenticationServices

class AuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var accessToken: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let userDefaultsKeyToken = "stride_access_token"
    private let userDefaultsKeyUserId = "stride_user_id"
    private let userDefaultsKeyEmail = "stride_user_email"
    private let userDefaultsKeyName = "stride_user_name"

    override init() {
        super.init()
        loadCredentialsFromUserDefaults()
    }

    func signInWithEmail(_ email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil

        let url = URL(string: "\(Config.supabaseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(false, self?.errorMessage)
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No response data"
                    completion(false, self?.errorMessage)
                    return
                }

                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let accessToken = jsonObject["access_token"] as? String,
                           let user = jsonObject["user"] as? [String: Any],
                           let userId = user["id"] as? String {
                            self?.accessToken = accessToken
                            self?.userId = userId
                            self?.userEmail = email
                            self?.isAuthenticated = true
                            self?.saveCredentialsToUserDefaults()
                            completion(true, nil)
                            return
                        }

                        if let errorDescription = jsonObject["error_description"] as? String {
                            self?.errorMessage = errorDescription
                            completion(false, self?.errorMessage)
                            return
                        }
                    }

                    self?.errorMessage = "Invalid response format"
                    completion(false, self?.errorMessage)
                } catch {
                    self?.errorMessage = "JSON parsing error: \(error.localizedDescription)"
                    completion(false, self?.errorMessage)
                }
            }
        }.resume()
    }

    func signInWithGoogle(presentationContextProvider: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil

        let authURL = URL(string: "\(Config.supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(Config.oauthCallbackScheme)://callback")!

        let authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: Config.oauthCallbackScheme) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    if (error as NSError).code != ASWebAuthenticationSessionError.cancelledLogin.rawValue {
                        self?.errorMessage = "Authentication error: \(error.localizedDescription)"
                        completion(false, self?.errorMessage)
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    self?.errorMessage = "No callback URL received"
                    completion(false, self?.errorMessage)
                    return
                }

                if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                   let fragment = components.fragment,
                   let fragmentParams = fragment.split(separator: "&").map({ $0.split(separator: "=") }),
                   let accessTokenPair = fragmentParams.first(where: { $0.first == "access_token" }) {
                    let accessToken = String(accessTokenPair.last ?? "")
                    if !accessToken.isEmpty {
                        self?.accessToken = accessToken
                        self?.isAuthenticated = true
                        self?.fetchUserFromToken(accessToken) { success, error in
                            if success {
                                self?.saveCredentialsToUserDefaults()
                                completion(true, nil)
                            } else {
                                completion(false, error)
                            }
                        }
                        return
                    }
                }

                self?.errorMessage = "Failed to extract access token from callback"
                completion(false, self?.errorMessage)
            }
        }

        authSession.presentationContextProvider = presentationContextProvider as? ASWebAuthenticationPresentationContextProviding
        authSession.start()
    }

    private func fetchUserFromToken(_ token: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(Config.supabaseURL)/auth/v1/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Failed to fetch user: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    completion(false, "No user data")
                    return
                }

                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let userId = jsonObject["id"] as? String {
                            self?.userId = userId
                            self?.userEmail = jsonObject["email"] as? String
                            completion(true, nil)
                            return
                        }
                    }
                    completion(false, "Invalid user data")
                } catch {
                    completion(false, "JSON parsing error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func signOut() {
        isAuthenticated = false
        userId = nil
        accessToken = nil
        userEmail = nil
        userName = nil
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyToken)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyUserId)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyEmail)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyName)
    }

    private func saveCredentialsToUserDefaults() {
        UserDefaults.standard.set(accessToken, forKey: userDefaultsKeyToken)
        UserDefaults.standard.set(userId, forKey: userDefaultsKeyUserId)
        UserDefaults.standard.set(userEmail, forKey: userDefaultsKeyEmail)
        UserDefaults.standard.set(userName, forKey: userDefaultsKeyName)
    }

    private func loadCredentialsFromUserDefaults() {
        if let token = UserDefaults.standard.string(forKey: userDefaultsKeyToken),
           let userId = UserDefaults.standard.string(forKey: userDefaultsKeyUserId) {
            accessToken = token
            self.userId = userId
            userEmail = UserDefaults.standard.string(forKey: userDefaultsKeyEmail)
            userName = UserDefaults.standard.string(forKey: userDefaultsKeyName)
            isAuthenticated = true
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
        return window
    }
}
