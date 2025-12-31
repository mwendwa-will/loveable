/// Represents a period entry
class Period {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity? flowIntensity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Period({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.flowIntensity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Duration of period in days
  int? get durationDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// Whether period is currently ongoing
  bool get isOngoing => endDate == null;

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      flowIntensity: json['flow_intensity'] != null
          ? FlowIntensity.fromString(json['flow_intensity'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'flow_intensity': flowIntensity?.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Period copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    FlowIntensity? flowIntensity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Period(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Period && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Period(id: $id, startDate: $startDate, endDate: $endDate)';
}

/// Flow intensity levels
enum FlowIntensity {
  light('light'),
  medium('medium'),
  heavy('heavy');

  final String value;
  const FlowIntensity(this.value);

  static FlowIntensity fromString(String value) {
    return FlowIntensity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FlowIntensity.medium,
    );
  }
}
