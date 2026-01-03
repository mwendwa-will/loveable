import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/widgets/symptom_picker.dart';

void main() {
  group('SymptomPicker', () {
    testWidgets('show displays all symptom types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.show(context);
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

      expect(find.text('Add Symptom'), findsOneWidget);
      
      // All symptom types should be present (some may need scrolling)
      expect(find.text('Cramps'), findsOneWidget);
      expect(find.text('Headache'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);
      expect(find.text('Bloating'), findsOneWidget);
      expect(find.text('Nausea'), findsOneWidget);
      expect(find.text('Back Pain'), findsOneWidget);
      expect(find.text('Breast Tenderness'), findsOneWidget);
      // Scroll to see Acne
      await tester.dragUntilVisible(
        find.text('Acne'),
        find.byType(ListView),
        const Offset(0, -50),
      );
      expect(find.text('Acne'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.show(context);
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

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('returns selected symptom when tapped', (tester) async {
      SymptomType? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await SymptomPicker.show(context);
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

      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();

      expect(result, SymptomType.headache);
    });

    testWidgets('marks already selected symptoms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.show(
                      context,
                      selectedSymptoms: [
                        SymptomType.cramps,
                        SymptomType.headache,
                      ],
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

      // Should show "Already logged" subtitle for selected symptoms
      expect(find.text('Already logged'), findsNWidgets(2));
    });

    testWidgets('search filters symptoms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.show(context);
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

      // Type "head" in search
      await tester.enterText(find.byType(TextField), 'head');
      await tester.pumpAndSettle();

      // Only Headache should be visible
      expect(find.text('Headache'), findsOneWidget);
      expect(find.text('Cramps'), findsNothing);
      expect(find.text('Nausea'), findsNothing);
    });

    testWidgets('showSeverity displays severity levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.showSeverity(
                      context,
                      SymptomType.cramps,
                    );
                  },
                  child: const Text('Show Severity'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Severity'));
      await tester.pumpAndSettle();

      expect(find.text('How severe is cramps?'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);
      expect(find.text('Extreme'), findsOneWidget);
    });

    testWidgets('showSeverity returns selected severity', (tester) async {
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await SymptomPicker.showSeverity(
                      context,
                      SymptomType.headache,
                    );
                  },
                  child: const Text('Show Severity'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Severity'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();

      expect(result, 3);
    });

    testWidgets('severity picker shows descriptive subtitles',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.showSeverity(
                      context,
                      SymptomType.fatigue,
                    );
                  },
                  child: const Text('Show Severity'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Severity'));
      await tester.pumpAndSettle();

      expect(find.text('Barely noticeable'), findsOneWidget);
      expect(find.text('Noticeable but manageable'), findsOneWidget);
      expect(find.text('Uncomfortable'), findsOneWidget);
      expect(find.text('Very uncomfortable'), findsOneWidget);
      expect(find.text('Unbearable'), findsOneWidget);
    });

    testWidgets('displays symptom icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SymptomPicker.show(context);
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

      // Check for specific symptom icons
      expect(find.byIcon(Icons.favorite), findsOneWidget); // Cramps
      expect(find.byIcon(Icons.psychology), findsOneWidget); // Headache
      expect(find.byIcon(Icons.sick), findsOneWidget); // Nausea
    });
  });
}
