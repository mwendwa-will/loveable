import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/screens/auth/email_verification_pending_screen.dart';
import 'package:lovely/screens/main/home_screen.dart';
import 'package:lovely/screens/onboarding/onboarding_screen.dart';
import 'package:lovely/screens/welcome_screen.dart';

/// AuthGate: Authentication Gateway
///
/// This widget implements persistent authentication by checking for existing
/// Supabase sessions on app launch. It routes users to the appropriate screen:
///
/// Flow:
/// 1. App launches → AuthGate checks for currentSession
/// 2. If session exists → Check onboarding status
///    - Onboarding complete → Navigate to HomeScreen
///    - Onboarding incomplete → Navigate to OnboardingScreen
/// 3. If no session → Navigate to WelcomeScreen for login
///
/// Session Persistence:
/// - Supabase automatically stores auth tokens in device storage
/// - Android: SharedPreferences (survives cache clear, lost on data clear)
/// - iOS: UserDefaults (survives cache clear, lost on data clear)
/// - Sessions auto-refresh for 30 days, then require re-login
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.read(supabaseServiceProvider);

    // Check for existing session
    final session = supabase.currentSession;

    if (session != null) {
      // Check if email verification is required
      if (supabase.requiresVerification) {
        return const EmailVerificationPendingScreen();
      }

      // User has a valid session - check onboarding status
      return FutureBuilder<bool>(
        future: supabase.hasCompletedOnboarding(),
        builder: (context, snapshot) {
          // Show loading indicator while checking onboarding status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Lovely...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle errors gracefully - fallback to home screen
          if (snapshot.hasError) {
            debugPrint('⚠️ Error checking onboarding: ${snapshot.error}');
            return const HomeScreen();
          }

          // Route based on onboarding completion
          final hasCompletedOnboarding = snapshot.data ?? false;
          return hasCompletedOnboarding
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      );
    }

    // No session found - show welcome/login screen
    return const WelcomeScreen();
  }
}
