import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/widgets/upgrade_sheet.dart';

void main() {
  testWidgets('UpgradeSheet renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpgradeSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to show sheet
    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify sheet is displayed
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Start 48-Hour Free Trial'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets('UpgradeSheet shows feature name when provided', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    UpgradeSheet.show(context, featureName: 'Edit Cycle Settings'),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unlock "Edit Cycle Settings" and all premium features'),
      findsOneWidget,
    );
  });

  testWidgets('UpgradeSheet billing toggle switches correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpgradeSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify yearly is default (shows yearly price)
    expect(find.textContaining('\$39.99 / year'), findsOneWidget);

    // Switch to monthly
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    // Verify monthly price is shown
    expect(find.textContaining('\$4.99 / month'), findsOneWidget);
  });

  testWidgets('UpgradeSheet displays all premium features', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpgradeSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify feature list is displayed
    expect(find.text('Everything in Free'), findsOneWidget);
    expect(find.text('Edit cycle settings'), findsOneWidget);
    expect(find.text('Unlimited history'), findsOneWidget);
    expect(find.text('Advanced cycle insights'), findsOneWidget);
    expect(find.text('Custom affirmations'), findsOneWidget);
    expect(find.text('Ad-free experience'), findsOneWidget);

    // Verify check icons
    expect(
      find.byIcon(Icons.check_circle_rounded),
      findsNWidgets(8), // 8 features in premium tier
    );
  });

  testWidgets('UpgradeSheet maybe later button closes sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpgradeSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Premium'), findsOneWidget);

    // Scroll to make button visible
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    // Tap maybe later
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Sheet should be closed
    expect(find.text('Upgrade to Premium'), findsNothing);
  });

  testWidgets('UpgradeSheet shows Save 33% badge on yearly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpgradeSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Sheet'));
    await tester.pumpAndSettle();

    // Verify savings badge
    expect(find.text('Save 33%'), findsOneWidget);
  });
}
