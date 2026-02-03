// ignore_for_file: unnecessary_underscores

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lovely/config/supabase_config.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/core/exceptions/app_exceptions.dart';
import 'package:lovely/services/cycle_analyzer.dart';

class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() : _client = null;

  // For testing: allow injecting a mock client
  factory SupabaseService.forTest(SupabaseClient mockClient) {
    final service = SupabaseService._internalTest(mockClient);
    return service;
  }

  SupabaseService._internalTest(this._client);

  final SupabaseClient? _client;

  // Internal fallback test client used when Supabase.instance is not initialized.
  static final dynamic _testFallbackClient = _TestSupabaseClient();
  // When true, force using the test fallback client even if Supabase.instance
  // has been initialized. Set by test helpers when they want full control.
  static bool _forceUseTestFallback = false;

  // Get the Supabase client. Prefer an injected client, then the real
  // Supabase.instance client. If Supabase hasn't been initialized (common
  // in unit/widget tests where initialization order is tricky), return a
  // lightweight test fallback that provides minimal APIs used across the app.
  dynamic get client {
    if (_client != null) return _client;
    if (_forceUseTestFallback) return _testFallbackClient;
    try {
      return Supabase.instance.client;
    } catch (e) {
      // Supabase not initialized yet (will throw an assertion). Use test
      // fallback so tests and early widget builds don't crash; production
      // code should initialize Supabase in main().
      return _testFallbackClient;
    }
  }

  /// Test helper: configure the built-in test fallback auth state.
  /// Call from tests to set a fake `currentUser` and `currentSession`.
  /// If `user` is non-null, emits `AuthChangeEvent.signedIn`.
  static void setTestAuth({dynamic user, dynamic session}) {
    try {
      _forceUseTestFallback = true;
      final dynamic c = _testFallbackClient;
      if (c is _TestSupabaseClient) {
        c.auth.currentUser = user;
        c.auth.currentSession = session;
        c.auth.emitAuthChange(
          user != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
          session,
        );
      }
    } catch (_) {}
  }

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
    // Require verification after 24 hours grace period
    return !isEmailVerified && daysSinceSignup > 1;
  }

  /// Check if username is available (case-insensitive)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await client.rpc(
        'is_username_available',
        params: {'check_username': username.trim()},
      );
      return result as bool;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      // If the function doesn't exist yet, do a direct query
      try {
        final response = await client
            .from('users')
            .select('username')
            .ilike('username', username.trim())
            .maybeSingle();
        return response == null;
      } catch (e2) {
        debugPrint('Fallback username check failed: $e2');
        return false; // Assume not available on error to be safe
      }
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Merge username/names with any additional metadata
      final combinedMetadata = <String, dynamic>{
        ...?metadata,
        if (username != null) 'username': username.trim(),
        // Set username as display_name in Supabase auth
        if (username != null) 'display_name': username.trim(),
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
      };

      final response = await client.auth.signUp(
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

  // Sign in with email OR username and password
  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String emailToUse = emailOrUsername.trim();

      // If input doesn't contain @, it's likely a username - look up email
      if (!emailOrUsername.contains('@')) {
        try {
          final result = await client.rpc(
            'get_user_by_username_or_email',
            params: {'identifier': emailOrUsername.trim()},
          );

          if (result != null && result is List && result.isNotEmpty) {
            final userData = result[0] as Map<String, dynamic>;
            emailToUse = userData['email'] as String;
            debugPrint('Found user by username: $emailOrUsername');
          } else {
            throw AuthException.invalidCredentials();
          }
        } catch (e) {
          debugPrint('Username lookup failed: $e');
          // If RPC fails, try direct query as fallback
          try {
            final userRecord = await client
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
            debugPrint('Fallback username query failed: $e2');
            throw AuthException.invalidCredentials();
          }
        }
      }

      // Now sign in with the email
      final response = await client.auth.signInWithPassword(
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
      'average_cycle_length': ?averageCycleLength,
      'average_period_length': ?averagePeriodLength,
      if (lastPeriodStart != null)
        'last_period_start': lastPeriodStart.toIso8601String(),
      'notifications_enabled': ?notificationsEnabled,
    };

    return await client.auth.updateUser(UserAttributes(data: updates));
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('Password updated successfully');
    } catch (e) {
      debugPrint('Error updating password: $e');
      rethrow;
    }
  }

  // Save user data to database (called after onboarding)
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
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    // Create combined name for backward compatibility with 'name' column
    String? fullName;
    if (firstName != null) {
      fullName = lastName != null && lastName.isNotEmpty
          ? '$firstName $lastName'
          : firstName;
    }

    await client.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'name': ?fullName,
      'first_name': ?firstName,
      'last_name': ?lastName,
      'username': ?username,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'average_cycle_length': averageCycleLength ?? 28,
      'average_period_length': averagePeriodLength ?? 5,
      'last_period_start': lastPeriodStart?.toIso8601String(),
      'onboarding_complete': true,
      'notifications_enabled': notificationsEnabled ?? true,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // If lastPeriodStart is provided during onboarding, create a period record
    // This ensures the calendar shows the period correctly for new users
    if (lastPeriodStart != null) {
      // Check if a period already exists for this date
      final existingPeriod = await client
          .from('periods')
          .select()
          .eq('user_id', user.id)
          .eq('start_date', lastPeriodStart.toIso8601String())
          .maybeSingle();

      // Only create if it doesn't exist
      if (existingPeriod == null) {
        await startPeriod(startDate: lastPeriodStart);
      }
    }
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
  // Onboarding is complete when user has saved their cycle preferences
  // Names are optional and can be added later in profile settings
  Future<bool> hasCompletedOnboarding() async {
    final userData = await getUserData();
    // Check if user exists in database (means onboarding was completed)
    return userData != null;
  }

  /// Update user profile (first_name, last_name, username, bio, date of birth)
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    final user = currentUser;
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

      await client.from('users').update(updates).eq('id', user.id);

      // Update display_name in auth metadata if username changed
      if (username != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'display_name': username.trim()}),
        );
      }

      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Update user data (generic key-value updates)
  /// Used by CycleAnalyzer for predictions
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await client.from('users').update(updates).eq('id', user.id);
      debugPrint('User data updated');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  /// Get completed periods (periods with end_date set)
  /// Used by CycleAnalyzer to calculate cycle lengths
  Future<List<Period>> getCompletedPeriods({int? limit}) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    var query = client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .not('end_date', 'is', null)
        .order('start_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((json) => Period.fromJson(json)).toList();
  }

  // Period Logging Methods

  // Start a new period (ENHANCED with Truth Event - Instance 6)
  Future<Period> startPeriod({
    required DateTime startDate,
    FlowIntensity? intensity,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    // STEP 0: Auto-close any ongoing periods older than 15 days (data cleanup)
    try {
      final ongoingPeriods = await client
          .from('periods')
          .select()
          .eq('user_id', user.id)
          .isFilter('end_date', null);

      for (final periodData in ongoingPeriods) {
        final period = Period.fromJson(periodData);
        final daysSinceStart = DateTime.now()
            .difference(period.startDate)
            .inDays;

        if (daysSinceStart > 15) {
          // Auto-close this abnormally long period
          final autoEndDate = period.startDate.add(
            const Duration(days: 7),
          ); // Default 7-day period
          debugPrint(
            'Warning: Auto-closing period ${period.id} ($daysSinceStart days old) with end date: $autoEndDate',
          );

          await client
              .from('periods')
              .update({'end_date': autoEndDate.toIso8601String()})
              .eq('id', period.id)
              .eq('user_id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Warning: Error auto-closing old periods: $e');
    }

    // STEP 1: Record prediction accuracy if this is not the first period
    try {
      final userData = await getUserData();

      if (userData == null) {
        debugPrint('Warning: User data not found');
      } else {
        final lastPeriodStart = userData['last_period_start'] != null
            ? DateTime.parse(userData['last_period_start']!)
            : null;

        if (lastPeriodStart != null) {
          // Calculate cycle number for this truth event
          final completedPeriods = await getCompletedPeriods(limit: 100);
          final cycleNumber = completedPeriods.length + 1;

          // Record prediction accuracy (Instance 6: Truth Event)
          await CycleAnalyzer.recordPredictionAccuracy(
            userId: user.id,
            cycleNumber: cycleNumber,
            actualDate: startDate,
          );
        }
      }
    } catch (e) {
      debugPrint('Warning: Error recording prediction accuracy: $e');
    }

    // STEP 2: Create new period
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

    // STEP 3: Update user's last period start
    await updateUserData({'last_period_start': startDate.toIso8601String()});

    // STEP 4: RECALCULATE all predictions based on new data
    try {
      await CycleAnalyzer.recalculateAfterPeriodStart(user.id);
      debugPrint('Period started, predictions recalculated');
    } catch (e) {
      debugPrint('Warning: Error recalculating predictions: $e');
    }

    return Period.fromJson(response);
  }

  // End the current period
  Future<Period> endPeriod({
    required String periodId,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    // Validate: Get the period to check start date
    final periodData = await client
        .from('periods')
        .select()
        .eq('id', periodId)
        .eq('user_id', user.id)
        .single();

    final period = Period.fromJson(periodData);

    // Validation 1: End date must be after or equal to start date
    if (endDate.isBefore(period.startDate)) {
      throw ValidationException(
        'End date cannot be before start date',
        code: 'VAL_003',
      );
    }

    // Validation 2: Period cannot be longer than 15 days
    final durationDays = endDate.difference(period.startDate).inDays;
    if (durationDays > 15) {
      throw ValidationException(
        'Please keep periods under 15 days. Check the selected dates.',
        code: 'VAL_004',
      );
    }

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
    if (user == null) throw AuthException.sessionExpired();

    // Use limit(1) to handle edge case of duplicate ongoing periods
    final response = await client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .isFilter('end_date', null)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Period.fromJson(response);
  }

  // Get all periods for the user
  Future<List<Period>> getPeriods({int? limit}) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    // Fetch periods that could overlap with the range
    // Start 60 days before to catch periods that might extend into the range
    final lookbackDate = startDate.subtract(const Duration(days: 60));

    final response = await client
        .from('periods')
        .select()
        .eq('user_id', user.id)
        .gte('start_date', lookbackDate.toIso8601String())
        .lte('start_date', endDate.toIso8601String())
        .order('start_date', ascending: false);

    final allPeriods = (response as List)
        .map((json) => Period.fromJson(json))
        .toList();

    // Filter to only include periods that actually overlap with the date range
    return allPeriods.where((period) {
      final periodStart = period.startDate;
      final periodEnd = period.endDate ?? DateTime.now(); // Ongoing period

      // Check if period overlaps with the requested range
      // Period overlaps if: start <= endDate AND end >= startDate
      return periodStart.isBefore(endDate.add(const Duration(days: 1))) &&
          periodEnd.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  // Update period flow intensity
  Future<Period> updatePeriodIntensity({
    required String periodId,
    required FlowIntensity intensity,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    // Check if mood already exists for this date
    final existing = await client
        .from('moods')
        .select()
        .eq('user_id', user.id)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    try {
      if (existing != null) {
        // Update existing mood
        final response = await client
            .from('moods')
            .update({'mood_type': mood.name, 'notes': ?notes})
            .eq('id', existing['id'])
            .select()
            .single();

        return Mood.fromJson(response);
      } else {
        // Insert new mood
        final data = {
          'user_id': user.id,
          'date': date.toIso8601String().split('T')[0],
          'mood_type': mood.name,
          'notes': ?notes,
        };

        final response = await client
            .from('moods')
            .insert(data)
            .select()
            .single();

        return Mood.fromJson(response);
      }
    } catch (e) {
      debugPrint('Failed to save mood for ${date.toIso8601String()}: $e');
      rethrow;
    }
  }

  // Get mood for a specific date
  Future<Mood?> getMoodForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    final dateStr = date.toIso8601String().split('T')[0];

    // Build new symptoms data BEFORE deleting
    final symptomsData = symptomTypes.map((type) {
      return {
        'user_id': user.id,
        'date': dateStr,
        'symptom_type': type.value, // Use .value instead of .name for database
        'severity': severities?[type] ?? 3,
        if (notes?[type] != null) 'notes': notes![type],
      };
    }).toList();

    // If no symptoms, just delete existing and return
    if (symptomsData.isEmpty) {
      await client
          .from('symptoms')
          .delete()
          .eq('user_id', user.id)
          .eq('date', dateStr);
      return [];
    }

    // Delete existing symptoms for this date
    await client
        .from('symptoms')
        .delete()
        .eq('user_id', user.id)
        .eq('date', dateStr);

    // Insert new symptoms
    try {
      final response = await client
          .from('symptoms')
          .insert(symptomsData)
          .select();

      return (response as List).map((json) => Symptom.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to save symptoms for $dateStr: $e');
      throw Exception('Failed to save symptoms: ${e.toString()}');
    }
  }

  // Get moods for a date range (batch query optimization)
  Future<List<Mood>> getMoodsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    final response = await client
        .from('symptoms')
        .select()
        .eq('user_id', user.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);

    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  // Delete mood entry
  Future<void> deleteMood(String moodId) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    await client.from('moods').delete().eq('id', moodId).eq('user_id', user.id);
  }

  // Delete symptom entry
  Future<void> deleteSymptom(String symptomId) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    await client
        .from('symptoms')
        .delete()
        .eq('id', symptomId)
        .eq('user_id', user.id);
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
    if (user == null) throw AuthException.sessionExpired();

    final data = {
      'user_id': user.id,
      'date': date.toIso8601String().split('T')[0],
      'protection_used': protectionUsed,
      'protection_type': protectionType?.value,
      'notes': notes,
    };

    try {
      final response = await client
          .from('sexual_activities')
          .insert(data)
          .select()
          .single();

      return SexualActivity.fromJson(response);
    } catch (e) {
      debugPrint(
        'Failed to log sexual activity for ${date.toIso8601String()}: $e',
      );
      rethrow;
    }
  }

  // Get sexual activity for a specific date
  Future<SexualActivity?> getSexualActivityForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    // Check if note exists for this date
    final existing = await getNoteForDate(date);

    if (existing != null) {
      try {
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
      } catch (e) {
        debugPrint('Failed to update note for ${date.toIso8601String()}: $e');
        rethrow;
      }
    } else {
      // Create new note
      final data = {
        'user_id': user.id,
        'date': date.toIso8601String().split('T')[0],
        'content': content,
      };
      try {
        final response = await client
            .from('notes')
            .insert(data)
            .select()
            .single();

        return Note.fromJson(response);
      } catch (e) {
        debugPrint('Failed to create note for ${date.toIso8601String()}: $e');
        rethrow;
      }
    }
  }

  // Get note for a specific date
  Future<Note?> getNoteForDate(DateTime date) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

    await client.from('notes').delete().eq('id', id).eq('user_id', user.id);
  }

  // Pregnancy Mode Methods

  // Enable pregnancy mode
  Future<void> enablePregnancyMode({
    required DateTime conceptionDate,
    DateTime? dueDate,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
    if (user == null) throw AuthException.sessionExpired();

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

  // Delete account and all associated data
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      // Delete all user data from related tables
      await client.from('moods').delete().eq('user_id', user.id);
      await client.from('symptoms').delete().eq('user_id', user.id);
      await client.from('periods').delete().eq('user_id', user.id);
      await client.from('sexual_activities').delete().eq('user_id', user.id);
      await client.from('notes').delete().eq('user_id', user.id);

      // Delete user record (this will cascade delete other data due to foreign keys)
      await client.from('users').delete().eq('id', user.id);

      // Delete the auth account
      await client.auth.admin.deleteUser(user.id);

      // Sign out
      await signOut();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Stream Methods - Real-time data with Supabase subscriptions

  /// Stream periods for a specific date range
  Stream<List<Period>> getPeriodsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
        })
        .cast<List<Period>>();
  }

  /// Stream moods for a date range
  Stream<List<Mood>> getMoodsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
        })
        .cast<List<Mood>>();
  }

  /// Stream symptoms for a date range
  Stream<List<Symptom>> getSymptomsStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    return client
        .from('symptoms')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          final list = (data as List);
          return list
              .where((s) {
                final sDate = DateTime.parse('${s['date']}T00:00:00');
                // Use inclusive comparison to include start and end dates
                return !sDate.isBefore(startDate) && sDate.isBefore(endDate);
              })
              .map((json) => Symptom.fromJson(json))
              .toList();
        })
        .cast<List<Symptom>>();
  }

  /// Stream sexual activities for a date range
  Stream<List<SexualActivity>> getSexualActivitiesStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
        })
        .cast<List<SexualActivity>>();
  }

  /// Stream notes for a date range
  Stream<List<Note>> getNotesStream({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

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
        })
        .cast<List<Note>>();
  }

  /// Stream mood for a specific date
  Stream<Mood?> getMoodStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();
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
        })
        .cast<Mood?>();
  }

  /// Stream note for a specific date
  Stream<Note?> getNoteStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();
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
        })
        .cast<Note?>();
  }

  /// Stream sexual activity for a specific date
  Stream<SexualActivity?> getSexualActivityStream(DateTime date) {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();
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
        })
        .cast<SexualActivity?>();
  }

  // Notification Preferences Methods
  /// Get notification preferences for current user
  Future<Map<String, dynamic>?> getNotificationPreferencesData() async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      final response = await client
          .from('users')
          .select('notification_preferences')
          .eq('id', user.id)
          .maybeSingle();

      return response?['notification_preferences'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      return null;
    }
  }

  /// Save notification preferences for current user
  Future<void> saveNotificationPreferencesData(
    Map<String, dynamic> preferences,
  ) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await client
          .from('users')
          .update({'notification_preferences': preferences})
          .eq('id', user.id);
      debugPrint('Notification preferences saved');
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Save FCM token for current user
  Future<void> saveFCMToken(String token) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await client.from('users').update({'fcm_token': token}).eq('id', user.id);
      debugPrint('FCM token saved to database');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
      rethrow;
    }
  }

  /// Get FCM token for current user
  Future<String?> getFCMToken() async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      final response = await client
          .from('users')
          .select('fcm_token')
          .eq('id', user.id)
          .maybeSingle();
      return response?['fcm_token'] as String?;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Update FCM token when it refreshes
  Future<void> updateFCMToken(String newToken) async {
    final user = currentUser;
    if (user == null) throw AuthException.sessionExpired();

    try {
      await client
          .from('users')
          .update({'fcm_token': newToken})
          .eq('id', user.id);
      debugPrint('FCM token updated in database');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      rethrow;
    }
  }

  // Note: These methods are implemented in the notification_provider.dart
  // This service layer provides the data persistence mechanisms
}

// ------------------
// Test fallback client
// ------------------

/// Lightweight fake Supabase client used during tests when the real
/// Supabase.instance hasn't been initialized. This provides minimal
/// `auth` and `from(...)` APIs to avoid assertions during widget/unit
/// tests while keeping behavior predictable (no authenticated user,
/// empty query results, no-op mutations).
class _TestSupabaseClient {
  final _FakeAuth auth = _FakeAuth();

  _FakeQueryBuilder from(String table) => _FakeQueryBuilder(table);

  Future<dynamic> rpc(String name, {Map<String, dynamic>? params}) async {
    return null;
  }

  // simple stream helper for real-time calls
  Stream<List<dynamic>> stream(String table) => Stream<List<dynamic>>.value([]);
}

class _FakeAuth {
  // Mutable current user/session so tests can simulate auth state
  dynamic currentUser;
  dynamic currentSession;

  final _FakeAdmin admin = _FakeAdmin();

  final StreamController<_FakeAuthChange> _controller =
      StreamController<_FakeAuthChange>.broadcast();

  // Default no-op implementations
  Future<void> signOut() async {
    // simulate sign out
    currentUser = null;
    currentSession = null;
    _controller.add(_FakeAuthChange(AuthChangeEvent.signedOut, null));
  }

  Future<void> updateUser(dynamic attrs) async {}

  Future<void> resend({dynamic type, String? email}) async {}

  Future<void> resetPasswordForEmail(String email) async {}

  // Stream that mimics Supabase auth state change events
  Stream<_FakeAuthChange> get onAuthStateChange => _controller.stream;

  // Helper for tests to emit auth state changes
  void emitAuthChange(AuthChangeEvent event, Session? session) {
    currentSession = session;
    currentUser = session?.user;
    _controller.add(_FakeAuthChange(event, session));
  }
}

class _FakeAuthChange {
  final AuthChangeEvent event;
  final Session? session;
  _FakeAuthChange(this.event, this.session);
}

class _FakeAdmin {
  Future<void> deleteUser(String id) async {}
}

class _FakeQueryBuilder implements Future<List<dynamic>> {
  final String table;
  final Future<List<dynamic>> _result;

  _FakeQueryBuilder(this.table) : _result = Future.value([]);

  // Chainable API: return this for builder methods
  _FakeQueryBuilder select([dynamic _]) => this;
  _FakeQueryBuilder eq(String _, dynamic __) => this;
  _FakeQueryBuilder ilike(String _, String __) => this;
  _FakeQueryBuilder not(String _, String __, dynamic ___) => this;
  _FakeQueryBuilder isFilter(String _, dynamic __) => this;
  _FakeQueryBuilder order(String _, {bool ascending = true}) => this;
  _FakeQueryBuilder limit(int _) => this;
  _FakeQueryBuilder insert(dynamic _) => this;
  _FakeQueryBuilder update(dynamic _) => this;
  _FakeQueryBuilder delete() => this;

  // Methods that return singletons or values
  Future<dynamic> maybeSingle() async => null;
  Future<dynamic> single() async => throw Exception('No data');
  Future<dynamic> singleOrNull() async => null;

  // Stream support used by .stream(...).map(...)
  Stream<List<dynamic>> stream({List<String>? primaryKey}) =>
      Stream<List<dynamic>>.value([]);

  // Future interface delegation
  @override
  Stream<List<dynamic>> asStream() => _result.asStream();

  @override
  Future<List<dynamic>> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) => _result.catchError(onError as dynamic, test: test);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<dynamic> value) onValue, {
    Function? onError,
  }) => _result.then(onValue, onError: onError as dynamic);

  @override
  Future<List<dynamic>> timeout(
    Duration timeLimit, {
    FutureOr<List<dynamic>> Function()? onTimeout,
  }) => _result.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<dynamic>> whenComplete(FutureOr Function() action) =>
      _result.whenComplete(action);
}
