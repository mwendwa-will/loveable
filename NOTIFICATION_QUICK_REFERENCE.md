# Notification System Quick Reference

## 🚀 Quick Setup (5 minutes)

1. **Configure Firebase**:
   ```dart
   // lib/firebase_options.dart
   // Replace YOUR_* placeholders with actual Firebase credentials
   ```

2. **Run pub get**:
   ```bash
   flutter pub get
   ```

3. **Add Supabase columns**:
   ```sql
   ALTER TABLE users ADD COLUMN fcm_token TEXT;
   ALTER TABLE users ADD COLUMN notification_preferences JSONB;
   ```

4. **Test**:
   ```bash
   flutter run
   # Go to Profile → Settings → Notifications
   ```

---

## 📱 Send a Notification (Code Examples)

### Local Notification
```dart
import 'package:lovely/services/notification_service.dart';

// Send immediately
await NotificationService().sendMoodCheckInReminder();

// Schedule for specific time
await NotificationService().scheduleRecurringNotification(
  id: 1,
  title: 'Time for Check-In',
  body: 'How are you feeling?',
  hour: 14,
  minute: 30,
  channelKey: 'lovely_channel',
);
```

### Remote Notification (From Supabase Edge Function)
```typescript
// Supabase Edge Function
const response = await fetch(
  'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send',
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: userFcmToken,
        notification: {
          title: 'Your Period is Starting Soon',
          body: 'Track your cycle in Lovely',
        },
      },
    }),
  }
);
```

---

## 🎛️ Notification Types

| Type | Icon | Default Time | Customizable |
|------|------|--------------|--------------|
| Period Reminders | 💧 | 9:00 AM | ✅ |
| Mood Check-In | 😊 | 6:00 PM | ✅ |
| Affirmations | ❤️ | 7:00 AM | ✅ |
| Task Reminders | ✓ | 8:00 AM | ✅ |

---

## 🔧 Key Classes & Methods

### NotificationService
```dart
// Initialization
await NotificationService().initialize();

// Send notifications
await NotificationService().sendPeriodReminder(title, message);
await NotificationService().sendMoodCheckInReminder();
await NotificationService().sendAffirmationNotification(affirmation);
await NotificationService().sendTaskReminder(taskTitle);

// Schedule notifications
await NotificationService().scheduleNotification(...);
await NotificationService().scheduleRecurringNotification(...);

// Manage notifications
await NotificationService().cancelAllNotifications();
await NotificationService().cancelNotification(id);

// FCM
String? token = await NotificationService().getFCMToken();
```

### NotificationProvider (Riverpod)
```dart
// Watch preferences in UI
final preferences = ref.watch(notificationPreferencesProvider);

// Update preferences
ref.read(notificationPreferencesProvider.notifier).togglePeriodReminders(true);
ref.read(notificationPreferencesProvider.notifier).setPeriodReminderTime(9, 0);
```

### SupabaseService
```dart
// FCM Token
await SupabaseService().saveFCMToken(token);
String? token = await SupabaseService().getFCMToken();
await SupabaseService().updateFCMToken(newToken);

// Preferences
await SupabaseService().saveNotificationPreferencesData(map);
Map? prefs = await SupabaseService()._getNotificationPreferencesData();
```

---

## 📊 Database Schema

```sql
-- Add to users table
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

---

## 🐛 Troubleshooting

**Problem**: Firebase initialization error
```
Solution: Check firebase_options.dart has correct credentials
```

**Problem**: FCM token not saving
```
Solution: Verify user is authenticated & Supabase columns exist
```

**Problem**: Notifications not showing on Android
```
Solution: 
  1. Settings → Apps → Lovely → Notifications → Allow
  2. Disable battery saver
  3. Check notification channel in Firebase Console
```

**Problem**: Notifications not showing on iOS
```
Solution:
  1. Check APNs certificate uploaded to Firebase
  2. Verify GoogleService-Info.plist in Xcode
  3. Settings → Notifications → Lovely → Allow
```

---

## 📚 Documentation

- **Full Setup Guide**: `FIREBASE_SETUP.md`
- **Architecture Overview**: `NOTIFICATION_SYSTEM.md`
- **Awesome Notifications Docs**: https://pub.dev/packages/awesome_notifications
- **Firebase Flutter Docs**: https://firebase.flutter.dev/

---

## ✅ Checklist Before Going Live

- [ ] Firebase project created
- [ ] `firebase_options.dart` configured
- [ ] `android/app/google-services.json` added
- [ ] iOS `GoogleService-Info.plist` added
- [ ] Supabase columns created
- [ ] Test notifications work locally
- [ ] FCM token appears in logs
- [ ] Notifications persist across app restarts
- [ ] Profile → Notifications settings accessible
- [ ] Toggle & time picker fully functional

---

## 🎯 Common Tasks

### Add a New Notification Type
1. Add fields to `NotificationPreferences` model
2. Add toggle switch to settings dialog
3. Add method to `NotificationService`
4. Add state management to `NotificationProvider`
5. Update Supabase JSON default value

### Send Notification from Backend
1. Query user's FCM token from Supabase
2. Use Firebase Admin SDK or FCM REST API
3. Target user's token with message payload
4. App will automatically display notification

### Change Default Notification Time
```dart
// In notification_provider.dart NotificationPreferences constructor
affirmationHour = 7,    // Change to desired hour
affirmationMinute = 0,  // Change to desired minute
```

---

**Last Updated**: January 2026  
**Status**: Production Ready (after Firebase setup)  
**Maintainer**: Lovely Dev Team
