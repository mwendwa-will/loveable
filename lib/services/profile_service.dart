import 'package:lovely/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/repositories/user_repository.dart';

/// Wrapper for user/profile related data access
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService({SupabaseService? supabase}) => _instance;

  late final UserRepository _repository;

  ProfileService._internal({SupabaseService? supabase}) {
    _repository = UserRepository((supabase ?? SupabaseService()).client);
  }

  Future<Map<String, dynamic>?> getUserData() => _repository.getUserData();

  User? get currentUser => Supabase
      .instance
      .client
      .auth
      .currentUser; // Accessed directly or via repo helper if available

  Future<bool> hasCompletedOnboarding() async {
    final data = await getUserData();
    // Simplify check or move logic to repo. Keeping logic here using repo data.
    if (data == null) return false;
    return data['first_name'] != null || data['username'] != null;
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) => _repository.updateUserProfileFull(
    firstName: firstName,
    lastName: lastName,
    username: username,
    bio: bio,
    dateOfBirth: dateOfBirth,
  );

  Future<void> updateUserData(Map<String, dynamic> updates) =>
      _repository.updateUserData(updates);

  Future<void> saveUserData({
    String? firstName,
    String? lastName,
    String? username,
    DateTime? dateOfBirth,
    int? averageCycleLength,
    int? averagePeriodLength,
    DateTime? lastPeriodStart,
    bool? notificationsEnabled,
  }) => _repository.saveUserData(
    firstName: firstName,
    lastName: lastName,
    username: username,
    dateOfBirth: dateOfBirth,
    averageCycleLength: averageCycleLength,
    averagePeriodLength: averagePeriodLength,
    lastPeriodStart: lastPeriodStart,
    notificationsEnabled: notificationsEnabled,
  );

  Future<bool> isUsernameAvailable(String username) =>
      _repository.isUsernameAvailable(username);

  Future<Map<String, dynamic>?> getPregnancyInfo() =>
      _repository.getPregnancyInfo();

  Future<void> enablePregnancyMode({
    required DateTime conceptionDate,
    required DateTime dueDate,
  }) => _repository.enablePregnancyMode(
    conceptionDate: conceptionDate,
    dueDate: dueDate,
  );

  Future<void> disablePregnancyMode() => _repository.disablePregnancyMode();
}
