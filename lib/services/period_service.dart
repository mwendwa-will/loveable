import 'dart:async';

import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/models/period.dart';

/// Wrapper for period-related operations
class PeriodService {
  static final PeriodService _instance = PeriodService._internal();
    factory PeriodService({SupabaseService? supabase}) => _instance;
    PeriodService._internal({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService();

    final SupabaseService _supabase;
    final StreamController<void> _periodChangeController = StreamController<void>.broadcast();

    /// Stream that emits when periods change (created/ended/updated)
    Stream<void> get periodChanges => _periodChangeController.stream;

  Future<List<Period>> getCompletedPeriods({int? limit}) => _supabase.getCompletedPeriods(limit: limit);

    Future<Period> startPeriod({required DateTime startDate, FlowIntensity? intensity}) async {
            final period = await _supabase.startPeriod(startDate: startDate, intensity: intensity);
            try {
                _periodChangeController.add(null);
            } catch (_) {}
            return period;
    }

  Future<void> deletePeriod(String periodId) => _supabase.deletePeriod(periodId);

  Future<Period> updatePeriodIntensity({required String periodId, required FlowIntensity intensity}) =>
      _supabase.updatePeriodIntensity(periodId: periodId, intensity: intensity);

  Future<Period> endPeriod({required String periodId, required DateTime endDate}) =>
      _supabase.endPeriod(periodId: periodId, endDate: endDate);

  Future<Period?> getCurrentPeriod() => _supabase.getCurrentPeriod();

  Future<List<Period>> getPeriods({int? limit}) => _supabase.getPeriods(limit: limit);

  Future<List<Period>> getPeriodsInRange({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getPeriodsInRange(startDate: startDate, endDate: endDate);

  Stream<List<Period>> getPeriodsStream({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getPeriodsStream(startDate: startDate, endDate: endDate);

    Future<void> logPrediction({
        required String userId,
        required int cycleNumber,
        required DateTime predictedDate,
        required double confidence,
        required String method,
    }) async {
        await _supabase.client.from('prediction_logs').insert({
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
        final logs = await _supabase.client.from('prediction_logs').select().eq('user_id', userId).eq('cycle_number', cycleNumber).order('created_at', ascending: false).limit(1);
                return (logs as List).cast<Map<String, dynamic>>();
    }

    Future<void> updatePredictionLog(String id, Map<String, dynamic> updates) async {
        await _supabase.client.from('prediction_logs').update(updates).eq('id', id);
    }

    Future<void> logAnomaly({
        required String userId,
        required DateTime periodDate,
        required int cycleLength,
        required double averageCycle,
        required double variability,
    }) async {
        await _supabase.client.from('cycle_anomalies').insert({
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
            await _supabase.client.rpc('increment_anomaly_count', params: {'p_user_id': userId});
        } catch (_) {
            // RPC might not exist; ignore errors
        }
    }

    Future<List<Map<String, dynamic>>> getPredictionLogs(String userId) async {
        final logs = await _supabase.client.from('prediction_logs').select().eq('user_id', userId).order('created_at', ascending: false);
        return (logs as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList();
    }
}
