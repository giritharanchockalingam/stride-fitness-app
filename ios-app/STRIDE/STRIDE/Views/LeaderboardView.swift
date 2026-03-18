import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedPeriod = 0
    @State private var selectedMetric = 0
    @State private var userRank = 42
    @State private var userScore: Double = 8234

    let periods = ["Weekly", "Monthly", "All Time"]
    let metrics = ["Steps", "Workouts", "Streak"]

    var body: some View {
        ZStack {
            Color.strideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        periodSelector
                        metricSelector
                        topThreePodium
                        userRankSection
                        fullRankingList
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            loadLeaderboard()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leaderboard")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.strideText)

            Text("See how you stack up")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.strideSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Text(period).tag(index)
            }
        }
        .pickerStyle(.segmented)
        .tint(.stridePrimary)
    }

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    Button(action: { selectedMetric = index }) {
                        Text(metric)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedMetric == index ? .strideText : .strideSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedMetric == index ? Color.stridePrimary : Color.strideCard)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
        }
    }

    private var topThreePodium: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                secondPlaceCard
                firstPlaceCard
                thirdPlaceCard
            }
            .frame(height: 220)
        }
    }

    private var firstPlaceCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "FFD700"))

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("A")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.strideText)
                }
                .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Text("Alex Johnson")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.strideText)

                    Text("52,420 steps")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("1st Place")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.strideText)
                }

                Text("+2,480")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            .padding(8)
            .background(Color.strideCard)
            .cornerRadius(8)
        }
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFD700").opacity(0.15), Color(hex: "FFA500").opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "FFD700"), lineWidth: 1)
        )
    }

    private var secondPlaceCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text("2")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "C0C0C0"))

                ZStack {
                    Circle()
                        .fill(Color.strideCard)

                    Text("S")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.strideText)
                }
                .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Text("Sarah Lee")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.strideText)

                    Text("48,900 steps")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            VStack(spacing: 4) {
                Text("2nd Place")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.strideText)

                Text("-3,520")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "C0C0C0"))
            }
            .padding(8)
            .background(Color.strideCard)
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color.strideCard.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C0C0C0"), lineWidth: 1)
        )
    }

    private var thirdPlaceCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text("3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "CD7F32"))

                ZStack {
                    Circle()
                        .fill(Color.strideCard)

                    Text("M")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.strideText)
                }
                .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Text("Mike Davis")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.strideText)

                    Text("46,300 steps")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            VStack(spacing: 4) {
                Text("3rd Place")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.strideText)

                Text("-6,120")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "CD7F32"))
            }
            .padding(8)
            .background(Color.strideCard)
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color.strideCard.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "CD7F32"), lineWidth: 1)
        )
    }

    private var userRankSection: some View {
        VStack(spacing: 12) {
            Text("Your Rank")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.strideSecondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(userRank)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.stridePrimary)

                    Text(authManager.userName ?? authManager.userEmail ?? "You")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.strideText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f", userScore))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.strideText)

                    Text(metricLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }
            .padding(16)
            .background(Color.strideCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.strideBorder, lineWidth: 1)
            )
        }
    }

    private var fullRankingList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Rankings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.strideText)

                Spacer()

                Text("Top 50")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)
            }

            VStack(spacing: 8) {
                ForEach(1...15, id: \.self) { index in
                    leaderboardRow(rank: index, name: "User \(index)", score: Double(55000 - index * 1000), isUser: index == userRank)
                }
            }
        }
    }

    private func leaderboardRow(rank: Int, name: String, score: Double, isUser: Bool) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("#\(rank)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isUser ? .stridePrimary : .strideSecondary)
                    .frame(width: 30, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(isUser ? Color.stridePrimary.opacity(0.2) : Color.strideCard)

                    Text(String(name.prefix(1)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.strideText)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.strideText)

                    Text(isUser ? "You" : "")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            Spacer()

            HStack(alignment: .center, spacing: 4) {
                Text(String(format: "%.0f", score))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isUser ? .stridePrimary : .strideText)

                if rank < 4 {
                    Image(systemName: "arrow.up.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.strideAccent)
                }
            }
        }
        .padding(12)
        .background(isUser ? Color.stridePrimary.opacity(0.1) : Color.strideCard)
        .cornerRadius(10)
        .overlay(
            isUser ?
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.stridePrimary, lineWidth: 1) : nil
        )
    }

    private var metricLabel: String {
        switch selectedMetric {
        case 0:
            return "steps"
        case 1:
            return "workouts"
        case 2:
            return "day streak"
        default:
            return "score"
        }
    }

    private func loadLeaderboard() {
        let metric = metrics[selectedMetric].lowercased()
        let period = periods[selectedPeriod].lowercased()
        supabaseManager.fetchLeaderboard(metric: metric, period: period) {
            print("Leaderboard loaded")
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(SupabaseManager())
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
