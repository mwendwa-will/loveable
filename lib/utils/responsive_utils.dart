import 'package:flutter/material.dart';

/// Centralized responsive sizing utilities for consistent UI across device sizes.
/// 
/// Usage:
/// ```dart
/// final sizing = ResponsiveSizing.of(context);
/// Text('Hello', style: TextStyle(fontSize: sizing.bodyFontSize));
/// Icon(Icons.star, size: sizing.iconSize);
/// ```
class ResponsiveSizing {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final ScreenSize screenSize;

  ResponsiveSizing.of(this.context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    screenSize = _getScreenSize();
  }

  ScreenSize _getScreenSize() {
    if (screenWidth < 360) return ScreenSize.small;
    if (screenWidth < 400) return ScreenSize.medium;
    if (screenWidth < 600) return ScreenSize.large;
    return ScreenSize.tablet;
  }

  // ============== CALENDAR & WEEK STRIP ==============

  /// Aspect ratio for calendar day cells
  double get calendarCellAspectRatio {
    switch (screenSize) {
      case ScreenSize.small:
        return 0.85;
      case ScreenSize.medium:
        return 0.9;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 1.0;
    }
  }

  /// Font size for date numbers in calendar
  double get calendarDateFontSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 11.0;
      case ScreenSize.medium:
        return 12.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 13.0;
    }
  }

  /// Icon size for mood/symptom indicators in calendar
  double get calendarIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 9.0;
      case ScreenSize.medium:
        return 9.5;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 10.0;
    }
  }

  /// Icon size for sexual activity heart in calendar
  double get calendarActivityIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 10.0;
      case ScreenSize.medium:
        return 11.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 12.0;
    }
  }

  /// Size of symptom dots in calendar
  double get calendarDotSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 2.0;
      case ScreenSize.medium:
        return 2.5;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 3.0;
    }
  }

  // ============== WEEK STRIP (HOME SCREEN) ==============

  /// Size of the date circle in week strip
  double get weekStripCircleSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 36.0;
      case ScreenSize.medium:
        return 38.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 40.0;
    }
  }

  /// Font size for date in week strip
  double get weekStripDateFontSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 12.0;
      case ScreenSize.medium:
        return 13.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 14.0;
    }
  }

  /// Icon size for mood in week strip
  double get weekStripMoodIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 14.0;
      case ScreenSize.medium:
        return 15.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 16.0;
    }
  }

  /// Icon size for activity heart in week strip
  double get weekStripActivityIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 12.0;
      case ScreenSize.medium:
        return 13.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 14.0;
    }
  }

  /// Size of symptom dots in week strip
  double get weekStripDotSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 2.5;
      case ScreenSize.medium:
        return 3.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 3.0;
    }
  }

  // ============== GENERAL TYPOGRAPHY ==============

  /// Small body text
  double get smallFontSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 11.0;
      case ScreenSize.medium:
        return 12.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 13.0;
    }
  }

  /// Regular body text
  double get bodyFontSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 13.0;
      case ScreenSize.medium:
        return 14.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 15.0;
    }
  }

  /// Section titles
  double get titleFontSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 15.0;
      case ScreenSize.medium:
        return 16.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 18.0;
    }
  }

  // ============== GENERAL ICONS ==============

  /// Small icons (indicators, badges)
  double get smallIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 16.0;
      case ScreenSize.medium:
        return 18.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 20.0;
    }
  }

  /// Regular icons (buttons, list items)
  double get iconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 20.0;
      case ScreenSize.medium:
        return 22.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 24.0;
    }
  }

  /// Large icons (FAB, primary actions)
  double get largeIconSize {
    switch (screenSize) {
      case ScreenSize.small:
        return 24.0;
      case ScreenSize.medium:
        return 26.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 28.0;
    }
  }

  // ============== SPACING ==============

  /// Extra small spacing (2-4px)
  double get spacingXs {
    switch (screenSize) {
      case ScreenSize.small:
        return 2.0;
      case ScreenSize.medium:
        return 3.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 4.0;
    }
  }

  /// Small spacing (4-8px)
  double get spacingSm {
    switch (screenSize) {
      case ScreenSize.small:
        return 4.0;
      case ScreenSize.medium:
        return 6.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 8.0;
    }
  }

  /// Medium spacing (8-16px)
  double get spacingMd {
    switch (screenSize) {
      case ScreenSize.small:
        return 8.0;
      case ScreenSize.medium:
        return 12.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 16.0;
    }
  }

  /// Large spacing (16-24px)
  double get spacingLg {
    switch (screenSize) {
      case ScreenSize.small:
        return 12.0;
      case ScreenSize.medium:
        return 16.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 20.0;
    }
  }

  /// Extra large spacing (24-32px)
  double get spacingXl {
    switch (screenSize) {
      case ScreenSize.small:
        return 20.0;
      case ScreenSize.medium:
        return 24.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 28.0;
    }
  }

  // ============== TOUCH TARGETS ==============

  /// Minimum touch target size (Material guidelines: 48px)
  double get minTouchTarget {
    switch (screenSize) {
      case ScreenSize.small:
        return 44.0;
      case ScreenSize.medium:
        return 46.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 48.0;
    }
  }

  // ============== CONTAINERS ==============

  /// Border radius for cards and containers
  double get borderRadius {
    switch (screenSize) {
      case ScreenSize.small:
        return 12.0;
      case ScreenSize.medium:
        return 14.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 16.0;
    }
  }

  /// Small border radius (chips, badges)
  double get borderRadiusSm {
    switch (screenSize) {
      case ScreenSize.small:
        return 6.0;
      case ScreenSize.medium:
        return 7.0;
      case ScreenSize.large:
      case ScreenSize.tablet:
        return 8.0;
    }
  }
}

/// Screen size categories
enum ScreenSize {
  small,   // < 360px (compact phones)
  medium,  // 360-400px (standard phones)
  large,   // 400-600px (large phones)
  tablet,  // > 600px (tablets)
}

/// Extension for easy access via context
extension ResponsiveContext on BuildContext {
  ResponsiveSizing get responsive => ResponsiveSizing.of(this);
}
