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
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(unit)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if let arrow = trendArrow {
                    Image(systemName: arrow)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(arrow.contains("up") ? .green : .red)
                }
            }
            .padding(12)
            .background(Color(hex: "141414"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
            )
        }
    }
}

#Preview {
    StatCardView(
        icon: "figure.walk",
        value: "8,234",
        unit: "steps",
        label: "Steps",
        color: Color(hex: "007AFF"),
        trendArrow: "arrow.up.right"
    )
    .padding()
    .background(Color(hex: "0a0a0a"))
}
