import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/services/pin_service.dart';
import 'package:lovely/screens/welcome_screen.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';
import 'package:lovely/screens/settings/edit_profile_screen.dart';
import 'package:lovely/screens/settings/change_password_screen.dart';
import 'package:lovely/screens/settings/notifications_settings_screen.dart';
import 'package:lovely/screens/settings/cycle_settings_screen.dart';
import 'package:lovely/screens/security/pin_setup_screen.dart';
import 'package:lovely/core/feedback/feedback_service.dart';
import 'package:lovely/providers/pin_lock_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  String _userEmail = '';
  bool _isEmailVerified = false;
  double _profileCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final service = SupabaseService();
      final user = service.currentUser;
      final userData = await service.getUserData();
      
      if (mounted) {
        setState(() {
          _userName = userData?['first_name'] as String? ?? user?.userMetadata?['name'] as String? ?? 'User';
          _userEmail = user?.email ?? 'No email';
          _isEmailVerified = service.isEmailVerified;
          _profileCompletion = _calculateProfileCompletion(userData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculateProfileCompletion(Map<String, dynamic>? userData) {
    if (userData == null) return 0.0;
    
    int completed = 0;
    int total = 5;
    
    if (userData['first_name'] != null && (userData['first_name'] as String).isNotEmpty) completed++;
    if (userData['username'] != null && (userData['username'] as String).isNotEmpty) completed++;
    if (userData['last_period_start'] != null) completed++;
    if (_isEmailVerified) completed++;
    if (userData['date_of_birth'] != null) completed++;
    
    return completed / total;
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await SupabaseService().signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackService.showError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.only(right: context.responsive.spacingMd),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: _profileCompletion,
                        strokeWidth: 3,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _profileCompletion >= 1.0 ? Colors.green : AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(_profileCompletion * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: context.responsive.spacingMd),
                  Text(
                    'Loading your profile...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.responsive.spacingLg),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      size: context.responsive.largeIconSize,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingMd),
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (_isEmailVerified) ...[
                        SizedBox(width: context.responsive.spacingMd),
                        Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: context.responsive.smallIconSize,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // PROFILE Section
            _buildSection(
              context,
              title: 'PROFILE',
              sectionColor: const Color(0xFFFF6F61), // Coral
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.user,
                  iconColor: const Color(0xFFFF6F61),
                  title: 'Edit Profile',
                  subtitle: _profileCompletion >= 1.0 ? 'Make it yours' : 'Complete your profile ✨',
                  showBadge: _profileCompletion < 1.0,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    if (result == true && context.mounted) {
                      await _loadUserData();
                    }
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.envelope,
                  iconColor: const Color(0xFFFF6F61),
                  title: 'Email Verification',
                  subtitle: _isEmailVerified ? 'Verified ✓' : 'Almost there - verify to unlock features',
                  showBadge: !_isEmailVerified,
                  onTap: () {
                    if (!_isEmailVerified) {
                      _showVerificationOptions(context);
                    }
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.lock,
                  iconColor: const Color(0xFFFF6F61),
                  title: 'Change Password',
                  subtitle: 'Keep your account secure',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // YOUR WELLNESS Section
            _buildSection(
              context,
              title: 'YOUR WELLNESS',
              sectionColor: const Color(0xFF26A69A), // Teal
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.calendar,
                  iconColor: const Color(0xFF26A69A),
                  title: 'Cycle Settings',
                  subtitle: 'Fine-tune your insights',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CycleSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.download,
                  iconColor: const Color(0xFF26A69A),
                  title: 'Export Data',
                  subtitle: 'Download your wellness journey',
                  onTap: () {
                    _showExportDataDialog(context);
                  },
                ),
              ],
            ),

            // App Preferences Section
            _buildSection(
              context,
              title: 'PREFERENCES',
              sectionColor: const Color(0xFF5C6BC0),
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.bell,
                  iconColor: const Color(0xFF5C6BC0),
                  title: 'Notifications',
                  subtitle: 'Stay in the loop, your way',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.palette,
                  iconColor: const Color(0xFF5C6BC0),
                  title: 'Appearance',
                  subtitle: 'Choose your theme',
                  onTap: () {
                    _showAppearanceDialog(context);
                  },
                ),
              ],
            ),

            // Privacy & Security Section
            _buildSection(
              context,
              title: 'PRIVACY & SECURITY',
              sectionColor: const Color(0xFFE91E63), // Pink
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.lock,
                  iconColor: const Color(0xFFE91E63),
                  title: 'App PIN Lock',
                  subtitle: 'Protect your data with a PIN',
                  onTap: () => _showPinSettings(context),
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.shield,
                  iconColor: const Color(0xFFE91E63),
                  title: 'Privacy Settings',
                  subtitle: 'Control who sees what',
                  onTap: () {
                    FeedbackService.showInfo(context, 'Privacy settings coming soon');
                  },
                ),
              ],
            ),

            // Support & Legal Section
            _buildSection(
              context,
              title: 'SUPPORT & LEGAL',
              sectionColor: const Color(0xFF9C27B0),
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.shield,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Privacy Policy',
                  subtitle: 'Your data is private and secure 🔒',
                  onTap: () {
                    FeedbackService.showInfo(context, 'Privacy Policy: https://lovely.app/privacy');
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.fileContract,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Terms of Service',
                  subtitle: 'Know your rights',
                  onTap: () {
                    FeedbackService.showInfo(context, 'Terms: https://lovely.app/terms');
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.heart,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Rate Us',
                  subtitle: 'Help us grow and improve',
                  onTap: () {
                    FeedbackService.showInfo(context, 'Rate us on App Store coming soon');
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.circleInfo,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'About Lovely',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),

            // ACCOUNT ACTIONS Section
            _buildSection(
              context,
              title: 'ACCOUNT ACTIONS',
              sectionColor: AppColors.error,
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.trashCan,
                  iconColor: AppColors.error,
                  title: 'Delete Account',
                  subtitle: 'We\'ll miss you - this can\'t be undone',
                  titleColor: AppColors.error,
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: EdgeInsets.all(context.responsive.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive.spacingMd,
                    ),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                  label: const Text('Sign Out'),
                ),
              ),
            ),

            SizedBox(height: context.responsive.spacingLg),
          ],
        ),
              ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    required Color sectionColor,
    bool showCompletion = false,
    double completion = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.spacingMd,
        vertical: context.responsive.spacingSm,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: sectionColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsive.spacingMd,
                context.responsive.spacingMd,
                context.responsive.spacingMd,
                context.responsive.spacingSm,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: sectionColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (showCompletion) ...[
                    const Spacer(),
                    Text(
                      '${(completion * 100).toInt()}%',
                      style: TextStyle(
                        color: sectionColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    bool showBadge = false,
    required VoidCallback onTap,
  }) {
    final effectiveIconColor = iconColor ?? titleColor ?? Theme.of(context).iconTheme.color;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconColor?.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 20,
            color: effectiveIconColor,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
            ),
          ),
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showVerificationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Verification',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Almost there! Verifying your email unlocks password recovery and helps keep your wellness journey secure ✨',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await SupabaseService().resendVerificationEmail();
                    if (context.mounted) {
                      Navigator.pop(context);
                      FeedbackService.showSuccess(
                        context,
                        'Verification email sent!',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      FeedbackService.showError(context, e);
                    }
                  }
                },
                icon: const FaIcon(FontAwesomeIcons.envelope),
                label: const Text('Resend Verification Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPinSettings(BuildContext context) async {
    final pinService = PinService();
    final hasPin = await pinService.hasPin();
    final isEnabled = await pinService.isPinEnabled();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App PIN Lock',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasPin && isEnabled
                  ? 'PIN protection is active. Your wellness data is secure 🔒'
                  : 'Set a 4-digit PIN to protect your sensitive health data from prying eyes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            if (hasPin && isEnabled) ...[
              // Change PIN
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _changePin(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.key),
                  label: const Text('Change PIN'),
                ),
              ),
              const SizedBox(height: 12),
              // Disable PIN
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _disablePin(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.lockOpen),
                  label: const Text('Disable PIN'),
                ),
              ),
            ] else ...[
              // Enable PIN
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      ref.read(pinLockProvider.notifier).refresh();
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.lock),
                  label: const Text('Enable PIN Lock'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    // Show change PIN dialog
    FeedbackService.showInfo(context, 'Change PIN coming soon');
  }

  Future<void> _disablePin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN Lock?'),
        content: const Text(
          'Your app will no longer be protected by a PIN. Anyone with access to your device can view your wellness data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await PinService().removePin();
        ref.read(pinLockProvider.notifier).disablePin();
        if (context.mounted) {
          FeedbackService.showSuccess(context, 'PIN lock disabled');
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackService.showError(context, e);
        }
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: AppColors.error,
            ),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAccountDeletion(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }



  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            RadioGroup<int>(
              groupValue: 1,
              onChanged: (value) {
                // Theme selection will be implemented
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(value: 0),
                      const Icon(Icons.light_mode),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Light')),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(value: 1),
                      const Icon(Icons.dark_mode),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Dark')),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(value: 2),
                      const Icon(Icons.brightness_auto),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('System (Current)')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                FeedbackService.showInfo(context, 'Edit Profile coming soon');
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Download your personal data including:'),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Period tracking data'),
                  Text('• Mood & symptom logs'),
                  Text('• Activity records'),
                  Text('• Notes & journal entries'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your data will be exported as a CSV file.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              FeedbackService.showInfo(context, 'Data export starting...');
            },
            icon: const FaIcon(FontAwesomeIcons.download),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Lovely'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lovely',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'Your journey to wellness and self-care starts here.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Period & cycle tracking'),
                  Text('✓ Mood & symptom logging'),
                  Text('✓ Activity tracking'),
                  Text('✓ Daily insights'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context) async {
    try {
      // Show progress dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Deleting Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Just a moment...'),
            ],
          ),
        ),
      );

      // Call delete account on backend
      await SupabaseService().deleteAccount();

      // Close progress dialog
      if (!context.mounted) return;
      Navigator.pop(context);

      // Navigate to welcome screen
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      // Close progress dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }
}
