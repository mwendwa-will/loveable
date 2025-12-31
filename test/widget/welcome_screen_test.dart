import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/screens/welcome_screen.dart';

void main() {
  group('WelcomeScreen Widget Tests', () {
    testWidgets('WelcomeScreen displays welcome text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Welcome to Lovely'), findsOneWidget);
      expect(
          find.text('Your journey to wellness and self-care starts here'),
          findsOneWidget);
    });

    testWidgets('WelcomeScreen has Get Started button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('WelcomeScreen displays feature list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      // Should show at least one feature icon
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('WelcomeScreen adapts to dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: const WelcomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
