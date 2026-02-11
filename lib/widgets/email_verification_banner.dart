import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/services/auth_service.dart';
import 'package:lunara/core/feedback/feedback_service.dart';

class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isDismissed = false;
  bool _isResending = false;

  Future<void> _handleResendEmail() async {
    setState(() => _isResending = true);

    try {
      await AuthService().resendVerificationEmail();

      if (mounted) {
        FeedbackService.showSuccess(
          context,
          'Email sent! Check your inbox',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _handleDismiss() {
    setState(() => _isDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if dismissed temporarily
    if (_isDismissed) return const SizedBox.shrink();

    final daysSinceSignup = AuthService().daysSinceSignup;
    final isUrgent = daysSinceSignup > 5; // Show urgency after 5 days

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.orange.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                isUrgent
                    ? FontAwesomeIcons.triangleExclamation
                    : FontAwesomeIcons.envelope,
                size: 20,
                color: isUrgent ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrgent
                      ? 'Time to verify your email'
                      : 'Let\'s verify your email',

                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUrgent
                        ? Colors.orange.shade900
                        : Colors.blue.shade900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _handleDismiss,
                color: Colors.grey.shade600,
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isUrgent
                ? 'You have ${7 - daysSinceSignup} days left to verify your email to keep full access to your account and enable password recovery.'
                : 'Check your inbox and click the verification link to secure your account and enable password recovery.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _isResending ? null : _handleResendEmail,
                icon: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.rotateRight, size: 14),
                label: Text(_isResending ? 'Sending...' : 'Resend Email'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Refresh to check if email was verified
                  setState(() {});
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
                child: const Text('I verified it'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
