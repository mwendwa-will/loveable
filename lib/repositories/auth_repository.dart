import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lovely/core/exceptions/app_exceptions.dart';
import 'package:lovely/services/supabase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseService().client);
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final combinedMetadata = <String, dynamic>{
        ...?metadata,
        if (username != null) 'username': username.trim(),
        if (username != null) 'display_name': username.trim(),
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
      };

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: combinedMetadata,
      );
      return response;
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      if (e.message.contains('already registered')) {
        throw AuthException.emailAlreadyInUse();
      }
      if (e.message.contains('weak password') ||
          e.message.contains('Password')) {
        throw AuthException.weakPassword();
      }
      throw AuthException(e.message, code: e.code, originalError: e);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Sign up failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String emailToUse = emailOrUsername.trim();

      if (!emailOrUsername.contains('@')) {
        try {
          final result = await _client.rpc(
            'get_user_by_username_or_email',
            params: {'identifier': emailOrUsername.trim()},
          );

          if (result != null && result is List && result.isNotEmpty) {
            final userData = result[0] as Map<String, dynamic>;
            emailToUse = userData['email'] as String;
          } else {
            throw AuthException.invalidCredentials();
          }
        } catch (e) {
          try {
            final userRecord = await _client
                .from('users')
                .select('email')
                .ilike('username', emailOrUsername.trim())
                .maybeSingle();

            if (userRecord != null) {
              emailToUse = userRecord['email'] as String;
            } else {
              throw AuthException.invalidCredentials();
            }
          } catch (e2) {
            throw AuthException.invalidCredentials();
          }
        }
      }

      final response = await _client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      if (response.session == null) {
        throw AuthException.invalidCredentials();
      }

      return response;
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException.invalidCredentials();
      }
      if (e.message.contains('Email not confirmed')) {
        throw AuthException.emailNotVerified();
      }
      throw AuthException(e.message, code: e.code, originalError: e);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Sign in failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
  }) async {
    await _client.auth.signInWithOAuth(provider, redirectTo: redirectTo);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No authenticated user', code: 'AUTH_999');
    }
    try {
      await _client.auth.resend(type: OtpType.signup, email: user.email!);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Failed to resend verification email',
        originalError: e,
      );
    }
  }
}
