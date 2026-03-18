//
//  ActivityRowView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct ActivityRowView: View {
    let title: String
    let duration: Int
    let distance: Double
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "FC4C02"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "FC4C02").opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(getTimeAgoString())
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", distance))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(duration)m")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
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

    private func getTimeAgoString() -> String {
        return "2 hours ago"
    }
}

#Preview {
    ActivityRowView(
        title: "Morning Run",
        duration: 45,
        distance: 5.2,
        icon: "figure.run"
    )
    .padding()
    .background(Color(hex: "0a0a0a"))
}
