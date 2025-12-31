/// Represents a menstrual cycle with predictions
class Cycle {
  final String id;
  final String userId;
  final int cycleNumber;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLength;
  final int? periodLength;
  final DateTime? predictedNextPeriod;
  final DateTime? predictedOvulation;
  final DateTime? predictedFertileWindowStart;
  final DateTime? predictedFertileWindowEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cycle({
    required this.id,
    required this.userId,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    this.cycleLength,
    this.periodLength,
    this.predictedNextPeriod,
    this.predictedOvulation,
    this.predictedFertileWindowStart,
    this.predictedFertileWindowEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether cycle is currently ongoing
  bool get isOngoing => endDate == null;

  /// Current cycle day (1-based)
  int get currentDay {
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) {
      return cycleLength ?? 0;
    }
    return now.difference(startDate).inDays + 1;
  }

  /// Current cycle phase
  CyclePhase get currentPhase {
    if (!isOngoing) return CyclePhase.unknown;

    final day = currentDay;
    if (periodLength != null && day <= periodLength!) {
      return CyclePhase.menstrual;
    }

    // Approximate phase based on typical 28-day cycle
    if (day <= 13) {
      return CyclePhase.follicular;
    } else if (day <= 17) {
      return CyclePhase.ovulation;
    } else {
      return CyclePhase.luteal;
    }
  }

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cycleNumber: json['cycle_number'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      cycleLength: json['cycle_length'] as int?,
      periodLength: json['period_length'] as int?,
      predictedNextPeriod: json['predicted_next_period'] != null
          ? DateTime.parse(json['predicted_next_period'] as String)
          : null,
      predictedOvulation: json['predicted_ovulation'] != null
          ? DateTime.parse(json['predicted_ovulation'] as String)
          : null,
      predictedFertileWindowStart:
          json['predicted_fertile_window_start'] != null
          ? DateTime.parse(json['predicted_fertile_window_start'] as String)
          : null,
      predictedFertileWindowEnd: json['predicted_fertile_window_end'] != null
          ? DateTime.parse(json['predicted_fertile_window_end'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cycle_number': cycleNumber,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'predicted_next_period': predictedNextPeriod?.toIso8601String().split(
        'T',
      )[0],
      'predicted_ovulation': predictedOvulation?.toIso8601String().split(
        'T',
      )[0],
      'predicted_fertile_window_start': predictedFertileWindowStart
          ?.toIso8601String()
          .split('T')[0],
      'predicted_fertile_window_end': predictedFertileWindowEnd
          ?.toIso8601String()
          .split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Cycle copyWith({
    String? id,
    String? userId,
    int? cycleNumber,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    DateTime? predictedNextPeriod,
    DateTime? predictedOvulation,
    DateTime? predictedFertileWindowStart,
    DateTime? predictedFertileWindowEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cycle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      predictedNextPeriod: predictedNextPeriod ?? this.predictedNextPeriod,
      predictedOvulation: predictedOvulation ?? this.predictedOvulation,
      predictedFertileWindowStart:
          predictedFertileWindowStart ?? this.predictedFertileWindowStart,
      predictedFertileWindowEnd:
          predictedFertileWindowEnd ?? this.predictedFertileWindowEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cycle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Cycle(#$cycleNumber, start: $startDate, length: $cycleLength days)';
}

/// Menstrual cycle phases
enum CyclePhase {
  menstrual('Menstrual', 'Period is active'),
  follicular('Follicular', 'Post-period, pre-ovulation'),
  ovulation('Ovulation', 'Fertile window'),
  luteal('Luteal', 'Post-ovulation, pre-period'),
  unknown('Unknown', 'Phase not determined');

  final String displayName;
  final String description;
  const CyclePhase(this.displayName, this.description);
}
