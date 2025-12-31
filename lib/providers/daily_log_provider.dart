import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/providers/period_provider.dart';

// Stream provider for mood for a specific date - auto-disposes when not watched
final moodStreamProvider = StreamProvider.autoDispose
    .family<Mood?, DateTime>((ref, date) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getMoodStream(date);
});

// Stream provider for symptoms for a specific date
final symptomsStreamProvider = StreamProvider.autoDispose
    .family<List<Symptom>, DateTime>((ref, date) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase
      .getSymptomsStream(
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      )
      .map((symptoms) => symptoms.where((s) {
            final symptomDate =
                DateTime.parse('${s.date}T00:00:00').toLocal();
            final targetDate = date.toLocal();
            return symptomDate.year == targetDate.year &&
                symptomDate.month == targetDate.month &&
                symptomDate.day == targetDate.day;
          }).toList());
});

// Stream provider for sexual activity for a specific date
final sexualActivityStreamProvider = StreamProvider.autoDispose
    .family<SexualActivity?, DateTime>((ref, date) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getSexualActivityStream(date);
});

// Stream provider for note for a specific date
final noteStreamProvider =
    StreamProvider.autoDispose.family<Note?, DateTime>((ref, date) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getNoteStream(date);
});

// Combined daily log data class
class DailyLogData {
  final Mood? mood;
  final List<Symptom> symptoms;
  final SexualActivity? sexualActivity;
  final Note? note;

  DailyLogData({
    this.mood,
    this.symptoms = const [],
    this.sexualActivity,
    this.note,
  });

  bool get hasAnyData =>
      mood != null ||
      symptoms.isNotEmpty ||
      sexualActivity != null ||
      note != null;
}
