# STRIDE - Strava-Style Fitness Tracker iOS App

A production-quality dark-themed fitness tracking application built in SwiftUI that connects to HealthKit and Supabase backend.

## Architecture Overview

### Directory Structure
```
STRIDE/
├── STRIDEApp.swift              # App entry point with tab navigation
├── Services/
│   ├── Config.swift             # Supabase config & theme colors
│   ├── AuthManager.swift        # Authentication (Email, Google OAuth)
│   ├── HealthKitManager.swift   # HealthKit integration
│   └── SupabaseManager.swift    # REST API client
├── Views/
│   ├── LoginView.swift          # Authentication UI
│   ├── DashboardView.swift      # Home tab with activity overview
│   ├── ActivityView.swift       # Activity stats & charts
│   ├── WorkoutView.swift        # Workout tracking
│   ├── LeaderboardView.swift    # Competitive rankings
│   └── ProfileView.swift        # User profile & settings
└── Components/
    ├── ActivityRingView.swift   # Custom activity ring visualization
    ├── StatCardView.swift       # Reusable stat card
    └── ActivityRowView.swift    # Activity list item
```

## Features

### Authentication
- **Email/Password Sign-in**: Direct authentication via Supabase
- **Google OAuth**: ASWebAuthenticationSession-based OAuth flow with callback scheme `com.stride.stridesync`
- **Persistent Sessions**: Token storage in UserDefaults

### HealthKit Integration
- **Data Collection**:
  - Step count
  - Active energy burned (calories)
  - Distance (walking/running + cycling)
  - Heart rate (instantaneous & readings)
  - Active exercise time
  - Workouts

- **Sync Operations**:
  - Automatic sync on app launch
  - Sync when returning to foreground
  - Manual sync button in Profile settings
  - Sends 14 days of daily stats + activities + heart rate readings

### Dashboard (Home Tab)
- Time-based greeting (Good Morning/Afternoon/Evening/Night)
- Current streak display with fire emoji
- Activity rings (Move/Exercise/Steps) with progress
- Quick stats grid: Steps, Calories, Heart Rate, Distance
- Weekly steps bar chart
- Recent activities list
- Featured workout plans

### Activity Tab
- Large activity rings with percentage indicator
- Time range selector (Day/Week/Month)
- Metric tabs (Steps/Calories/Heart Rate/Distance)
- Interactive charts using SwiftUI Charts framework
- All activities list with filtering

### Workout Tab
- Quick Start banner for fast workout creation
- Category filters (All/Strength/Cardio/HIIT/Flexibility)
- Browse workout plans from Supabase
- Active workout interface with:
  - Stopwatch timer (hours:minutes:seconds)
  - Exercise checklist
  - Calories burned counter
  - Feeling selector on completion
  - Save to Supabase

### Leaderboard Tab
- Period selector (Weekly/Monthly/All Time)
- Metric pills (Steps/Workouts/Streak)
- Top 3 podium with medal colors (Gold/Silver/Bronze)
- Full ranking list (top 50)
- User's rank highlighted
- Real-time leaderboard from Supabase

### Profile Tab
- User avatar with initial
- Stats row (Workouts/Activities/Streak)
- Streak calendar for current month
- Segmented tabs:
  - **Achievements**: 6 unlockable badges
  - **Stats**: Lifetime statistics
  - **Settings**: Profile/goals/HealthKit sync/sign out
- Health data sync button

## Design System

### Colors
- **Background**: `#0a0a0a` (near black)
- **Cards**: `#141414` (dark gray)
- **Borders**: `#2C2C2E` (subtle gray)
- **Primary**: `#FC4C02` → `#FF6B35` (orange gradient)
- **Accent**: `#00D4AA` (teal green)
- **Blue**: `#007AFF` (iOS default)
- **Text**: White, Gray (#8E8E93), Tertiary (#636366)

### Typography
- System San Francisco font family
- Heavy (700) and Bold (600) weights for headers
- Regular (400) for body text
- Monospaced for timer displays

### Component Patterns
- 16-20pt corner radius on cards
- 12-16px padding inside cards
- 1px borders with `strideBorder` color
- Gradient overlays for CTAs
- SF Symbols for all icons

## API Integration

### Supabase Endpoints
Base URL: `https://ecylmwvutlxgqivhrxdc.supabase.co`

**Tables (accessed via REST `/rest/v1/`)**:
- `profiles`: User account information
- `activities`: Past workouts & exercises
- `workout_plans`: Available workout templates
- `workout_sessions`: Saved workout records
- `achievements`: Badge definitions
- `user_achievements`: Earned badges per user
- `notifications`: User notifications
- `leaderboard_entries`: Ranked users
- `daily_stats`: Historical daily summaries

**Edge Functions (accessed via `/functions/v1/`)**:
- `healthkit-sync`: POST 14 days of HealthKit data
  - Body: `{ user_id, daily_stats, activities, heart_rate }`
  - Auth: Bearer token + fallback user_id

### Auth Flow
1. **Email/Password**:
   ```
   POST /auth/v1/token?grant_type=password
   Body: { email, password }
   Response: { access_token, user: { id, ... } }
   ```

2. **Google OAuth**:
   ```
   GET /auth/v1/authorize?provider=google&redirect_to=com.stride.stridesync://callback
   Callback parses: com.stride.stridesync://callback#access_token=...&...
   ```

## State Management

### AuthManager (Observable)
- `isAuthenticated`, `userId`, `accessToken`
- `userEmail`, `userName`, `errorMessage`
- Methods: `signInWithEmail()`, `signInWithGoogle()`, `signOut()`

### HealthKitManager (Observable)
- `todaySteps`, `todayCalories`, `todayDistance`, `todayHeartRate`, `todayActiveMinutes`
- `weeklySteps`, `heartRateReadings`
- Methods: `requestAuthorization()`, `fetchTodayStats()`, `fetchWeeklyStats()`, `syncToSupabase()`

### SupabaseManager (Observable)
- Published arrays: `activities`, `workoutPlans`, `achievements`, `leaderboardEntries`, etc.
- Methods: `query()`, `insert()`, `update()`, `fetch*()` family

## HealthKit Permissions

Required in Info.plist:
```xml
<key>NSHealthShareUsageDescription</key>
<string>STRIDE needs access to your fitness data to track your workouts and activity.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>STRIDE can save your workout data to Health.</string>
```

## OAuth Configuration

1. **Callback Scheme**: `com.stride.stridesync://` (configure in Xcode project settings)
2. **Google OAuth Setup**: Configure in Supabase Project Settings > Auth > Google
3. **ASWebAuthenticationSession**: Handles redirect with `ASWebAuthenticationPresentationContextProviding`

## Performance Optimizations

- Lazy loading of activity lists with `.prefix(3)` for dashboard
- DispatchGroup for parallel HealthKit queries
- Charts use SwiftUI Charts framework for efficient rendering
- Tab-based navigation prevents unnecessary view reloads
- Color(hex:) uses efficient Scanner-based parsing

## Error Handling

- Network errors caught and displayed in UI
- HealthKit authorization failures logged
- JWT token refresh handled via stored credentials
- API errors propagated to completion handlers

## Testing Recommendations

1. **On Real Device**: HealthKit requires physical device
2. **Simulator**: API calls work, HealthKit returns empty
3. **Test Accounts**: Create via Supabase dashboard
4. **Google OAuth**: Test on physical device with Google Play Services

## Future Enhancements

- Offline data caching with Core Data
- Real-time notifications with Push
- Social features (friend challenges, activity sharing)
- Advanced analytics dashboard
- Custom workout plan builder
- Integration with Strava API
- Apple Watch companion app
