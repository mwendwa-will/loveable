import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/providers/daily_log_provider.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:intl/intl.dart';
import 'package:lovely/core/feedback/feedback_service.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DailyLogScreen({super.key, required this.selectedDate});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final _noteController = TextEditingController();

  // Sexual activity form state
  bool _hadSex = false;
  bool _protectionUsed = false;
  ProtectionType? _protectionType;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadSexualActivityData();
    _loadNoteData();
  }

  void _loadSexualActivityData() {
    ref.read(sexualActivityStreamProvider(widget.selectedDate).future).then((
      data,
    ) {
      if (mounted && data != null) {
        setState(() {
          _hadSex = true;
          _protectionUsed = data.protectionUsed;
          _protectionType = data.protectionType;
        });
      }
    });
  }

  void _loadNoteData() {
    ref.read(noteStreamProvider(widget.selectedDate).future).then((data) {
      if (mounted && data != null) {
        setState(() {
          _noteController.text = data.content;
        });
      }
    });
  }

  Future<bool> _checkPeriodOnDate(DateTime date) async {
    final supabase = ref.read(supabaseServiceProvider);
    final periods = await supabase
        .getPeriodsStream(
          startDate: date,
          endDate: date.add(const Duration(days: 1)),
        )
        .first;
    return periods.isNotEmpty;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveSexualActivity() async {
    if (_hadSex) {
      final periodData = await _checkPeriodOnDate(widget.selectedDate);
      if (periodData) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sex During Menstruation'),
            content: const Text(
              'You have a period logged for this date. Are you sure you want to log sexual activity during menstruation?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    final supabase = ref.read(supabaseServiceProvider);
    try {
      if (_hadSex) {
        await supabase.logSexualActivity(
          date: widget.selectedDate,
          protectionUsed: _protectionUsed,
          protectionType: _protectionType,
        );
        if (mounted) {
          FeedbackService.showSuccess(context, 'Sexual activity logged');
        }
      } else {
        final sexualActivity = await ref.read(
          sexualActivityStreamProvider(widget.selectedDate).future,
        );
        if (sexualActivity != null) {
          await supabase.deleteSexualActivity(sexualActivity.id);
          if (mounted) {
            FeedbackService.showSuccess(context, 'Sexual activity removed');
          }
        }
      }
      ref.invalidate(sexualActivityStreamProvider(widget.selectedDate));
      ref.invalidate(moodStreamProvider(widget.selectedDate));
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    final supabase = ref.read(supabaseServiceProvider);
    try {
      await supabase.saveNote(
        date: widget.selectedDate,
        content: _noteController.text.trim(),
      );
      if (mounted) {
        FeedbackService.showSuccess(context, 'Note saved');
      }
      ref.invalidate(noteStreamProvider(widget.selectedDate));
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(widget.selectedDate);
    final moodAsync = ref.watch(moodStreamProvider(widget.selectedDate));
    final symptomsAsync = ref.watch(
      symptomsStreamProvider(widget.selectedDate),
    );
    final activityAsync = ref.watch(
      sexualActivityStreamProvider(widget.selectedDate),
    );
    final noteAsync = ref.watch(noteStreamProvider(widget.selectedDate));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      backgroundColor: colorScheme.surface,
      body: moodAsync.when(
        data: (mood) => symptomsAsync.when(
          data: (symptoms) => activityAsync.when(
            data: (activity) => noteAsync.when(
              data: (note) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMoodSection(mood),
                    const SizedBox(height: 16),
                    _buildSymptomsSection(symptoms),
                    const SizedBox(height: 16),
                    _buildSexualActivitySection(activity),
                    const SizedBox(height: 16),
                    _buildNoteSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSection(Mood? mood) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (mood == null)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      // TODO: Navigate to add mood
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (mood != null)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mood.moodType.icon,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood.moodType.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        // TODO: Add delete mood functionality
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_neutral,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No mood logged for this day',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection(List<Symptom> symptoms) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.healing,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Symptoms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () {
                    // TODO: Navigate to add symptoms
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (symptoms.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptoms.map((symptom) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          symptom.symptomType.icon,
                          size: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          symptom.symptomType.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            // TODO: Add delete symptom functionality
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No symptoms logged for this day',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSexualActivitySection(SexualActivity? sexualActivity) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sexual Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  'Had sex',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                value: _hadSex,
                onChanged: (value) {
                  setState(() {
                    _hadSex = value;
                    if (!value) {
                      _protectionUsed = false;
                      _protectionType = null;
                    }
                  });
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                activeThumbColor: colorScheme.primary,
              ),
            ),
            if (_hadSex) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Protection used',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  value: _protectionUsed,
                  onChanged: (value) {
                    setState(() {
                      _protectionUsed = value;
                      if (!value) {
                        _protectionType = null;
                      }
                    });
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  activeThumbColor: colorScheme.primary,
                ),
              ),
              if (_protectionUsed) ...[
                const SizedBox(height: 16),
                Text(
                  'Protection Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProtectionType.values.map((type) {
                    final isSelected = _protectionType == type;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(type.value.replaceAll('_', ' ')),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _protectionType = selected ? type : null;
                        });
                      },
                      backgroundColor: colorScheme.surface,
                      selectedColor: colorScheme.tertiaryContainer,
                      checkmarkColor: colorScheme.onTertiaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveSexualActivity,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Sexual Activity'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (sexualActivity != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saveSexualActivity,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Sexual Activity'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.note,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 5,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText:
                    'Write your thoughts, feelings, or anything you want to remember about today...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save),
                label: const Text('Save Note'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
