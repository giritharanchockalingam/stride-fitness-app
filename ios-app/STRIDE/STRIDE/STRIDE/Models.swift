//
//  Models.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import Foundation

// MARK: - Auth Models

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let userMetadata: UserMetadata?

    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }
}

struct UserMetadata: Codable {
    let fullName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Profile

struct Profile: Codable, Identifiable {
    let id: String
    let email: String
    var fullName: String?
    var avatarUrl: String?
    var username: String?
    var bio: String?
    var fitnessLevel: String?
    var dailyStepGoal: Int?
    var dailyCalorieGoal: Int?
    var dailyActiveMinutesGoal: Int?
    var currentStreak: Int?
    var longestStreak: Int?
    var totalWorkouts: Int?
    var totalActivities: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, username, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case fitnessLevel = "fitness_level"
        case dailyStepGoal = "daily_step_goal"
        case dailyCalorieGoal = "daily_calorie_goal"
        case dailyActiveMinutesGoal = "daily_active_minutes_goal"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalWorkouts = "total_workouts"
        case totalActivities = "total_activities"
        case createdAt = "created_at"
    }
}

// MARK: - Activity

struct ActivityRecord: Codable, Identifiable {
    let id: String?
    let userId: String?
    let activityType: String
    var title: String?
    var description: String?
    let startedAt: String
    var endedAt: String?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var caloriesBurned: Double?
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var steps: Int?
    var isPublic: Bool?
    let createdAt: String?
    var provider: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case title, description
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case caloriesBurned = "calories_burned"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case steps
        case isPublic = "is_public"
        case createdAt = "created_at"
        case provider
    }

    var activityIcon: String {
        switch activityType.lowercased() {
        case "run", "running": return "figure.run"
        case "walk", "walking": return "figure.walk"
        case "cycle", "cycling": return "figure.outdoor.cycle"
        case "swim", "swimming": return "figure.pool.swim"
        case "hike", "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        case "strength": return "dumbbell.fill"
        case "hiit": return "flame.fill"
        default: return "figure.run"
        }
    }

    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "--" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDistance: String {
        guard let meters = distanceMeters, meters > 0 else { return "--" }
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }

    var timeAgo: String {
        guard let dateString = createdAt ?? Optional(startedAt),
              let date = ISO8601DateFormatter().date(from: dateString) else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        return "\(Int(interval / 604800))w ago"
    }
}

// MARK: - Daily Stats

struct DailyStats: Codable, Identifiable {
    let id: String?
    let userId: String?
    let date: String
    var totalSteps: Int?
    var totalCalories: Double?
    var activeMinutes: Int?
    var totalDistanceMeters: Double?
    var avgHeartRate: Int?
    var restingHeartRate: Int?
    var moveRingProgress: Double?
    var exerciseRingProgress: Double?
    var standRingProgress: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case totalSteps = "total_steps"
        case totalCalories = "total_calories"
        case activeMinutes = "active_minutes"
        case totalDistanceMeters = "total_distance_meters"
        case avgHeartRate = "avg_heart_rate"
        case restingHeartRate = "resting_heart_rate"
        case moveRingProgress = "move_ring_progress"
        case exerciseRingProgress = "exercise_ring_progress"
        case standRingProgress = "stand_ring_progress"
    }
}

// MARK: - Workout Plans

struct WorkoutPlan: Codable, Identifiable {
    let id: String
    let userId: String?
    let title: String
    var description: String?
    var category: String?
    var difficulty: String?
    var estimatedDurationMinutes: Int?
    var coverImageUrl: String?
    var isPublic: Bool?
    var isFeatured: Bool?
    var exercises: [WorkoutExercise]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, description, category, difficulty
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case coverImageUrl = "cover_image_url"
        case isPublic = "is_public"
        case isFeatured = "is_featured"
        case exercises
    }

    var categoryIcon: String {
        switch (category ?? "").lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio", "running": return "figure.run"
        case "hiit": return "flame.fill"
        case "flexibility", "yoga": return "figure.yoga"
        case "cycling": return "figure.outdoor.cycle"
        default: return "dumbbell.fill"
        }
    }

    var difficultyColor: String {
        switch (difficulty ?? "").lowercased() {
        case "beginner": return "34C759"
        case "intermediate": return "FF9500"
        case "advanced": return "FF3B30"
        default: return "007AFF"
        }
    }
}

struct WorkoutExercise: Codable, Identifiable {
    let id: String
    let planId: String?
    let exerciseName: String
    var exerciseType: String?
    var sets: Int?
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?
    var restSeconds: Int?
    var sortOrder: Int
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case exerciseName = "exercise_name"
        case exerciseType = "exercise_type"
        case sets, reps
        case weightKg = "weight_kg"
        case durationSeconds = "duration_seconds"
        case restSeconds = "rest_seconds"
        case sortOrder = "sort_order"
        case notes
    }
}

// MARK: - Workout Sessions

struct WorkoutSession: Codable, Identifiable {
    let id: String?
    let userId: String?
    var planId: String?
    let title: String
    let startedAt: String
    var endedAt: String?
    var durationSeconds: Int?
    var caloriesBurned: Double?
    var avgHeartRate: Int?
    var feeling: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planId = "plan_id"
        case title
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case caloriesBurned = "calories_burned"
        case avgHeartRate = "avg_heart_rate"
        case feeling, notes
    }
}

// MARK: - Achievement

struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    var description: String?
    var icon: String?
    var category: String?
    var thresholdValue: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, category
        case thresholdValue = "threshold_value"
    }

    var displayIcon: String {
        switch (icon ?? "").lowercased() {
        case "steps": return "figure.walk"
        case "fire", "streak": return "flame.fill"
        case "trophy", "medal": return "trophy.fill"
        case "heart": return "heart.fill"
        case "distance": return "location.fill"
        case "workout": return "dumbbell.fill"
        default: return "star.fill"
        }
    }
}

struct UserAchievement: Codable, Identifiable {
    let id: String
    let userId: String
    let achievementId: String
    let earnedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case earnedAt = "earned_at"
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    var periodType: String?
    var periodStart: String?
    var totalSteps: Int?
    var totalCalories: Double?
    var totalDistanceMeters: Double?
    var totalWorkouts: Int?
    var totalActiveMinutes: Int?
    var rank: Int?
    var userName: String?
    var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case periodType = "period_type"
        case periodStart = "period_start"
        case totalSteps = "total_steps"
        case totalCalories = "total_calories"
        case totalDistanceMeters = "total_distance_meters"
        case totalWorkouts = "total_workouts"
        case totalActiveMinutes = "total_active_minutes"
        case rank
        case userName = "user_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Notification

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    var type: String?
    let title: String
    var body: String?
    var isRead: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, body
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Heart Rate

struct HeartRateReading: Codable, Identifiable {
    let id: String?
    let userId: String?
    var activityId: String?
    let bpm: Int
    let recordedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case bpm
        case recordedAt = "recorded_at"
    }
}
