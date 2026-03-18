//
//  LeaderboardView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var authManager: AuthManager

    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedMetric: LeaderboardMetric = .steps
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Config.Colors.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    periodPills
                    metricPills

                    if leaderboardData.count >= 3 {
                        podiumSection
                    }

                    rankingsList
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .task { await loadLeaderboard() }
        .onChange(of: selectedPeriod) { _, _ in Task { await loadLeaderboard() } }
        .onChange(of: selectedMetric) { _, _ in /* re-sort client side */ }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Leaderboard")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("Compete with the community")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Period Pills

    private var periodPills: some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                pillButton(title: period.label, isSelected: selectedPeriod == period) {
                    withAnimation { selectedPeriod = period }
                }
            }
            Spacer()
        }
    }

    // MARK: - Metric Pills

    private var metricPills: some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                pillButton(title: metric.label, isSelected: selectedMetric == metric) {
                    withAnimation { selectedMetric = metric }
                }
            }
            Spacer()
        }
    }

    private func pillButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Config.Colors.primaryOrange : Config.Colors.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Config.Colors.borderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Podium

    private var podiumSection: some View {
        let sorted = sortedData
        guard sorted.count >= 3 else { return AnyView(EmptyView()) }

        return AnyView(
            HStack(alignment: .bottom, spacing: 12) {
                // 2nd Place
                podiumColumn(
                    entry: sorted[1],
                    rank: 2,
                    medal: "\u{1F948}",
                    medalColor: Config.Colors.silver,
                    barHeight: 100
                )

                // 1st Place
                podiumColumn(
                    entry: sorted[0],
                    rank: 1,
                    medal: "\u{1F947}",
                    medalColor: Config.Colors.gold,
                    barHeight: 140
                )

                // 3rd Place
                podiumColumn(
                    entry: sorted[2],
                    rank: 3,
                    medal: "\u{1F949}",
                    medalColor: Config.Colors.bronze,
                    barHeight: 70
                )
            }
            .padding(.horizontal, 8)
        )
    }

    private func podiumColumn(entry: LeaderboardEntry, rank: Int, medal: String, medalColor: Color, barHeight: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(medal)
                .font(.system(size: 32))

            Text(entry.userName ?? "User")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(getDisplayValue(for: entry))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Config.Colors.primaryOrange)

            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [medalColor.opacity(0.6), medalColor.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: barHeight)
                .overlay(
                    Text("#\(rank)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white.opacity(0.5))
                )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rankings List

    private var rankingsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rankings")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if sortedData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No rankings available yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(sortedData.enumerated()), id: \.offset) { index, entry in
                        rankRow(entry: entry, rank: index + 1)
                    }
                }
            }
        }
        .padding(20)
        .background(Config.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Config.Colors.borderColor, lineWidth: 1)
        )
    }

    private func rankRow(entry: LeaderboardEntry, rank: Int) -> some View {
        let isCurrentUser = entry.userId == authManager.userId

        return HStack(spacing: 12) {
            // Rank badge
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(rank <= 3 ? .white : .gray)
                .frame(width: 28, height: 28)
                .background(rank <= 3 ? Config.Colors.primaryOrange.opacity(0.8) : Config.Colors.borderColor.opacity(0.5))
                .cornerRadius(8)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isCurrentUser ? [Config.Colors.primaryOrange, Config.Colors.orangeGradient] : [Config.Colors.borderColor, Config.Colors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text(String((entry.userName ?? "U").prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName ?? "User")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if isCurrentUser {
                    Text("You")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Config.Colors.primaryOrange)
                }
            }

            Spacer()

            Text(getDisplayValue(for: entry))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isCurrentUser ? Config.Colors.primaryOrange : .gray)
        }
        .padding(12)
        .background(isCurrentUser ? Config.Colors.primaryOrange.opacity(0.08) : Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrentUser ? Config.Colors.primaryOrange.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var sortedData: [LeaderboardEntry] {
        switch selectedMetric {
        case .steps:
            return leaderboardData.sorted { ($0.totalSteps ?? 0) > ($1.totalSteps ?? 0) }
        case .workouts:
            return leaderboardData.sorted { ($0.totalWorkouts ?? 0) > ($1.totalWorkouts ?? 0) }
        case .distance:
            return leaderboardData.sorted { ($0.totalDistanceMeters ?? 0) > ($1.totalDistanceMeters ?? 0) }
        }
    }

    private func getDisplayValue(for entry: LeaderboardEntry) -> String {
        switch selectedMetric {
        case .steps:
            let steps = entry.totalSteps ?? 0
            if steps >= 1000 { return "\(steps / 1000)K" }
            return "\(steps)"
        case .workouts:
            return "\(entry.totalWorkouts ?? 0)"
        case .distance:
            let km = (entry.totalDistanceMeters ?? 0) / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    private func loadLeaderboard() async {
        guard let token = authManager.accessToken else { return }
        isLoading = true
        leaderboardData = await supabaseManager.fetchLeaderboard(
            periodType: selectedPeriod.apiValue,
            token: token
        )
        isLoading = false
    }
}

// MARK: - Enums

enum LeaderboardPeriod: CaseIterable {
    case weekly, monthly, allTime

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .allTime: return "All Time"
        }
    }

    var apiValue: String {
        switch self {
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .allTime: return "all_time"
        }
    }
}

enum LeaderboardMetric: CaseIterable {
    case steps, workouts, distance

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .workouts: return "Workouts"
        case .distance: return "Distance"
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
}
