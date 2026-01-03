# Profile & Security Features - Implementation Plan

## Overview
Implementation plan for completing the profile screen with:
1. Edit Profile with initials avatar
2. Change Password 
3. PIN Login with optional biometrics

---

## Phase 1: Profile Provider & Avatar System (1-2 hours)

### 1.1 Create Profile Provider
**File**: `lib/providers/profile_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/services/supabase_service.dart';

class UserProfile {
  final String name;
  final String? bio;
  final DateTime? dateOfBirth;
  
  UserProfile({
    required this.name,
    this.bio,
    this.dateOfBirth,
  });
  
  UserProfile copyWith({
    String? name,
    String? bio,
    DateTime? dateOfBirth,
  }) {
    return UserProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
  
  /// Get initials from name (first two words)
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '??';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

class ProfileNotifier extends Notifier<UserProfile> {
  late SupabaseService _supabaseService;
  
  @override
  UserProfile build() {
    _supabaseService = SupabaseService();
    loadProfile();
    return UserProfile(name: 'Loading...');
  }
  
  Future<void> loadProfile() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      
      final userData = await _supabaseService.getUserData();
      
      state = UserProfile(
        name: userData?['name'] as String? ?? 'User',
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
    String? name,
    String? bio,
    DateTime? dateOfBirth,
  }) async {
    // Optimistic update (instant UI feedback)
    final previousState = state;
    
    try {
      state = state.copyWith(
        name: name,
        bio: bio,
        dateOfBirth: dateOfBirth,
      );
      
      // Persist to Supabase
      await _supabaseService.updateUserProfile(
        name: name ?? state.name,
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
```

### 1.2 Add Avatar Widget
**File**: `lib/widgets/user_avatar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:lovely/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 50,
    this.backgroundColor,
    this.textColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundColor == null
            ? AppColors.primaryGradient
            : null,
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
```

---

## Phase 2: Edit Profile Bottom Sheet (2 hours)

### 2.1 Create Edit Profile Bottom Sheet
**File**: `lib/screens/dialogs/edit_profile_bottom_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lovely/providers/profile_provider.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';

class EditProfileBottomSheet extends ConsumerStatefulWidget {
  const EditProfileBottomSheet({super.key});
  
  @override
  ConsumerState<EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState
    extends ConsumerState<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio ?? '');
    _selectedDateOfBirth = profile.dateOfBirth;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(profileProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: context.responsive.spacingMd,
        left: context.responsive.spacingMd,
        right: context.responsive.spacingMd,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                ),
              ],
            ),
            SizedBox(height: context.responsive.spacingLg),
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                prefixIcon: const Icon(FontAwesomeIcons.user, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length > 50) {
                  return 'Name must be 50 characters or less';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsive.spacingMd),
            
            // Bio field
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                prefixIcon: const Icon(FontAwesomeIcons.penToSquare, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: '${_bioController.text.length}/200 characters',
              ),
              maxLines: 3,
              maxLength: 200,
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value != null && value.length > 200) {
                  return 'Bio must be 200 characters or less';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsive.spacingMd),
            
            // Date of Birth (Optional)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateOfBirth ?? 
                      DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDateOfBirth = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  prefixIcon: const Icon(FontAwesomeIcons.cakeCandles, size: 18),
                  suffixIcon: _selectedDateOfBirth != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _selectedDateOfBirth = null),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                      : 'Select your date of birth',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null 
                        ? null 
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            SizedBox(height: context.responsive.spacingLg),
            
            // Save button
            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: context.responsive.spacingMd,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
            SizedBox(height: context.responsive.spacingMd),
          ],
        ),
      ),
    );
  }
}
```

### 2.2 Add Supabase Method
**Add to**: `lib/services/supabase_service.dart`

```dart
/// Update user profile (name, bio, date of birth)
Future<void> updateUserProfile({
  String? name,
  String? bio,
  DateTime? dateOfBirth,
}) async {
  final user = currentUser;
  if (user == null) throw Exception('User not authenticated');
  
  try {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (name != null) updates['name'] = name.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    
    await client.from('users').update(updates).eq('id', user.id);
    
    debugPrint('✅ Profile updated successfully');
  } catch (e) {
    debugPrint('❌ Error updating profile: $e');
    rethrow;
  }
}
```

---

## Phase 3: Change Password Dialog (1-2 hours)

### 3.1 Create Change Password Dialog
**File**: `lib/screens/dialogs/change_password_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});
  
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }
  
  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return const SizedBox.shrink();
    
    final strength = _calculatePasswordStrength(password);
    Color color;
    String label;
    
    if (strength <= 2) {
      color = Colors.red;
      label = 'Weak';
    } else if (strength <= 4) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.green;
      label = 'Strong';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingSm),
        LinearProgressIndicator(
          value: strength / 6,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        SizedBox(height: context.responsive.spacingSm),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await SupabaseService().changePassword(_newPasswordController.text);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(FontAwesomeIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: FaIcon(
                    _obscureNewPassword
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 18,
                  ),
                  onPressed: () => setState(
                    () => _obscureNewPassword = !_obscureNewPassword,
                  ),
                ),
              ),
              validator: _validateNewPassword,
              onChanged: (value) => setState(() {}),
            ),
            _buildPasswordStrengthIndicator(),
            SizedBox(height: context.responsive.spacingMd),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(FontAwesomeIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: FaIcon(
                    _obscureConfirmPassword
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 18,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Change Password'),
        ),
      ],
    );
  }
}
```

### 3.2 Add Supabase Method
**Add to**: `lib/services/supabase_service.dart`

```dart
/// Change user password
Future<void> changePassword(String newPassword) async {
  final user = currentUser;
  if (user == null) throw Exception('User not authenticated');
  
  try {
    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    debugPrint('✅ Password changed successfully');
  } catch (e) {
    debugPrint('❌ Error changing password: $e');
    throw Exception('Failed to change password. Please try again.');
  }
}
```

---

## Phase 4: PIN & Biometric Login (Future - 3-4 hours)

### 4.1 Dependencies
Add to `pubspec.yaml`:
```yaml
local_auth: ^2.3.0  # Biometric authentication
flutter_secure_storage: ^9.2.2  # Secure PIN storage
```

### 4.2 Architecture Plan

```
User logs in with email/password
    ↓
Offers to set up PIN
    ↓
User creates 4-6 digit PIN
    ↓
Store PIN hash in flutter_secure_storage
    ↓
If device supports biometrics:
    ↓
    Offer to enable biometric login
    ↓
    Store preference in secure storage
    
On next app launch:
    ↓
    Check if PIN is set
    ↓
    If yes: Show PIN screen
         ├─ If biometric enabled: Show biometric prompt
         └─ Fallback to PIN entry
    ↓
    Validate PIN → Restore Supabase session
```

### 4.3 Files to Create

- `lib/services/pin_service.dart` - PIN management
- `lib/services/biometric_service.dart` - Biometric authentication
- `lib/screens/auth/pin_setup_screen.dart` - PIN creation
- `lib/screens/auth/pin_login_screen.dart` - PIN entry
- `lib/widgets/pin_input.dart` - PIN input widget
- `lib/providers/security_provider.dart` - Security state management

### 4.4 Security Considerations

✅ PIN stored as salted hash (not plaintext)
✅ flutter_secure_storage encrypts data
✅ Max 3 PIN attempts before lockout
✅ Biometric fallback to PIN
✅ PIN required after 7 days even with biometric
✅ Session token refresh mechanism

---

## Database Migrations Needed

```sql
-- Add bio column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;

-- date_of_birth already exists but is now optional

-- For future PIN/biometric (Phase 4)
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT FALSE;
```

---

## Implementation Timeline

### Week 1
- **Day 1-2**: Profile Provider + Avatar Widget + Edit Profile Bottom Sheet
- **Day 3**: Change Password Dialog + Integration
- **Day 4-5**: Testing, polish, documentation

### Week 2 (Future)
- **Day 1-2**: PIN Service + Setup Screen
- **Day 3**: Biometric Service + Integration
- **Day 4-5**: PIN Login Screen + Security Testing

---

## Testing Checklist

### Edit Profile
- [ ] Name validation (required, max 50 chars)
- [ ] Bio validation (optional, max 200 chars)
- [ ] Date of birth picker works
- [ ] Initials avatar updates immediately
- [ ] Profile header shows updated name
- [ ] Empty bio clears field
- [ ] Network error handling
- [ ] Optimistic update rollback on error

### Change Password
- [ ] Password strength indicator works
- [ ] Min 8 chars validation
- [ ] Uppercase/lowercase/number requirements
- [ ] Passwords must match
- [ ] Show/hide password toggle
- [ ] Success message displays
- [ ] Error handling for auth failures
- [ ] Dialog closes on success

### PIN/Biometric (Future)
- [ ] PIN creation flow
- [ ] Biometric enrollment
- [ ] PIN login with attempts limit
- [ ] Biometric fallback to PIN
- [ ] Session restoration
- [ ] Lockout after failed attempts

---

## Key Design Decisions

✅ **Bottom sheet for profile** - Casual editing, swipe-to-dismiss
✅ **Dialog for password** - Security-critical action
✅ **Initials avatar** - No image upload complexity yet
✅ **Optional date of birth** - Privacy-focused approach
✅ **Optimistic updates** - Instant UI feedback
✅ **Password strength indicator** - User education
✅ **PIN for future** - Planned but not blocking current release

This implementation follows all AGENTS.md guidelines and provides a solid foundation for security features! 🎯
