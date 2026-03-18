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

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "FC4C02"),
                                        Color(hex: "FF6B35")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)

                        Text("STRIDE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Achieve Your Goals")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            TextField("Enter your email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(Color(hex: "141414"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            SecureField("Enter your password", text: $password)
                                .padding(12)
                                .background(Color(hex: "141414"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                        }
                    }

                    VStack(spacing: 12) {
                        Button(action: {
                            isLoading = true
                            Task {
                                await authManager.signIn(email: email, password: password)
                                isLoading = false
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FC4C02"),
                                    Color(hex: "FF6B35")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }

                    HStack {
                        VStack(alignment: .center) {
                            Divider()
                                .background(Color(hex: "2C2C2E"))
                        }

                        Text("or")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)

                        VStack(alignment: .center) {
                            Divider()
                                .background(Color(hex: "2C2C2E"))
                        }
                    }

                    Button(action: {
                        authManager.startGoogleOAuth()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color(hex: "141414"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
