import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/providers/daily_log_provider.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/period.dart';
import 'package:intl/intl.dart';
import 'package:lovely/core/feedback/feedback_service.dart';
import 'package:lovely/constants/app_colors.dart';

/// Redesigned Daily Log Screen - Minimal taps, inline everything, auto-save
class DailyLogScreenV2 extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DailyLogScreenV2({super.key, required this.selectedDate});

  @override
  ConsumerState<DailyLogScreenV2> createState() => _DailyLogScreenV2State();
}

class _DailyLogScreenV2State extends ConsumerState<DailyLogScreenV2> {
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();
  bool _noteSaved = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNoteData();
    _noteController.addListener(_onNoteChanged);
  }

  void _loadNoteData() {
    ref.read(noteStreamProvider(widget.selectedDate).future).then((data) {
      if (mounted && data != null) {
        _noteController.text = data.content;
        _noteSaved = true;
      }
    }).catchError((e) {
      // Ignore errors from provider disposal during navigation
      debugPrint('Note stream error (likely navigation): $e');
    });
  }

  void _onNoteChanged() {
    if (_noteSaved) {
      setState(() => _noteSaved = false);
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  // Auto-save helper with haptic feedback
  Future<void> _autoSave(Future<void> Function() action) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      await action();
    } catch (e) {
      if (mounted) FeedbackService.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(widget.selectedDate);
    final isToday = DateUtils.isSameDay(widget.selectedDate, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Today' : dateStr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.cloud_done_outlined,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodFlowSection(),
            const SizedBox(height: 20),
            _buildMoodSection(),
            const SizedBox(height: 20),
            _buildSymptomsSection(),
            const SizedBox(height: 20),
            _buildSexualActivitySection(),
            const SizedBox(height: 20),
            _buildNoteSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==================== PERIOD FLOW SECTION ====================
  // 1 tap to log period with intensity
  Widget _buildPeriodFlowSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final periodsAsync = ref.watch(
      periodsStreamProvider(
        DateRange(
          startDate: widget.selectedDate,
          endDate: widget.selectedDate.add(const Duration(days: 1)),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Period Flow', Icons.water_drop, AppColors.getPeriodColor(context)),
        const SizedBox(height: 12),
        periodsAsync.when(
          data: (periods) {
            final hasPeriod = periods.isNotEmpty;
            final currentIntensity = hasPeriod ? periods.first.flowIntensity : null;

            return Row(
              children: [
                _buildFlowChip(
                  label: 'None',
                  icon: Icons.close,
                  isSelected: !hasPeriod,
                  color: colorScheme.surfaceContainerHighest,
                  onTap: hasPeriod
                      ? () => _autoSave(() async {
                            await ref.read(supabaseServiceProvider).deletePeriod(periods.first.id);
                          })
                      : null,
                ),
                const SizedBox(width: 8),
                _buildFlowChip(
                  label: 'Light',
                  icon: Icons.water_drop_outlined,
                  isSelected: currentIntensity == FlowIntensity.light,
                  color: AppColors.getPeriodColor(context).withValues(alpha: 0.4),
                  onTap: () => _logOrUpdatePeriod(FlowIntensity.light, periods.isNotEmpty ? periods.first : null),
                ),
                const SizedBox(width: 8),
                _buildFlowChip(
                  label: 'Medium',
                  icon: Icons.water_drop,
                  isSelected: currentIntensity == FlowIntensity.medium,
                  color: AppColors.getPeriodColor(context).withValues(alpha: 0.7),
                  onTap: () => _logOrUpdatePeriod(FlowIntensity.medium, periods.isNotEmpty ? periods.first : null),
                ),
                const SizedBox(width: 8),
                _buildFlowChip(
                  label: 'Heavy',
                  icon: Icons.water_drop,
                  isSelected: currentIntensity == FlowIntensity.heavy,
                  color: AppColors.getPeriodColor(context),
                  onTap: () => _logOrUpdatePeriod(FlowIntensity.heavy, periods.isNotEmpty ? periods.first : null),
                ),
              ],
            );
          },
          loading: () => _buildLoadingChips(4),
          error: (_, _) => const Text('Couldn\'t load this'),
        ),
      ],
    );
  }

  Widget _buildFlowChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.getPeriodColor(context), width: 2)
                : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logOrUpdatePeriod(FlowIntensity intensity, Period? existingPeriod) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      if (existingPeriod != null) {
        await supabase.updatePeriodIntensity(
          periodId: existingPeriod.id,
          intensity: intensity,
        );
      } else {
        await supabase.startPeriod(startDate: widget.selectedDate, intensity: intensity);
      }
      // Force UI refresh
      ref.invalidate(periodsStreamProvider(DateRange(
        startDate: widget.selectedDate,
        endDate: widget.selectedDate.add(const Duration(days: 1)),
      )));
    });
  }

  // ==================== MOOD SECTION ====================
  // 1 tap to log mood - inline grid
  Widget _buildMoodSection() {
    final moodAsync = ref.watch(moodStreamProvider(widget.selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mood', Icons.mood, Colors.amber),
        const SizedBox(height: 12),
        moodAsync.when(
          data: (currentMood) => _buildMoodGrid(currentMood),
          loading: () => _buildLoadingChips(7),
          error: (_, _) => const Text('Couldn\'t load this'),
        ),
      ],
    );
  }

  Widget _buildMoodGrid(Mood? currentMood) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MoodType.values.map((moodType) {
        final isSelected = currentMood?.moodType == moodType;
        final moodColor = _getMoodColor(moodType);

        return GestureDetector(
          onTap: () => _toggleMood(moodType, currentMood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? moodColor.withValues(alpha: 0.2) : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: moodColor, width: 2)
                  : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  moodType.icon,
                  size: 28,
                  color: isSelected ? moodColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  moodType.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? moodColor : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _toggleMood(MoodType moodType, Mood? currentMood) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      if (currentMood?.moodType == moodType) {
        // Tapping same mood removes it
        await supabase.deleteMood(currentMood!.id);
      } else {
        // Save new mood (replaces existing)
        await supabase.saveMood(date: widget.selectedDate, mood: moodType);
      }
      // Force UI refresh
      ref.invalidate(moodStreamProvider(widget.selectedDate));
    });
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

  // ==================== SYMPTOMS SECTION ====================
  // 1 tap to toggle symptom on/off
  Widget _buildSymptomsSection() {
    final symptomsAsync = ref.watch(symptomsStreamProvider(widget.selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Symptoms', Icons.healing, Colors.teal),
        const SizedBox(height: 12),
        symptomsAsync.when(
          data: (symptoms) => _buildSymptomChips(symptoms),
          loading: () => _buildLoadingChips(8),
          error: (_, _) => const Text('Couldn\'t load this'),
        ),
      ],
    );
  }

  Widget _buildSymptomChips(List<Symptom> loggedSymptoms) {
    final colorScheme = Theme.of(context).colorScheme;
    final loggedTypes = loggedSymptoms.map((s) => s.symptomType).toSet();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SymptomType.values.map((symptomType) {
        final isSelected = loggedTypes.contains(symptomType);
        final symptom = isSelected
            ? loggedSymptoms.firstWhere((s) => s.symptomType == symptomType)
            : null;
        final symptomColor = _getSymptomColor(symptomType);
        final severity = symptom?.severity ?? 3;

        return GestureDetector(
          onTap: () {
            // Always show severity picker - for new symptoms, pass null
            _showSeverityPicker(
              symptomType: symptomType,
              existingSymptom: symptom,
              currentSeverity: symptom?.severity ?? 3,
              allSymptoms: loggedSymptoms,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? symptomColor.withValues(alpha: 0.2) : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: symptomColor, width: 2)
                  : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  symptomType.icon,
                  size: 18,
                  color: isSelected ? symptomColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  symptomType.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? symptomColor : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  // Show severity dots instead of checkmark
                  _buildSeverityDots(severity, symptomColor),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Severity dots indicator (1-5 dots)
  Widget _buildSeverityDots(int severity, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < severity;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : color.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  // Show severity picker bottom sheet
  void _showSeverityPicker({
    required SymptomType symptomType,
    required Symptom? existingSymptom,
    required int currentSeverity,
    required List<Symptom> allSymptoms,
  }) {
    final symptomColor = _getSymptomColor(symptomType);
    final isNewSymptom = existingSymptom == null;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(symptomType.icon, color: symptomColor),
                const SizedBox(width: 8),
                Text(
                  '${symptomType.displayName} Severity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = currentSeverity == level;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (isNewSymptom) {
                      // Add new symptom with selected severity
                      _addSymptomWithSeverity(symptomType, level, allSymptoms);
                    } else {
                      // Update existing symptom severity
                      _updateSymptomSeverity(existingSymptom, level, allSymptoms);
                    }
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? symptomColor
                              : symptomColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: symptomColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : symptomColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSeverityLabel(level),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Remove button (only show for existing symptoms)
            if (!isNewSymptom)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _removeSymptom(existingSymptom, allSymptoms);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove Symptom'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSeverityLabel(int level) {
    switch (level) {
      case 1: return 'Mild';
      case 2: return 'Light';
      case 3: return 'Mod';
      case 4: return 'Strong';
      case 5: return 'Severe';
      default: return '';
    }
  }

  Future<void> _addSymptomWithSeverity(
    SymptomType symptomType,
    int severity,
    List<Symptom> allSymptoms,
  ) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      final currentTypes = allSymptoms.map((s) => s.symptomType).toList();
      final severities = <SymptomType, int>{};
      for (var s in allSymptoms) {
        severities[s.symptomType] = s.severity ?? 3;
      }
      severities[symptomType] = severity;

      await supabase.saveSymptoms(
        date: widget.selectedDate,
        symptomTypes: [...currentTypes, symptomType],
        severities: severities,
      );
      ref.invalidate(symptomsStreamProvider(widget.selectedDate));
    });
  }

  Future<void> _removeSymptom(Symptom symptom, List<Symptom> allSymptoms) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.deleteSymptom(symptom.id);
      ref.invalidate(symptomsStreamProvider(widget.selectedDate));
    });
  }

  Future<void> _updateSymptomSeverity(
    Symptom symptom,
    int newSeverity,
    List<Symptom> allSymptoms,
  ) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      final severities = <SymptomType, int>{};
      for (var s in allSymptoms) {
        if (s.symptomType == symptom.symptomType) {
          severities[s.symptomType] = newSeverity;
        } else {
          severities[s.symptomType] = s.severity ?? 3;
        }
      }
      await supabase.saveSymptoms(
        date: widget.selectedDate,
        symptomTypes: allSymptoms.map((s) => s.symptomType).toList(),
        severities: severities,
      );
      ref.invalidate(symptomsStreamProvider(widget.selectedDate));
    });
  }

  Color _getSymptomColor(SymptomType symptom) {
    switch (symptom) {
      case SymptomType.cramps:
        return Colors.red;
      case SymptomType.headache:
        return Colors.purple;
      case SymptomType.fatigue:
        return Colors.blueGrey;
      case SymptomType.bloating:
        return Colors.blue;
      case SymptomType.nausea:
        return Colors.green;
      case SymptomType.backPain:
        return Colors.brown;
      case SymptomType.breastTenderness:
        return Colors.pink;
      case SymptomType.acne:
        return Colors.orange;
    }
  }

  // ==================== SEXUAL ACTIVITY SECTION ====================
  // Inline toggles - no dialogs
  Widget _buildSexualActivitySection() {
    final colorScheme = Theme.of(context).colorScheme;
    final activityAsync = ref.watch(sexualActivityStreamProvider(widget.selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Intimacy', Icons.favorite, Colors.pink),
        const SizedBox(height: 12),
        activityAsync.when(
          data: (activity) => _buildSexualActivityContent(activity),
          loading: () => Container(
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          error: (_, _) => const Text('Couldn\'t load this'),
        ),
      ],
    );
  }

  Widget _buildSexualActivityContent(SexualActivity? activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final hadSex = activity != null;

    return Column(
      children: [
        // Main toggle row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleSexualActivity(false, activity),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !hadSex ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: !hadSex
                        ? Border.all(color: colorScheme.outline, width: 2)
                        : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontWeight: !hadSex ? FontWeight.w600 : FontWeight.w400,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleSexualActivity(true, activity),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: hadSex ? Colors.pink.withValues(alpha: 0.2) : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: hadSex
                        ? Border.all(color: Colors.pink, width: 2)
                        : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hadSex) const Icon(Icons.favorite, size: 18, color: Colors.pink),
                        if (hadSex) const SizedBox(width: 6),
                        Text(
                          'Yes',
                          style: TextStyle(
                            fontWeight: hadSex ? FontWeight.w600 : FontWeight.w400,
                            color: hadSex ? Colors.pink : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Protection options - only show if had sex
        if (hadSex) ...[
          const SizedBox(height: 12),
          _buildProtectionSection(activity),
        ],
      ],
    );
  }

  Widget _buildProtectionSection(SexualActivity activity) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protection',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildProtectionChip('None', null, activity),
            ...ProtectionType.values.map((type) => _buildProtectionChip(
                  type.value.replaceAll('_', ' '),
                  type,
                  activity,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildProtectionChip(String label, ProtectionType? type, SexualActivity activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = (type == null && !activity.protectionUsed) ||
        (type != null && activity.protectionUsed && activity.protectionType == type);

    return GestureDetector(
      onTap: () => _updateProtection(type, activity),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.withValues(alpha: 0.15) : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.pink.withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Text(
          label.substring(0, 1).toUpperCase() + label.substring(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.pink : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSexualActivity(bool hadSex, SexualActivity? existing) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      if (hadSex && existing == null) {
        await supabase.logSexualActivity(
          date: widget.selectedDate,
          protectionUsed: false,
        );
      } else if (!hadSex && existing != null) {
        await supabase.deleteSexualActivity(existing.id);
      }
      // Force UI refresh
      ref.invalidate(sexualActivityStreamProvider(widget.selectedDate));
    });
  }

  Future<void> _updateProtection(ProtectionType? type, SexualActivity activity) async {
    await _autoSave(() async {
      final supabase = ref.read(supabaseServiceProvider);
      // Delete and re-create with new protection info
      await supabase.deleteSexualActivity(activity.id);
      await supabase.logSexualActivity(
        date: widget.selectedDate,
        protectionUsed: type != null,
        protectionType: type,
      );
      // Force UI refresh
      ref.invalidate(sexualActivityStreamProvider(widget.selectedDate));
    });
  }

  // ==================== NOTE SECTION ====================
  // Auto-save on blur
  Widget _buildNoteSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('Notes', Icons.edit_note, colorScheme.primary),
            const Spacer(),
            if (!_noteSaved)
              TextButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          focusNode: _noteFocusNode,
          maxLines: 4,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'How was your day?',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onEditingComplete: _saveNote,
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    await _autoSave(() async {
      await ref.read(supabaseServiceProvider).saveNote(
            date: widget.selectedDate,
            content: _noteController.text.trim(),
          );
      setState(() => _noteSaved = true);
      // Force UI refresh
      ref.invalidate(noteStreamProvider(widget.selectedDate));
    });
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChips(int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        count,
        (_) => Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
