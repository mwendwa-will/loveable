import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/repositories/period_repository.dart';
import 'package:lunara/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:lunara/repositories/auth_repository.dart';
import 'package:lunara/services/notification_service.dart';

// State class for Home Screen
class HomeState {
  final bool isLoading;
  final bool showVerificationRequired;
  final Period? currentPeriod;
  final DateTime? lastPeriodStart;
  final int averageCycleLength;
  final int averagePeriodLength;

  const HomeState({
    this.isLoading = true,
    this.showVerificationRequired = false,
    this.currentPeriod,
    this.lastPeriodStart,
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? showVerificationRequired,
    Period? currentPeriod,
    DateTime? lastPeriodStart,
    int? averageCycleLength,
    int? averagePeriodLength,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      showVerificationRequired:
          showVerificationRequired ?? this.showVerificationRequired,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
    );
  }
}

// ViewModel provider
final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(
  () => HomeViewModel(),
);

class HomeViewModel extends AsyncNotifier<HomeState> {
  late PeriodRepository _periodRepo;
  late UserRepository _userRepo;
  late AuthRepository _authRepo;

  @override
  Future<HomeState> build() async {
    _periodRepo = ref.watch(periodRepositoryProvider);
    _userRepo = ref.watch(userRepositoryProvider);
    _authRepo = ref.watch(authRepositoryProvider);

    // Initial load
    return await _loadData();
  }

  Future<HomeState> _loadData() async {
    final showVerification = !_authRepo.isEmailVerified;

    // Load parallel data
    final results = await Future.wait([
      _userRepo.getUserData(),
      _periodRepo.getCurrentPeriod(),
    ]);

    final userData = results[0] as Map<String, dynamic>?;
    final currentPeriod = results[1] as Period?;

    DateTime? lastPeriodStart;
    int avgCycle = 28;
    int avgPeriod = 5;

    if (userData != null) {
      lastPeriodStart = userData['last_period_start'] != null
          ? DateTime.parse(userData['last_period_start'])
          : null;
      avgCycle = userData['average_cycle_length'] ?? 28;
      avgPeriod = userData['average_period_length'] ?? 5;
    }

    final homeState = HomeState(
      isLoading: false,
      showVerificationRequired: showVerification,
      currentPeriod: currentPeriod,
      lastPeriodStart: lastPeriodStart,
      averageCycleLength: avgCycle,
      averagePeriodLength: avgPeriod,
    );

    // Automate Notification Scheduling (Fire and forget)
    _scheduleReminders(lastPeriodStart, avgCycle);

    return homeState;
  }

  void _scheduleReminders(DateTime? lastPeriodStart, int avgCycle) {
    try {
      final notificationService = NotificationService();

      // 1. Daily Log Reminder (every evening)
      notificationService.scheduleRecurringNotification(
        id: 2,
        title: 'How are you feeling today?',
        body: 'Take a moment to log your wellness data in Lunara.',
        hour: 20, // 8 PM
        minute: 0,
        channelKey: 'lovely_channel',
      );

      // 2. Period Forecast (if we have data)
      if (lastPeriodStart != null) {
        final nextPeriodDate = lastPeriodStart.add(Duration(days: avgCycle));
        notificationService.schedulePeriodForecast(nextPeriodDate);
      }
    } catch (e) {
      debugPrint('Warning: Failed to schedule reminders: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadData());
  }

  void setVerificationRequired(bool required) {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(showVerificationRequired: required),
      );
    }
  }
}
