import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/notification_provider.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info Card
            Container(
              margin: EdgeInsets.all(context.responsive.spacingMd),
              padding: EdgeInsets.all(context.responsive.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                    size: context.responsive.iconSize,
                  ),
                  SizedBox(width: context.responsive.spacingMd),
                  Expanded(
                    child: Text(
                      'Get gentle reminders to help you stay on track with your wellness journey ✨',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Period Reminders Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.droplet,
              title: 'Period Reminders',
              subtitle: 'Get notified when your period is approaching',
              enabled: preferences.periodRemindersEnabled,
              onToggle: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .togglePeriodReminders(value),
              hour: preferences.periodReminderHour,
              minute: preferences.periodReminderMinute,
              onTimeChanged: (hour, minute) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setPeriodReminderTime(hour, minute),
            ),

            const Divider(height: 1),

            // Mood Check-In Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.faceSmile,
              title: 'Mood Check-In',
              subtitle: 'Daily reminder to log your mood',
              enabled: preferences.moodCheckInEnabled,
              onToggle: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .toggleMoodCheckIn(value),
              hour: preferences.moodCheckInHour,
              minute: preferences.moodCheckInMinute,
              onTimeChanged: (hour, minute) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setMoodCheckInTime(hour, minute),
            ),

            const Divider(height: 1),

            // Affirmations Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.heart,
              title: 'Daily Affirmations',
              subtitle: 'Start your day with positive energy',
              enabled: preferences.affirmationsEnabled,
              onToggle: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .toggleAffirmations(value),
              hour: preferences.affirmationHour,
              minute: preferences.affirmationMinute,
              onTimeChanged: (hour, minute) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setAffirmationTime(hour, minute),
            ),

            const Divider(height: 1),

            // Task Reminders Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.listCheck,
              title: 'Task Reminders',
              subtitle: 'Remember your daily wellness tasks',
              enabled: preferences.taskRemindersEnabled,
              onToggle: (value) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .toggleTaskReminders(value),
              hour: preferences.taskReminderHour,
              minute: preferences.taskReminderMinute,
              onTimeChanged: (hour, minute) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setTaskReminderTime(hour, minute),
            ),

            SizedBox(height: context.responsive.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onToggle,
    required int hour,
    required int minute,
    required Function(int, int) onTimeChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.spacingMd,
        vertical: context.responsive.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  size: context.responsive.smallIconSize,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: context.responsive.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            SizedBox(height: context.responsive.spacingMd),
            Container(
              margin: EdgeInsets.only(left: context.responsive.spacingLg + context.responsive.smallIconSize),
              padding: EdgeInsets.all(context.responsive.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: context.responsive.smallIconSize,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: context.responsive.spacingSm),
                      Text(
                        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showTimePicker(
                      context,
                      hour,
                      minute,
                      onTimeChanged,
                    ),
                    child: const Text('Change Time'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    int currentHour,
    int currentMinute,
    Function(int, int) onTimeChanged,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (picked != null) {
      onTimeChanged(picked.hour, picked.minute);
    }
  }
}
