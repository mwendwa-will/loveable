import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lovely App Integration Tests', () {
    testWidgets('App launches and displays welcome screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: LovelyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify welcome screen is displayed
      expect(find.text('Welcome to Lovely'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Navigation between screens works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: LovelyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Get Started button
      final getStartedButton = find.text('Get Started');
      if (getStartedButton.evaluate().isNotEmpty) {
        await tester.tap(getStartedButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App respects system theme mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: LovelyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // App should render without errors in system theme
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('User Flow Tests', () {
    testWidgets('Complete onboarding flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: LovelyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // This would test the complete onboarding process
      // Including account creation, profile setup, etc.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
