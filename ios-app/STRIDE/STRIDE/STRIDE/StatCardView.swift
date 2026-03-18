//
//  StatCardView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct StatCardView: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    var trendArrow: String?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)

                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer(minLength: 0)

            if let arrow = trendArrow {
                Image(systemName: arrow)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(arrow.contains("up") ? Config.Colors.distanceGreen : Config.Colors.heartRed)
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

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            StatCardView(icon: "figure.walk", value: "8,234", unit: "steps", label: "Steps", color: Config.Colors.stepsRing, trendArrow: "arrow.up.right")
            StatCardView(icon: "flame.fill", value: "342", unit: "kcal", label: "Calories", color: Config.Colors.orangeGradient)
        }
        HStack(spacing: 12) {
            StatCardView(icon: "heart.fill", value: "72", unit: "bpm", label: "Avg HR", color: Config.Colors.heartRed)
            StatCardView(icon: "location.fill", value: "5.2", unit: "km", label: "Distance", color: Config.Colors.distanceGreen)
        }
    }
    .padding()
    .background(Config.Colors.darkBackground)
}
