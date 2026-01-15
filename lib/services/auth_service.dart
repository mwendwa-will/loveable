import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/services/supabase_service.dart';

/// Thin wrapper around SupabaseService for auth-related operations.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService({SupabaseService? supabase}) => _instance;
  AuthService._internal({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService();

  final SupabaseService _supabase;

  Future<void> resendVerificationEmail() async {
    return _supabase.resendVerificationEmail();
  }

  int get daysSinceSignup => _supabase.daysSinceSignup;

  bool get requiresVerification => _supabase.requiresVerification;

  User? get currentUser => _supabase.currentUser;

  Session? get currentSession => _supabase.currentSession;

  bool get isEmailVerified => _supabase.isEmailVerified;

  Future<void> signOut() => _supabase.signOut();

  Future<void> refreshSession() async {
    try {
      await _supabase.client.auth.refreshSession();
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    return _supabase.signIn(emailOrUsername: emailOrUsername, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) => _supabase.signUp(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );

  Future<void> updatePassword(String newPassword) => _supabase.updatePassword(newPassword);

  Future<void> deleteAccount() => _supabase.deleteAccount();

  Future<void> resetPassword({required String email}) => _supabase.resetPassword(email: email);
}
