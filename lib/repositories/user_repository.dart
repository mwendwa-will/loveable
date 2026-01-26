import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lovely/core/exceptions/app_exceptions.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/services/supabase_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(SupabaseService().client);
});

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  User? get _currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> updateUserData(Map<String, dynamic> updates) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await _client.from('users').update(updates).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> saveUserData({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    String? fullName;
    if (firstName != null) {
      fullName = lastName != null && lastName.isNotEmpty
          ? '$firstName $lastName'
          : firstName;
    }

    await _client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      if (fullName != null) 'name': fullName,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (username != null) 'username': username,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'average_cycle_length': averageCycleLength ?? 28,
      'average_period_length': averagePeriodLength ?? 5,
      'last_period_start': lastPeriodStart?.toIso8601String(),
      'onboarding_complete': true,
      'notifications_enabled': notificationsEnabled ?? true,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Create initial period if needed (logic moved here to keep it contained)
    if (lastPeriodStart != null) {
      final existingPeriod = await _client
          .from('periods')
          .select()
          .eq('user_id', user.id)
          .eq('start_date', lastPeriodStart.toIso8601String())
          .maybeSingle();

      if (existingPeriod == null) {
        // We need to call PeriodRepository here, but to avoid circular dependencies
        // we'll do a direct insert. In a perfect world, we'd use a UseCase.
        await _client.from('periods').insert({
          'user_id': user.id,
          'start_date': lastPeriodStart.toIso8601String(),
          'flow_intensity': FlowIntensity.medium.name,
        });
      }
    }
  }

  Future<UserResponse> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) async {
    final updates = <String, dynamic>{
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (username != null && username.isNotEmpty) 'username': username,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      if (averageCycleLength != null)
        'average_cycle_length': averageCycleLength,
      if (averagePeriodLength != null)
        'average_period_length': averagePeriodLength,
      if (lastPeriodStart != null)
        'last_period_start': lastPeriodStart.toIso8601String(),
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
    };

    return await _client.auth.updateUser(UserAttributes(data: updates));
  }

  Future<void> updateUserProfileFull({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) updates['first_name'] = firstName.trim();
      if (lastName != null) updates['last_name'] = lastName.trim();
      if (username != null) updates['username'] = username.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }

      await _client.from('users').update(updates).eq('id', user.id);

      if (username != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'display_name': username.trim()}),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _client.rpc(
        'is_username_available',
        params: {'check_username': username.trim()},
      );
      return result as bool;
    } catch (e) {
      try {
        final response = await _client
            .from('users')
            .select('username')
            .ilike('username', username.trim())
            .maybeSingle();
        return response == null;
      } catch (e2) {
        return false;
      }
    }
  }

  Future<Map<String, dynamic>?> getPregnancyInfo() async {
    final user = _currentUser;
    if (user == null) return null;

    final response = await _client
        .from('pregnancy_mode')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> enablePregnancyMode({
    required DateTime conceptionDate,
    required DateTime dueDate,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    await _client.from('pregnancy_mode').upsert({
      'user_id': user.id,
      'conception_date': conceptionDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    // Pause cycle tracking
    await updateUserData({'pregnancy_mode_enabled': true});
  }

  Future<void> disablePregnancyMode() async {
    final user = _currentUser;
    if (user == null) throw AuthException.sessionExpired();

    await _client.from('pregnancy_mode').delete().eq('user_id', user.id);
    // Resume cycle tracking
    await updateUserData({'pregnancy_mode_enabled': false});
  }
}
