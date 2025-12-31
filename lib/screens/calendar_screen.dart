import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CalendarView();
  }
}

class _CalendarView extends ConsumerStatefulWidget {
  const _CalendarView();

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  final _supabase = SupabaseService();
  late PageController _pageController;
  final int _currentPageIndex = 1; // Changed from 6 to 1 (only 3 months)
  final int _totalMonths = 3; // Changed from 12 to 3 for lazy loading
  DateTime _currentMonth = DateTime.now();

  // Memoized color cache to avoid repeated theme lookups
  final Map<String, Color> _colorCache = {};

  final Map<String, Future<CalendarData>> _calendarDataCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPageIndex,
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCacheKey(DateTime start, DateTime end) {
    return '${start.year}-${start.month}-${start.day}_${end.year}-${end.month}-${end.day}';
  }

  Future<CalendarData> _loadCalendarDataCached(DateTime start, DateTime end) {
    final key = _getCacheKey(start, end);
    return _calendarDataCache.putIfAbsent(
      key,
      () => _loadCalendarData(start, end),
    );
  }

  DateTime _getMonthForPage(int pageIndex) {
    final validPageIndex = pageIndex.clamp(0, _totalMonths - 1);
    final monthsFromStart = validPageIndex - _currentPageIndex;
    final now = DateTime.now();
    return DateTime(now.year, now.month + monthsFromStart, 1);
  }

  void _goToToday() {
    _pageController.animateToPage(
      _currentPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _totalMonths) {
      _pageController.jumpToPage(index.clamp(0, _totalMonths - 1));
      return;
    }

    final newMonth = _getMonthForPage(index);
    if (newMonth.month != _currentMonth.month ||
        newMonth.year != _currentMonth.year) {
      setState(() {
        _currentMonth = newMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Go to today',
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildWeekdayHeaders(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _totalMonths,
              itemBuilder: (context, index) {
                final month = _getMonthForPage(index);
                return _buildMonthView(month);
              },
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Expanded(child: _WeekdayHeaderCell(day: 'Sun')),
          Expanded(child: _WeekdayHeaderCell(day: 'Mon')),
          Expanded(child: _WeekdayHeaderCell(day: 'Tue')),
          Expanded(child: _WeekdayHeaderCell(day: 'Wed')),
          Expanded(child: _WeekdayHeaderCell(day: 'Thu')),
          Expanded(child: _WeekdayHeaderCell(day: 'Fri')),
          Expanded(child: _WeekdayHeaderCell(day: 'Sat')),
        ],
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    final monthYear = DateFormat('MMMM yyyy').format(month);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                monthYear,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(child: _buildCalendarGrid(month)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekday));
    final totalDays = 42;

    return FutureBuilder<CalendarData>(
      future: _loadCalendarDataCached(
        startDate,
        startDate.add(Duration(days: totalDays)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final data = snapshot.data ?? CalendarData.empty();

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: totalDays,
          itemBuilder: (context, index) {
            final date = startDate.add(Duration(days: index));
            final isCurrentMonth = date.month == month.month;
            final isToday =
                _normalizeDate(date) == _normalizeDate(DateTime.now());

            return _buildDayCell(date, isCurrentMonth, isToday, data);
          },
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime date,
    bool isCurrentMonth,
    bool isToday,
    CalendarData data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedDate = _normalizeDate(date);

    final hasPeriod = data.periodDays.contains(normalizedDate);
    final hasPredictedPeriod = data.predictedPeriodDays.contains(
      normalizedDate,
    );
    final isFertile = data.fertileDays.contains(normalizedDate);
    final isOvulation = data.ovulationDays.contains(normalizedDate);

    final hasMood = data.moods.containsKey(normalizedDate);
    final hasSymptoms = data.symptoms.containsKey(normalizedDate);
    final hasSexualActivity = data.sexualActivities.containsKey(normalizedDate);
    final hasNote = data.notes.containsKey(normalizedDate);
    final hasAnyLog = hasMood || hasSymptoms || hasSexualActivity || hasNote;

    Color? backgroundColor;
    Color? textColor;
    Color? borderColor;

    if (hasPeriod) {
      backgroundColor = _getMemoizedColor(
        context,
        'menstrual_bg',
        () => AppColors.getMenstrualPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'menstrual_text',
        () => AppColors.getMenstrualTextColor(context),
      );
    } else if (hasPredictedPeriod) {
      backgroundColor = _getMemoizedColor(
        context,
        'luteal_bg',
        () => AppColors.getLutealPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'predicted_text',
        () => AppColors.getPredictedTextColor(context),
      );
    } else if (isOvulation) {
      backgroundColor = _getMemoizedColor(
        context,
        'ovulation_bg',
        () => AppColors.getOvulationDayColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'ovulation_text',
        () => AppColors.getOvulationTextColor(context),
      );
    } else if (isFertile) {
      backgroundColor = _getMemoizedColor(
        context,
        'fertile_bg',
        () => AppColors.getFollicularPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'fertile_text',
        () => AppColors.getFertileTextColor(context),
      );
    }

    if (isToday) {
      borderColor = colorScheme.primary;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Show day details or open daily log
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          border: Border.all(
            color:
                borderColor ??
                colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: borderColor != null ? 2.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: !isCurrentMonth
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : textColor ?? colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            if (hasPeriod && hasSexualActivity)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.onError,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.error, width: 1),
                  ),
                ),
              ),
            if (hasAnyLog && !hasPeriod && !hasPredictedPeriod)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasMood)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getMemoizedColor(
                            context,
                            'mood_log',
                            () => AppColors.getMoodLogColor(context),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasSymptoms)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getMemoizedColor(
                            context,
                            'symptoms_log',
                            () => AppColors.getSymptomsLogColor(context),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasSexualActivity)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getMemoizedColor(
                            context,
                            'activity_log',
                            () => AppColors.getSexualActivityLogColor(context),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasNote)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getMemoizedColor(
                            context,
                            'note_log',
                            () => AppColors.getNoteLogColor(context),
                          ),
                          shape: BoxShape.circle,
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

  Widget _buildLegend() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildLegendItem(
                AppColors.getMenstrualPhaseColor(context),
                'Period',
                textColor: AppColors.getMenstrualTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getLutealPhaseColor(context),
                'Predicted',
                textColor: AppColors.getPredictedTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getOvulationDayColor(context),
                'Ovulation',
                textColor: AppColors.getOvulationTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getFollicularPhaseColor(context),
                'Fertile',
                textColor: AppColors.getFertileTextColor(context),
              ),
              _buildLegendItem(
                colorScheme.surface,
                'Today',
                border: colorScheme.primary,
                textColor: colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Daily Logs',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildDotLegend(AppColors.getMoodLogColor(context), 'Mood'),
              _buildDotLegend(
                AppColors.getSymptomsLogColor(context),
                'Symptoms',
              ),
              _buildDotLegend(
                AppColors.getSexualActivityLogColor(context),
                'Activity',
              ),
              _buildDotLegend(AppColors.getNoteLogColor(context), 'Note'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    Color? border,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: border != null
                ? Border.all(color: border, width: 2)
                : Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: border != null
              ? null
              : Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? colorScheme.onSurface,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDotLegend(Color color, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<CalendarData> _loadCalendarData(DateTime start, DateTime end) async {
    try {
      // Load periods
      final periods = await _supabase.getPeriodsInRange(
        startDate: start,
        endDate: end,
      );

      // Load user data for predictions
      final userData = await _supabase.getUserData();
      final lastPeriodStart = userData?['last_period_start'] != null
          ? DateTime.parse(userData!['last_period_start'])
          : null;
      final averageCycleLength = userData?['average_cycle_length'] ?? 28;
      final averagePeriodLength = userData?['average_period_length'] ?? 5;

      // Calculate period days
      final periodDays = <DateTime>{};
      for (final period in periods) {
        final periodStart = period.startDate;
        final periodEnd = period.endDate ?? DateTime.now();

        for (int i = 0; i <= periodEnd.difference(periodStart).inDays; i++) {
          periodDays.add(
            _normalizeDate(
              DateTime(
                periodStart.year,
                periodStart.month,
                periodStart.day + i,
              ),
            ),
          );
        }
      }

      // Calculate predictions
      final predictedPeriodDays = <DateTime>{};
      final fertileDays = <DateTime>{};
      final ovulationDays = <DateTime>{};

      if (lastPeriodStart != null) {
        final today = DateTime.now();
        final endDate = DateTime(today.year, today.month + 4, 1);
        DateTime currentPrediction = lastPeriodStart;

        while (currentPrediction.isBefore(endDate)) {
          if (currentPrediction.isAfter(
            today.subtract(const Duration(days: 1)),
          )) {
            for (int i = 0; i < averagePeriodLength; i++) {
              final day = currentPrediction.add(Duration(days: i));
              predictedPeriodDays.add(_normalizeDate(day));
            }

            final ovulationDate = currentPrediction.add(
              Duration(days: averageCycleLength - 14),
            );
            ovulationDays.add(_normalizeDate(ovulationDate));

            for (int i = -5; i <= 0; i++) {
              final fertileDay = ovulationDate.add(Duration(days: i));
              if (!ovulationDays.contains(_normalizeDate(fertileDay))) {
                fertileDays.add(_normalizeDate(fertileDay));
              }
            }
          }
          currentPrediction = currentPrediction.add(
            Duration(days: averageCycleLength),
          );
        }
      }

      // Load daily logs in parallel using batch queries (performance optimization)
      final moods = <DateTime, Mood>{};
      final symptoms = <DateTime, List<Symptom>>{};
      final sexualActivities = <DateTime, SexualActivity>{};
      final notes = <DateTime, Note>{};

      // Use Future.wait to fetch all data in parallel instead of sequential loop
      final results = await Future.wait([
        _supabase.getMoodsInRange(startDate: start, endDate: end),
        _supabase.getSymptomsInRange(startDate: start, endDate: end),
        _supabase.getSexualActivitiesInRange(startDate: start, endDate: end),
        _supabase.getNotesInRange(startDate: start, endDate: end),
      ]);

      // Process moods - index-based data structure
      for (final mood in results[0] as List<Mood>) {
        moods[_normalizeDate(mood.date)] = mood;
      }

      // Process symptoms - index-based data structure
      for (final symptom in results[1] as List<Symptom>) {
        final normalizedDate = _normalizeDate(symptom.date);
        symptoms.putIfAbsent(normalizedDate, () => []).add(symptom);
      }

      // Process sexual activities - index-based data structure
      for (final activity in results[2] as List<SexualActivity>) {
        sexualActivities[_normalizeDate(activity.date)] = activity;
      }

      // Process notes - index-based data structure
      for (final note in results[3] as List<Note>) {
        notes[_normalizeDate(note.date)] = note;
      }

      return CalendarData(
        periodDays: periodDays,
        predictedPeriodDays: predictedPeriodDays,
        fertileDays: fertileDays,
        ovulationDays: ovulationDays,
        moods: moods,
        symptoms: symptoms,
        sexualActivities: sexualActivities,
        notes: notes,
      );
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
      return CalendarData.empty();
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Memoized color getter to avoid repeated theme context lookups
  Color _getMemoizedColor(
    BuildContext context,
    String key,
    Color Function() colorGetter,
  ) {
    return _colorCache.putIfAbsent(key, colorGetter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear color cache on theme changes
    _colorCache.clear();
  }
}

class CalendarData {
  final Set<DateTime> periodDays;
  final Set<DateTime> predictedPeriodDays;
  final Set<DateTime> fertileDays;
  final Set<DateTime> ovulationDays;
  final Map<DateTime, Mood> moods;
  final Map<DateTime, List<Symptom>> symptoms;
  final Map<DateTime, SexualActivity> sexualActivities;
  final Map<DateTime, Note> notes;

  CalendarData({
    required this.periodDays,
    required this.predictedPeriodDays,
    required this.fertileDays,
    required this.ovulationDays,
    required this.moods,
    required this.symptoms,
    required this.sexualActivities,
    required this.notes,
  });

  factory CalendarData.empty() {
    return CalendarData(
      periodDays: {},
      predictedPeriodDays: {},
      fertileDays: {},
      ovulationDays: {},
      moods: {},
      symptoms: {},
      sexualActivities: {},
      notes: {},
    );
  }
}

// Const widget for weekday headers (performance optimization)
class _WeekdayHeaderCell extends StatelessWidget {
  final String day;

  const _WeekdayHeaderCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
