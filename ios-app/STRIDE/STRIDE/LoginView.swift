//
//  LoginView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // Logo & Branding
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Config.Colors.primaryOrange, Config.Colors.orangeGradient],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Config.Colors.primaryOrange.opacity(0.4), radius: 20, y: 8)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("STRIDE")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)

                        Text("Track. Compete. Achieve.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)

                    // Tab Toggle
                    HStack(spacing: 0) {
                        tabButton(title: "Sign In", isSelected: !isSignUp) { isSignUp = false }
                        tabButton(title: "Sign Up", isSelected: isSignUp) { isSignUp = true }
                    }
                    .background(Config.Colors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Config.Colors.borderColor, lineWidth: 1)
                    )

                    // Form Fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            formField(
                                label: "Full Name",
                                icon: "person.fill",
                                placeholder: "Enter your name",
                                text: $fullName,
                                isSecure: false
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        formField(
                            label: "Email",
                            icon: "envelope.fill",
                            placeholder: "Enter your email",
                            text: $email,
                            isSecure: false,
                            keyboardType: .emailAddress
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textInputAutocapitalization(.never)
                                        .foregroundColor(.white)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .foregroundColor(.white)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(14)
                            .background(Config.Colors.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Config.Colors.borderColor, lineWidth: 1)
                            )
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: isSignUp)

                    // Error Message
                    if let error = authManager.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "FF6B6B").opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Primary Action Button
                    Button(action: { performAuth() }) {
                        Group {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Config.Colors.primaryOrange, Config.Colors.orangeGradient],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Config.Colors.primaryOrange.opacity(0.3), radius: 12, y: 6)
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)

                    // Divider
                    HStack(spacing: 16) {
                        Rectangle().frame(height: 1).foregroundColor(Config.Colors.borderColor)
                        Text("or")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                        Rectangle().frame(height: 1).foregroundColor(Config.Colors.borderColor)
                    }

                    // Google OAuth
                    Button(action: { authManager.startGoogleOAuth() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundColor(.white)
                        .background(Config.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Config.Colors.borderColor, lineWidth: 1)
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Subviews

    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Config.Colors.primaryOrange : Color.clear)
                .cornerRadius(10)
        }
        .padding(3)
    }

    private func formField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)

                if isSecure {
                    SecureField(placeholder, text: text)
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .keyboardType(keyboardType)
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .background(Config.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Config.Colors.borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password.count >= 6
        }
        return !email.isEmpty && !password.isEmpty
    }

    private func performAuth() {
        Task {
            if isSignUp {
                await authManager.signUp(email: email, password: password, fullName: fullName)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
