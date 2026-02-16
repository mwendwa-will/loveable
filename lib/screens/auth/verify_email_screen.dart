import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/providers/auth_provider.dart';
import 'package:lunara/utils/responsive_utils.dart';

/// Email verification screen shown after signup
/// Guides users through email confirmation process
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? email;

  const VerifyEmailScreen({super.key, this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  @override
  void initState() {
    super.initState();
    // Periodically check if email is verified (every 3 seconds)
    _startVerificationCheck();
  }

  Future<void> _startVerificationCheck() async {
    for (int i = 0; i < 60; i++) {
      // Try for 3 minutes max
      await Future.delayed(const Duration(seconds: 3));

      final isVerified = ref.read(isEmailVerifiedProvider);
      if (isVerified) {
        // Email verified! Close this screen
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSizing.of(context).spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: ResponsiveSizing.of(context).spacingXl * 2),

                // Success Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.envelope,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: ResponsiveSizing.of(context).spacingXl),

                // Title
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ResponsiveSizing.of(context).spacingMd),

                // Description
                Text(
                  'We\'ve sent a confirmation link to ${widget.email ?? "your email"}.\n\nClick the link to verify your account and get started with Lunara.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: ResponsiveSizing.of(context).spacingXl * 2),

                // Loading indicator
                const CircularProgressIndicator(),

                SizedBox(height: ResponsiveSizing.of(context).spacingLg),

                Text(
                  'Waiting for verification...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                SizedBox(height: ResponsiveSizing.of(context).spacingXl * 3),

                // Back button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to sign in',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
