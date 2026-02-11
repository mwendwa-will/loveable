import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/models/mood.dart';
import 'package:lunara/models/symptom.dart';
import 'package:lunara/models/sexual_activity.dart';
import 'package:lunara/models/note.dart';

void main() {
  group('Period Model', () {
    test('Period can be created with required fields', () {
      final now = DateTime.now();
      final period = Period(
        id: 'test-id',
        userId: 'user-123',
        startDate: DateTime(2024, 1, 1),
        endDate: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(period.id, equals('test-id'));
      expect(period.userId, equals('user-123'));
      expect(period.startDate, equals(DateTime(2024, 1, 1)));
      expect(period.endDate, isNull);
    });

    test('Period.fromJson correctly deserializes data', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'start_date': '2024-01-01T00:00:00.000',
        'end_date': '2024-01-05T00:00:00.000',
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      };

      final period = Period.fromJson(json);

      expect(period.id, equals('test-id'));
      expect(period.userId, equals('user-123'));
      expect(period.startDate, equals(DateTime(2024, 1, 1)));
      expect(period.endDate, equals(DateTime(2024, 1, 5)));
    });
  });

  group('Mood Model', () {
    test('MoodType enum has correct display names', () {
      expect(MoodType.happy.displayName, equals('Happy'));
      expect(MoodType.sad.displayName, equals('Sad'));
      expect(MoodType.anxious.displayName, equals('Anxious'));
      expect(MoodType.energetic.displayName, equals('Energetic'));
      expect(MoodType.tired.displayName, equals('Tired'));
    });

    test('Mood can be created and serialized', () {
      final now = DateTime.now();
      final mood = Mood(
        id: 'mood-1',
        userId: 'user-123',
        date: DateTime(2024, 1, 1),
        moodType: MoodType.happy,
        notes: 'Feeling great today!',
        createdAt: now,
      );

      expect(mood.id, equals('mood-1'));
      expect(mood.moodType, equals(MoodType.happy));
      expect(mood.notes, equals('Feeling great today!'));
    });
  });

  group('Symptom Model', () {
    test('SymptomType enum includes common symptoms', () {
      expect(SymptomType.cramps, isNotNull);
      expect(SymptomType.bloating, isNotNull);
      expect(SymptomType.headache, isNotNull);
      expect(SymptomType.acne, isNotNull);
    });

    test('Symptom can be created with severity', () {
      final now = DateTime.now();
      final symptom = Symptom(
        id: 'symptom-1',
        userId: 'user-123',
        date: DateTime(2024, 1, 1),
        symptomType: SymptomType.cramps,
        severity: 3,
        createdAt: now,
      );

      expect(symptom.symptomType, equals(SymptomType.cramps));
      expect(symptom.severity, equals(3));
    });
  });

  group('SexualActivity Model', () {
    test('SexualActivity can be created with protection status', () {
      final now = DateTime.now();
      final activity = SexualActivity(
        id: 'activity-1',
        userId: 'user-123',
        date: DateTime(2024, 1, 1),
        protectionUsed: true,
        createdAt: now,
      );

      expect(activity.protectionUsed, isTrue);
    });
  });

  group('Note Model', () {
    test('Note can be created with content', () {
      final now = DateTime.now();
      final note = Note(
        id: 'note-1',
        userId: 'user-123',
        date: DateTime(2024, 1, 1),
        content: 'Today was a good day',
        createdAt: now,
        updatedAt: now,
      );

      expect(note.content, equals('Today was a good day'));
    });
  });
}
