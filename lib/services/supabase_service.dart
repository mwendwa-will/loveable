import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lovely/config/supabase_config.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/core/exceptions/app_exceptions.dart';

class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase - call this in main() before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Auth methods
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // Email verification helpers
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  int get daysSinceSignup {
    final user = currentUser;
    if (user == null) return 0;

    // Parse createdAt which is a String in ISO 8601 format
    try {
      final createdAt = DateTime.parse(user.createdAt);
      return DateTime.now().difference(createdAt).inDays;
    } catch (e) {
      return 0;
    }
  }

  bool get requiresVerification {
    // Require verification after 7 days grace period
    return !isEmailVerified && daysSinceSignup > 7;
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
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

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
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

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword({required String email}) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No authenticated user', code: 'AUTH_999');
    }
    if (isEmailVerified) {
      throw AuthException('Email already verified', code: 'AUTH_998');
    }

    try {
      await client.auth.resend(type: OtpType.signup, email: user.email!);
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

  // Update user profile
  Future<UserResponse> updateProfile({
    required String name,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) async {
    final updates = <String, dynamic>{
      if (name.isNotEmpty) 'name': name,
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

    return await client.auth.updateUser(UserAttributes(data: updates));
  }

  // Save user data to database (called after onboarding)
  Future<void> saveUserData({
    required String name,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    await client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'name': name,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'average_cycle_length': averageCycleLength ?? 28,
      'average_period_length': averagePeriodLength ?? 5,
      'last_period_start': lastPeriodStart?.toIso8601String(),
      'notifications_enabled': notificationsEnabled ?? true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get user data from database
  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final userData = await getUserData();
    return userData?['name'] != null && userData?['date_of_birth'] != null;
  }

  // Period Logging Methods

  // Start a new period
  Future<Period> startPeriod({
    required DateTime startDate,
    FlowIntensity? intensity,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = {
      'user_id': user.id,
      'start_date': startDate.toIso8601String(),
      'flow_intensity': intensity?.name ?? FlowIntensity.medium.name,
    };

    final response = await client
        .from('periods')
        .insert(data)
        .select()
        .single();

    return Period.fromJson(response);
  }

  // End the current period
  Future<Period> endPeriod({
    required String periodId,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('periods')
        .update({'end_date': endDate.toIso8601String()})
        .eq('id', periodId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Period.fromJson(response);
  }

  // Get current ongoing period (if any)
  Future<Period?> getCurrentPeriod() async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .isFilter('end_date', null)
        .order('start_date', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return Period.fromJson(response);
  }

  // Get all periods for the user
  Future<List<Period>> getPeriods({int? limit}) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    var query = client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .order('start_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((json) => Period.fromJson(json)).toList();
  }

  // Get periods for a specific date range
  Future<List<Period>> getPeriodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .gte('start_date', startDate.toIso8601String())
        .lte('start_date', endDate.toIso8601String())
        .order('start_date', ascending: false);

    return (response as List).map((json) => Period.fromJson(json)).toList();
  }

  // Update period flow intensity
  Future<Period> updatePeriodIntensity({
    required String periodId,
    required FlowIntensity intensity,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('periods')
        .update({'flow_intensity': intensity.name})
        .eq('id', periodId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Period.fromJson(response);
  }

  // Delete a period
  Future<void> deletePeriod(String periodId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('periods')
        .delete()
        .eq('id', periodId)
        .eq('user_id', user.id);
  }

  // Mood & Symptom Methods

  // Save mood for a specific date
  Future<Mood> saveMood({
    required DateTime date,
    required MoodType mood,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if mood already exists for this date
    final existing = await client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (existing != null) {
      // Update existing mood
      final response = await client
          .from('moods')
          .update({'mood': mood.name, if (notes != null) 'notes': notes})
          .eq('id', existing['id'])
          .select()
          .single();

      return Mood.fromJson(response);
    } else {
      // Insert new mood
      final data = {
        'user_id': user.id,
        'date': date.toIso8601String().split('T')[0],
        'mood': mood.name,
        if (notes != null) 'notes': notes,
      };

      final response = await client
          .from('moods')
          .insert(data)
          .select()
          .single();

      return Mood.fromJson(response);
    }
  }

  // Get mood for a specific date
  Future<Mood?> getMoodForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return Mood.fromJson(response);
  }

  // Save symptoms for a specific date
  Future<List<Symptom>> saveSymptoms({
    required DateTime date,
    required List<SymptomType> symptomTypes,
    Map<SymptomType, int>? severities,
    Map<SymptomType, String>? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Delete existing symptoms for this date first
    await client
        .from('symptoms')
        .delete()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0]);

    // Insert new symptoms
    final symptomsData = symptomTypes.map((type) {
      return {
        'user_id': user.id,
        'date': date.toIso8601String().split('T')[0],
        'symptom_type': type.name,
        'severity': severities?[type] ?? 3,
        if (notes?[type] != null) 'notes': notes![type],
      };
    }).toList();

    if (symptomsData.isEmpty) return [];

    final response = await client
        .from('symptoms')
        .insert(symptomsData)
        .select();

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  // Get moods for a date range (batch query optimization)
  Future<List<Mood>> getMoodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: true);

    return (response as List).map((json) => Mood.fromJson(json)).toList();
  }

  // Get symptoms for a specific date
  Future<List<Symptom>> getSymptomsForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0]);

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  // Get symptoms in a date range
  Future<List<Symptom>> getSymptomsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  // Sexual Activity Methods

  // Log sexual activity
  Future<SexualActivity> logSexualActivity({
    required DateTime date,
    required bool protectionUsed,
    ProtectionType? protectionType,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final data = {
      'user_id': user.id,
      'date': date.toIso8601String().split('T')[0],
      'protection_used': protectionUsed,
      'protection_type': protectionType?.value,
      'notes': notes,
    };

    final response = await client
        .from('sexual_activities')
        .insert(data)
        .select()
        .single();

    return SexualActivity.fromJson(response);
  }

  // Get sexual activity for a specific date
  Future<SexualActivity?> getSexualActivityForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('sexual_activities')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return SexualActivity.fromJson(response);
  }

  // Get sexual activities in a date range
  Future<List<SexualActivity>> getSexualActivitiesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('sexual_activities')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);

    return (response as List)
        .map((json) => SexualActivity.fromJson(json))
        .toList();
  }

  // Delete sexual activity
  Future<void> deleteSexualActivity(String id) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('sexual_activities')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // Note Methods

  // Save or update note for a date
  Future<Note> saveNote({
    required DateTime date,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if note exists for this date
    final existing = await getNoteForDate(date);

    if (existing != null) {
      // Update existing note
      final response = await client
          .from('notes')
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return Note.fromJson(response);
    } else {
      // Create new note
      final data = {
        'user_id': user.id,
        'date': date.toIso8601String().split('T')[0],
        'content': content,
      };

      final response = await client
          .from('notes')
          .insert(data)
          .select()
          .single();

      return Note.fromJson(response);
    }
  }

  // Get note for a specific date
  Future<Note?> getNoteForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('notes')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return Note.fromJson(response);
  }

  // Get notes in a date range
  Future<List<Note>> getNotesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('notes')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);

    return (response as List).map((json) => Note.fromJson(json)).toList();
  }

  // Delete note
  Future<void> deleteNote(String id) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client.from('notes').delete().eq('id', id).eq('user_id', user.id);
  }

  // Pregnancy Mode Methods

  // Enable pregnancy mode
  Future<void> enablePregnancyMode({
    required DateTime conceptionDate,
    DateTime? dueDate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('users')
        .update({
          'pregnancy_mode': true,
          'conception_date': conceptionDate.toIso8601String(),
          'due_date': dueDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // Disable pregnancy mode
  Future<void> disablePregnancyMode() async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('users')
        .update({
          'pregnancy_mode': false,
          'conception_date': null,
          'due_date': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // Get pregnancy info
  Future<Map<String, dynamic>?> getPregnancyInfo() async {
    final userData = await getUserData();
    if (userData == null || userData['pregnancy_mode'] != true) return null;

    return {
      'conception_date': userData['conception_date'] != null
          ? DateTime.parse(userData['conception_date'])
          : null,
      'due_date': userData['due_date'] != null
          ? DateTime.parse(userData['due_date'])
          : null,
    };
  }

  // Stream Methods - Real-time data with Supabase subscriptions

  /// Stream periods for a specific date range
  Stream<List<Period>> getPeriodsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('periods')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((p) {
                final pDate = DateTime.parse(p['start_date']);
                return pDate.isAfter(startDate) && pDate.isBefore(endDate);
              })
              .map((json) => Period.fromJson(json))
              .toList();
        });
  }

  /// Stream moods for a date range
  Stream<List<Mood>> getMoodsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('moods')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((m) {
                final mDate = DateTime.parse('${m['date']}T00:00:00');
                return mDate.isAfter(startDate) && mDate.isBefore(endDate);
              })
              .map((json) => Mood.fromJson(json))
              .toList();
        });
  }

  /// Stream symptoms for a date range
  Stream<List<Symptom>> getSymptomsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('symptoms')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((s) {
                final sDate = DateTime.parse('${s['date']}T00:00:00');
                return sDate.isAfter(startDate) && sDate.isBefore(endDate);
              })
              .map((json) => Symptom.fromJson(json))
              .toList();
        });
  }

  /// Stream sexual activities for a date range
  Stream<List<SexualActivity>> getSexualActivitiesStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('sexual_activities')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((a) {
                final aDate = DateTime.parse('${a['date']}T00:00:00');
                return aDate.isAfter(startDate) && aDate.isBefore(endDate);
              })
              .map((json) => SexualActivity.fromJson(json))
              .toList();
        });
  }

  /// Stream notes for a date range
  Stream<List<Note>> getNotesStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((n) {
                final nDate = DateTime.parse('${n['date']}T00:00:00');
                return nDate.isAfter(startDate) && nDate.isBefore(endDate);
              })
              .map((json) => Note.fromJson(json))
              .toList();
        });
  }

  /// Stream mood for a specific date
  Stream<Mood?> getMoodStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    final dateStr = date.toIso8601String().split('T')[0];

    return client
        .from('moods')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          if ((data as List).isEmpty) return null;
          for (final item in data) {
            if (item['date'] == dateStr) {
              return Mood.fromJson(item);
            }
          }
          return null;
        });
  }

  /// Stream note for a specific date
  Stream<Note?> getNoteStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    final dateStr = date.toIso8601String().split('T')[0];

    return client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          if ((data as List).isEmpty) return null;
          for (final item in data) {
            if (item['date'] == dateStr) {
              return Note.fromJson(item);
            }
          }
          return null;
        });
  }

  /// Stream sexual activity for a specific date
  Stream<SexualActivity?> getSexualActivityStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');
    final dateStr = date.toIso8601String().split('T')[0];

    return client
        .from('sexual_activities')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          if ((data as List).isEmpty) return null;
          for (final item in data) {
            if (item['date'] == dateStr) {
              return SexualActivity.fromJson(item);
            }
          }
          return null;
        });
  }
}
