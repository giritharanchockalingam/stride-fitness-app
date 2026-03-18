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

    @State private var leaderboardData: [[String: Any]] = []
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedMetric: LeaderboardMetric = .steps
    @State private var userRank: Int = 0

    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    periodSelector()

                    metricSelector()

                    if leaderboardData.count >= 3 {
                        podium()
                    }

                    rankedList()
                }
                .padding(16)
            }
        }
        .onAppear {
            Task {
                await loadLeaderboard()
            }
        }
    }

    private func periodSelector() -> some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedPeriod == period ? .white : .gray
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ?
                            Color(hex: "FC4C02") :
                            Color(hex: "141414")
                        )
                        .cornerRadius(8)
                }
            }
            Spacer()
        }
    }

    private func metricSelector() -> some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                Button(action: { selectedMetric = metric }) {
                    Text(metric.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedMetric == metric ? .white : .gray
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedMetric == metric ?
                            Color(hex: "FC4C02") :
                            Color(hex: "141414")
                        )
                        .cornerRadius(8)
                }
            }
            Spacer()
        }
    }

    private func podium() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                podiumPlace(
                    rank: 2,
                    medal: "🥈",
                    name: (leaderboardData[1]["name"] as? String) ?? "User 2",
                    value: getDisplayValue(for: leaderboardData[1]),
                    height: 120
                )

                podiumPlace(
                    rank: 1,
                    medal: "🥇",
                    name: (leaderboardData[0]["name"] as? String) ?? "User 1",
                    value: getDisplayValue(for: leaderboardData[0]),
                    height: 160
                )

                podiumPlace(
                    rank: 3,
                    medal: "🥉",
                    name: (leaderboardData[2]["name"] as? String) ?? "User 3",
                    value: getDisplayValue(for: leaderboardData[2]),
                    height: 80
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func podiumPlace(
        rank: Int,
        medal: String,
        name: String,
        value: String,
        height: CGFloat
    ) -> some View {
        VStack(spacing: 8) {
            Text(medal)
                .font(.system(size: 28))

            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "FC4C02"))
            }
            .padding(12)
            .background(Color(hex: "141414"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func rankedList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rankings")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                ForEach(Array(leaderboardData.enumerated()), id: \.offset) { index, entry in
                    if let name = entry["name"] as? String {
                        let isCurrentUser = name == authManager.userEmail

                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(getDisplayValue(for: entry))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(
                                    isCurrentUser ? Color(hex: "FC4C02") : .gray
                                )
                        }
                        .padding(12)
                        .background(
                            isCurrentUser ?
                            Color(hex: "141414") :
                            Color(hex: "0a0a0a")
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isCurrentUser ?
                                    Color(hex: "FC4C02") :
                                    Color(hex: "2C2C2E"),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "141414"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }

    private func getDisplayValue(for entry: [String: Any]) -> String {
        switch selectedMetric {
        case .steps:
            return String(entry["steps"] as? Int ?? 0)
        case .workouts:
            return String(entry["workouts"] as? Int ?? 0)
        case .streak:
            return String(entry["streak"] as? Int ?? 0)
        }
    }

    private func loadLeaderboard() async {
        guard let token = authManager.accessToken else { return }
        leaderboardData = await supabaseManager.query(
            table: "leaderboard",
            token: token,
            order: "score.desc",
            limit: 20
        )
    }
}

enum LeaderboardPeriod: CaseIterable {
    case weekly
    case monthly
    case allTime

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .allTime: return "All Time"
        }
    }
}

enum LeaderboardMetric: CaseIterable {
    case steps
    case workouts
    case streak

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .workouts: return "Workouts"
        case .streak: return "Streak"
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(AuthManager())
        .environmentObject(SupabaseManager())
}
