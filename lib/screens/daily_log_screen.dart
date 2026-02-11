import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/providers/period_provider.dart';
import 'package:lunara/providers/daily_log_provider.dart';
import 'package:lunara/models/mood.dart';
import 'package:lunara/models/symptom.dart';
import 'package:lunara/models/sexual_activity.dart';
import 'package:lunara/models/period.dart';
import 'package:intl/intl.dart';
import 'package:lunara/core/feedback/feedback_service.dart';
import 'package:lunara/widgets/mood_picker.dart';
import 'package:lunara/widgets/symptom_picker.dart';
import 'package:lunara/widgets/app_dialog.dart';

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
    final periodService = ref.read(periodServiceProvider);
    final periods = await periodService
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

    final health = ref.read(healthServiceProvider);
    try {
        if (_hadSex) {
        await health.logSexualActivity(
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
          await health.deleteSexualActivity(sexualActivity.id);
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

    final health = ref.read(healthServiceProvider);
    try {
      await health.saveNote(
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
                    _buildPeriodSection(),
                    const SizedBox(height: 16),
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
                    onPressed: () async {
                      final selectedMood = await MoodPicker.show(
                        context,
                        currentMood: mood?.moodType,
                      );

                      if (selectedMood != null) {
                        try {
                          await ref
                              .read(healthServiceProvider)
                              .saveMood(
                                date: widget.selectedDate,
                                mood: selectedMood,
                              );

                          if (mounted) {
                            FeedbackService.showSuccess(
                              context,
                              'Mood logged successfully!',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            FeedbackService.showError(context, e);
                          }
                        }
                      }
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
                      onTap: () async {
                        final confirmed = await AppDialog.showConfirmation(
                          context,
                          title: 'Delete Mood',
                          message: 'Remove this mood entry?',
                          confirmText: 'Delete',
                          isDangerous: true,
                        );

                        if (confirmed == true) {
                          try {
                            await ref
                              .read(healthServiceProvider)
                              .deleteMood(mood.id);

                            if (mounted) {
                              FeedbackService.showSuccess(
                                context,
                                'Mood deleted',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              FeedbackService.showError(context, e);
                            }
                          }
                        }
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
                  onPressed: () async {
                    final currentSymptomTypes = symptoms
                        .map((s) => s.symptomType)
                        .toList();

                    if (!mounted) return;
                    final selectedSymptom = await SymptomPicker.show(
                      context,
                      selectedSymptoms: currentSymptomTypes,
                    );

                    if (selectedSymptom != null && mounted) {
                      // Ask for severity
                      final severity = await SymptomPicker.showSeverity(
                        context,
                        selectedSymptom,
                      );

                      if (severity != null) {
                        try {
                          final updatedSymptoms = [
                            ...currentSymptomTypes,
                            selectedSymptom,
                          ];

                          final severities = <SymptomType, int>{};
                          for (var s in symptoms) {
                            severities[s.symptomType] = s.severity ?? 3;
                          }
                          severities[selectedSymptom] = severity;

                          await ref
                              .read(healthServiceProvider)
                              .saveSymptoms(
                                date: widget.selectedDate,
                                symptomTypes: updatedSymptoms,
                                severities: severities,
                              );

                          if (mounted) {
                            FeedbackService.showSuccess(
                              context,
                              'Symptom logged successfully!',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            FeedbackService.showError(context, e);
                          }
                        }
                      }
                    }
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
                          onTap: () async {
                            final confirmed = await AppDialog.showConfirmation(
                              context,
                              title: 'Delete Symptom',
                              message:
                                  'Remove ${symptom.symptomType.displayName}?',
                              confirmText: 'Delete',
                              isDangerous: true,
                            );

                            if (confirmed == true) {
                              try {
                                await ref
                                  .read(healthServiceProvider)
                                  .deleteSymptom(symptom.id);

                                if (mounted) {
                                  FeedbackService.showSuccess(
                                    context,
                                    'Symptom deleted',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  FeedbackService.showError(context, e);
                                }
                              }
                            }
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

  Widget _buildPeriodSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final periodsAsync = ref.watch(
      periodsStreamProvider(
        DateRange(
          startDate: widget.selectedDate,
          endDate: widget.selectedDate.add(const Duration(days: 1)),
        ),
      ),
    );

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
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Period Flow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                periodsAsync.when(
                  data: (periods) {
                    final hasPeriod = periods.isNotEmpty;
                    if (!hasPeriod) {
                      return FilledButton.tonalIcon(
                        onPressed: () => _logPeriodStart(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log Period'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            periodsAsync.when(
              data: (periods) {
                if (periods.isEmpty) {
                  return Container(
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
                          'No period logged for this day',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final period = periods.first;
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 20,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period.flowIntensity != null
                            ? '${period.flowIntensity!.name.substring(0, 1).toUpperCase()}${period.flowIntensity!.name.substring(1)} flow'
                            : 'Period started',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () async {
                          final confirmed = await AppDialog.showConfirmation(
                            context,
                            title: 'Delete Period',
                            message: 'Remove this period entry?',
                            confirmText: 'Delete',
                            isDangerous: true,
                          );

                          if (confirmed == true) {
                            try {
                                await ref
                                  .read(periodServiceProvider)
                                  .deletePeriod(period.id);

                              if (mounted) {
                                FeedbackService.showSuccess(
                                  context,
                                  'Period deleted',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                FeedbackService.showError(context, e);
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Error loading period data',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logPeriodStart() async {
    final intensity = await showDialog<FlowIntensity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Period Start'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select flow intensity for ${DateFormat('MMM d, yyyy').format(widget.selectedDate)}:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFlowButton(
                  context,
                  FlowIntensity.light,
                  'Light',
                  Icons.water_drop_outlined,
                ),
                _buildFlowButton(
                  context,
                  FlowIntensity.medium,
                  'Medium',
                  Icons.water_drop,
                ),
                _buildFlowButton(
                  context,
                  FlowIntensity.heavy,
                  'Heavy',
                  Icons.water_drop,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (intensity != null) {
      try {
        await ref.read(periodServiceProvider).startPeriod(
              startDate: widget.selectedDate,
              intensity: intensity,
            );

        if (mounted) {
          FeedbackService.showSuccess(
            context,
            'Period logged! Predictions updated.',
          );
        }
      } catch (e) {
        if (mounted) {
          FeedbackService.showError(context, e);
        }
      }
    }
  }

  Widget _buildFlowButton(
    BuildContext context,
    FlowIntensity intensity,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.pop(context, intensity),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
