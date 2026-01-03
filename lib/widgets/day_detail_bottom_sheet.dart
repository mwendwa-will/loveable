import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/providers/daily_log_provider.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/screens/daily_log_screen_v2.dart';

/// Bottom sheet showing full day details when tapping a date
class DayDetailBottomSheet extends ConsumerWidget {
  final DateTime date;

  const DayDetailBottomSheet({super.key, required this.date});

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailBottomSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateKey = DateTime(date.year, date.month, date.day);

    final moodAsync = ref.watch(moodStreamProvider(dateKey));
    final symptomsAsync = ref.watch(symptomsStreamProvider(dateKey));
    final activityAsync = ref.watch(sexualActivityStreamProvider(dateKey));
    final noteAsync = ref.watch(noteStreamProvider(dateKey));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(date),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildCycleInfo(context, date, ref),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLogScreenV2(selectedDate: dateKey),
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood Section
                  _buildSection(
                    context,
                    title: 'Mood',
                    icon: Icons.mood,
                    child: moodAsync.when(
                      data: (mood) => mood != null
                          ? _buildMoodChip(context, mood)
                          : _buildEmptyState('No mood logged'),
                      loading: () => _buildLoadingState(),
                      error: (_, _) => _buildEmptyState('Couldn\'t load this'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Symptoms Section
                  _buildSection(
                    context,
                    title: 'Symptoms',
                    icon: Icons.medical_services_outlined,
                    child: symptomsAsync.when(
                      data: (symptoms) => symptoms.isNotEmpty
                          ? _buildSymptomsList(context, symptoms)
                          : _buildEmptyState('No symptoms logged'),
                      loading: () => _buildLoadingState(),
                      error: (_, _) => _buildEmptyState('Couldn\'t load this'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sexual Activity Section
                  _buildSection(
                    context,
                    title: 'Intimacy',
                    icon: Icons.favorite_outline,
                    child: activityAsync.when(
                      data: (activity) => activity != null
                          ? _buildActivityInfo(context, activity)
                          : _buildEmptyState('No activity logged'),
                      loading: () => _buildLoadingState(),
                      error: (_, _) => _buildEmptyState('Couldn\'t load this'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes Section
                  _buildSection(
                    context,
                    title: 'Notes',
                    icon: Icons.note_outlined,
                    child: noteAsync.when(
                      data: (note) => note != null
                          ? _buildNoteCard(context, note)
                          : _buildEmptyState('No notes'),
                      loading: () => _buildLoadingState(),
                      error: (_, _) => _buildEmptyState('Couldn\'t load this'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleInfo(BuildContext context, DateTime date, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          return Text(
            'Cycle info isn\'t available yet',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        final lastPeriodStartStr = userData['last_period_start'];
        if (lastPeriodStartStr == null) {
          return Text(
            'Start tracking your period to see cycle insights ✨',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        final lastPeriodStart = DateTime.parse(lastPeriodStartStr as String);
        final averageCycleLength = (userData['average_cycle_length'] ?? 28) as int;
        final averagePeriodLength = (userData['average_period_length'] ?? 5) as int;

        final daysSincePeriodStart = date.difference(lastPeriodStart).inDays;
        final cycleDay = (daysSincePeriodStart % averageCycleLength) + 1;

        // Determine cycle phase
        String phaseInfo = '';
        if (cycleDay <= averagePeriodLength) {
          phaseInfo = 'Menstrual Phase';
        } else if (cycleDay <= 13) {
          phaseInfo = 'Follicular Phase';
        } else if (cycleDay == 14) {
          phaseInfo = 'Ovulation Day';
        } else if (cycleDay <= 20) {
          phaseInfo = 'Luteal Phase';
        } else {
          phaseInfo = 'Late Luteal Phase';
        }

        return Text(
          'Cycle Day $cycleDay • $phaseInfo',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
      loading: () => SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      error: (_, _) => Text(
        'Couldn\'t calculate cycle day',
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildMoodChip(BuildContext context, Mood mood) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getMoodColor(mood.moodType).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMoodColor(mood.moodType).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mood.moodType.icon,
            size: 20,
            color: _getMoodColor(mood.moodType),
          ),
          const SizedBox(width: 8),
          Text(
            mood.moodType.displayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return Colors.green;
      case MoodType.calm:
        return Colors.blue;
      case MoodType.tired:
        return Colors.grey;
      case MoodType.sad:
        return Colors.indigo;
      case MoodType.irritable:
        return Colors.orange;
      case MoodType.anxious:
        return Colors.purple;
      case MoodType.energetic:
        return Colors.amber;
    }
  }

  Widget _buildSymptomsList(BuildContext context, List<Symptom> symptoms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((symptom) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                symptom.symptomType.icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                symptom.symptomType.displayName,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              if (symptom.severity != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${symptom.severity}/5',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityInfo(BuildContext context, SexualActivity activity) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Logged',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      activity.protectionUsed ? Icons.shield : Icons.shield_outlined,
                      size: 14,
                      color: activity.protectionUsed
                          ? Colors.green
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.protectionUsed
                          ? 'Protected${activity.protectionType != null ? ' (${_formatProtectionType(activity.protectionType!)})' : ''}'
                          : 'Unprotected',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        note.content,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Builder(
      builder: (context) => Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  String _formatProtectionType(ProtectionType type) {
    switch (type) {
      case ProtectionType.condom:
        return 'Condom';
      case ProtectionType.birthControl:
        return 'Birth Control';
      case ProtectionType.iud:
        return 'IUD';
      case ProtectionType.withdrawal:
        return 'Withdrawal';
      case ProtectionType.other:
        return 'Other';
    }
  }
}
