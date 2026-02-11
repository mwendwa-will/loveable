import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/services/auth_service.dart';
import 'package:lunara/core/feedback/feedback_service.dart';
import 'package:lunara/core/exceptions/app_exceptions.dart';

/// Screen shown when user needs to verify their email
class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({super.key});

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  bool _isResending = false;
  String? _resendMessage;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.envelope,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Let\'s verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We just sent a verification link to:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Email address
              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Instructions
              Text(
                'Check your inbox and click the link to continue your wellness journey!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Resend message
              if (_resendMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _resendMessage!.contains('Error')
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        _resendMessage!.contains('Error')
                            ? FontAwesomeIcons.circleExclamation
                            : FontAwesomeIcons.circleCheck,
                        size: 16,
                        color: _resendMessage!.contains('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resendMessage!,
                          style: TextStyle(
                            color: _resendMessage!.contains('Error')
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Resend button
              OutlinedButton.icon(
                onPressed: _isResending ? null : _resendVerificationEmail,
                icon: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                label: Text(_isResending ? 'Sending...' : 'Resend Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout button
              TextButton.icon(
                onPressed: _logout,
                icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 16),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _resendMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user?.email == null) {
        throw AuthException('No email found', code: 'AUTH_008');
      }

      await AuthService().resendVerificationEmail();

      setState(() {
        _resendMessage = 'Verification email sent! Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _resendMessage = 'Error sending email. Please try again later.';
      });
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      // AuthGate will automatically redirect to WelcomeScreen
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }
}
