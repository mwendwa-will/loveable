import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/services/profile_service.dart';
import 'package:lunara/services/auth_service.dart';
import 'package:lunara/services/pin_service.dart';
import 'package:lunara/services/period_service.dart';
import 'package:lunara/services/export_service.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/utils/responsive_utils.dart';
import 'package:lunara/navigation/app_router.dart';
import 'package:lunara/core/feedback/feedback_service.dart';
import 'package:lunara/providers/pin_lock_provider.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/widgets/upgrade_sheet.dart';

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
      final profileService = ProfileService();
      final authService = AuthService();
      final user = authService.currentUser;
      final userData = await profileService.getUserData();

      if (mounted) {
        setState(() {
          _userName =
              userData?['first_name'] as String? ??
              user?.userMetadata?['name'] as String? ??
              'User';
          _userEmail = user?.email ?? 'No email';
          _isEmailVerified = authService.isEmailVerified;
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

    if (userData['first_name'] != null &&
        (userData['first_name'] as String).isNotEmpty) {
      completed++;
    }
    if (userData['username'] != null &&
        (userData['username'] as String).isNotEmpty) {
      completed++;
    }
    if (userData['last_period_start'] != null) {
      completed++;
    }
    if (_isEmailVerified) {
      completed++;
    }
    if (userData['date_of_birth'] != null) {
      completed++;
    }

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
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
                          _profileCompletion >= 1.0
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(_profileCompletion * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                    // Profile Header (Premium Dashboard Card)
                    _buildPremiumHeader(context),

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
                          subtitle: _profileCompletion >= 1.0
                              ? 'Make it yours'
                              : 'Complete your profile',
                          showBadge: _profileCompletion < 1.0,
                          onTap: () async {
                            final result = await Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.editProfile);
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
                          subtitle: _isEmailVerified
                              ? 'Verified'
                              : 'Almost there - verify to unlock features',
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
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.changePassword);
                          },
                        ),
                      ],
                    ),

                    // SUBSCRIPTION Section
                    _buildSubscriptionSection(context),

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
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.cycleSettings);
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
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.notificationsSettings);
                          },
                        ),
                        /*
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
                        */
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
                        /*
                        _buildListTile(
                          context,
                          icon: FontAwesomeIcons.shield,
                          iconColor: const Color(0xFFE91E63),
                          title: 'Privacy Settings',
                          subtitle: 'Coming in Phase 2',
                          onTap: () {
                            FeedbackService.showInfo(
                              context,
                              'Privacy settings will be available in Phase 2',
                            );
                          },
                        ),
                        */
                      ],
                    ),

                    // Support & Legal Section
                    _buildSection(
                      context,
                      title: 'SUPPORT & LEGAL',
                      sectionColor: const Color(0xFF9C27B0),
                      items: [
                        /*
                        _buildListTile(
                          context,
                          icon: FontAwesomeIcons.shield,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'Privacy Policy',
                          subtitle: 'Your data is private and secure',
                          onTap: () {
                            FeedbackService.showInfo(
                              context,
                              'Privacy Policy: https://lovely.app/privacy',
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: FontAwesomeIcons.fileContract,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'Terms of Service',
                          subtitle: 'Know your rights',
                          onTap: () {
                            FeedbackService.showInfo(
                              context,
                              'Terms: https://lovely.app/terms',
                            );
                          },
                        ),
                        _buildListTile(
                          context,
                          icon: FontAwesomeIcons.heart,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'Rate Us',
                          subtitle: 'Coming in Phase 2',
                          onTap: () {
                            FeedbackService.showInfo(
                              context,
                              'App Store rating will be available in Phase 2',
                            );
                          },
                        ),
                        */
                        _buildListTile(
                          context,
                          icon: FontAwesomeIcons.circleInfo,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'About Lunara',
                          subtitle: 'Version 1.0.0',
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),
                      ],
                    ),

                    // ACCOUNT ACTIONS Section
                    _buildPremiumSection(
                      context,
                      title: 'ACCOUNT ACTIONS',
                      sectionColor: AppColors.error,
                      items: [
                        _buildPremiumItem(
                          context,
                          icon: FontAwesomeIcons.trashCan,
                          iconColor: AppColors.error,
                          title: 'Delete Account',
                          subtitle: "We'll miss you - this can't be undone",
                          titleColor: AppColors.error,
                          onTap: () {
                            _showDeleteAccountDialog(context);
                          },
                        ),
                      ],
                    ),

                    // Sign Out Button
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingLg,
                        vertical: context.responsive.spacingMd,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSignOut(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: context.responsive.spacingMd,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          icon: const FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            size: 18,
                          ),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: context.responsive.spacingMd,
        vertical: context.responsive.spacingMd,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Glassmorphic overlay effect
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.responsive.spacingLg),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: _profileCompletion,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        _buildInitialsAvatar(radius: 48),
                      ],
                    ),
                    SizedBox(height: context.responsive.spacingMd),
                    Text(
                      _userName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                    SizedBox(height: context.responsive.spacingXs),
                    Text(
                      _userEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (_isEmailVerified) ...[
                      SizedBox(height: context.responsive.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Verified Member',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    
    return subscriptionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (subscription) {
        final isPremium = subscription?.isPremium ?? false;
        final isTrial = subscription?.isTrialActive ?? false;
        final planName = isPremium ? 'Premium' : 'Free';
        final trialDisplay = subscription?.trialRemainingDisplay ?? '';
        
        return _buildSection(
          context,
          title: 'SUBSCRIPTION',
          sectionColor: const Color(0xFFFFB74D), // Amber
          items: [
            _buildListTile(
              context,
              icon: isPremium ? FontAwesomeIcons.crown : FontAwesomeIcons.gift,
              iconColor: const Color(0xFFFFB74D),
              title: 'Current Plan',
              subtitle: isTrial 
                  ? '$planName (Trial: $trialDisplay)' 
                  : planName,
              onTap: () {
                if (!isPremium) {
                  UpgradeSheet.show(context);
                }
              },
            ),
            if (!isPremium)
              _buildListTile(
                context,
                icon: FontAwesomeIcons.arrowUp,
                iconColor: const Color(0xFFFFB74D),
                title: 'Upgrade to Premium',
                subtitle: 'Unlock all features',
                onTap: () {
                  UpgradeSheet.show(context);
                },
              ),
            _buildListTile(
              context,
              icon: FontAwesomeIcons.rotateRight,
              iconColor: const Color(0xFFFFB74D),
              title: 'Restore Purchases',
              subtitle: 'Sync your subscription',
              onTap: () async {
                try {
                  await ref.read(subscriptionProvider.notifier).restore();
                  if (context.mounted) {
                    FeedbackService.showSuccess(
                      context,
                      'Purchase restored successfully',
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    FeedbackService.showError(context, e);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    required Color sectionColor,
  }) {
    return _buildPremiumSection(
      context,
      title: title,
      items: items,
      sectionColor: sectionColor,
    );
  }

  Widget _buildPremiumSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    required Color sectionColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.spacingMd,
        vertical: context.responsive.spacingSm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsive.spacingLg,
                context.responsive.spacingLg,
                context.responsive.spacingLg,
                context.responsive.spacingSm,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: sectionColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...items,
            SizedBox(height: context.responsive.spacingSm),
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
    return _buildPremiumItem(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      titleColor: titleColor,
      iconColor: iconColor,
      showBadge: showBadge,
      onTap: onTap,
    );
  }

  Widget _buildPremiumItem(
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
    final effectiveIconColor =
        iconColor ?? titleColor ?? Theme.of(context).iconTheme.color;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.spacingLg,
          vertical: context.responsive.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveIconColor?.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(icon, size: 18, color: effectiveIconColor),
              ),
            ),
            SizedBox(width: context.responsive.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
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
              'Almost there! Verifying your email unlocks password recovery and helps keep your wellness journey secure',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    await AuthService().resendVerificationEmail();
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              hasPin && isEnabled
                  ? 'PIN protection is active. Your wellness data is secure'
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
                    final result = await Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.pinSetup);
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
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.pinSetup, arguments: {'isChangeMode': true});
    if (result == true && mounted) {
      ref.read(pinLockProvider.notifier).refresh();
    }
  }

  Future<void> _disablePin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN Lock?'),
        content: const Text(
          'For your security, please enter your current PIN to disable protection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show PIN entry to verify before disabling
      final verified = await Navigator.of(
        context,
      ).pushNamed(AppRoutes.pinUnlock);

      if (verified == true && mounted) {
        try {
          await PinService().removePin();
          await ref.read(pinLockProvider.notifier).refresh();
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

  /*
  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: Theme.of(context).textTheme.titleSmall),
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
  */

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download your personal data including:'),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Period tracking data'),
                  Text('• Flow intensity logs'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
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
            onPressed: () async {
              Navigator.pop(context);
              FeedbackService.showInfo(context, 'Preparing your data...');
              try {
                final periods = await ref
                    .read(periodServiceProvider)
                    .getPeriods(limit: 1000);
                await ExportService().exportPeriodsToCSV(periods);
                if (context.mounted) {
                  FeedbackService.showSuccess(context, 'Export complete!');
                }
              } catch (e) {
                if (context.mounted) {
                  FeedbackService.showError(context, e);
                }
              }
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
        title: const Text('About Lunara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lunara',
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
            Text('Features:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Period & cycle tracking'),
                  Text('Mood & symptom logging'),
                  Text('Activity tracking'),
                  Text('Daily insights'),
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
      await AuthService().deleteAccount();

      // Close progress dialog
      if (!context.mounted) return;
      Navigator.pop(context);

      // Show success feedback
      if (!context.mounted) return;
      FeedbackService.showSuccess(
        context,
        'Account deleted successfully. We\'re sorry to see you go!',
      );

      // Wait a moment for user to see the feedback
      await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate to login screen
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  Widget _buildInitialsAvatar({
    required double radius,
    Color? backgroundColor,
  }) {
    String initials = '';
    if (_userName.isNotEmpty) {
      final parts = _userName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    if (initials.isEmpty) initials = 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: backgroundColor == null ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}
