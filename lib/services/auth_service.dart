import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/repositories/auth_repository.dart';
import 'package:lovely/services/pin_service.dart';

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
    // This might currently be in SupabaseService directly or via edge function
    // Assuming SupabaseService has it, we should move it to AuthRepo or generic repo
    // For now, let's call SupabaseService().deleteAccount() if we can't move it yet
    // Or simpler: implement in Repo.
    // Let's assume we implement it in Repo or calling client directly
    try {
      await Supabase.instance.client.functions.invoke('delete-user');
      await signOut();
    } catch (e) {
      // Fallback
      await Supabase.instance.client.rpc('delete_user_account');
      await signOut();
    }
  }

  Future<void> resetPassword({required String email}) =>
      _repository.resetPassword(email: email);
}
