import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/screens/main/profile_screen.dart';
import 'package:lovely/screens/daily_log_screen.dart';
import 'package:lovely/screens/calendar_screen.dart';
import 'package:lovely/widgets/email_verification_banner.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showVerificationRequired = false;
  String? _selectedMood;
  final List<String> _selectedSymptoms = [];
  Period? _currentPeriod;
  bool _isLoading = true;

  DateTime? _lastPeriodStart;
  int _averageCycleLength = 28;
  int _averagePeriodLength = 5;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
    _loadData();
  }

  void _checkVerificationStatus() {
    if (ref.read(supabaseServiceProvider).requiresVerification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showVerificationRequired = true);
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final userData = await supabase.getUserData();
      final currentPeriod = await supabase.getCurrentPeriod();
      final today = DateTime.now();
      final todayMood = await supabase.getMoodForDate(today);
      final todaySymptoms = await supabase.getSymptomsForDate(today);

      if (mounted) {
        setState(() {
          _currentPeriod = currentPeriod;
          _selectedMood = todayMood?.moodType.name;
          _selectedSymptoms.clear();
          _selectedSymptoms.addAll(
            todaySymptoms.map((s) => s.symptomType.name),
          );

          if (userData != null) {
            _lastPeriodStart = userData['last_period_start'] != null
                ? DateTime.parse(userData['last_period_start'])
                : null;
            _averageCycleLength = userData['average_cycle_length'] ?? 28;
            _averagePeriodLength = userData['average_period_length'] ?? 5;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  void _showVerificationDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Email Verification Required')),
          ],
        ),
        content: const Text(
          'Your 7-day grace period has ended. Please verify your email address to continue using Lovely and enable account recovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.resendVerificationEmail();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text('Send Verification Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMood(String moodName) async {
    try {
      final moodType = MoodType.values.firstWhere((m) => m.name == moodName);
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.saveMood(date: DateTime.now(), mood: moodType);

      setState(() => _selectedMood = moodName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood saved: ${moodType.displayName}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleSymptom(String symptomName) async {
    try {
      List<String> updatedSymptoms = List.from(_selectedSymptoms);

      if (updatedSymptoms.contains(symptomName)) {
        updatedSymptoms.remove(symptomName);
      } else {
        updatedSymptoms.add(symptomName);
      }

      final symptomTypes = updatedSymptoms
          .map((name) => SymptomType.values.firstWhere((s) => s.name == name))
          .toList();

      final supabase = ref.read(supabaseServiceProvider);
      await supabase.saveSymptoms(
        date: DateTime.now(),
        symptomTypes: symptomTypes,
      );

      setState(() {
        _selectedSymptoms.clear();
        _selectedSymptoms.addAll(updatedSymptoms);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedSymptoms.contains(symptomName)
                  ? 'Symptom added'
                  : 'Symptom removed',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving symptom: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildWeekStrip() {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    DateTime? referenceDate;
    if (_currentPeriod != null && _currentPeriod!.endDate == null) {
      referenceDate = _currentPeriod!.startDate;
    } else if (_lastPeriodStart != null) {
      referenceDate = _lastPeriodStart;
    }

    DateTime? nextPeriodDate;
    DateTime? ovulationDate;
    DateTime? fertileWindowStart;
    DateTime? fertileWindowEnd;

    if (referenceDate != null) {
      final daysSinceLastPeriod = DateTime.now()
          .difference(referenceDate)
          .inDays;
      final cycleCount = (daysSinceLastPeriod ~/ _averageCycleLength) + 1;
      final nextCycleStart = referenceDate.add(
        Duration(days: cycleCount * _averageCycleLength),
      );
      nextPeriodDate = nextCycleStart;
      ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
      fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
      fertileWindowEnd = ovulationDate;
    }

    Color getPhaseColor(DateTime date) {
      if (referenceDate == null) {
        return colorScheme.surfaceContainerHighest;
      }

      if (nextPeriodDate != null) {
        if (date.isAfter(nextPeriodDate.subtract(Duration(days: 1))) &&
            date.isBefore(
              nextPeriodDate.add(Duration(days: _averagePeriodLength)),
            )) {
          return brightness == Brightness.dark
              ? const Color(0xFFE53935)
              : const Color(0xFFEF5350);
        }
      }
      final daysSince = date.difference(referenceDate).inDays;
      final cycleDay = (daysSince % _averageCycleLength) + 1;

      if (ovulationDate != null &&
          date.day == ovulationDate.day &&
          date.month == ovulationDate.month &&
          date.year == ovulationDate.year) {
        //Menstrual Phase
        if (cycleDay <= _averagePeriodLength) {
          return brightness == Brightness.dark
              ? const Color(0xFFD32F2F) // A deeper, calmer red
              : const Color(0xFFFFCDD2);
        }
      }

      if (fertileWindowStart != null && fertileWindowEnd != null) {
        if ((date.isAfter(
                  fertileWindowStart.subtract(const Duration(days: 1)),
                ) ||
                date.isAtSameMomentAs(fertileWindowStart)) &&
            (date.isBefore(fertileWindowEnd.add(const Duration(days: 1))) ||
                date.isAtSameMomentAs(fertileWindowEnd))) {
          return brightness == Brightness.dark
              ? const Color(0xFF1976D2)
              : const Color(0xFFBBDEFB);
        }
      }

      if (cycleDay <= _averagePeriodLength) {
        return brightness == Brightness.dark
            ? const Color(0xFFE53935)
            : const Color(0xFFEF5350);
      } else if (cycleDay <= 13) {
        return brightness == Brightness.dark
            ? const Color(0xFF1976D2)
            : const Color(0xFFBBDEFB);
      } else if (cycleDay == 14) {
        return brightness == Brightness.dark
            ? const Color(0xFF7B1FA2)
            : const Color(0xFFE1BEE7);
      } else {
        return brightness == Brightness.dark
            ? const Color(0xFFAD1457)
            : const Color(0xFFF8BBD0);
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isToday =
              date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;
          final phaseColor = getPhaseColor(date);
          final textColor = phaseColor.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white;

          return Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: phaseColor,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: colorScheme.primary, width: 2.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCycleCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    DateTime? referenceDate;
    if (_currentPeriod != null && _currentPeriod!.endDate == null) {
      referenceDate = _currentPeriod!.startDate;
    } else if (_lastPeriodStart != null) {
      referenceDate = _lastPeriodStart;
    }

    DateTime? nextPeriodDate;
    DateTime? ovulationDate;
    DateTime? fertileWindowStart;
    DateTime? fertileWindowEnd;
    String? currentPeriodRange;
    int? currentCycleDay;

    if (referenceDate != null) {
      final daysSinceStart = DateTime.now().difference(referenceDate).inDays;
      currentCycleDay = (daysSinceStart % _averageCycleLength) + 1;

      if (_currentPeriod != null && _currentPeriod!.endDate == null) {
        currentPeriodRange =
            '${DateFormat('MMM d').format(referenceDate)} - ongoing';
      }

      final daysSinceLastPeriod = DateTime.now()
          .difference(referenceDate)
          .inDays;
      final cycleCount = (daysSinceLastPeriod ~/ _averageCycleLength) + 1;
      final nextCycleStart = referenceDate.add(
        Duration(days: cycleCount * _averageCycleLength),
      );

      nextPeriodDate = nextCycleStart;
      ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
      fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
      fertileWindowEnd = ovulationDate;

      if (_currentPeriod != null && _currentPeriod!.endDate != null) {
        currentPeriodRange =
            '${DateFormat('MMM d').format(_currentPeriod!.startDate)} - ${DateFormat('MMM d').format(_currentPeriod!.endDate!)}';
      }
    }

    final periodColor = brightness == Brightness.dark
        ? const Color(0xFFE53935)
        : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Cycle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentCycleDay != null
                ? 'Day $currentCycleDay of $_averageCycleLength'
                : 'No data',
            style: TextStyle(
              fontSize: 32,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (currentCycleDay != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (currentCycleDay - 1) / _averageCycleLength,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(periodColor),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (nextPeriodDate != null) ...[
            _buildPredictionRow(
              icon: Icons.water_drop_outlined,
              label: 'Predicted next period',
              date: DateFormat('E, MMM d').format(nextPeriodDate),
            ),
            const SizedBox(height: 12),
          ],
          if (_currentPeriod != null || currentPeriodRange != null) ...[
            _buildPredictionRow(
              icon: Icons.favorite_outline,
              label: 'Period',
              date: currentPeriodRange ?? 'Not tracked',
            ),
            const SizedBox(height: 12),
          ],
          if (fertileWindowStart != null && fertileWindowEnd != null) ...[
            _buildPredictionRow(
              icon: Icons.eco_outlined,
              label: 'Predicted fertile window',
              date:
                  '${DateFormat('MMM d').format(fertileWindowStart)} - ${DateFormat('MMM d').format(fertileWindowEnd)}',
            ),
            const SizedBox(height: 12),
          ],
          if (ovulationDate != null)
            _buildPredictionRow(
              icon: Icons.star_outline,
              label: 'Predicted ovulation',
              date: DateFormat('E, MMM d').format(ovulationDate),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow({
    required IconData icon,
    required String label,
    required String date,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    final colorScheme = Theme.of(context).colorScheme;

    final moods = [
      {'icon': Icons.sentiment_very_satisfied, 'label': 'happy'},
      {'icon': Icons.sentiment_satisfied, 'label': 'calm'},
      {'icon': Icons.sentiment_neutral, 'label': 'tired'},
      {'icon': Icons.sentiment_dissatisfied, 'label': 'sad'},
      {'icon': Icons.sentiment_very_dissatisfied, 'label': 'irritable'},
      {'icon': Icons.mood_bad, 'label': 'anxious'},
      {'icon': Icons.bolt, 'label': 'energetic'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
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
                  Icons.mood,
                  size: 20,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((mood) {
              final isSelected = _selectedMood == mood['label'];
              final label = mood['label'] as String;
              return FilterChip(
                onSelected: (_) => _saveMood(label),
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(mood['icon'] as IconData, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label[0].toUpperCase() + label.substring(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.tertiaryContainer,
                checkmarkColor: colorScheme.onTertiaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    final symptoms = [
      {'icon': Icons.ac_unit, 'label': 'cramps'},
      {'icon': Icons.healing, 'label': 'headache'},
      {'icon': Icons.nightlight, 'label': 'fatigue'},
      {'icon': Icons.local_fire_department, 'label': 'bloating'},
      {'icon': Icons.sick, 'label': 'nausea'},
      {'icon': Icons.accessibility_new, 'label': 'back_pain'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
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
                  Icons.medical_services_outlined,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Log your symptoms',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom['label']);
              final label = symptom['label'] as String;
              return FilterChip(
                onSelected: (_) => _toggleSymptom(label),
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(symptom['icon'] as IconData, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map(
                            (word) => word[0].toUpperCase() + word.substring(1),
                          )
                          .join(' '),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.secondaryContainer,
                checkmarkColor: colorScheme.onSecondaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPreview() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Cycle at a Glance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View your full cycle calendar with predictions and logged activities.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Open Calendar'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.onTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Wellness Tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay hydrated and get enough rest during your follicular phase.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final supabase = ref.read(supabaseServiceProvider);
    final isEmailVerified = supabase.isEmailVerified;
    final greeting = _getGreeting();
    final cycleStatus = _getCycleStatus();

    if (_showVerificationRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVerificationDialog();
        setState(() => _showVerificationRequired = false);
      });
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.titleLarge),
              Text('Loading...', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.titleLarge),
            Text(
              cycleStatus,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
            tooltip: 'Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DailyLogScreen(selectedDate: DateTime.now()),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('Log Today'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          if (!isEmailVerified) const EmailVerificationBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildWeekStrip(),
                  _buildCycleCard(),
                  _buildMoodSection(),
                  _buildSymptomsSection(),
                  _buildDailyTip(),
                  _buildCalendarPreview(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCycleStatus() {
    if (_currentPeriod != null && _currentPeriod!.endDate == null) {
      final daysSince =
          DateTime.now().difference(_currentPeriod!.startDate).inDays + 1;
      return 'Day $daysSince of period';
    } else if (_lastPeriodStart != null) {
      final today = DateTime.now();
      final daysSince = today.difference(_lastPeriodStart!).inDays;
      final cycleDay = (daysSince % _averageCycleLength) + 1;
      return 'Day $cycleDay of $_averageCycleLength-day cycle';
    }
    return 'Start tracking your cycle';
  }

  // Helper for accessible text colors on colored backgrounds
  Color _getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Responsive sizing helpers
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.9;
    if (width > 600) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.95;
    if (width > 600) return baseSize * 1.05;
    return baseSize;
  }
}
