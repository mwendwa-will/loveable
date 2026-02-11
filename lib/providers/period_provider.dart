import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/services/supabase_service.dart';
import 'package:lunara/services/period_service.dart';
import 'package:lunara/services/profile_service.dart';
import 'package:lunara/services/health_service.dart';
import 'package:lunara/services/auth_service.dart';

// Provider for SupabaseService (deprecated - prefer domain services)
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Domain service providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final periodServiceProvider = Provider<PeriodService>((ref) {
  return PeriodService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

// Stream provider for periods in a date range - with auto disposal and caching
final periodsStreamProvider = StreamProvider.autoDispose
    .family<List<Period>, DateRange>((ref, dateRange) {
      final periodService = ref.watch(periodServiceProvider);
      return periodService.getPeriodsStream(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// FutureProvider for user data (cached, non-auto-disposing)
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final profile = ref.watch(profileServiceProvider);
  return await profile.getUserData();
});

// Helper class for date range
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}
