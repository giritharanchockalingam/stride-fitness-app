import SwiftUI

struct StatCardView: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let trend: String?

    init(icon: String, label: String, value: String, unit: String, color: Color = .stridePrimary, trend: String? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.unit = unit
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.strideSecondary)

                    if let trend = trend {
                        Text(trend)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.strideAccent)
                    }
                }

                Spacer()
            }

            HStack(alignment: .baseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.strideText)

                Text(unit)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.strideSecondary)

                Spacer()
            }
        }
        .padding(16)
        .background(Color.strideCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.strideBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.strideBackground
            .ignoresSafeArea()

        VStack(spacing: 12) {
            StatCardView(icon: "figure.walk", label: "Steps", value: "8,234", unit: "steps", color: .strideBlue)
            StatCardView(icon: "flame.fill", label: "Calories", value: "324", unit: "kcal", color: .stridePrimary, trend: "+12% from yesterday")
            StatCardView(icon: "heart.fill", label: "Heart Rate", value: "72", unit: "bpm", color: .red)
        }
        .padding(16)
    }
}
