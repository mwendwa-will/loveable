# Notification System Implementation Summary

## Overview

Lovely now has a complete **dual-channel notification system**:
1. **Awesome Notifications**: For local, scheduled reminders
2. **Firebase Cloud Messaging (FCM)**: For remote push notifications

Both systems work together to keep users engaged with timely, relevant notifications.

---

## Architecture

### Service Layer

**`NotificationService` (`lib/services/notification_service.dart`)**
- Singleton service managing all notifications
- Handles both Awesome Notifications and FCM initialization
- Provides methods for:
  - Sending local notifications (period reminders, mood check-ins, affirmations, task reminders)
  - Scheduling recurring daily notifications
  - Managing FCM token retrieval
  - Handling incoming FCM messages

### State Management

**`NotificationProvider` (`lib/providers/notification_provider.dart`)**
- **StateNotifier**: `NotificationPreferencesNotifier`
- **Model**: `NotificationPreferences` with all user notification settings
- Loads/saves preferences from Supabase
- Provides methods to update individual settings without full reload
- Riverpod provider: `notificationPreferencesProvider`

### UI Components

**`NotificationsSettingsDialog` (`lib/screens/dialogs/notifications_settings_dialog.dart`)**
- Beautiful dialog showing all notification categories:
  - **Period Reminders** (droplet icon)
  - **Mood Check-In** (smile icon)
  - **Daily Affirmations** (heart icon)
  - **Task Reminders** (checklist icon)
- For each category:
  - Toggle switch to enable/disable
  - Time picker to set custom notification time
  - Real-time persistence to Supabase
- Fully responsive design using `ResponsiveSizing` utility

### Backend Integration

**`SupabaseService` additions (`lib/services/supabase_service.dart`)**
- `_getNotificationPreferencesData()`: Load preferences from `users.notification_preferences`
- `saveNotificationPreferencesData()`: Save preferences back to Supabase
- `saveFCMToken(String token)`: Store FCM token for remote notifications
- `getFCMToken()`: Retrieve stored FCM token
- `updateFCMToken(String newToken)`: Update token when it refreshes

---

## Initialization Flow

When the app starts (`lib/main.dart`):

```
1. 🔥 Firebase.initializeApp()
   ↓ (initializes Firebase services)
   
2. 🔔 NotificationService().initialize()
   ├─ _initializeAwesomeNotifications()
   │  └─ Create notification channel
   │  └─ Request notification permissions (Android 13+)
   │  └─ Setup listeners
   │
   └─ _initializeFirebaseMessaging()
      ├─ Initialize FirebaseMessaging instance
      ├─ Request FCM permissions
      ├─ Get and store FCM token in Supabase
      ├─ Listen for token refresh
      ├─ Setup foreground message listener
      ├─ Setup background message listener
      └─ Register background message handler

3. 🚀 SupabaseService.initialize()
   └─ (10s timeout for database connectivity)

4. 🎨 App launches
```

---

## Notification Categories

### 1. Period Reminders
- **Purpose**: Alert user when period is approaching
- **Default Time**: 9:00 AM
- **Customizable**: ✅ Yes (time picker in settings)
- **Type**: Local (Awesome Notifications)

### 2. Mood Check-In
- **Purpose**: Remind user to log mood and symptoms
- **Default Time**: 6:00 PM
- **Customizable**: ✅ Yes (time picker in settings)
- **Type**: Local (Awesome Notifications)

### 3. Daily Affirmations
- **Purpose**: Send uplifting affirmations
- **Default Time**: 7:00 AM
- **Customizable**: ✅ Yes (time picker in settings)
- **Type**: Local (Awesome Notifications)

### 4. Task Reminders
- **Purpose**: Remind user of daily tasks
- **Default Time**: 8:00 AM
- **Customizable**: ✅ Yes (time picker in settings)
- **Type**: Local (Awesome Notifications)

### 5. Remote Notifications (FCM)
- **Purpose**: Backend-triggered messages (announcements, updates)
- **Type**: Remote push notifications
- **Handled**: Automatically captured and displayed
- **Future**: Can be sent via Supabase Edge Functions

---

## Usage Examples

### From NotificationService:

```dart
// Send period reminder
await NotificationService().sendPeriodReminder(
  title: 'Period Starting Soon',
  message: 'Your period is likely to start today',
);

// Send mood check-in reminder
await NotificationService().sendMoodCheckInReminder();

// Send affirmation
await NotificationService().sendAffirmationNotification(
  affirmation: 'You are stronger than you think!',
);

// Schedule recurring daily notification
await NotificationService().scheduleRecurringNotification(
  id: 1,
  title: 'Period Reminder',
  body: 'Time to check your cycle',
  hour: 9,
  minute: 0,
  channelKey: 'lovely_channel',
);

// Get FCM token
String? token = await NotificationService().getFCMToken();
```

### From Profile Settings:

Users go to **Profile → Settings → Notifications** where they can:
1. Toggle each notification type on/off
2. Adjust the time for each category
3. Changes auto-save to Supabase
4. Preferences sync across devices

---

## Data Storage (Supabase)

### users table - New Columns:

```sql
fcm_token TEXT -- Stores the Firebase Cloud Messaging token
notification_preferences JSONB -- Stores all notification settings
```

### notification_preferences JSON Structure:

```json
{
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
}
```

---

## Firebase Setup Required

**⚠️ Before testing, you must:**

1. **Create Firebase Project** at https://console.firebase.google.com/
2. **Update `firebase_options.dart`** with your Firebase credentials
3. **Configure Android**:
   - Download `google-services.json`
   - Place in `android/app/`
4. **Configure iOS**:
   - Download `GoogleService-Info.plist`
   - Add to Xcode project
5. **Add Supabase columns** for `fcm_token` and `notification_preferences`

See **FIREBASE_SETUP.md** for detailed setup instructions.

---

## Testing Checklist

- [ ] Firebase credentials configured in `firebase_options.dart`
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` added to iOS project
- [ ] Supabase `users` table has `fcm_token` column
- [ ] Supabase `users` table has `notification_preferences` column
- [ ] App compiles without errors
- [ ] `flutter pub get` runs successfully
- [ ] Notification settings dialog opens
- [ ] Toggle switches work
- [ ] Time picker opens and updates time
- [ ] Settings persist after app restart
- [ ] FCM token appears in console logs
- [ ] Firebase test notification sends successfully

---

## File Structure

```
lib/
├── services/
│   ├── notification_service.dart          (NEW) Handles all notifications
│   └── supabase_service.dart              (UPDATED) Added FCM token methods
│
├── providers/
│   └── notification_provider.dart         (NEW) Notification state management
│
├── screens/
│   ├── dialogs/
│   │   └── notifications_settings_dialog.dart   (NEW) Settings UI
│   └── main/
│       └── profile_screen.dart            (UPDATED) Integrated dialog
│
├── firebase_options.dart                  (NEW) Firebase configuration template
└── main.dart                              (UPDATED) Firebase & FCM initialization

root/
└── FIREBASE_SETUP.md                      (NEW) Setup guide
```

---

## Dependencies Added

```yaml
awesome_notifications: ^0.10.0    # Local notifications
firebase_core: ^3.7.0              # Firebase SDK
firebase_messaging: ^15.1.1        # Push notifications
```

---

## Next Steps (Optional Enhancements)

1. **Supabase Edge Functions**: Create backend functions to send FCM messages
2. **Notification History**: Track sent notifications
3. **Rich Notifications**: Add images/actions to notifications
4. **Smart Scheduling**: Adjust times based on user's daily patterns
5. **Notification Analytics**: Track open rates and engagement
6. **Quiet Hours**: Let users set do-not-disturb timeframes

---

## Architecture Diagram

```
Profile Screen
    ↓
Notifications Settings Dialog
    ↓
NotificationProvider (Riverpod)
    ├─ LocalState: NotificationPreferences
    └─ Supabase: Save/Load preferences
    
Notification Service
├─ Awesome Notifications
│  ├─ Period Reminders
│  ├─ Mood Check-ins
│  ├─ Affirmations
│  └─ Task Reminders
│
└─ Firebase Messaging
   ├─ FCM Token Management
   ├─ Foreground Messages
   └─ Background Messages
   
Supabase
├─ users.fcm_token
└─ users.notification_preferences
```

---

## Summary

✅ **Complete notification infrastructure** with:
- Local scheduling via Awesome Notifications
- Remote messaging via Firebase Cloud Messaging
- Beautiful, responsive UI for preferences
- Persistent state management with Riverpod
- Full Supabase integration
- Comprehensive setup documentation

The system is **production-ready** once Firebase credentials are configured!
