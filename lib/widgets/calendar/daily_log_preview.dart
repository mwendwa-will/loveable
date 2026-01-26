import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/providers/calendar_provider.dart';

class DailyLogPreview extends ConsumerWidget {
  final DateTime selectedDate;

  const DailyLogPreview({super.key, required this.selectedDate});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateKey = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday =
        dateKey.year == DateTime.now().year &&
        dateKey.month == DateTime.now().month &&
        dateKey.day == DateTime.now().day;

    // Get data directly from the calendar state
    final calendarState = ref.watch(calendarProvider).asData?.value;

    if (calendarState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mood = calendarState.moods[dateKey];
    final symptoms = calendarState.symptoms[dateKey] ?? [];
    final activity = calendarState.sexualActivities[dateKey];
    final note = calendarState.notes[dateKey];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(selectedDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  // Mood
                  _buildSection(
                    context,
                    icon: Icons.mood,
                    title: 'Mood',
                    hasData: mood != null,
                    emptyText: 'No mood logged',
                    content: mood != null ? _buildMoodChip(mood) : null,
                  ),

                  // Symptoms
                  _buildSection(
                    context,
                    icon: Icons.medical_services_outlined,
                    title: 'Symptoms',
                    hasData: symptoms.isNotEmpty,
                    emptyText: 'No symptoms logged',
                    content: symptoms.isNotEmpty
                        ? _buildSymptomsWrap(symptoms, colorScheme)
                        : null,
                  ),

                  // Activity
                  _buildSection(
                    context,
                    icon: Icons.favorite_outline,
                    title: 'Intimacy',
                    hasData: activity != null,
                    emptyText: 'No activity logged',
                    content: activity != null
                        ? _buildActivityChip(activity)
                        : null,
                  ),

                  // Notes
                  _buildSection(
                    context,
                    icon: Icons.note_outlined,
                    title: 'Notes',
                    hasData: note != null,
                    emptyText: 'No notes',
                    content: note != null
                        ? _buildNoteCard(note, colorScheme)
                        : null,
                  ),

                  // Bottom padding for fab
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool hasData,
    required String emptyText,
    Widget? content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!hasData) {
      return Opacity(
        opacity: 0.5,
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        content!,
      ],
    );
  }

  Widget _buildMoodChip(Mood mood) {
    final color = _getMoodColor(mood.moodType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(mood.moodType.icon, size: 18, color: color),
          Text(
            mood.moodType.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsWrap(List<Symptom> symptoms, ColorScheme colorScheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: symptoms.map((s) {
        final severity = (s.severity ?? 3).clamp(1, 5);
        final severityLabel = [
          'Mild',
          'Mild',
          'Moderate',
          'Severe',
          'Severe',
        ][severity - 1];
        final severityColor = [
          Colors.green,
          Colors.green,
          Colors.orange,
          Colors.deepOrange,
          Colors.red,
        ][severity - 1];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Text(
                s.symptomType.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  severityLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityChip(SexualActivity activity) {
    final color = activity.protectionUsed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(
            activity.protectionUsed
                ? Icons.health_and_safety_sharp
                : Icons.warning_amber_rounded,
            size: 16,
            color: color,
          ),
          Text(
            activity.protectionUsed ? 'Protected' : 'Unprotected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Text(
        note.content,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
