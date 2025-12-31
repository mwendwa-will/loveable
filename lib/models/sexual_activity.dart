import 'package:flutter/material.dart';

/// Represents a sexual activity entry
class SexualActivity {
  final String id;
  final String userId;
  final DateTime date;
  final bool protectionUsed;
  final ProtectionType? protectionType;
  final String? notes;
  final DateTime createdAt;

  SexualActivity({
    required this.id,
    required this.userId,
    required this.date,
    required this.protectionUsed,
    this.protectionType,
    this.notes,
    required this.createdAt,
  });

  factory SexualActivity.fromJson(Map<String, dynamic> json) {
    return SexualActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      protectionUsed: json['protection_used'] as bool,
      protectionType: json['protection_type'] != null
          ? ProtectionType.fromString(json['protection_type'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'protection_used': protectionUsed,
      'protection_type': protectionType?.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SexualActivity copyWith({
    String? id,
    String? userId,
    DateTime? date,
    bool? protectionUsed,
    ProtectionType? protectionType,
    String? notes,
    DateTime? createdAt,
  }) {
    return SexualActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      protectionUsed: protectionUsed ?? this.protectionUsed,
      protectionType: protectionType ?? this.protectionType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ProtectionType {
  condom('condom', Icons.shield),
  birthControl('birth_control', Icons.medication),
  iud('iud', Icons.lock),
  withdrawal('withdrawal', Icons.warning),
  other('other', Icons.notes);

  final String value;
  final IconData icon;

  const ProtectionType(this.value, this.icon);

  static ProtectionType fromString(String value) {
    return ProtectionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProtectionType.other,
    );
  }
}
