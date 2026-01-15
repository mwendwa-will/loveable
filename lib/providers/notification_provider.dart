import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/services/notification_prefs_service.dart';

/// Model for notification preferences
class NotificationPreferences {
  final bool periodRemindersEnabled;
  final int periodReminderHour;
  final int periodReminderMinute;

  final bool moodCheckInEnabled;
  final int moodCheckInHour;
  final int moodCheckInMinute;

  final bool affirmationsEnabled;
  final int affirmationHour;
  final int affirmationMinute;

  final bool taskRemindersEnabled;
  final int taskReminderHour;
  final int taskReminderMinute;

  NotificationPreferences({
    this.periodRemindersEnabled = true,
    this.periodReminderHour = 9,
    this.periodReminderMinute = 0,
    this.moodCheckInEnabled = true,
    this.moodCheckInHour = 18,
    this.moodCheckInMinute = 0,
    this.affirmationsEnabled = true,
    this.affirmationHour = 7,
    this.affirmationMinute = 0,
    this.taskRemindersEnabled = true,
    this.taskReminderHour = 8,
    this.taskReminderMinute = 0,
  });

  NotificationPreferences copyWith({
    bool? periodRemindersEnabled,
    int? periodReminderHour,
    int? periodReminderMinute,
    bool? moodCheckInEnabled,
    int? moodCheckInHour,
    int? moodCheckInMinute,
    bool? affirmationsEnabled,
    int? affirmationHour,
    int? affirmationMinute,
    bool? taskRemindersEnabled,
    int? taskReminderHour,
    int? taskReminderMinute,
  }) {
    return NotificationPreferences(
      periodRemindersEnabled:
          periodRemindersEnabled ?? this.periodRemindersEnabled,
      periodReminderHour: periodReminderHour ?? this.periodReminderHour,
      periodReminderMinute: periodReminderMinute ?? this.periodReminderMinute,
      moodCheckInEnabled: moodCheckInEnabled ?? this.moodCheckInEnabled,
      moodCheckInHour: moodCheckInHour ?? this.moodCheckInHour,
      moodCheckInMinute: moodCheckInMinute ?? this.moodCheckInMinute,
      affirmationsEnabled: affirmationsEnabled ?? this.affirmationsEnabled,
      affirmationHour: affirmationHour ?? this.affirmationHour,
      affirmationMinute: affirmationMinute ?? this.affirmationMinute,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      taskReminderHour: taskReminderHour ?? this.taskReminderHour,
      taskReminderMinute: taskReminderMinute ?? this.taskReminderMinute,
    );
  }
}

/// Notification preferences state notifier
class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  late NotificationPrefsService _prefsService;

  @override
  NotificationPreferences build() {
    _prefsService = NotificationPrefsService();
    // Load preferences on initialization
    loadPreferences();
    return NotificationPreferences();
  }

  /// Load notification preferences from Supabase
  Future<void> loadPreferences() async {
    try {
      final data = await _prefsService.getNotificationPreferencesData();
      if (data != null) {
        state = NotificationPreferences(
          periodRemindersEnabled:
              data['periodRemindersEnabled'] as bool? ?? true,
          periodReminderHour: data['periodReminderHour'] as int? ?? 9,
          periodReminderMinute: data['periodReminderMinute'] as int? ?? 0,
          moodCheckInEnabled: data['moodCheckInEnabled'] as bool? ?? true,
          moodCheckInHour: data['moodCheckInHour'] as int? ?? 18,
          moodCheckInMinute: data['moodCheckInMinute'] as int? ?? 0,
          affirmationsEnabled: data['affirmationsEnabled'] as bool? ?? true,
          affirmationHour: data['affirmationHour'] as int? ?? 7,
          affirmationMinute: data['affirmationMinute'] as int? ?? 0,
          taskRemindersEnabled: data['taskRemindersEnabled'] as bool? ?? true,
          taskReminderHour: data['taskReminderHour'] as int? ?? 8,
          taskReminderMinute: data['taskReminderMinute'] as int? ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      state = preferences;
      await _prefsService.saveNotificationPreferencesData({
        'periodRemindersEnabled': preferences.periodRemindersEnabled,
        'periodReminderHour': preferences.periodReminderHour,
        'periodReminderMinute': preferences.periodReminderMinute,
        'moodCheckInEnabled': preferences.moodCheckInEnabled,
        'moodCheckInHour': preferences.moodCheckInHour,
        'moodCheckInMinute': preferences.moodCheckInMinute,
        'affirmationsEnabled': preferences.affirmationsEnabled,
        'affirmationHour': preferences.affirmationHour,
        'affirmationMinute': preferences.affirmationMinute,
        'taskRemindersEnabled': preferences.taskRemindersEnabled,
        'taskReminderHour': preferences.taskReminderHour,
        'taskReminderMinute': preferences.taskReminderMinute,
      });
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  /// Toggle period reminders
  Future<void> togglePeriodReminders(bool enabled) async {
    final updated = state.copyWith(periodRemindersEnabled: enabled);
    await updatePreferences(updated);
  }

  /// Update period reminder time
  Future<void> setPeriodReminderTime(int hour, int minute) async {
    final updated = state.copyWith(
      periodReminderHour: hour,
      periodReminderMinute: minute,
    );
    await updatePreferences(updated);
  }

  /// Toggle mood check-in reminders
  Future<void> toggleMoodCheckIn(bool enabled) async {
    final updated = state.copyWith(moodCheckInEnabled: enabled);
    await updatePreferences(updated);
  }

  /// Update mood check-in time
  Future<void> setMoodCheckInTime(int hour, int minute) async {
    final updated = state.copyWith(
      moodCheckInHour: hour,
      moodCheckInMinute: minute,
    );
    await updatePreferences(updated);
  }

  /// Toggle affirmations
  Future<void> toggleAffirmations(bool enabled) async {
    final updated = state.copyWith(affirmationsEnabled: enabled);
    await updatePreferences(updated);
  }

  /// Update affirmation time
  Future<void> setAffirmationTime(int hour, int minute) async {
    final updated = state.copyWith(
      affirmationHour: hour,
      affirmationMinute: minute,
    );
    await updatePreferences(updated);
  }

  /// Toggle task reminders
  Future<void> toggleTaskReminders(bool enabled) async {
    final updated = state.copyWith(taskRemindersEnabled: enabled);
    await updatePreferences(updated);
  }

  /// Update task reminder time
  Future<void> setTaskReminderTime(int hour, int minute) async {
    final updated = state.copyWith(
      taskReminderHour: hour,
      taskReminderMinute: minute,
    );
    await updatePreferences(updated);
  }
}

// Riverpod provider for notification preferences
final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        () {
  return NotificationPreferencesNotifier();
});
