import 'package:flutter/material.dart';

/// Lovely App Color Constants
/// Following the Coral Sunset theme and Material Design principles

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFFF6F61);
  static const Color primaryLight = Color(0xFFFF8E7E);
  static const Color primarySoft = Color(0xFFFFB5A7);

  // Cycle Phase Colors
  static const Color menstrualPhase = Color(0xFFFF6F61);
  static const Color follicularPhase = Color(0xFFFFB5A7);
  static const Color ovulationPhase = Color(0xFFFF69B4);
  static const Color lutealPhase = Color(0xFFE8B4F5);

  // Dark Colors
  static const Color darkBackground = Color(0xFF2D1B3D);
  static const Color darkSecondary = Color(0xFF1A1A2E);
  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkAppBarForeground = Color(0xFFE1E1E1);

  // Light Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color textGray = Color(0xFF6C757D);
  static const Color lightAppBarForeground = Color(0xFF1A1A1A);
  static const Color textDarkGray = Color(0xFF333333);
  static const Color textMediumGray = Color(0xFF666666);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, darkSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calendarGradient = LinearGradient(
    colors: [lutealPhase, Color(0xFFFFC9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme-aware color helpers
  static Color getAdaptiveColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  static Color getBorderColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.grey.shade300,
      darkColor: Colors.grey.shade700,
    );
  }

  static Color getCardBackgroundColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.white,
      darkColor: Colors.grey.shade900,
    );
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.grey.shade700,
      darkColor: Colors.grey.shade400,
    );
  }

  // Calendar-specific theme colors
  static Color getPeriodColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.red.shade400,
      darkColor: Colors.red.shade300,
    );
  }

  static Color getPredictedPeriodColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.pink.shade100,
      darkColor: Colors.pink.shade600,
    );
  }

  static Color getOvulationColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.purple.shade100,
      darkColor: Colors.purple.shade600,
    );
  }

  static Color getFertileWindowColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.blue.shade100,
      darkColor: Colors.blue.shade600,
    );
  }

  // Daily log indicator colors
  static Color getMoodIndicatorColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.amber.shade700,
      darkColor: Colors.amber.shade400,
    );
  }

  static Color getSymptomsIndicatorColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.orange.shade700,
      darkColor: Colors.orange.shade400,
    );
  }

  static Color getSexualActivityIndicatorColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.pink.shade700,
      darkColor: Colors.pink.shade400,
    );
  }

  static Color getNoteIndicatorColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: Colors.blue.shade700,
      darkColor: Colors.blue.shade400,
    );
  }

  // Text color helpers for accessibility
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Additional cycle phase colors
  static Color getMenstrualPhaseColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFFFCDD2), // Gentle red
      darkColor: const Color(0xFFD32F2F), // Calmer red
    );
  }

  static Color getFollicularPhaseColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFB2DFDB), // Soft teal
      darkColor: const Color(0xFF00695C), // Deep teal
    );
  }

  static Color getLutealPhaseColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFF8BBD0), // Soft pink
      darkColor: const Color(0xFFC2185B), // Deep pink
    );
  }

  // Legend and indicator colors
  static Color getMoodLogColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFFF6F00), // Orange 900
      darkColor: const Color(0xFFFFA726), // Orange 400
    );
  }

  static Color getSymptomsLogColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFE65100), // Orange 900 dark
      darkColor: const Color(0xFFFFB74D), // Orange 300
    );
  }

  static Color getSexualActivityLogColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFC2185B), // Pink 700
      darkColor: const Color(0xFFEC407A), // Pink 400
    );
  }

  static Color getNoteLogColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFF1976D2), // Blue 700
      darkColor: const Color(0xFF42A5F5), // Blue 400
    );
  }

  static Color getOvulationDayColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      lightColor: const Color(0xFFFFF9C4), // Soft yellow
      darkColor: const Color(0xFFF9A825), // Gold
    );
  }

  // Theme-specific color for text on colored backgrounds
  static Color getMenstrualTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFFAD1457);
  }

  static Color getPredictedTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF880E4F);
  }

  static Color getOvulationTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFFC2185B);
  }

  static Color getFertileTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF004D40);
  }
}
