import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.strideBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        loginTabView
                            .frame(width: UIScreen.main.bounds.width)

                        signupTabView
                            .frame(width: UIScreen.main.bounds.width)
                    }
                }
                .frame(height: UIScreen.main.bounds.height - 100)
            }
        }
    }

    private var loginTabView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.stridePrimary)

                Text("STRIDE")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.strideText)

                Text("Track your fitness journey")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.strideSecondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .padding(12)
                    .background(Color.strideCard)
                    .cornerRadius(12)
                    .foregroundColor(.strideText)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                HStack(spacing: 12) {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }

                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.strideSecondary)
                    }
                }
                .padding(12)
                .background(Color.strideCard)
                .cornerRadius(12)
            }

            if let error = authManager.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Button(action: signIn) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .strideText))
                } else {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.strideText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)

            Divider()
                .background(Color.strideBorder)

            GoogleSignInButton(isLoading: authManager.isLoading) {
                signInWithGoogle()
            }

            Spacer()

            HStack(spacing: 8) {
                Text("Don't have an account?")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.strideSecondary)

                Button(action: {}) {
                    Text("Sign up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.stridePrimary)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(20)
    }

    private var signupTabView: some View {
        VStack(spacing: 20) {
            Text("Coming Soon")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.strideText)

            Text("Sign up functionality will be available soon")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.strideSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(20)
    }

    private func signIn() {
        authManager.signInWithEmail(email, password: password) { success, error in
            if !success {
                print("Sign in failed: \(error ?? "Unknown error")")
            }
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }

        authManager.signInWithGoogle(presentationContextProvider: viewController) { success, error in
            if !success {
                print("Google sign in failed: \(error ?? "Unknown error")")
            }
        }
    }
}

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.strideText)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .strideText))
                        .scaleEffect(0.8)
                } else {
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.strideText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.strideCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.strideBorder, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
