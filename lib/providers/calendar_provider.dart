import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/models/mood.dart';
import 'package:lunara/models/symptom.dart';
import 'package:lunara/models/sexual_activity.dart';
import 'package:lunara/models/note.dart';
import 'package:lunara/services/period_service.dart';
import 'package:lunara/services/cycle_analyzer.dart';
import 'package:lunara/services/health_service.dart';
import 'package:lunara/services/supabase_service.dart';

// --- State Class ---

class CalendarState {
  final Set<DateTime> periodDays;
  final Set<DateTime> predictedPeriodDays;
  final Set<DateTime> fertileDays;
  final Set<DateTime> ovulationDays;
  final Map<DateTime, Mood> moods;
  final Map<DateTime, List<Symptom>> symptoms;
  final Map<DateTime, SexualActivity> sexualActivities;
  final Map<DateTime, Note> notes;

  // Selected date state
  final DateTime selectedDate;
  final DateTime focusedDay;

  const CalendarState({
    required this.periodDays,
    required this.predictedPeriodDays,
    required this.fertileDays,
    required this.ovulationDays,
    required this.moods,
    required this.symptoms,
    required this.sexualActivities,
    required this.notes,
    required this.selectedDate,
    required this.focusedDay,
  });

  factory CalendarState.initial() {
    final now = DateTime.now();
    return CalendarState(
      periodDays: {},
      predictedPeriodDays: {},
      fertileDays: {},
      ovulationDays: {},
      moods: {},
      symptoms: {},
      sexualActivities: {},
      notes: {},
      selectedDate: now,
      focusedDay: now,
    );
  }

  CalendarState copyWith({
    Set<DateTime>? periodDays,
    Set<DateTime>? predictedPeriodDays,
    Set<DateTime>? fertileDays,
    Set<DateTime>? ovulationDays,
    Map<DateTime, Mood>? moods,
    Map<DateTime, List<Symptom>>? symptoms,
    Map<DateTime, SexualActivity>? sexualActivities,
    Map<DateTime, Note>? notes,
    DateTime? selectedDate,
    DateTime? focusedDay,
  }) {
    return CalendarState(
      periodDays: periodDays ?? this.periodDays,
      predictedPeriodDays: predictedPeriodDays ?? this.predictedPeriodDays,
      fertileDays: fertileDays ?? this.fertileDays,
      ovulationDays: ovulationDays ?? this.ovulationDays,
      moods: moods ?? this.moods,
      symptoms: symptoms ?? this.symptoms,
      sexualActivities: sexualActivities ?? this.sexualActivities,
      notes: notes ?? this.notes,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDay: focusedDay ?? this.focusedDay,
    );
  }
}

// --- Provider ---

final calendarProvider = AsyncNotifierProvider<CalendarNotifier, CalendarState>(
  () => CalendarNotifier(),
);

class CalendarNotifier extends AsyncNotifier<CalendarState> {
  final _periodService = PeriodService();
  final _healthService = HealthService();

  @override
  Future<CalendarState> build() async {
    final now = DateTime.now();
    // Initially fetch a reasonable range (e.g., 3 months back/forward)
    // The screen can request more data as the user scrolls, or we can load a large window

    // Default to current state data if available (e.g. during pull-to-refresh)
    // but on first build, start fresh
    final initialState = CalendarState.initial();

    // Load initial data
    final data = await _fetchDataRange(
      now.subtract(const Duration(days: 90)),
      now.add(const Duration(days: 90)),
    );

    return initialState.copyWith(
      periodDays: data.periodDays,
      predictedPeriodDays: data.predictedPeriodDays,
      fertileDays: data.fertileDays,
      ovulationDays: data.ovulationDays,
      moods: data.moods,
      symptoms: data.symptoms,
      sexualActivities: data.sexualActivities,
      notes: data.notes,
    );
  }

  // Public method to change selected date
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final currentState = state.asData?.value;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(
          selectedDate: selectedDay,
          focusedDay: focusedDay,
        ),
      );
    }
  }

  // Update only focused day (for page changes)
  void updateFocusedDay(DateTime focusedDay) {
    final currentState = state.asData?.value;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(focusedDay: focusedDay),
      );
    }
  }

  // Public method to refresh data (e.g. after adding a log)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  // Fetch data for a range
  Future<CalendarState> _fetchDataRange(DateTime start, DateTime end) async {
    try {
      // 1. Periods & User Settings
      final periods = await _periodService.getPeriodsInRange(
        startDate: start,
        endDate: end,
      );
      final userData = await SupabaseService().client
          .from('users')
          .select('average_period_length')
          .maybeSingle();
      final avgPeriodLength = userData?['average_period_length'] ?? 5;

      final periodDays = <DateTime>{};
      for (final period in periods) {
        final pStart = period.startDate;
        // Cap ongoing period at average length or today, whichever is more conservative for visualization
        DateTime pEnd = period.endDate ?? DateTime.now();
        if (period.endDate == null) {
          final maxOngoing = pStart.add(Duration(days: avgPeriodLength - 1));
          if (pEnd.isAfter(maxOngoing)) {
            pEnd = maxOngoing;
          }
        }

        for (int i = 0; i <= pEnd.difference(pStart).inDays; i++) {
          periodDays.add(_normalizeDate(pStart.add(Duration(days: i))));
        }
      }

      // 2. Predictions
      final predictions = await CycleAnalyzer.getCurrentPrediction();
      final predictedPeriodDays = predictions['predictedPeriodDays'] ?? {};
      final fertileDays = predictions['fertileDays'] ?? {};
      final ovulationDays = predictions['ovulationDays'] ?? {};

      // 3. User Logs in parallel
      final results = await Future.wait([
        _healthService.getMoodsInRange(startDate: start, endDate: end),
        _healthService.getSymptomsInRange(startDate: start, endDate: end),
        _healthService.getSexualActivitiesInRange(
          startDate: start,
          endDate: end,
        ),
        _healthService.getNotesInRange(startDate: start, endDate: end),
      ]);

      final moods = <DateTime, Mood>{};
      for (final m in results[0] as List<Mood>) {
        moods[_normalizeDate(m.date)] = m;
      }

      final symptoms = <DateTime, List<Symptom>>{};
      for (final s in results[1] as List<Symptom>) {
        final date = _normalizeDate(s.date);
        symptoms.putIfAbsent(date, () => []).add(s);
      }

      final activities = <DateTime, SexualActivity>{};
      for (final a in results[2] as List<SexualActivity>) {
        activities[_normalizeDate(a.date)] = a;
      }

      final notes = <DateTime, Note>{};
      for (final n in results[3] as List<Note>) {
        notes[_normalizeDate(n.date)] = n;
      }

      // Preserve existing selection/focus if reloading
      final currentState = state.asData?.value ?? CalendarState.initial();

      return currentState.copyWith(
        periodDays: periodDays,
        predictedPeriodDays: predictedPeriodDays,
        fertileDays: fertileDays,
        ovulationDays: ovulationDays,
        moods: moods,
        symptoms: symptoms,
        sexualActivities: activities,
        notes: notes,
      );
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
      // On error, return empty state with current date selection to allow retry or at least navigation
      final currentState = state.asData?.value ?? CalendarState.initial();
      return currentState;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
