import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/screens/welcome_screen.dart';
import 'package:lovely/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  double _getResponsiveSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / 375);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;
    final userName = user?.userMetadata?['name'] as String? ?? 'User';
    final userEmail = user?.email ?? 'No email';
    final isEmailVerified = SupabaseService().isEmailVerified;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_getResponsiveSize(context, 24)),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: _getResponsiveSize(context, 50),
                    backgroundColor: Colors.white,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      size: _getResponsiveSize(context, 40),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 16)),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 4)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (isEmailVerified) ...[
                        SizedBox(width: _getResponsiveSize(context, 8)),
                        Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: _getResponsiveSize(context, 18),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Account Section
            _buildSection(
              context,
              title: 'Account',
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.user,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    // TODO: Navigate to edit profile
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.envelope,
                  title: 'Email Verification',
                  subtitle: isEmailVerified ? 'Verified' : 'Not verified',
                  trailing: isEmailVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    if (!isEmailVerified) {
                      _showVerificationOptions(context);
                    }
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
              ],
            ),

            // Settings Section
            _buildSection(
              context,
              title: 'Settings',
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.bell,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.calendar,
                  title: 'Cycle Settings',
                  subtitle: 'Adjust cycle length and predictions',
                  onTap: () {
                    // TODO: Navigate to cycle settings
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.palette,
                  title: 'Appearance',
                  subtitle: 'Theme and display options',
                  onTap: () {
                    // TODO: Navigate to appearance settings
                  },
                ),
              ],
            ),

            // Privacy & Data Section
            _buildSection(
              context,
              title: 'Privacy & Data',
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.shield,
                  title: 'Privacy Policy',
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.fileContract,
                  title: 'Terms of Service',
                  onTap: () {
                    // TODO: Show terms of service
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.database,
                  title: 'Export Data',
                  subtitle: 'Download your data',
                  onTap: () {
                    // TODO: Export user data
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.trashCan,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  titleColor: Colors.red,
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),

            // About Section
            _buildSection(
              context,
              title: 'About',
              items: [
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.circleInfo,
                  title: 'About Lovely',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    // TODO: Show about page
                  },
                ),
                _buildListTile(
                  context,
                  icon: FontAwesomeIcons.heart,
                  title: 'Rate Us',
                  subtitle: 'Share your feedback',
                  onTap: () {
                    // TODO: Open app store rating
                  },
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: EdgeInsets.all(_getResponsiveSize(context, 24)),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handleSignOut(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(
                      vertical: _getResponsiveSize(context, 16),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                  label: const Text('Sign Out'),
                ),
              ),
            ),

            SizedBox(height: _getResponsiveSize(context, 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            _getResponsiveSize(context, 16),
            _getResponsiveSize(context, 24),
            _getResponsiveSize(context, 16),
            _getResponsiveSize(context, 8),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: FaIcon(
        icon,
        size: _getResponsiveSize(context, 20),
        color: titleColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
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
              'Your email is not verified. Verify your email to enable password recovery and secure your account.',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email sent!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
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
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
