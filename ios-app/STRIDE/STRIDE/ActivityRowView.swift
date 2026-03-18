//
//  ActivityRowView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct ActivityRowView: View {
    let activity: ActivityRecord

    var body: some View {
        HStack(spacing: 14) {
            // Activity Type Icon
            Image(systemName: activity.activityIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Config.Colors.primaryOrange)
                .frame(width: 42, height: 42)
                .background(Config.Colors.primaryOrange.opacity(0.12))
                .cornerRadius(10)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title ?? activity.activityType.capitalized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    if !activity.timeAgo.isEmpty {
                        Text(activity.timeAgo)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    if activity.durationSeconds != nil {
                        Text(activity.formattedDuration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    if activity.distanceMeters != nil && (activity.distanceMeters ?? 0) > 0 {
                        Text(activity.formattedDistance)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Calories
            if let cal = activity.caloriesBurned, cal > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(cal))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Config.Colors.orangeGradient)
                    Text("kcal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 8) {
        ActivityRowView(activity: ActivityRecord(
            id: "1",
            userId: nil,
            activityType: "running",
            title: "Morning Run",
            startedAt: ISO8601DateFormatter().string(from: Date()),
            durationSeconds: 1800,
            distanceMeters: 5200,
            caloriesBurned: 342,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        ))

        ActivityRowView(activity: ActivityRecord(
            id: "2",
            userId: nil,
            activityType: "yoga",
            title: "Evening Yoga",
            startedAt: ISO8601DateFormatter().string(from: Date()),
            durationSeconds: 2400,
            caloriesBurned: 120,
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        ))
    }
    .padding()
    .background(Config.Colors.darkBackground)
}
