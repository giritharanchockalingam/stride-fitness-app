# STRIDE Sync — iOS Companion App

Native iOS companion app that syncs Apple Health data to your STRIDE fitness dashboard.

## What it syncs
- **Daily stats**: Steps, calories, distance, active minutes, heart rate (14 days)
- **Workouts**: Running, walking, cycling, swimming, hiking, yoga (14 days)
- **Heart rate**: Today's readings (up to 100 samples)
- **Streak**: Auto-calculates your current streak

## Setup in Xcode

1. Open Xcode → **File → New → Project → iOS App**
2. Name: `STRIDESync`, Interface: **SwiftUI**, Language: **Swift**
3. Replace the generated files with the files in `STRIDESync/STRIDESync/`
4. In **Signing & Capabilities**:
   - Add **HealthKit** capability (check "Background Delivery")
   - Add **Background Modes** (check "Background fetch" and "Background processing")
5. Build and run on your iPhone (HealthKit requires a real device, not simulator)

## Usage
1. Open STRIDESync on your iPhone
2. Sign in with the same email/password as your STRIDE web account
3. Tap "Enable HealthKit" and approve all health data permissions
4. Tap "Sync to STRIDE" — your data appears on the web dashboard instantly

## Architecture
```
iPhone (HealthKit) → STRIDESync App → Supabase Edge Function → Supabase DB → STRIDE Web App
```

The app reads HealthKit data using native iOS APIs and posts it as JSON to a Supabase Edge Function (`healthkit-sync`), which writes it to the same database tables the web app reads from.
