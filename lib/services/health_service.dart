import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';

/// Wrapper for mood/symptom/note/sexual activity operations
class HealthService {
  static final HealthService _instance = HealthService._internal();
    factory HealthService({SupabaseService? supabase}) => _instance;
    HealthService._internal({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService();

    final SupabaseService _supabase;

  Future<List<dynamic>> getMoodsInRange({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getMoodsInRange(startDate: startDate, endDate: endDate);

  Future<List<dynamic>> getSymptomsInRange({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getSymptomsInRange(startDate: startDate, endDate: endDate);

  Future<List<dynamic>> getSexualActivitiesInRange({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getSexualActivitiesInRange(startDate: startDate, endDate: endDate);

  Future<List<dynamic>> getNotesInRange({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getNotesInRange(startDate: startDate, endDate: endDate);

  Stream<Mood?> getMoodStream(DateTime date) => _supabase.getMoodStream(date);

  Stream<List<Symptom>> getSymptomsStream({required DateTime startDate, required DateTime endDate}) =>
      _supabase.getSymptomsStream(startDate: startDate, endDate: endDate);

  Stream<SexualActivity?> getSexualActivityStream(DateTime date) => _supabase.getSexualActivityStream(date);

  Stream<Note?> getNoteStream(DateTime date) => _supabase.getNoteStream(date);

  Future<void> saveMood({required DateTime date, required MoodType mood}) =>
      _supabase.saveMood(date: date, mood: mood);

  Future<void> deleteMood(String id) => _supabase.deleteMood(id);

    Future<void> saveSymptoms({
        required DateTime date,
        required List<SymptomType> symptomTypes,
        Map<SymptomType, int>? severities,
        Map<SymptomType, String>? notes,
    }) => _supabase.saveSymptoms(
                date: date,
                symptomTypes: symptomTypes,
                severities: severities,
                notes: notes,
            );

  Future<void> deleteSymptom(String id) => _supabase.deleteSymptom(id);

    Future<void> saveNote({required DateTime date, required String content}) => _supabase.saveNote(date: date, content: content);

  Future<void> deleteNote(String id) => _supabase.deleteNote(id);

    Future<void> logSexualActivity({required DateTime date, required bool protectionUsed, ProtectionType? protectionType}) =>
            _supabase.logSexualActivity(date: date, protectionUsed: protectionUsed, protectionType: protectionType);

    Future<void> deleteSexualActivity(String id) => _supabase.deleteSexualActivity(id);
}
