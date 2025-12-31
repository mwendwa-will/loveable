import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovely/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    testWidgets('getTextColorForBackground returns correct contrast colors',
        (WidgetTester tester) async {
      // Test light background -> dark text
      final lightBgColor = Colors.white;
      final darkText = AppColors.getTextColorForBackground(lightBgColor);
      expect(darkText, equals(Colors.black87));

      // Test dark background -> light text
      final darkBgColor = Colors.black;
      final lightText = AppColors.getTextColorForBackground(darkBgColor);
      expect(lightText, equals(Colors.white));
    });

    testWidgets('getAdaptiveColor returns light color in light mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final color = AppColors.getAdaptiveColor(
                context,
                lightColor: Colors.red,
                darkColor: Colors.blue,
              );
              expect(color, equals(Colors.red));
              return const Placeholder();
            },
          ),
        ),
      );
    });

    testWidgets('getAdaptiveColor returns dark color in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              final color = AppColors.getAdaptiveColor(
                context,
                lightColor: Colors.red,
                darkColor: Colors.blue,
              );
              expect(color, equals(Colors.blue));
              return const Placeholder();
            },
          ),
        ),
      );
    });

    testWidgets('Theme-aware color methods work correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              // Test each theme-aware method
              expect(AppColors.getPeriodColor(context), isNotNull);
              expect(AppColors.getOvulationColor(context), isNotNull);
              expect(AppColors.getFertileWindowColor(context), isNotNull);
              expect(AppColors.getMenstrualPhaseColor(context), isNotNull);
              expect(AppColors.getFollicularPhaseColor(context), isNotNull);
              expect(AppColors.getLutealPhaseColor(context), isNotNull);
              return const Placeholder();
            },
          ),
        ),
      );
    });

    test('Primary color constants are defined correctly', () {
      expect(AppColors.primary, equals(const Color(0xFFFF6F61)));
      expect(AppColors.primaryLight, equals(const Color(0xFFFF8E7E)));
      expect(AppColors.primarySoft, equals(const Color(0xFFFFB5A7)));
    });

    test('Semantic color constants are defined correctly', () {
      expect(AppColors.success, equals(const Color(0xFF28A745)));
      expect(AppColors.warning, equals(const Color(0xFFFFC107)));
      expect(AppColors.error, equals(const Color(0xFFDC3545)));
      expect(AppColors.info, equals(const Color(0xFF17A2B8)));
    });
  });
}
