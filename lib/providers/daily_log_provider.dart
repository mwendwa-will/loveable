import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/providers/period_provider.dart';

// Stream provider for mood for a specific date - auto-disposes when not watched
final moodStreamProvider = StreamProvider.autoDispose
    .family<Mood?, DateTime>((ref, date) {
  final health = ref.watch(healthServiceProvider);
  final controller = StreamController<Mood?>();
  
  final subscription = health.getMoodStream(date).listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  
  ref.onDispose(() {
    subscription.cancel();
    if (!controller.isClosed) controller.close();
  });
  
  return controller.stream;
});

// Stream provider for symptoms for a specific date
final symptomsStreamProvider = StreamProvider.autoDispose
    .family<List<Symptom>, DateTime>((ref, date) {
  final health = ref.watch(healthServiceProvider);
  final controller = StreamController<List<Symptom>>();
  
  final subscription = health.getSymptomsStream(
    startDate: date,
    endDate: date.add(const Duration(days: 1)),
  ).listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  
  ref.onDispose(() {
    subscription.cancel();
    if (!controller.isClosed) controller.close();
  });
  
  return controller.stream;
});

// Stream provider for sexual activity for a specific date
final sexualActivityStreamProvider = StreamProvider.autoDispose
    .family<SexualActivity?, DateTime>((ref, date) {
  final health = ref.watch(healthServiceProvider);
  final controller = StreamController<SexualActivity?>();
  
  final subscription = health.getSexualActivityStream(date).listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  
  ref.onDispose(() {
    subscription.cancel();
    if (!controller.isClosed) controller.close();
  });
  
  return controller.stream;
});

// Stream provider for note for a specific date
final noteStreamProvider =
    StreamProvider.autoDispose.family<Note?, DateTime>((ref, date) {
  final health = ref.watch(healthServiceProvider);
  final controller = StreamController<Note?>();
  
  final subscription = health.getNoteStream(date).listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  
  ref.onDispose(() {
    subscription.cancel();
    if (!controller.isClosed) controller.close();
  });
  
  return controller.stream;
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
