import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lunara/core/exceptions/app_exceptions.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/services/supabase_service.dart';
import 'package:lunara/services/cycle_analyzer.dart';
import 'package:lunara/repositories/user_repository.dart';

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository(
    SupabaseService().client,
    ref.watch(userRepositoryProvider),
  );
});

class PeriodRepository {
  final SupabaseClient _client;
  final UserRepository _userRepo;

  PeriodRepository(this._client, this._userRepo);

  User? get _currentUser => _client.auth.currentUser;

  Future<List<Period>> getPeriods({int? limit}) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    var query = _client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .order('start_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((json) => Period.fromJson(json)).toList();
  }

  Future<List<Period>> getCompletedPeriods({int? limit}) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    var query = _client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .not('end_date', 'is', null)
        .order('start_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((json) => Period.fromJson(json)).toList();
  }

  // Alias for analytics
  Future<List<Period>> getPeriodHistory() => getCompletedPeriods();

  Future<List<Period>> getPeriodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final lookbackDate = startDate.subtract(const Duration(days: 60));

    final response = await _client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .gte('start_date', lookbackDate.toIso8601String())
        .lte('start_date', endDate.toIso8601String())
        .order('start_date', ascending: false);

    final allPeriods = (response as List)
        .map((json) => Period.fromJson(json))
        .toList();

    return allPeriods.where((period) {
      final periodStart = period.startDate;
      final periodEnd = period.endDate ?? DateTime.now();
      return periodStart.isBefore(endDate.add(const Duration(days: 1))) &&
          periodEnd.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  Future<Period?> getCurrentPeriod() async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .isFilter('end_date', null)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Period.fromJson(response);
  }

  Future<Period> startPeriod({
    required DateTime startDate,
    FlowIntensity? intensity,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    // Auto-close old periods
    try {
      final ongoingPeriods = await _client
          .from('periods')
          .select()
          .eq('user_id', user.id)
          .isFilter('end_date', null);

      for (final periodData in ongoingPeriods) {
        final period = Period.fromJson(periodData);
        final daysSinceStart = DateTime.now()
            .difference(period.startDate)
            .inDays;

        if (daysSinceStart > 15) {
          final autoEndDate = period.startDate.add(const Duration(days: 7));
          await _client
              .from('periods')
              .update({'end_date': autoEndDate.toIso8601String()})
              .eq('id', period.id)
              .eq('user_id', user.id);
        }
      }
    } catch (_) {}

    // Record accuracy
    try {
      final userData = await _userRepo.getUserData();
      if (userData != null) {
        final lastPeriodStart = userData['last_period_start'] != null
            ? DateTime.parse(userData['last_period_start'])
            : null;

        if (lastPeriodStart != null) {
          final completedPeriods = await getCompletedPeriods(limit: 100);
          final cycleNumber = completedPeriods.length + 1;
          await CycleAnalyzer.recordPredictionAccuracy(
            userId: user.id,
            cycleNumber: cycleNumber,
            actualDate: startDate,
          );
        }
      }
    } catch (_) {}

    final data = {
      'user_id': user.id,
      'start_date': startDate.toIso8601String(),
      'flow_intensity': intensity?.name ?? FlowIntensity.medium.name,
    };

    final response = await _client
        .from('periods')
        .insert(data)
        .select()
        .single();

    // Update user stats
    await _userRepo.updateUserData({
      'last_period_start': startDate.toIso8601String(),
    });

    try {
      await CycleAnalyzer.recalculateAfterPeriodStart(user.id);
    } catch (_) {}

    return Period.fromJson(response);
  }

  Future<Period> endPeriod({
    required String periodId,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final periodData = await _client
        .from('periods')
        .select()
        .eq('id', periodId)
        .eq('user_id', user.id)
        .single();

    final period = Period.fromJson(periodData);

    if (endDate.isBefore(period.startDate)) {
      throw ValidationException(
        'End date cannot be before start date',
        code: 'VAL_003',
      );
    }

    final durationDays = endDate.difference(period.startDate).inDays;
    if (durationDays > 15) {
      throw ValidationException(
        'Periods should be under 15 days',
        code: 'VAL_004',
      );
    }

    final response = await _client
        .from('periods')
        .update({'end_date': endDate.toIso8601String()})
        .eq('id', periodId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Period.fromJson(response);
  }

  Future<void> logPrediction({
    required String userId,
    required int cycleNumber,
    required DateTime predictedDate,
    required double confidence,
    required String method,
  }) async {
    await _client.from('prediction_logs').insert({
      'user_id': userId,
      'cycle_number': cycleNumber,
      'predicted_date': predictedDate.toIso8601String(),
      'confidence_at_prediction': confidence,
      'prediction_method': method,
    });
  }

  Future<List<Map<String, dynamic>>> getLatestPredictionLog({
    required String userId,
    required int cycleNumber,
  }) async {
    final logs = await _client
        .from('prediction_logs')
        .select()
        .eq('user_id', userId)
        .eq('cycle_number', cycleNumber)
        .order('created_at', ascending: false)
        .limit(1);
    return (logs as List).cast<Map<String, dynamic>>();
  }

  Future<void> updatePredictionLog(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await _client.from('prediction_logs').update(updates).eq('id', id);
  }

  Future<void> logAnomaly({
    required String userId,
    required DateTime periodDate,
    required int cycleLength,
    required double averageCycle,
    required double variability,
  }) async {
    await _client.from('cycle_anomalies').insert({
      'user_id': userId,
      'period_date': periodDate.toIso8601String(),
      'cycle_length': cycleLength,
      'average_cycle': averageCycle,
      'variability': variability,
      'detected_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> incrementAnomalyCount(String userId) async {
    try {
      await _client.rpc(
        'increment_anomaly_count',
        params: {'p_user_id': userId},
      );
    } catch (_) {
      // RPC might not exist; ignore errors
    }
  }

  Future<List<Map<String, dynamic>>> getPredictionLogs(String userId) async {
    final logs = await _client
        .from('prediction_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (logs as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
  }

  // --- Daily Flow Tracking ---

  Future<void> saveDailyFlow({
    required DateTime date,
    required FlowIntensity intensity,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();
    final dateStr = date.toIso8601String().split('T')[0];

    // Check if flow exists for this day (upsert)
    await _client.from('daily_flows').upsert({
      'user_id': user.id,
      'date': dateStr,
      'flow_intensity': intensity.name,
    }, onConflict: 'user_id, date');
  }

  Future<FlowIntensity?> getDailyFlow(DateTime date) async {
    final user = _currentUser;
    if (user == null) return null;

    final response = await _client
        .from('daily_flows')
        .select('flow_intensity')
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return FlowIntensity.fromString(response['flow_intensity'] as String);
  }

  Future<void> deleteDailyFlow(DateTime date) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    await _client
        .from('daily_flows')
        .delete()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0]);
  }
}
