import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/screens/auth/forgot_password.dart';
import 'package:lovely/screens/auth/signup.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/screens/onboarding/onboarding_screen.dart';
import 'package:lovely/screens/main/home_screen.dart';
import 'package:lovely/core/feedback/feedback_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null; // Clear previous errors
        _isLoading = true;
      });

      try {
        final supabase = ref.read(supabaseServiceProvider);
        final response = await supabase.signIn(
          emailOrUsername: _emailOrUsernameController.text.trim(),
          password: _passwordController.text,
        );

        if (response.session != null && mounted) {
          // Check if user has completed onboarding
          final hasCompleted = await supabase.hasCompletedOnboarding();

          if (mounted) {
            if (hasCompleted) {
              // Navigate to home screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else {
              // Navigate to onboarding
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = FeedbackService.getErrorMessage(e);
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    // TODO: Implement social login logic
    FeedbackService.showInfo(context, '$provider login coming soon');
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'Lovely app logo',
                    child: FaIcon(
                      FontAwesomeIcons.heart,
                      color: Theme.of(context).colorScheme.primary,
                      size: 72,
                      semanticLabel: 'Heart icon',
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Inline error display
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Semantics(
                    label: 'Email or username input field',
                    textField: true,
                    child: TextFormField(
                      controller: _emailOrUsernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Email or Username',
                        hintText: 'Enter your email or username',
                        prefixIcon: const Icon(
                          FontAwesomeIcons.envelope,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6B9D),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or username';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Password input field',
                    textField: true,
                    obscured: !_isPasswordVisible,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(FontAwesomeIcons.lock, size: 20),
                        suffixIcon: Semantics(
                          label: _isPasswordVisible
                              ? 'Hide password'
                              : 'Show password',
                          button: true,
                          child: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              );
                            },
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF6B9D),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      hint: 'Reset your password',
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFFFF6B9D)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    enabled: !_isLoading,
                    hint: 'Sign in to your account',
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider with "Or continue with"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Button
                      Semantics(
                        button: true,
                        label: 'Sign in with Google',
                        child: _SocialLoginButton(
                          icon: FontAwesomeIcons.google,
                          onPressed: () => _handleSocialLogin('Google'),
                          backgroundColor: Colors.white,
                          iconColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Facebook Button
                      Semantics(
                        button: true,
                        label: 'Sign in with Facebook',
                        child: _SocialLoginButton(
                          icon: FontAwesomeIcons.facebookF,
                          onPressed: () => _handleSocialLogin('Facebook'),
                          backgroundColor: const Color(0xFF1877F2),
                          iconColor: Colors.white,
                        ),
                      ),

                      // Apple Button (iOS only)
                      if (isIOS) ...[
                        const SizedBox(width: 16),
                        Semantics(
                          button: true,
                          label: 'Sign in with Apple',
                          child: _SocialLoginButton(
                            icon: FontAwesomeIcons.apple,
                            onPressed: () => _handleSocialLogin('Apple'),
                            backgroundColor: Colors.black,
                            iconColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Semantics(
                        button: true,
                        hint: 'Create a new account',
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;

  const _SocialLoginButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

// If you want to replace the TextButtons with ElevatedButtons:
// Replace the "Forgot Password?" TextButton (around line 156-165) with:
/*
ElevatedButton(
  onPressed: () {
    // TODO: Navigate to forgot password
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xFFFF6B9D),
    elevation: 0,
    shadowColor: Colors.transparent,
  ),
  child: const Text('Forgot Password?'),
),
*/

// Replace the "Sign Up" TextButton (around line 206-215) with:
/*
ElevatedButton(
  onPressed: () {
    // TODO: Navigate to sign up
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xFFFF6B9D),
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: EdgeInsets.zero,
  ),
  child: const Text(
    'Sign Up',
    style: TextStyle(
      color: Color(0xFFFF6B9D),
      fontWeight: FontWeight.w600,
    ),
  ),
),
*/
