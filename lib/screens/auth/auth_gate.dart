import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/providers/auth_provider.dart';
import 'package:lunara/screens/main/home_screen.dart';
import 'package:lunara/screens/onboarding/onboarding_screen.dart';
import 'package:lunara/screens/auth/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lunara/services/supabase_service.dart';

/// AuthGate: Authentication Gateway
///
/// Routes users based on authentication and onboarding status:
/// - Not authenticated → WelcomeScreen
/// - Authenticated but not onboarded → OnboardingScreen
/// - Authenticated and onboarded → HomeScreen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state stream for real-time updates
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // Loading state - show splash screen
      loading: () => Scaffold(
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
      ),

      // Error state - show error message
      error: (error, stackTrace) {
        debugPrint('Auth error: $error');
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },

      // Data state - check if authenticated
      data: (state) {
        final session = state.session;

        // No session - show welcome screen
        if (session == null) {
          return const WelcomeScreen();
        }

        // Has session - check onboarding status
        return _OnboardingGate(session: session);
      },
    );
  }
}

/// Onboarding gateway - checks if user has completed onboarding
class _OnboardingGate extends StatelessWidget {
  final Session session;

  const _OnboardingGate({required this.session});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return FutureBuilder<bool>(
      future: _checkOnboarding(supabase),
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
          debugPrint('Warning: Error checking onboarding: ${snapshot.error}');
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

  /// Helper to check if user completed onboarding
  Future<bool> _checkOnboarding(SupabaseClient supabase) async {
    try {
      final response = await supabase
          .from('users')
          .select('onboarding_complete')
          .eq('id', session.user.id)
          .single();
      return response['onboarding_complete'] == true;
    } catch (e) {
      // If the `onboarding_completed` column does not exist (older schema),
      // fall back to the service-level check which treats presence of a
      // users row as completion. This keeps older DBs compatible.
      debugPrint('Error checking onboarding via column: $e');
      try {
        final fallback = await SupabaseService().hasCompletedOnboarding();
        debugPrint('Fallback onboarding check result: $fallback');
        return fallback;
      } catch (e2) {
        debugPrint('Fallback onboarding check failed: $e2');
        return false;
      }
    }
  }
}
