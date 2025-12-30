import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/config/supabase_config.dart';

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

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword({required String email}) async {
    await client.auth.resetPasswordForEmail(email);
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
      if (averageCycleLength != null) 'average_cycle_length': averageCycleLength,
      if (averagePeriodLength != null) 'average_period_length': averagePeriodLength,
      if (lastPeriodStart != null) 'last_period_start': lastPeriodStart.toIso8601String(),
      if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
    };

    return await client.auth.updateUser(
      UserAttributes(
        data: updates,
      ),
    );
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
}
