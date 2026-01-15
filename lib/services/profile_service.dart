import 'package:lovely/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper for user/profile related data access
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService({SupabaseService? supabase}) => _instance;
  ProfileService._internal({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService();

  final SupabaseService _supabase;

  Future<Map<String, dynamic>?> getUserData() => _supabase.getUserData();

  User? get currentUser => _supabase.currentUser;

  Future<bool> hasCompletedOnboarding() => _supabase.hasCompletedOnboarding();

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) => _supabase.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        bio: bio,
        dateOfBirth: dateOfBirth,
      );

  Future<void> updateUserData(Map<String, dynamic> updates) => _supabase.updateUserData(updates);

  Future<void> saveUserData({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) => _supabase.saveUserData(
        firstName: firstName,
        lastName: lastName,
        username: username,
        dateOfBirth: dateOfBirth,
        averageCycleLength: averageCycleLength,
        averagePeriodLength: averagePeriodLength,
        lastPeriodStart: lastPeriodStart,
        notificationsEnabled: notificationsEnabled,
      );

  Future<bool> isUsernameAvailable(String username) => _supabase.isUsernameAvailable(username);

  Future<Map<String, dynamic>?> getPregnancyInfo() => _supabase.getPregnancyInfo();

  Future<void> enablePregnancyMode({required DateTime conceptionDate, required DateTime dueDate}) =>
      _supabase.enablePregnancyMode(conceptionDate: conceptionDate, dueDate: dueDate);

  Future<void> disablePregnancyMode() => _supabase.disablePregnancyMode();
}
