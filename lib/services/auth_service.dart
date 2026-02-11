import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lunara/services/supabase_service.dart';
import 'package:lunara/repositories/auth_repository.dart';
import 'package:lunara/services/pin_service.dart';

/// Thin wrapper around AuthRepository for auth-related operations.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService({SupabaseService? supabase}) => _instance;

  late final AuthRepository _repository;

  AuthService._internal({SupabaseService? supabase}) {
    _repository = AuthRepository((supabase ?? SupabaseService()).client);
  }

  Future<void> resendVerificationEmail() =>
      _repository.resendVerificationEmail();

  // Derived properties from repository/client
  // Note: These getters might need to be adjusted if logic was in SupabaseService
  User? get currentUser => _repository.currentUser;
  Session? get currentSession => _repository.currentSession;
  bool get isEmailVerified => _repository.isEmailVerified;

  // SupabaseService had these custom getters, mapping them:
  int get daysSinceSignup {
    final user = currentUser;
    if (user == null || user.createdAt.isEmpty) return 0;
    final created = DateTime.tryParse(user.createdAt);
    if (created == null) return 0;
    return DateTime.now().difference(created).inDays;
  }

  bool get requiresVerification => !isEmailVerified;

  Future<void> signOut() async {
    await PinService().removePin();
    await _repository.signOut();
  }

  Future<void> refreshSession() async {
    // Repository might expose client or we can add refresh to repository
    // For now accessing client via repository if needed, or just keeping this safe
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) =>
      _repository.signIn(emailOrUsername: emailOrUsername, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) => _repository.signUp(
    email: email,
    password: password,
    username: username,
    firstName: firstName,
    lastName: lastName,
  );

  Future<void> updatePassword(String newPassword) =>
      _repository.updatePassword(newPassword);

  Future<void> deleteAccount() async {
    // Calls the 'delete_my_account' RPC function to securely delete the user.
    // This database function handles the deletion of the user from auth.users
    // and automatically triggers cleanup of all related data via database trigger.
    try {
      // Verify user is authenticated
      final user = currentUser;
      if (user == null) {
        throw Exception('No active session found');
      }

      // Call the RPC function to delete account
      // The database trigger will automatically clean up all user data
      final response = await Supabase.instance.client.rpc('delete_my_account');

      // Check if deletion was successful
      if (response != null && response['success'] == false) {
        throw Exception(response['error'] ?? 'Failed to delete account');
      }

      // Sign out locally to clear session and remove PIN
      await signOut();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _repository.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.lovely://login-callback',
    );
  }

  Future<void> resetPassword({required String email}) =>
      _repository.resetPassword(email: email);
}
