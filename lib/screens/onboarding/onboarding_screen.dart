import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lovely/services/auth_service.dart';
import 'package:lovely/services/profile_service.dart';
import 'package:lovely/services/period_service.dart';
import 'package:lovely/services/cycle_analyzer.dart';
import 'package:lovely/navigation/app_router.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/core/feedback/feedback_service.dart';
import 'package:lovely/core/exceptions/app_exceptions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Form controllers
  DateTime? _dateOfBirth;
  int _averageCycleLength = 28;
  int _averagePeriodLength = 5;
  DateTime? _lastPeriodStart;
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();

      debugPrint('Loading user data...');

      // Wait a bit for auth state to settle
      await Future.delayed(const Duration(milliseconds: 100));

      var user = authService.currentUser;

      if (user != null) {
        debugPrint('User loaded: ${user.email}');
        debugPrint(
          'Session: ${authService.currentSession != null ? 'Valid' : 'None'}',
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        // If still no user, retry once with session refresh
        debugPrint('No user found, retrying with session refresh...');
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          await authService.refreshSession();
        } catch (e) {
          debugPrint('Warning: Session refresh failed: $e');
        }

        user = authService.currentUser;
        if (user != null) {
          debugPrint('User loaded after refresh: ${user.email}');
        } else {
          debugPrint('Still no user after refresh');
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  void _nextPage() {
    // Validate current page before proceeding
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  bool _validateCurrentPage() {
    String? errorMessage;

    switch (_currentPage) {
      case 0: // Profile page - no required fields
        return true;

      case 1: // Cycle info page - validate cycle lengths
        if (_averageCycleLength < 21 || _averageCycleLength > 35) {
          errorMessage = 'Please keep cycle length between 21 and 35 days.';
        } else if (_averagePeriodLength < 2 || _averagePeriodLength > 10) {
          errorMessage = 'Period length works best between 2 and 10 days.';
        }
        break;

      case 2: // Last period page - require date
        if (_lastPeriodStart == null) {
          errorMessage = 'Please provide your last period date to get started.';
        }
        break;

      case 3: // Notifications page - no required fields
        return true;
    }

    if (errorMessage != null) {
      FeedbackService.showWarning(context, errorMessage);
      return false;
    }

    return true;
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      setState(() => _isLoading = true);
      final authService = AuthService();
      final profileService = ProfileService();
      final periodService = PeriodService();

      // Get current user with retry logic
      var user = authService.currentUser;

      // If no user, try refreshing session
      if (user == null) {
        debugPrint('No current user, attempting session refresh...');
        try {
          await authService.refreshSession();
          user = authService.currentUser;
          debugPrint('Session refreshed, user: ${user?.email}');
        } catch (e) {
          debugPrint('Session refresh failed: $e');
        }
      }

      // If still no user, fail
      if (user == null) {
        debugPrint('No authenticated user found after refresh');
        throw AuthException.sessionExpired();
      }

      debugPrint('User found: ${user.email}');

      // Get username and names from metadata
      var username = user.userMetadata?['username'] as String?;
      var firstName = user.userMetadata?['first_name'] as String?;
      var lastName = user.userMetadata?['last_name'] as String?;

      debugPrint('Username from metadata: $username');
      debugPrint('First name from metadata: $firstName');
      debugPrint('Last name from metadata: $lastName');

      // If username not in metadata, try to get it from the database
      if (username == null || username.isEmpty) {
        debugPrint('Username not in metadata, querying database...');
        final userData = await profileService.getUserData();
        username = userData?['username'] as String?;
        firstName ??= userData?['first_name'] as String?;
        lastName ??= userData?['last_name'] as String?;
        debugPrint('Username from database: $username');
      }

      // Username is required
      if (username == null || username.isEmpty) {
        throw AuthException(
          'Username not found. Please sign up again.',
          code: 'AUTH_009',
        );
      }

      debugPrint('Saving onboarding data for user: $username');

      // Save user data to Supabase
      await profileService.saveUserData(
        username: username,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _dateOfBirth,
        averageCycleLength: _averageCycleLength,
        averagePeriodLength: _averagePeriodLength,
        lastPeriodStart: _lastPeriodStart,
        notificationsEnabled: _notificationsEnabled,
      );

      debugPrint('Onboarding data saved successfully');

      // If last period start is recent (within average period length), create an active period record
      if (_lastPeriodStart != null) {
        final daysSinceStart = DateTime.now()
            .difference(_lastPeriodStart!)
            .inDays;
        // Use user's average period length instead of hardcoded 7 days
        if (daysSinceStart <= _averagePeriodLength) {
          try {
            debugPrint(
              'Last period is recent ($daysSinceStart days ago, threshold: $_averagePeriodLength days), creating active period record...',
            );
            // Start with light intensity by default, user can update in DailyLogScreen
            await periodService.startPeriod(
              startDate: _lastPeriodStart!,
              intensity: FlowIntensity.light,
            );
            debugPrint('Active period record created');
          } catch (e) {
            debugPrint('Warning: Error creating period record: $e');
            // Don't block navigation if this fails
          }
        }
      }

      // Generate initial predictions (Instance 3: First Forecast)
      try {
        final userId = authService.currentUser?.id;
        if (userId != null) {
          await CycleAnalyzer.generateInitialPredictions(userId);
          debugPrint('Initial predictions generated');
        }
      } catch (e) {
        debugPrint('Warning: Error generating predictions: $e');
        // Don't block navigation if prediction fails
      }

      if (mounted) {
        // Navigate to home screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        FeedbackService.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(
                  _totalPages,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < _totalPages - 1 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfilePage(),
                  _buildCycleInfoPage(),
                  _buildLastPeriodPage(),
                  _buildNotificationsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? 'Let\'s Go!' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.heart,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Welcome to Lovely!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            "Let's personalize your wellness journey",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Text(
            "We're here to support your cycle tracking, mood patterns, and overall wellness.\n\nYou can update everything anytime in Settings - this is just the beginning!",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCycleInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.chartLine,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Cycle Information',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Let\'s learn about your cycle',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Average cycle length
          Text(
            'Average Cycle Length',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (_averageCycleLength > 21) {
                      setState(() => _averageCycleLength--);
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.minus, size: 20),
                ),
                Text(
                  '$_averageCycleLength days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_averageCycleLength < 35) {
                      setState(() => _averageCycleLength++);
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Average period length
          Text(
            'Average Period Length',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (_averagePeriodLength > 3) {
                      setState(() => _averagePeriodLength--);
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.minus, size: 20),
                ),
                Text(
                  '$_averagePeriodLength days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_averagePeriodLength < 7) {
                      setState(() => _averagePeriodLength++);
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPeriodPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.calendarCheck,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Last Period Start Date',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'When did your last period begin? *',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            '* Required',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _lastPeriodStart = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _lastPeriodStart != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 48,
                    color: _lastPeriodStart != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _lastPeriodStart != null
                        ? DateFormat('MMMM dd, yyyy').format(_lastPeriodStart!)
                        : 'Select Date',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _lastPeriodStart != null ? null : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This helps us predict your cycle and give you personalized insights',
                    style: TextStyle(color: Colors.blue[900], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.bell,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Stay on Track',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Get gentle reminders for your wellness journey',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders and updates'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationItem(
                  FontAwesomeIcons.heartPulse,
                  'Period Predictions',
                  'Get notified before your period starts',
                ),
                /*
                const Divider(height: 32),
                _buildNotificationItem(
                  FontAwesomeIcons.listCheck,
                  'Task Reminders',
                  'Stay on top of your daily wellness tasks',
                ),
                const Divider(height: 32),
                _buildNotificationItem(
                  FontAwesomeIcons.comment,
                  'Daily Affirmations',
                  'Receive uplifting messages each day',
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        FaIcon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
