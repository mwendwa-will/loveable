import 'package:flutter/material.dart';
import 'package:lunara/models/symptom.dart';
import 'package:lunara/widgets/app_bottom_sheet.dart';

/// Reusable symptom picker widget using bottom sheet
class SymptomPicker {
  /// Show symptom picker and return selected symptom type
  static Future<SymptomType?> show(
    BuildContext context, {
    List<SymptomType> selectedSymptoms = const [],
  }) async {
    return AppBottomSheet.showList<SymptomType>(
      context,
      title: 'Add Symptom',
      showSearch: true,
      items: SymptomType.values.map((symptom) {
        // Don't show already selected symptoms
        final isAlreadySelected = selectedSymptoms.contains(symptom);

        return BottomSheetItem<SymptomType>(
          value: symptom,
          label: symptom.displayName,
          subtitle: isAlreadySelected ? 'Already logged' : null,
          icon: symptom.icon,
          color: _getSymptomColor(symptom),
        );
      }).toList(),
    );
  }

  /// Show severity picker (1-5 scale)
  static Future<int?> showSeverity(
    BuildContext context,
    SymptomType symptom,
  ) async {
    return AppBottomSheet.showList<int>(
      context,
      title: 'How severe is ${symptom.displayName.toLowerCase()}?',
      items: [
        BottomSheetItem(
          value: 1,
          label: 'Mild',
          subtitle: 'Barely noticeable',
          icon: Icons.looks_one,
          color: Colors.green,
        ),
        BottomSheetItem(
          value: 2,
          label: 'Light',
          subtitle: 'Noticeable but manageable',
          icon: Icons.looks_two,
          color: Colors.lightGreen,
        ),
        BottomSheetItem(
          value: 3,
          label: 'Moderate',
          subtitle: 'Uncomfortable',
          icon: Icons.looks_3,
          color: Colors.orange,
        ),
        BottomSheetItem(
          value: 4,
          label: 'Severe',
          subtitle: 'Very uncomfortable',
          icon: Icons.looks_4,
          color: Colors.deepOrange,
        ),
        BottomSheetItem(
          value: 5,
          label: 'Extreme',
          subtitle: 'Unbearable',
          icon: Icons.looks_5,
          color: Colors.red,
        ),
      ],
    );
  }

  /// Get color for symptom type
  static Color _getSymptomColor(SymptomType symptom) {
    switch (symptom) {
      case SymptomType.cramps:
        return Colors.red;
      case SymptomType.headache:
        return Colors.purple;
      case SymptomType.fatigue:
        return Colors.grey;
      case SymptomType.bloating:
        return Colors.blue;
      case SymptomType.nausea:
        return Colors.green;
      case SymptomType.backPain:
        return Colors.brown;
      case SymptomType.breastTenderness:
        return Colors.pink;
      case SymptomType.acne:
        return Colors.orange;
    }
  }
}
