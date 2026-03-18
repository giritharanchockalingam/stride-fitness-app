import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthKit: HealthKitManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STRIDE Sync")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(.white)
                                Text(authManager.userEmail ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: { authManager.signOut() }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.gray)
                                    .padding(10)
                                    .background(Color(hex: "1A1A1A"))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)

                        // HealthKit Status Card
                        if !healthKit.isAuthorized {
                            VStack(spacing: 16) {
                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "FF2D55"))
                                Text("Connect Apple Health")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Allow STRIDE to read your health data to sync steps, heart rate, workouts, and calories to your dashboard.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Button("Enable HealthKit") {
                                    Task { await healthKit.requestAuthorization() }
                                }
                                .fontWeight(.bold)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color(hex: "FF2D55"))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "141414"))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
                            .padding(.horizontal)
                        } else {
                            // Today's Stats
                            VStack(spacing: 16) {
                                Text("Today's Apple Health")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    StatTile(icon: "figure.walk", label: "Steps", value: "\(healthKit.todaySteps.formatted())", color: "FC4C02")
                                    StatTile(icon: "flame.fill", label: "Calories", value: "\(healthKit.todayCalories) kcal", color: "FF3B30")
                                    StatTile(icon: "heart.fill", label: "Heart Rate", value: healthKit.currentHeartRate > 0 ? "\(healthKit.currentHeartRate) bpm" : "—", color: "FF2D55")
                                    StatTile(icon: "figure.run", label: "Distance", value: String(format: "%.1f km", healthKit.todayDistance / 1000), color: "007AFF")
                                }
                            }
                            .padding(20)
                            .background(Color(hex: "141414"))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
                            .padding(.horizontal)

                            // Sync Button
                            VStack(spacing: 12) {
                                Button(action: {
                                    guard let token = authManager.accessToken else { return }
                                    Task { await healthKit.syncToSupabase(token: token) }
                                }) {
                                    HStack(spacing: 10) {
                                        if healthKit.isSyncing {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                        Text(healthKit.isSyncing ? "Syncing..." : "Sync to STRIDE")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(LinearGradient(colors: [Color(hex: "FC4C02"), Color(hex: "FF6B35")], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                    .shadow(color: Color(hex: "FC4C02").opacity(0.3), radius: 12)
                                }
                                .disabled(healthKit.isSyncing)
                                .padding(.horizontal)

                                if let lastSync = healthKit.lastSyncDate {
                                    Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                if let result = healthKit.syncResult {
                                    Text(result)
                                        .font(.caption)
                                        .foregroundColor(result.starts(with: "Error") ? .red : Color(hex: "00D4AA"))
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background(result.starts(with: "Error") ? Color.red.opacity(0.1) : Color(hex: "00D4AA").opacity(0.1))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                            }

                            // Info Card
                            VStack(alignment: .leading, spacing: 8) {
                                Label("How it works", systemImage: "info.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("This companion app reads your Apple Health data and syncs it to your STRIDE dashboard. Tap \"Sync to STRIDE\" to push the last 14 days of steps, calories, heart rate, distance, and workouts.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                                Text("Synced data appears instantly on stride-fitness-app.vercel.app")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "FC4C02"))
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "141414"))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
            .task {
                if healthKit.isAuthorized {
                    await healthKit.fetchTodayStats()
                }
            }
        }
    }
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: color))
                .frame(width: 32, height: 32)
                .background(Color(hex: color).opacity(0.15))
                .cornerRadius(8)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "2C2C2E"), lineWidth: 1))
    }
}
