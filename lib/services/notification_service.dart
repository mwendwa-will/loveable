import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late FirebaseMessaging _firebaseMessaging;

  /// Initialize awesome_notifications and FCM with app icon and channel
  Future<void> initialize() async {
    debugPrint('🔔 Initializing Awesome Notifications & FCM...');
    
    // Initialize Awesome Notifications
    await _initializeAwesomeNotifications();
    
    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
    
    debugPrint('✅ Notifications system initialized successfully');
  }

  /// Initialize Awesome Notifications
  Future<void> _initializeAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null, // Use default icon in the app (set in Android manifest)
        [
          NotificationChannel(
            channelGroupKey: 'lovely_channel_group',
            channelKey: 'lovely_channel',
            channelName: 'Lovely Notifications',
            channelDescription: 'Notifications for Lovely app',
            defaultColor: Color.fromARGB(255, 255, 111, 97), // Coral Sunset
            ledColor:  Color.fromARGB(255, 255, 111, 97),
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
      ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'lovely_channel_group',
            channelGroupName: 'Lovely',
          )
        ],
      );

      // Request permissions (Android 13+ requires explicit permission request)
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      debugPrint('✅ Awesome Notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Awesome Notifications: $e');
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM permission granted (provisional)');
      } else {
        debugPrint('❌ FCM permission denied');
      }

      // Get and store FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token obtained: ${token.substring(0, 20)}...');
        // Store token in Supabase (handled by supabase_service)
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
        // Update token in Supabase when it changes
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📬 FCM foreground message received');
        _handleFCMMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 FCM background message opened');
        _handleFCMMessage(message);
      });

      // Handle background message (in isolate)
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      debugPrint('✅ Firebase Messaging initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Send a period reminder notification
  Future<void> sendPeriodReminder({
    required String title,
    required String message,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'lovely_channel',
          title: title,
          body: message,
          notificationLayout: NotificationLayout.Default,
          largeIcon: 'asset://assets/icons/period_icon.png',
        ),
      );
      debugPrint('📬 Period reminder sent: $title');
    } catch (e) {
      debugPrint('❌ Error sending period reminder: $e');
    }
  }

  /// Send a mood check-in reminder
  Future<void> sendMoodCheckInReminder() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: 'lovely_channel',
          title: 'How are you feeling today?',
          body: 'Log your mood and symptoms to track your wellness journey',
          notificationLayout: NotificationLayout.Default,
          largeIcon: 'asset://assets/icons/mood_icon.png',
        ),
      );
      debugPrint('📬 Mood check-in reminder sent');
    } catch (e) {
      debugPrint('❌ Error sending mood check-in reminder: $e');
    }
  }

  /// Send a daily affirmation notification
  Future<void> sendAffirmationNotification({
    required String affirmation,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: 'lovely_channel',
          title: 'Daily Affirmation',
          body: affirmation,
          notificationLayout: NotificationLayout.Default,
          largeIcon: 'asset://assets/icons/affirmation_icon.png',
        ),
      );
      debugPrint('📬 Affirmation notification sent');
    } catch (e) {
      debugPrint('❌ Error sending affirmation: $e');
    }
  }

  /// Send a task reminder
  Future<void> sendTaskReminder({
    required String taskTitle,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 4,
          channelKey: 'lovely_channel',
          title: 'Task Reminder',
          body: taskTitle,
          notificationLayout: NotificationLayout.Default,
          largeIcon: 'asset://assets/icons/task_icon.png',
        ),
      );
      debugPrint('📬 Task reminder sent: $taskTitle');
    } catch (e) {
      debugPrint('❌ Error sending task reminder: $e');
    }
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelKey,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          allowWhileIdle: true,
          repeats: false,
        ),
      );
      debugPrint('📅 Notification scheduled for $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Schedule a recurring daily notification
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelKey,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          allowWhileIdle: true,
          repeats: true, // Repeat daily
        ),
      );
      debugPrint('📅 Recurring notification scheduled for $hour:$minute daily');
    } catch (e) {
      debugPrint('❌ Error scheduling recurring notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      debugPrint('✅ Notification $id cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Handle FCM messages (both foreground and background)
  void _handleFCMMessage(RemoteMessage message) {
    debugPrint('📨 Processing FCM message: ${message.notification?.title}');

    // Show awesome notification for FCM message
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'lovely_channel',
        title: message.notification?.title ?? 'Lovely',
        body: message.notification?.body ?? '',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}

/// Top-level function for Firebase background message handling
/// (Must be top-level or static for background isolate)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message: ${message.notification?.title}');
}
