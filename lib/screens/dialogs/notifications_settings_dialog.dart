import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/providers/notification_provider.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/utils/responsive_utils.dart';

class NotificationsSettingsDialog extends ConsumerWidget {
  const NotificationsSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);

    return AlertDialog(
      title: const Text('Notification Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Reminders Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.droplet,
              title: 'Period Reminders',
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
            SizedBox(height: context.responsive.spacingMd),
            const Divider(),
            SizedBox(height: context.responsive.spacingMd),

            // Mood Check-In Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.faceSmile,
              title: 'Mood Check-In',
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
            SizedBox(height: context.responsive.spacingMd),
            const Divider(),
            SizedBox(height: context.responsive.spacingMd),

            /*
            // Affirmations Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.heart,
              title: 'Daily Affirmations',
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
            SizedBox(height: context.responsive.spacingMd),
            const Divider(),
            SizedBox(height: context.responsive.spacingMd),

            // Task Reminders Section
            _buildNotificationSection(
              context,
              ref,
              icon: FontAwesomeIcons.listCheck,
              title: 'Task Reminders',
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
            */
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required bool enabled,
    required Function(bool) onToggle,
    required int hour,
    required int minute,
    required Function(int, int) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: context.responsive.smallIconSize,
              color: AppColors.primary,
            ),
            SizedBox(width: context.responsive.spacingSm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
          SizedBox(height: context.responsive.spacingSm),
          Padding(
            padding: EdgeInsets.only(left: context.responsive.spacingLg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showTimePicker(context, hour, minute, onTimeChanged),
                  icon: const FaIcon(FontAwesomeIcons.clock, size: 14),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
        ],
      ],
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
