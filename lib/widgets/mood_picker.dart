import 'package:flutter/material.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/widgets/app_bottom_sheet.dart';

/// Reusable mood picker widget using bottom sheet
class MoodPicker {
  /// Show mood picker and return selected mood type
  static Future<MoodType?> show(
    BuildContext context, {
    MoodType? currentMood,
  }) async {
    return AppBottomSheet.showList<MoodType>(
      context,
      title: 'How are you feeling?',
      selectedValue: currentMood,
      items: MoodType.values.map((mood) {
        return BottomSheetItem<MoodType>(
          value: mood,
          label: mood.displayName,
          icon: mood.icon,
          color: _getMoodColor(mood),
        );
      }).toList(),
    );
  }

  /// Get color for mood type
  static Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return Colors.green;
      case MoodType.calm:
        return Colors.blue;
      case MoodType.tired:
        return Colors.grey;
      case MoodType.sad:
        return Colors.indigo;
      case MoodType.irritable:
        return Colors.orange;
      case MoodType.anxious:
        return Colors.purple;
      case MoodType.energetic:
        return Colors.amber;
    }
  }
}
