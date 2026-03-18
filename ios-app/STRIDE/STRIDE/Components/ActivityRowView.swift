import SwiftUI

struct ActivityRowView: View {
    let type: String
    let title: String
    let timeAgo: String
    let distance: Double?
    let duration: Int
    let calories: Int?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(activityColor)
                .frame(width: 40, height: 40)
                .background(activityColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.strideText)

                HStack(spacing: 8) {
                    Text(timeAgo)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    if let distance = distance {
                        Text("• \(String(format: "%.1f", distance)) km")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.strideSecondary)
                    }

                    Text("• \(formatDuration(duration))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let calories = calories {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.stridePrimary)

                        Text("\(calories)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.strideText)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.strideSecondary)
            }
        }
        .padding(12)
        .background(Color.strideCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.strideBorder, lineWidth: 1)
        )
    }

    private var activityIcon: String {
        switch type.lowercased() {
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "walking":
            return "figure.walk"
        case "swimming":
            return "figure.pool.swim"
        case "strength", "weights":
            return "dumbbell.fill"
        case "yoga":
            return "figure.yoga"
        case "hiit":
            return "figure.stairs"
        default:
            return "heart.fill"
        }
    }

    private var activityColor: Color {
        switch type.lowercased() {
        case "running":
            return .strideBlue
        case "cycling":
            return .strideAccent
        case "walking":
            return Color(hex: "34C759")
        case "swimming":
            return Color(hex: "00B4D8")
        case "strength", "weights":
            return .stridePrimary
        case "yoga":
            return Color(hex: "FF9500")
        case "hiit":
            return Color(hex: "FF3B30")
        default:
            return .red
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

#Preview {
    ZStack {
        Color.strideBackground
            .ignoresSafeArea()

        VStack(spacing: 12) {
            ActivityRowView(
                type: "running",
                title: "Morning Run",
                timeAgo: "2 hours ago",
                distance: 5.2,
                duration: 42,
                calories: 520
            )

            ActivityRowView(
                type: "cycling",
                title: "Afternoon Ride",
                timeAgo: "5 hours ago",
                distance: 15.8,
                duration: 65,
                calories: 680
            )

            ActivityRowView(
                type: "strength",
                title: "Weight Training",
                timeAgo: "1 day ago",
                distance: nil,
                duration: 45,
                calories: 350
            )
        }
        .padding(16)
    }
}
