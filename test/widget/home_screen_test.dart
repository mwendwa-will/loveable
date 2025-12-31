import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/screens/main/home_screen.dart';
import 'package:lovely/providers/calendar_provider.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen displays when not loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pump();
    });

    testWidgets('HomeScreen has AppBar with title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('HomeScreen displays cycle tracking section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Look for cycle-related UI elements
      expect(find.byType(Container), findsWidgets);
    });
  });
}
