import 'package:flutter/material.dart';

/// Represents a daily mood entry
class Mood {
  final String id;
  final String userId;
  final DateTime date;
  final MoodType moodType;
  final String? notes;
  final DateTime createdAt;

  Mood({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodType,
    this.notes,
    required this.createdAt,
  });

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      moodType: MoodType.fromString(json['mood_type'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'mood_type': moodType.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Mood copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MoodType? moodType,
    String? notes,
    DateTime? createdAt,
  }) {
    return Mood(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      moodType: moodType ?? this.moodType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mood && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Mood(date: $date, type: ${moodType.displayName})';
}

/// Mood types
enum MoodType {
  happy('happy', 'Happy', Icons.sentiment_very_satisfied),
  calm('calm', 'Calm', Icons.spa),
  tired('tired', 'Tired', Icons.bedtime),
  sad('sad', 'Sad', Icons.sentiment_dissatisfied),
  irritable('irritable', 'Irritable', Icons.sentiment_very_dissatisfied),
  anxious('anxious', 'Anxious', Icons.psychology_alt),
  energetic('energetic', 'Energetic', Icons.bolt);

  final String value;
  final String displayName;
  final IconData icon;
  const MoodType(this.value, this.displayName, this.icon);

  static MoodType fromString(String value) {
    return MoodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MoodType.calm,
    );
  }
}
