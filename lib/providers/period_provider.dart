import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/services/supabase_service.dart';

// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Stream provider for periods in a date range - with auto disposal and caching
final periodsStreamProvider = StreamProvider.autoDispose
    .family<List<Period>, DateRange>((ref, dateRange) {
      final supabase = ref.watch(supabaseServiceProvider);
      return supabase.getPeriodsStream(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// FutureProvider for user data (cached, non-auto-disposing)
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return await supabase.getUserData();
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