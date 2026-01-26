import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lovely/core/exceptions/app_exceptions.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/services/supabase_service.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(SupabaseService().client);
});

class HealthRepository {
  final SupabaseClient _client;

  HealthRepository(this._client);

  User? get _currentUser => _client.auth.currentUser;

  // --- Moods ---

  Future<Mood> saveMood({
    required DateTime date,
    required MoodType mood,
    String? notes,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final existing = await _client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    try {
      if (existing != null) {
        final response = await _client
            .from('moods')
            .update({'mood_type': mood.name, if (notes != null) 'notes': notes})
            .eq('id', existing['id'])
            .select()
            .single();
        return Mood.fromJson(response);
      } else {
        final data = {
          'user_id': user.id,
          'date': date.toIso8601String().split('T')[0],
          'mood_type': mood.name,
          if (notes != null) 'notes': notes,
        };
        final response = await _client
            .from('moods')
            .insert(data)
            .select()
            .single();
        return Mood.fromJson(response);
      }
    } catch (e) {
      debugPrint('Failed to save mood: $e');
      rethrow;
    }
  }

  Future<Mood?> getMoodForDate(DateTime date) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return Mood.fromJson(response);
  }

  Future<List<Mood>> getMoodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return (response as List).map((json) => Mood.fromJson(json)).toList();
  }

  Future<void> deleteMood(int id) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();
    await _client.from('moods').delete().eq('id', id).eq('user_id', user.id);
  }

  // --- Symptoms ---

  Future<List<Symptom>> saveSymptoms({
    required DateTime date,
    required List<SymptomType> symptomTypes,
    Map<SymptomType, int>? severities,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();
    final dateStr = date.toIso8601String().split('T')[0];

    // Delete existing symptoms for this date (simpler than upserting individual records)
    // In a production app with high volume, this might be optimized
    await _client
        .from('symptoms')
        .delete()
        .eq('user_id', user.id)
        .eq('date', dateStr);

    if (symptomTypes.isEmpty) return [];

    final rows = symptomTypes
        .map(
          (type) => {
            'user_id': user.id,
            'date': dateStr,
            'symptom_type': type.name,
            'severity': severities?[type] ?? 3, // Default to moderate
          },
        )
        .toList();

    final response = await _client.from('symptoms').insert(rows).select();

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<List<Symptom>> getSymptomsForDate(DateTime date) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0]);

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<List<Symptom>> getSymptomsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<void> deleteSymptom(int id) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();
    await _client.from('symptoms').delete().eq('id', id).eq('user_id', user.id);
  }

  // --- Sexual Activity ---

  Future<SexualActivity?> getSexualActivityForDate(DateTime date) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('sexual_activities')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return SexualActivity.fromJson(response);
  }

  Future<List<SexualActivity>> getSexualActivitiesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('sexual_activities')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return (response as List)
        .map((json) => SexualActivity.fromJson(json))
        .toList();
  }

  // --- Notes ---

  Future<List<Note>> getNotesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return (response as List).map((json) => Note.fromJson(json)).toList();
  }
}
