import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/services/supabase_service.dart';

class UserProfile {
  final String firstName;
  final String? lastName;
  final String? username;
  final String? bio;
  final DateTime? dateOfBirth;
  
  UserProfile({
    required this.firstName,
    this.lastName,
    this.username,
    this.bio,
    this.dateOfBirth,
  });
  
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
  
  /// Get full name (first + last if available)
  String get fullName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }
  
  /// Get initials from name (first + last initial)
  String get initials {
    if (lastName != null && lastName!.isNotEmpty) {
      return '${firstName[0]}${lastName![0]}'.toUpperCase();
    }
    // If only first name, use first two characters if possible
    return firstName.length > 1 
        ? firstName.substring(0, 2).toUpperCase()
        : firstName[0].toUpperCase();
  }
}

class ProfileNotifier extends Notifier<UserProfile> {
  late SupabaseService _supabaseService;
  
  @override
  UserProfile build() {
    _supabaseService = SupabaseService();
    loadProfile();
    return UserProfile(firstName: 'Loading...');
  }
  
  Future<void> loadProfile() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      
      final userData = await _supabaseService.getUserData();
      
      state = UserProfile(
        firstName: userData?['first_name'] as String? ?? 'User',
        lastName: userData?['last_name'] as String?,
        username: userData?['username'] as String?,
        bio: userData?['bio'] as String?,
        dateOfBirth: userData?['date_of_birth'] != null
            ? DateTime.parse(userData!['date_of_birth'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }
  
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    // Optimistic update (instant UI feedback)
    final previousState = state;
    
    try {
      state = state.copyWith(
        firstName: firstName,
        lastName: lastName,
        username: username,
        bio: bio,
        dateOfBirth: dateOfBirth,
      );
      
      // Persist to Supabase
      await _supabaseService.updateUserProfile(
        firstName: firstName ?? state.firstName,
        lastName: lastName,
        username: username,
        bio: bio,
        dateOfBirth: dateOfBirth,
      );
    } catch (e) {
      // Rollback on error
      state = previousState;
      rethrow;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});
