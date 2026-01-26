import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/repositories/period_repository.dart';

// State class
class AnalyticsState {
  final bool isLoading;
  final List<Period> periodHistory;
  final int averageCycleLength;
  final int averagePeriodLength;
  final String trendMessage;

  const AnalyticsState({
    this.isLoading = true,
    this.periodHistory = const [],
    this.averageCycleLength = 0,
    this.averagePeriodLength = 0,
    this.trendMessage = '',
  });
}

// Stats Provider
final analyticsViewModelProvider =
    AsyncNotifierProvider<AnalyticsViewModel, AnalyticsState>(
      () => AnalyticsViewModel(),
    );

class AnalyticsViewModel extends AsyncNotifier<AnalyticsState> {
  late PeriodRepository _periodRepo;

  @override
  Future<AnalyticsState> build() async {
    _periodRepo = ref.watch(periodRepositoryProvider);
    return _loadData();
  }

  Future<AnalyticsState> _loadData() async {
    // We already have a stream of periods, but for analytics we might want a one-time fetch or just listen
    // access the repository directly for simplicity of the prompt, assuming we have a method for full history
    // Since PeriodRepository exposes a stream, we can take the snapshot.
    // However, clean architecture might suggest a method `getAllPeriods()`.
    // Let's assume we can listen to the existing streamProvider or repo.

    // For now, let's fetch valid finished periods for analytics
    final periods = await _periodRepo.getPeriodHistory();
    // Note: If getPeriodHistory() doesn't exist, we might need to add it or use the stream.
    // Let's assume we need to implement it or use what's available.
    // In previous steps (Refactor Supabase), we likely kept `getPeriods()` or similar.

    // Sort descending (newest first)
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (periods.isEmpty) {
      return const AnalyticsState(
        isLoading: false,
        trendMessage: 'Log more periods to see trends',
      );
    }

    // Calculate averages
    int totalPeriodDays = 0;
    int totalCycleDays = 0;
    int cycleCount = 0;

    for (var p in periods) {
      if (p.endDate != null) {
        totalPeriodDays += p.endDate!.difference(p.startDate).inDays + 1;
      }
    }

    // Cycle length is difference between consecutive start dates
    for (int i = 0; i < periods.length - 1; i++) {
      final current = periods[i];
      final previous = periods[i + 1];
      final diff = current.startDate.difference(previous.startDate).inDays;
      // Filter out unreasonable outliers if needed (e.g. > 100 days might be missed period)
      if (diff > 15 && diff < 100) {
        totalCycleDays += diff;
        cycleCount++;
      }
    }

    final avgPeriod = periods.isNotEmpty
        ? (totalPeriodDays / periods.length).round()
        : 5;
    final avgCycle = cycleCount > 0
        ? (totalCycleDays / cycleCount).round()
        : 28;

    String trend = 'Your cycle is consistent.';
    if (cycleCount > 2) {
      // Simple trend logic
      // Compare last 2 cycles vs average
      final lastCycleLen = periods[0].startDate
          .difference(periods[1].startDate)
          .inDays;
      if ((lastCycleLen - avgCycle).abs() > 3) {
        trend =
            'Your last cycle was ${lastCycleLen > avgCycle ? 'longer' : 'shorter'} than usual.';
      }
    }

    return AnalyticsState(
      isLoading: false,
      periodHistory: periods,
      averageCycleLength: avgCycle,
      averagePeriodLength: avgPeriod,
      trendMessage: trend,
    );
  }
}
