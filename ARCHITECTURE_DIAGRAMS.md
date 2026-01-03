# 🎯 Notification System - Complete Architecture Diagram

## System Overview

```
╔════════════════════════════════════════════════════════════════════════════════╗
║                      LOVELY NOTIFICATION SYSTEM                               ║
║                     (Awesome + Firebase Dual-Channel)                          ║
╚════════════════════════════════════════════════════════════════════════════════╝

┌────────────────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE LAYER                                  │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  Profile Screen                                                               │
│  └── Settings                                                                 │
│      └── Notifications                                                        │
│          └── NotificationsSettingsDialog                                      │
│              ├─ Period Reminders [Toggle] [TimePicker]                       │
│              ├─ Mood Check-In [Toggle] [TimePicker]                          │
│              ├─ Affirmations [Toggle] [TimePicker]                           │
│              └─ Task Reminders [Toggle] [TimePicker]                         │
│                                                                               │
└────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Riverpod Watch/Read
                                    ↓
┌────────────────────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT LAYER (Riverpod)                           │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  notificationPreferencesProvider: StateNotifierProvider<NotificationPreferences>
│  │                                                                             │
│  └─ NotificationPreferencesNotifier                                          │
│     ├─ State: NotificationPreferences                                         │
│     │   ├─ periodRemindersEnabled: bool                                      │
│     │   ├─ periodReminderHour: int (0-23)                                   │
│     │   ├─ periodReminderMinute: int (0-59)                                 │
│     │   ├─ moodCheckInEnabled: bool                                         │
│     │   ├─ moodCheckInHour: int (0-23)                                      │
│     │   ├─ moodCheckInMinute: int (0-59)                                    │
│     │   ├─ affirmationsEnabled: bool                                         │
│     │   ├─ affirmationHour: int (0-23)                                      │
│     │   ├─ affirmationMinute: int (0-59)                                    │
│     │   ├─ taskRemindersEnabled: bool                                        │
│     │   ├─ taskReminderHour: int (0-23)                                     │
│     │   └─ taskReminderMinute: int (0-59)                                   │
│     │                                                                         │
│     └─ Methods:                                                               │
│        ├─ loadPreferences()                                                   │
│        ├─ updatePreferences()                                                 │
│        ├─ togglePeriodReminders()                                            │
│        ├─ setPeriodReminderTime()                                            │
│        ├─ toggleMoodCheckIn()                                                │
│        ├─ setMoodCheckInTime()                                               │
│        ├─ toggleAffirmations()                                               │
│        ├─ setAffirmationTime()                                               │
│        ├─ toggleTaskReminders()                                              │
│        └─ setTaskReminderTime()                                              │
│                                                                               │
└────────────────────────────────────────────────────────────────────────────────┘
                                    │
                      ┌─────────────┴─────────────┐
                      │                           │
        Read/Write Data                    Request Token
                      │                           │
                      ↓                           ↓
┌──────────────────────────────┐    ┌────────────────────────────────────┐
│   SERVICE LAYER              │    │  NOTIFICATION SERVICE LAYER       │
├──────────────────────────────┤    ├────────────────────────────────────┤
│                              │    │                                    │
│  SupabaseService             │    │  NotificationService               │
│  │                           │    │  │                                 │
│  ├─ saveFCMToken()           │    │  ├─ initialize()                   │
│  ├─ getFCMToken()            │    │  │  ├─ _initializeAwesomeNotif()  │
│  ├─ updateFCMToken()         │    │  │  └─ _initializeFirebaseMessaging()
│  ├─ saveNotificationPref...()│    │  │                                 │
│  └─ _getNotificationPref...()│    │  ├─ sendPeriodReminder()          │
│                              │    │  ├─ sendMoodCheckInReminder()     │
│                              │    │  ├─ sendAffirmationNotification() │
│                              │    │  ├─ sendTaskReminder()            │
│                              │    │  │                                 │
│                              │    │  ├─ scheduleNotification()        │
│                              │    │  ├─ scheduleRecurringNotification│
│                              │    │  │                                │
│                              │    │  ├─ cancelNotification()          │
│                              │    │  ├─ cancelAllNotifications()      │
│                              │    │  │                                │
│                              │    │  ├─ getFCMToken()                 │
│                              │    │  └─ isNotificationAllowed()       │
│                              │    │                                    │
└──────────────────────────────┘    └────────────────────────────────────┘
                      │                           │
                      │                  ┌────────┴──────────┐
                      │                  │                   │
                      ↓                  ↓                   ↓
        ┌────────────────────┐  ┌──────────────────┐  ┌────────────────┐
        │  Supabase          │  │ Awesome          │  │ Firebase       │
        │  PostgreSQL        │  │ Notifications    │  │ Cloud          │
        │                    │  │                  │  │ Messaging      │
        │ users table:       │  │ ├─ Local notif.  │  │                │
        │ ├─ id              │  │ │   display      │  │ ├─ Token mgmt  │
        │ ├─ fcm_token       │  │ ├─ Schedule      │  │ ├─ Message     │
        │ └─ notification_   │  │ │   recurring    │  │ │  listeners   │
        │   preferences      │  │ ├─ Sound/        │  │ ├─ Foreground  │
        │                    │  │ │   Vibration    │  │ │  handling    │
        │ (JSON JSONB):      │  │ └─ Badge display│  │ ├─ Background  │
        │ {                  │  │                  │  │ │  handling    │
        │  "period...": bool │  │                  │  │ └─ Auto token  │
        │  "period...": int  │  │                  │  │    refresh    │
        │  "mood...": bool   │  │                  │  │                │
        │  "mood...": int    │  │                  │  │ (Firebase      │
        │  ...               │  │                  │  │  Console)      │
        │ }                  │  │                  │  │                │
        │                    │  │                  │  │ (FCM Service)  │
        └────────────────────┘  └──────────────────┘  └────────────────┘
```

---

## Data Flow Diagrams

### User Updates Notification Preference

```
User Changes Setting
    │
    ↓
NotificationsSettingsDialog.onToggle()
    │
    ↓ ref.read(notificationPreferencesProvider.notifier)
    │
    ├─ Call: togglePeriodReminders(value)
    │
    ├─ Notifier creates new state:
    │  state = state.copyWith(periodRemindersEnabled: value)
    │
    ├─ Call: updatePreferences(newState)
    │
    ├─ Notifier calls: _supabaseService.saveNotificationPreferencesData(map)
    │
    ├─ Supabase Update:
    │  UPDATE users 
    │  SET notification_preferences = {...}
    │  WHERE id = current_user_id
    │
    ├─ Supabase confirms update
    │
    └─ UI refreshes via Riverpod state change ✅
       (All widgets watching provider see new value)
```

### App Startup - Initialization

```
main()
    │
    ├─ WidgetsFlutterBinding.ensureInitialized()
    │
    ├─ Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
    │  └─ Loads firebase_options.dart configuration
    │  └─ Connects to Firebase backend
    │
    ├─ NotificationService().initialize()
    │  │
    │  ├─ _initializeAwesomeNotifications()
    │  │  ├─ Create notification channel (lovely_channel)
    │  │  ├─ Request notification permissions (Android 13+)
    │  │  ├─ Setup awesome notification handlers
    │  │  └─ Ready for local notifications ✅
    │  │
    │  └─ _initializeFirebaseMessaging()
    │     ├─ Initialize FirebaseMessaging instance
    │     ├─ Request FCM permissions
    │     ├─ Get FCM token from Firebase
    │     ├─ Save FCM token to Supabase (users.fcm_token)
    │     ├─ Listen for token refresh (update Supabase when changed)
    │     ├─ Setup onMessage listener (foreground messages)
    │     ├─ Setup onMessageOpenedApp listener (message tap)
    │     ├─ Setup onBackgroundMessage handler (background)
    │     └─ Ready for remote notifications ✅
    │
    ├─ SupabaseService.initialize() [timeout: 10 seconds]
    │  └─ Initialize Supabase client
    │  └─ Load session from encrypted storage
    │
    └─ runApp(ProviderScope(child: LovelyApp()))
       └─ App ready! All systems initialized ✅
```

### Local Notification - Period Reminder

```
9:00 AM (Notification Time)
    │
    └─ OS wakes up scheduled notification
       │
       ├─ Awesome Notifications triggers
       │
       ├─ Creates notification with:
       │  ├─ Title: "Period Starting Soon"
       │  ├─ Body: "Check your cycle"
       │  ├─ Icon: period icon
       │  ├─ Sound: enabled
       │  ├─ Vibration: enabled
       │  └─ Large icon: notification_icon
       │
       └─ User sees notification ✅
          └─ Can tap to open app
             └─ Navigate to calendar/cycle view
```

### Remote Notification - FCM Message

```
Backend sends FCM Message
    │
    └─ Message target: users.fcm_token
       │
       └─ Firebase Cloud Messaging receives
          │
          ├─ Check if app in foreground
          │
          ├─ If Foreground:
          │  ├─ FirebaseMessaging.onMessage listener triggered
          │  ├─ NotificationService._handleFCMMessage()
          │  ├─ Create Awesome Notification
          │  └─ User sees notification in app ✅
          │
          └─ If Background:
             ├─ FirebaseMessaging background handler triggered
             ├─ NotificationService._handleFCMMessage()
             ├─ Create Awesome Notification
             └─ Notification appears in notification tray ✅
                └─ User can tap to open app
```

---

## Component Interaction Matrix

```
                    Awesome    Firebase   Supabase   Profile   Dialog
                    Notif      Messaging  Service    Screen
                    ─────────────────────────────────────────────────
UI Dialog            ✗          ✗          ✗         ✓ send   ✓ show
                                                     update  settings
                                                     event

Notification         ✓ display  ✗          ✗         ✗        ✗
Service              ✓ schedule ✓ receive   ✓ token   ✗        ✗
                     ✓ cancel   ✓ FCM       ✓ store
                                           ✓ sync

Notification         ✗          ✗          ✓ save    ✗        ✓ watch
Provider             ✓ state    ✓ state    ✓ load    ✓ read   ✓ update
                     ✓ update   ✓ update   ✓ sync    ✓ watch

Supabase             ✗          ✗          ─────    ✓ auth    ✗
Service              ✓ request  ✗          ✓ store   ✓ query
                                          ✓ update
```

---

## Notification Channel Architecture

```
                    LOCAL NOTIFICATIONS
                     (Awesome)
                    
    ┌──────────────────────────────────┐
    │  lovely_channel_group             │
    │  (Notification Channel Group)     │
    │                                   │
    │  ├─ lovely_channel                │
    │  │  ├─ Name: Lovely Notifications │
    │  │  ├─ Importance: High            │
    │  │  ├─ Sound: Enabled              │
    │  │  ├─ Vibration: Enabled          │
    │  │  ├─ Light: Coral Sunset #FF6F61 │
    │  │  ├─ Badge: Show                 │
    │  │  └─ Notifications:              │
    │  │     ├─ Period Reminders         │
    │  │     ├─ Mood Check-In            │
    │  │     ├─ Affirmations             │
    │  │     └─ Task Reminders           │
    │  │                                │
    │  └─ [Can add more channels here]   │
    │                                   │
    └──────────────────────────────────┘
    
                    REMOTE NOTIFICATIONS
                     (Firebase)
                     
    ┌──────────────────────────────────┐
    │  Firebase Cloud Messaging         │
    │                                   │
    │  ├─ Token Storage: users.fcm_token│
    │  ├─ Token Refresh: Auto (monthly) │
    │  ├─ Listeners: Foreground+BG     │
    │  ├─ Display: Awesome Notifications│
    │  └─ Notifications:               │
    │     ├─ Server Announcements       │
    │     ├─ Feature Updates            │
    │     ├─ Event Reminders            │
    │     └─ [Custom messages]          │
    │                                   │
    └──────────────────────────────────┘
```

---

## Permission Flow

```
App Launch
    │
    ├─ Android 13+:
    │  ├─ AwesomeNotifications.requestPermissionToSendNotifications()
    │  │  └─ POST_NOTIFICATIONS permission
    │  │
    │  └─ FirebaseMessaging.requestPermission()
    │     └─ FCM notification permission
    │
    ├─ iOS:
    │  └─ FirebaseMessaging.requestPermission()
    │     ├─ Alert: true
    │     ├─ Badge: true
    │     ├─ Sound: true
    │     └─ [User sees permission dialog]
    │
    └─ User Response:
       ├─ ALLOWED:
       │  ├─ Local notifications ✅
       │  ├─ Remote notifications ✅
       │  └─ Notification light/sound ✅
       │
       └─ DENIED:
          ├─ App continues (graceful)
          └─ Notifications show as alerts only
```

---

## State Persistence

```
App Lifecycle
    │
    ├─ First Launch:
    │  ├─ Load default preferences
    │  ├─ Save to Supabase
    │  └─ Cache in Riverpod state
    │
    ├─ User Changes Setting:
    │  ├─ Update Riverpod state (instant)
    │  ├─ Save to Supabase (background)
    │  └─ Update local cache
    │
    ├─ App Backgrounded:
    │  ├─ State persists in memory
    │  ├─ Notifications still work (OS level)
    │  └─ Pending saves continue
    │
    ├─ App Killed:
    │  ├─ Supabase has latest state
    │  ├─ Notifications still scheduled (OS)
    │  └─ FCM token still valid
    │
    └─ App Reopened:
       ├─ Riverpod reloads state from Supabase
       ├─ Local cache refreshed
       ├─ FCM token refreshed
       └─ All settings restored ✅
```

---

## Error Recovery

```
Initialization Error
    │
    ├─ Firebase init fails:
    │  └─ Catch & continue (app still works)
    │
    ├─ Awesome Notifications fails:
    │  └─ Catch & continue (remote still works)
    │
    ├─ FCM initialization fails:
    │  └─ Catch & continue (local still works)
    │
    ├─ Supabase connection fails (10s timeout):
    │  └─ Catch & continue (use defaults)
    │
    └─ Runtime Errors:
       ├─ Notification send fails:
       │  ├─ Log error
       │  ├─ Show user feedback
       │  └─ Retry next interval
       │
       └─ Settings save fails:
          ├─ Keep local state
          ├─ Queue for retry
          └─ Show snackbar to user
```

---

## Summary

The notification system provides:

✅ **Two-way communication** (local + remote)  
✅ **User preferences** (enable/disable, custom times)  
✅ **State persistence** (survives app restart)  
✅ **Error resilience** (graceful fallbacks)  
✅ **Platform support** (Android + iOS)  
✅ **Clean architecture** (services, providers, UI separated)

All components work together to deliver a reliable, user-friendly notification experience! 🎉
