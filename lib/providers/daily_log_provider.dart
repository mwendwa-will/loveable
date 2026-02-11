import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/models/mood.dart';
import 'package:lunara/models/symptom.dart';
import 'package:lunara/models/sexual_activity.dart';
import 'package:lunara/models/note.dart';
import 'package:lunara/providers/period_provider.dart';

// Stream provider for mood for a specific date - auto-disposes when not watched
final moodStreamProvider = StreamProvider.autoDispose.family<Mood?, DateTime>((
  ref,
  date,
) {
  final health = ref.watch(healthServiceProvider);
  return health.getMoodStream(date);
});

// Stream provider for symptoms for a specific date
final symptomsStreamProvider = StreamProvider.autoDispose
    .family<List<Symptom>, DateTime>((ref, date) {
      final health = ref.watch(healthServiceProvider);
      return health.getSymptomsStream(
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      );
    });

// Stream provider for sexual activity for a specific date
final sexualActivityStreamProvider = StreamProvider.autoDispose
    .family<SexualActivity?, DateTime>((ref, date) {
      final health = ref.watch(healthServiceProvider);
      return health.getSexualActivityStream(date);
    });

// Stream provider for note for a specific date
final noteStreamProvider = StreamProvider.autoDispose.family<Note?, DateTime>((
  ref,
  date,
) {
  final health = ref.watch(healthServiceProvider);
  return health.getNoteStream(date);
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
