import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/screens/auth/login.dart';
import 'package:lunara/screens/onboarding/onboarding_screen.dart';
import 'package:lunara/navigation/app_router.dart';
import 'package:lunara/providers/period_provider.dart';
import 'package:lunara/services/auth_service.dart';
import 'package:lunara/services/profile_service.dart';
import 'package:lunara/core/feedback/feedback_service.dart';
import 'package:lunara/core/exceptions/app_exceptions.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = true;
  String? _usernameError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
        _usernameAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      // Debounce: wait 500ms before checking
      await Future.delayed(const Duration(milliseconds: 500));

      final supabase = ref.read(supabaseServiceProvider);
      final available = await supabase.isUsernameAvailable(username);

      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _usernameError = available ? null : 'Username already taken';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameError = 'Could not verify username';
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null; // Clear previous errors
        _isLoading = true;
      });

      try {
        final auth = AuthService();
        
        debugPrint('Attempting signup...');
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

        debugPrint('Signup response received');
        debugPrint('User: ${response.user?.email}');
        debugPrint('Session: ${response.session?.accessToken != null ? 'Created' : 'Not created'}');

        if (response.user != null && mounted) {
          // Wait a moment for auth state to stabilize
          await Future.delayed(const Duration(milliseconds: 500));
          
          debugPrint('Checking auth state after signup...');
          final currentUser = auth.currentUser;
          final currentSession = auth.currentSession;
          
          debugPrint('Current user: ${currentUser?.email}');
          debugPrint('Current session: ${currentSession != null ? 'Valid' : 'None'}');
          
          if (mounted) {
            // Navigate to onboarding after successful signup
            Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
          }
        } else {
          throw AuthException('Signup failed: No user returned', code: 'AUTH_007');
        }
      } catch (e) {
        debugPrint('Signup error: $e');
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
    if (mounted) {
      FeedbackService.showInfo(context, '$provider login coming soon');
    }
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
                  const SizedBox(height: 32),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

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

                  // First Name Field
                  Semantics(
                    label: 'First name input field',
                    textField: true,
                    child: TextFormField(
                      controller: _firstNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        hintText: 'Enter your first name',
                        prefixIcon: const Icon(FontAwesomeIcons.user, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  Semantics(
                    label: 'Last name input field',
                    textField: true,
                    child: TextFormField(
                      controller: _lastNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Enter your last name (optional)',
                        prefixIcon: const Icon(FontAwesomeIcons.user, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  Semantics(
                    label: 'Username input field',
                    textField: true,
                    child: TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Username *',
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
                            : _usernameController.text.length >= 3
                                ? Icon(
                                    _usernameAvailable
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _usernameAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
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
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  Semantics(
                    label: 'Email address input field',
                    textField: true,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
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
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Semantics(
                    label: 'Confirm password input field',
                    textField: true,
                    obscured: !_isConfirmPasswordVisible,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(FontAwesomeIcons.lock, size: 20),
                        suffixIcon: Semantics(
                          label: _isConfirmPasswordVisible
                              ? 'Hide password'
                              : 'Show password',
                          button: true,
                          child: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
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
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  Semantics(
                    button: true,
                    enabled: !_isLoading,
                    hint: 'Create your account',
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
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
                              'Sign Up',
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
                        label: 'Sign up with Google',
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
                        label: 'Sign up with Facebook',
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
                          label: 'Sign up with Apple',
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

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Semantics(
                        button: true,
                        hint: 'Navigate to sign in',
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign In',
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
