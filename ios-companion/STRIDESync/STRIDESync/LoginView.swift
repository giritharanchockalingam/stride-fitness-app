import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color(hex: "FC4C02"), Color(hex: "FF6B35")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color(hex: "FC4C02").opacity(0.4), radius: 16)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    Text("STRIDE")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Apple Health Companion")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer().frame(height: 20)

                // Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(.caption).foregroundColor(.gray)
                        HStack {
                            Image(systemName: "envelope").foregroundColor(.gray)
                            TextField("you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password").font(.caption).foregroundColor(.gray)
                        HStack {
                            Image(systemName: "lock").foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(Color(hex: "1A1A1A"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        Task { await authManager.signIn(email: email, password: password) }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(LinearGradient(colors: [Color(hex: "FC4C02"), Color(hex: "FF6B35")], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "FC4C02").opacity(0.4), radius: 8)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)

                    Text("Sign in with the same account you use on stride-fitness-app.vercel.app")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(24)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

// Color extension for hex
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(red: Double((rgbValue >> 16) & 0xFF) / 255, green: Double((rgbValue >> 8) & 0xFF) / 255, blue: Double(rgbValue & 0xFF) / 255)
    }
}
