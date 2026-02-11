import 'package:flutter/material.dart';
import 'package:lunara/screens/auth/welcome_screen.dart';
import 'package:lunara/screens/auth/login.dart';
import 'package:lunara/screens/auth/signup.dart';
import 'package:lunara/screens/auth/forgot_password.dart';
import 'package:lunara/screens/onboarding/onboarding_screen.dart';
import 'package:lunara/screens/main/home_screen.dart';
import 'package:lunara/screens/main/profile_screen.dart';
import 'package:lunara/screens/calendar_screen.dart';
import 'package:lunara/screens/daily_log_screen_v2.dart';
import 'package:lunara/screens/settings/edit_profile_screen.dart';
import 'package:lunara/screens/settings/change_password_screen.dart';
import 'package:lunara/screens/settings/notifications_settings_screen.dart';
import 'package:lunara/screens/settings/cycle_settings_screen.dart';
import 'package:lunara/screens/security/pin_setup_screen.dart';
import 'package:lunara/screens/security/pin_unlock_screen.dart';
import 'package:lunara/screens/analytics/analytics_screen.dart';
import 'package:lunara/screens/analytics/cycle_history_screen.dart';

/// Centralized route names used across the app.
abstract class AppRoutes {
  static const String welcome = '/';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String dailyLog = '/daily-log';
  static const String editProfile = '/settings/edit-profile';
  static const String changePassword = '/settings/change-password';
  static const String notificationsSettings = '/settings/notifications';
  static const String cycleSettings = '/settings/cycle';
  static const String pinSetup = '/security/pin-setup';
  static const String pinUnlock = '/pin-unlock';
  static const String analytics = '/analytics';
  static const String cycleHistory = '/cycle-history';
}

/// Simple centralized router using named routes. Keeps navigation
/// logic in one place so future migration to `auto_route` is straightforward.
class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case AppRoutes.dailyLog:
        final args = settings.arguments as Map<String, dynamic>?;
        final date = args?['selectedDate'] as DateTime?;
        if (date == null) {
          return MaterialPageRoute(
            builder: (_) => DailyLogScreenV2(selectedDate: DateTime.now()),
          );
        }
        return MaterialPageRoute(
          builder: (_) => DailyLogScreenV2(selectedDate: date),
        );
      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case AppRoutes.notificationsSettings:
        return MaterialPageRoute(
          builder: (_) => const NotificationsSettingsScreen(),
        );
      case AppRoutes.cycleSettings:
        return MaterialPageRoute(builder: (_) => const CycleSettingsScreen());
      case AppRoutes.pinSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        final isChangeMode = args?['isChangeMode'] as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => PinSetupScreen(isChangeMode: isChangeMode),
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.pinUnlock:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (ctx) =>
              PinUnlockScreen(onUnlocked: args?['onUnlocked'] as VoidCallback?),
          fullscreenDialog: true,
        );
      case AppRoutes.analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case AppRoutes.cycleHistory:
        return MaterialPageRoute(builder: (_) => const CycleHistoryScreen());
      default:
        return null;
    }
  }

  // Convenience helpers
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String name, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(name, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, U>(
    BuildContext context,
    String name, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushReplacementNamed<T, U>(name, arguments: arguments);
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.of(context).pop(result);
  }
}
