import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';
import 'package:lovely/core/feedback/feedback_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = true;
  String? _usernameError;
  String? _originalUsername;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final service = SupabaseService();
      
      // Get user data from database
      final userData = await service.getUserData();
      if (userData != null) {
        _firstNameController.text = userData['first_name'] as String? ?? '';
        _lastNameController.text = userData['last_name'] as String? ?? '';
        _usernameController.text = userData['username'] as String? ?? '';
        _originalUsername = _usernameController.text;
        
        // Parse date of birth if available
        final dobStr = userData['date_of_birth'] as String?;
        if (dobStr != null) {
          _dateOfBirth = DateTime.parse(dobStr);
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username == _originalUsername) {
      setState(() {
        _usernameAvailable = true;
        _usernameError = null;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final available = await SupabaseService().isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _usernameError = available ? null : 'Username already taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'Couldn\'t check username availability';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_usernameAvailable) return;

    setState(() => _isSaving = true);

    try {
      final service = SupabaseService();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim();
      
      // Update profile using SupabaseService method
      await service.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        username: username != _originalUsername ? username : null,
        dateOfBirth: _dateOfBirth,
      );

      if (mounted) {
        FeedbackService.showSuccess(context, 'Profile updated! ✨');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.responsive.spacingMd),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.responsive.spacingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro text
                    Text(
                      'Update your personal information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: context.responsive.spacingLg),
                    
                    // Profile Picture Section (placeholder for now)
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: FaIcon(
                                  FontAwesomeIcons.user,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      FeedbackService.showInfo(
                                        context,
                                        'Profile picture upload coming soon 📸',
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsive.spacingSm),
                          Text(
                            'Change Photo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: context.responsive.spacingLg),

                    // Form Fields Card
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.responsive.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First Name
                            Text(
                              'First Name',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                    SizedBox(height: context.responsive.spacingSm),
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter your first name',
                        prefixIcon: const Icon(FontAwesomeIcons.user, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.responsive.spacingMd),

                    // Last Name
                    Text(
                      'Last Name (Optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: context.responsive.spacingSm),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter your last name',
                        prefixIcon: const Icon(FontAwesomeIcons.user, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: context.responsive.spacingMd),

                    // Username
                    Text(
                      'Username',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: context.responsive.spacingSm),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Choose a unique username',
                        prefixIcon: const Icon(FontAwesomeIcons.at, size: 20),
                        suffixIcon: _isCheckingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _usernameController.text.length >= 3 &&
                                    _usernameController.text != _originalUsername
                                ? Icon(
                                    _usernameAvailable ? Icons.check_circle : Icons.error,
                                    color: _usernameAvailable ? Colors.green : Colors.red,
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: _usernameError,
                        helperText: 'Letters, numbers, _, -, . (3-30 chars)',
                      ),
                      onChanged: (value) {
                        if (value.length >= 3) {
                          _checkUsernameAvailability(value);
                        } else {
                          setState(() {
                            _usernameError = null;
                            _usernameAvailable = true;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (value.length > 30) {
                          return 'Username must be 30 characters or less';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                          return 'Only letters, numbers, _, -, . allowed';
                        }
                        if (!_usernameAvailable) {
                          return 'Username already taken';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.responsive.spacingMd),

                    // Date of Birth (Optional)
                    Text(
                      'Date of Birth (Optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: context.responsive.spacingSm),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateOfBirth ?? DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dateOfBirth = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(FontAwesomeIcons.cakeCandles, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
                              : 'Select your date of birth',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _dateOfBirth != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: context.responsive.spacingLg),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const FaIcon(FontAwesomeIcons.floppyDisk),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                      ),
                    ),

                    SizedBox(height: context.responsive.spacingMd),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    
                    SizedBox(height: context.responsive.spacingMd),
                  ],
                ),
              ),
            ),
    );
  }
}
