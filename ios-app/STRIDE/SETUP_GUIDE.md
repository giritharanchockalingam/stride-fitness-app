# STRIDE iOS App - Xcode Setup Guide

## Project Configuration

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new iOS App project
3. Product Name: **STRIDE**
4. Organization Identifier: **com.stride**
5. Interface: **SwiftUI**
6. Language: **Swift**

### Step 2: Copy Files

Copy all files from this directory into your Xcode project:

```
Your-Project/STRIDE/
├── STRIDEApp.swift
├── Services/
│   ├── Config.swift
│   ├── AuthManager.swift
│   ├── HealthKitManager.swift
│   └── SupabaseManager.swift
├── Views/
│   ├── LoginView.swift
│   ├── DashboardView.swift
│   ├── ActivityView.swift
│   ├── WorkoutView.swift
│   ├── LeaderboardView.swift
│   └── ProfileView.swift
└── Components/
    ├── ActivityRingView.swift
    ├── StatCardView.swift
    └── ActivityRowView.swift
```

### Step 3: Add Dependencies

Add these dependencies via Swift Package Manager (SPM):

**Charts Framework**:
1. File > Add Packages
2. Enter: `https://github.com/apple/swift-charts.git`
3. Up to next minor version (1.0.0...)
4. Add to target: STRIDE

### Step 4: Configure Info.plist

Add the following keys to Info.plist:

```xml
<key>NSHealthShareUsageDescription</key>
<string>STRIDE needs access to your fitness data to track your workouts and activity.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>STRIDE can save your workout data to Health.</string>

<key>NSHealthClinicalHealthRecordsShareUsageDescription</key>
<string>We need access to your health data to provide personalized fitness insights.</string>
```

### Step 5: Configure URL Schemes

1. Select project in Xcode
2. Select STRIDE target
3. Go to Info tab
4. Add URL Types:
   - Identifier: **com.stride.stridesync**
   - URL Schemes: **com.stride.stridesync** (add to list)

This enables OAuth callbacks from `com.stride.stridesync://callback`

### Step 6: Add HealthKit Capability

1. Select STRIDE target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Search and add: **HealthKit**

### Step 7: Verify Signing & Team

1. Select STRIDE target
2. Signing & Capabilities tab
3. Set Team to your development account
4. Ensure bundle identifier is: **com.stride.stridesync**

### Step 8: Configure Deployment Target

1. Select STRIDE target
2. General tab
3. Minimum Deployments: **iOS 15.0+**

### Step 9: Verify Build Settings

1. Select STRIDE target
2. Build Settings tab
3. Verify Swift Language Version: **Swift 5.7+**

## Supabase Configuration

### 1. Create Supabase Project

1. Go to https://supabase.com
2. Create new project
3. Default configuration is fine

### 2. Enable Google OAuth

1. In Supabase dashboard, go to Authentication > Providers
2. Enable Google
3. Add your OAuth Client ID and Client Secret (from Google Cloud Console)
4. Add Redirect URL: `com.stride.stridesync://callback`

### 3. Create Database Tables

Run these SQL commands in Supabase SQL Editor:

```sql
-- Profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    username TEXT UNIQUE,
    email TEXT,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Activities table
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    type TEXT NOT NULL,
    title TEXT,
    duration INTEGER,
    distance FLOAT,
    calories INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Workout Plans table
CREATE TABLE public.workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT,
    duration TEXT,
    intensity TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Workout Sessions table
CREATE TABLE public.workout_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    title TEXT,
    type TEXT,
    duration INTEGER,
    calories INTEGER,
    exercises_completed INTEGER,
    feeling TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Achievements table
CREATE TABLE public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User Achievements table
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    achievement_id UUID NOT NULL REFERENCES public.achievements(id),
    earned_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- Leaderboard Entries table
CREATE TABLE public.leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    metric TEXT NOT NULL,
    period TEXT NOT NULL,
    score FLOAT NOT NULL,
    rank INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Daily Stats table
CREATE TABLE public.daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    date DATE NOT NULL,
    steps INTEGER DEFAULT 0,
    calories FLOAT DEFAULT 0,
    distance FLOAT DEFAULT 0,
    active_minutes FLOAT DEFAULT 0,
    heart_rate INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    title TEXT NOT NULL,
    message TEXT,
    type TEXT,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. Enable Row Level Security (RLS)

For each table, enable RLS and add policies:

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_entries ENABLE ROW LEVEL SECURITY;

-- Allow public read on workout_plans
CREATE POLICY "Workout plans are readable by everyone"
    ON public.workout_plans FOR SELECT
    USING (true);

-- Allow users to read leaderboard
CREATE POLICY "Leaderboard is readable by everyone"
    ON public.leaderboard_entries FOR SELECT
    USING (true);

-- Allow users to read/write their own data
CREATE POLICY "Users can read their own data"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can read their own activities"
    ON public.activities FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own activities"
    ON public.activities FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

### 5. Create HealthKit Sync Edge Function

Create an edge function named `healthkit-sync`:

```typescript
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.4";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async (req) => {
  try {
    const { user_id, daily_stats, activities, heart_rate } = await req.json();

    // Insert daily stats
    if (daily_stats && daily_stats.length > 0) {
      await supabase
        .from("daily_stats")
        .upsert(daily_stats.map(stat => ({
          user_id,
          ...stat
        })), { onConflict: "user_id,date" });
    }

    // Insert activities
    if (activities && activities.length > 0) {
      await supabase
        .from("activities")
        .insert(activities.map(act => ({
          user_id,
          ...act
        })));
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { "Content-Type": "application/json" }, status: 400 }
    );
  }
});
```

## Build & Run

### Build for Simulator

```bash
xcodebuild -scheme STRIDE -configuration Debug -sdk iphonesimulator
```

### Build for Device

```bash
xcodebuild -scheme STRIDE -configuration Release -sdk iphoneos
```

### Run in Xcode

1. Select STRIDE scheme
2. Select target device/simulator (iOS 15.0+)
3. Press Cmd+R to build and run

**Note**: HealthKit only works on real devices. Simulator will return empty data.

## Testing Checklist

- [ ] Project builds without errors
- [ ] App launches and shows LoginView
- [ ] Can enter email and password
- [ ] Google sign-in button appears
- [ ] Dashboard loads after login
- [ ] Activity rings display
- [ ] Statistics load from HealthKit (device only)
- [ ] Charts render correctly
- [ ] Workout tab is functional
- [ ] Leaderboard displays
- [ ] Profile tab shows user info
- [ ] Settings tab works
- [ ] Sign out works

## Troubleshooting

### "Module 'Charts' not found"
- Add Charts dependency via SPM (see Step 3)
- Clean build folder: Cmd+Shift+K
- Rebuild project: Cmd+B

### HealthKit always returns 0
- Running on simulator? HealthKit needs real device
- Check permissions granted in Health app
- Verify app has HealthKit capability

### Google OAuth not working
- Verify URL scheme is set correctly
- Check Supabase redirect URL matches
- Ensure Google OAuth credentials are correct
- Test on physical device (simulator limited)

### API calls failing
- Verify Supabase URL in Config.swift
- Verify anon key is correct
- Check internet connectivity
- Verify RLS policies allow the operation

## Production Checklist

Before submitting to App Store:

1. [ ] Update app version number
2. [ ] Update build number
3. [ ] Test on multiple iOS versions (15.0+)
4. [ ] Test on multiple devices
5. [ ] Remove debug logging
6. [ ] Enable code signing with distribution certificate
7. [ ] Configure App Store Connect
8. [ ] Create App Store listing
9. [ ] Configure privacy policy
10. [ ] Add screenshots and descriptions
11. [ ] Submit for review

## Support

For issues:
1. Check Xcode build logs
2. Verify all configuration steps above
3. Check Supabase dashboard for API errors
4. Verify HealthKit permissions in Settings > Health > Data Access
