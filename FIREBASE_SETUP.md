# Firebase & FCM Integration Guide

This document outlines the setup required to enable Firebase Cloud Messaging (FCM) for the Lovely app.

## Overview

The Lovely app uses a dual notification system:
- **Awesome Notifications**: Local notifications (reminders, scheduled tasks)
- **Firebase Cloud Messaging (FCM)**: Remote push notifications from the server

## Setup Steps

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Lovely"
3. Enable Google Analytics (optional)
4. Wait for the project to be created

### 2. Register Your App

#### Android Setup

1. In Firebase Console, click "Add App" → Select Android
2. Enter Package Name: `com.lovely.app`
3. Enter SHA-1 Certificate Hash (get via: `keytool -list -v -keystore ~/.android/debug.keystore` on macOS/Linux or find in Android Studio)
4. Click "Register app"
5. Download `google-services.json`
6. Move the file to: `android/app/google-services.json`

#### iOS Setup

1. In Firebase Console, click "Add App" → Select iOS
2. Enter Bundle ID: `com.lovely.app`
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Drag and drop the plist file into Xcode (ensure "Copy items if needed" is checked)
7. Make sure the file is added to the Runner target

### 3. Update Firebase Configuration

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your Firebase project credentials:
   - Find your credentials in Firebase Console → Project Settings
   - Copy API Keys and other values for web, Android, and iOS

Example for Android:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyD...',
  appId: '1:123456789:android:abc123def456...',
  messagingSenderId: '123456789',
  projectId: 'lovely-app',
  storageBucket: 'lovely-app.appspot.com',
);
```

### 4. Configure Cloud Messaging

1. In Firebase Console, go to **Cloud Messaging**
2. Note your **Server API Key** (you'll need this to send messages)
3. For iOS, upload your APNs certificate (if testing on iOS)

## Notification Flows

### Local Notifications (Awesome Notifications)

These are automatically scheduled based on user preferences:
- **Period Reminders**: Notify user when period is likely to start
- **Mood Check-In**: Daily reminder to log mood/symptoms
- **Affirmations**: Daily affirmation message
- **Task Reminders**: Reminders for daily tasks

User can configure timing in Profile → Settings → Notifications

### Remote Notifications (FCM)

Push notifications sent from the backend to users. The app automatically:
1. Captures the FCM token on first launch
2. Stores it in Supabase (`users.fcm_token`)
3. Listens for incoming messages
4. Displays notifications both in foreground and background

## Testing FCM

### Using Firebase Console

1. Go to Cloud Messaging in Firebase Console
2. Click "Send your first message"
3. Enter Title and Body
4. Select "Send to a topic" or specific device
5. Click "Send"

### Using Supabase Functions (Recommended)

Create an Edge Function in Supabase to send notifications to user's FCM token:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as admin from "https://www.googleapis.com/service_account/v1"

const fcmUrl = "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send"

serve(async (req) => {
  const { title, body, userIds } = await req.json()

  // Get user FCM tokens from database
  const { data: users } = await supabase
    .from('users')
    .select('fcm_token')
    .in('id', userIds)

  // Send FCM message to each user
  for (const user of users) {
    if (user.fcm_token) {
      await fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getAccessToken()}`,
        },
        body: JSON.stringify({
          message: {
            token: user.fcm_token,
            notification: {
              title,
              body,
            },
          },
        }),
      })
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

## Troubleshooting

### FCM Token Not Saving

1. Check if user is authenticated
2. Verify Supabase `users` table has `fcm_token` column
3. Check console logs for errors

### Notifications Not Showing

**Android:**
- Check notification settings: Settings → Apps → Lovely → Notifications
- Ensure "Allow notifications" is enabled
- Check battery saver isn't blocking notifications

**iOS:**
- Check Notification Center settings
- Verify APNs certificate is uploaded to Firebase
- Check app has notification permissions

### Firebase Initialization Error

1. Ensure `google-services.json` is in `android/app/`
2. Ensure `GoogleService-Info.plist` is added to Xcode project
3. Run `flutter clean` and rebuild

## Database Schema

Add these columns to the `users` table in Supabase:

```sql
ALTER TABLE users ADD COLUMN fcm_token TEXT;
ALTER TABLE users ADD COLUMN notification_preferences JSONB DEFAULT '{
  "periodRemindersEnabled": true,
  "periodReminderHour": 9,
  "periodReminderMinute": 0,
  "moodCheckInEnabled": true,
  "moodCheckInHour": 18,
  "moodCheckInMinute": 0,
  "affirmationsEnabled": true,
  "affirmationHour": 7,
  "affirmationMinute": 0,
  "taskRemindersEnabled": true,
  "taskReminderHour": 8,
  "taskReminderMinute": 0
}'::jsonb;
```

## Next Steps

1. Configure Firebase credentials in `firebase_options.dart`
2. Add FCM token and notification_preferences columns to Supabase
3. Test notifications using Firebase Console
4. (Optional) Set up Supabase Edge Functions for backend-triggered notifications

## References

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Awesome Notifications](https://pub.dev/packages/awesome_notifications)
