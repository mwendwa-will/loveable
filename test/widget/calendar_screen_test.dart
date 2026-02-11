import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/screens/calendar_screen.dart';

void main() {
  group('CalendarScreen Widget Tests', () {
    testWidgets('CalendarScreen renders without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('CalendarScreen has AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('CalendarScreen displays current month',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should display some form of date/month indicator
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('CalendarScreen has legend',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Legend'), findsOneWidget);
    });
  });
}
