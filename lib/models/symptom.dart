import 'package:flutter/material.dart';

/// Represents a daily symptom entry
class Symptom {
  final String id;
  final String userId;
  final DateTime date;
  final SymptomType symptomType;
  final int? severity; // 1-5 scale
  final String? notes;
  final DateTime createdAt;

  Symptom({
    required this.id,
    required this.userId,
    required this.date,
    required this.symptomType,
    this.severity,
    this.notes,
    required this.createdAt,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      symptomType: SymptomType.fromString(json['symptom_type'] as String),
      severity: json['severity'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'symptom_type': symptomType.value,
      'severity': severity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Symptom copyWith({
    String? id,
    String? userId,
    DateTime? date,
    SymptomType? symptomType,
    int? severity,
    String? notes,
    DateTime? createdAt,
  }) {
    return Symptom(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      symptomType: symptomType ?? this.symptomType,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Symptom && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Symptom(date: $date, type: ${symptomType.value})';
}

/// Symptom types
enum SymptomType {
  cramps('cramps', 'Cramps', Icons.favorite),
  headache('headache', 'Headache', Icons.psychology),
  fatigue('fatigue', 'Fatigue', Icons.battery_0_bar),
  bloating('bloating', 'Bloating', Icons.radio_button_checked),
  nausea('nausea', 'Nausea', Icons.sick),
  backPain('back_pain', 'Back Pain', Icons.accessibility_new),
  breastTenderness(
    'breast_tenderness',
    'Breast Tenderness',
    Icons.health_and_safety,
  ),
  acne('acne', 'Acne', Icons.face);

  final String value;
  final String displayName;
  final IconData icon;
  const SymptomType(this.value, this.displayName, this.icon);

  static SymptomType fromString(String value) {
    return SymptomType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SymptomType.cramps,
    );
  }
}
