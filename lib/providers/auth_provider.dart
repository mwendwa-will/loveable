import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/services/supabase_service.dart';

/// Stream provider for real-time auth state changes
/// Automatically rebuilds when user logs in, logs out, or token refreshes
final authStateProvider = StreamProvider<dynamic>((ref) {
  return SupabaseService().client.auth.onAuthStateChange;
});

/// Current session provider - updates when auth state changes
final currentSessionProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session).value;
});

/// Current user provider - updates when auth state changes
final currentUserProvider = Provider<dynamic>((ref) {
  return ref.watch(currentSessionProvider)?.user;
});

/// Email verification status - checks if user's email is confirmed
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailConfirmedAt != null;
});
