import 'package:lunara/models/period.dart';

class DailyFlow {
  final String id;
  final String userId;
  final DateTime date;
  final FlowIntensity flowIntensity;
  final DateTime createdAt;

  DailyFlow({
    required this.id,
    required this.userId,
    required this.date,
    required this.flowIntensity,
    required this.createdAt,
  });

  factory DailyFlow.fromJson(Map<String, dynamic> json) {
    return DailyFlow(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      flowIntensity: FlowIntensity.fromString(json['flow_intensity'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'flow_intensity': flowIntensity.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
