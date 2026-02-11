import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/mood.dart';
import 'package:lunara/widgets/mood_picker.dart';

void main() {
  group('MoodPicker', () {
    testWidgets('show displays all mood types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MoodPicker.show(context);
                  },
                  child: const Text('Show Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      expect(find.text('How are you feeling?'), findsOneWidget);
      
      // All mood types should be present
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Tired'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('Irritable'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Energetic'), findsOneWidget);
    });

    testWidgets('returns selected mood when tapped', (tester) async {
      MoodType? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await MoodPicker.show(context);
                  },
                  child: const Text('Show Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calm'));
      await tester.pumpAndSettle();

      expect(result, MoodType.calm);
    });

    testWidgets('shows checkmark on currently selected mood', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MoodPicker.show(
                      context,
                      currentMood: MoodType.happy,
                    );
                  },
                  child: const Text('Show Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Should have one checkmark for the selected mood
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays mood icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MoodPicker.show(context);
                  },
                  child: const Text('Show Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Check for specific mood icons
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
      expect(find.byIcon(Icons.spa), findsOneWidget);
      expect(find.byIcon(Icons.bedtime), findsOneWidget);
    });

    testWidgets('returns null when dismissed', (tester) async {
      MoodType? result = MoodType.happy; // Set initial value

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await MoodPicker.show(context);
                  },
                  child: const Text('Show Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Dismiss by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, null);
    });
  });
}
