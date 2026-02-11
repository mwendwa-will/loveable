// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/screens/auth/auth_gate.dart';
import 'package:lunara/screens/security/pin_unlock_screen.dart';
import 'package:lunara/services/auth_service.dart';
import 'package:lunara/services/notification_service.dart';
import 'package:lunara/services/pin_service.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:lunara/providers/pin_lock_provider.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'firebase_options.dart';
import 'package:lunara/services/supabase_service.dart';
import 'package:lunara/navigation/app_router.dart';
import 'package:lunara/core/feedback/feedback_service.dart';
import 'package:app_links/app_links.dart';
import 'package:lunara/providers/entitlements.dart';

void main() {
  // Run the app inside a guarded zone. Ensure bindings and runApp occur
  // within the same zone to avoid zone-mismatch warnings.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Launch asynchronous bootstrap inside the zone. We intentionally do not
      // await here so the zone encloses all callbacks created during init.
      _bootstrapAndRunApp();
    },
    (error, stack) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        try {
          FeedbackService.showError(ctx, error);
        } catch (_) {}
      }
    },
  );
}

Future<void> _bootstrapAndRunApp() async {
  debugPrint('App starting...');

  // Initialize Firebase
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Warning: Firebase initialization warning: $e');
  }

  // Initialize Notifications (Awesome + FCM)
  try {
    debugPrint('Initializing Notification Service...');
    await NotificationService().initialize();
    debugPrint('Notification Service initialized');
  } catch (e) {
    debugPrint('Warning: Notification Service initialization warning: $e');
  }

  // Initialize Supabase with timeout
  try {
    debugPrint('Initializing Supabase (10s timeout)...');

    try {
      await SupabaseService.initialize().timeout(const Duration(seconds: 10));
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      if (e is Exception && e.toString().contains('timeout')) {
        debugPrint('Supabase initialization timed out - continuing without it');
      } else {
        rethrow;
      }
    }
  } catch (e, stack) {
    debugPrint('Error during Supabase init: $e');
    debugPrint('Stack: $stack');
  }

  // Initialize SubscriptionService (RevenueCat)
  try {
    debugPrint('Initializing SubscriptionService...');
    await SubscriptionService().initialize();
    debugPrint('SubscriptionService initialized');
  } catch (e) {
    debugPrint('Warning: SubscriptionService initialization failed: $e');
  }

  debugPrint('Launching app...');
  // Centralize uncaught errors and forward to `FeedbackService` where possible.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      try {
        FeedbackService.showError(ctx, details.exception);
      } catch (_) {}
    }
  };

  runApp(const ProviderScope(child: LovelyApp()));
}

// Global navigation key for auth redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LovelyApp extends ConsumerStatefulWidget {
  const LovelyApp({super.key});

  @override
  ConsumerState<LovelyApp> createState() => _LovelyAppState();
}

class _LovelyAppState extends ConsumerState<LovelyApp>
    with WidgetsBindingObserver {
  late Future<void> _pinCheckFuture;
  bool _pinEnabled = false;
  bool _pinUnlocked = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkListener();
    WidgetsBinding.instance.addObserver(this);

    // If running under `flutter test`, skip PIN/platform-channel checks which
    // cause MissingPluginException in the test environment.
    final bool isRunningTests = Platform.environment['FLUTTER_TEST'] == 'true';

    if (isRunningTests) {
      // Short-circuit PIN flow during tests to avoid plugin calls
      _pinEnabled = false;
      _pinUnlocked = true;
      _pinCheckFuture = Future<void>.value();
      debugPrint('Running in test mode: skipping PIN checks');
    } else {
      // Check PIN after first frame (gives Android time to initialize)
      _pinCheckFuture = Future.delayed(const Duration(milliseconds: 100)).then((
        _,
      ) async {
        if (!mounted) return;

        try {
          final pinService = PinService();
          final isEnabled = await pinService.isPinEnabled();
          debugPrint('PIN enabled check: $isEnabled');
          if (mounted) {
            setState(() {
              _pinEnabled = isEnabled;
              if (isEnabled) {
                pinService.saveLockTimestamp();
                debugPrint('PIN check complete - PIN enabled');
              } else {
                _pinUnlocked = true; // No PIN, proceed immediately
                debugPrint('PIN check complete - PIN disabled');
              }
            });
          }
        } catch (e, stack) {
          debugPrint('Warning: PIN check error: $e');
          debugPrint('Stack: $stack');
          if (mounted) {
            setState(() => _pinEnabled = false);
          }
        }
      });
    }
  }

  StreamSubscription<Uri?>? _linkSub;
  final AppLinks _appLinks = AppLinks();

  void _setupDeepLinkListener() {
    // Subscribe to initial link and subsequent links via AppLinks
    _linkSub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) _handleIncomingUri(uri.toString());
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleIncomingUri(String link) {
    debugPrint('Incoming deep link: $link');
    try {
      final uri = Uri.parse(link);

      // Handle Purchase/Payment Success
      if (uri.scheme == 'lovely' &&
          (uri.host == 'success' || uri.path.contains('success'))) {
        // Refresh entitlements when returning from website checkout
        ref.read(entitlementsProvider.notifier).refresh();

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Purchase restored — premium unlocked if active'),
            ),
          );
        }
      }
      // Handle Social Auth Redirect
      else if (uri.scheme == 'io.supabase.lovely' &&
          uri.host == 'login-callback') {
        debugPrint(
          'Social login deep link captured - Supabase will handle the session',
        );
      }
    } catch (e) {
      debugPrint('Failed to handle deep link: $e');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final pinState = ref.read(pinLockProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background - lock it
      if (pinState.isEnabled) {
        ref.read(pinLockProvider.notifier).lock();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Refresh subscription state when app resumes
      _refreshSubscriptionState();
      
      // App returned to foreground - check timeout first
      if (pinState.isLocked && pinState.isEnabled) {
        _checkTimeoutAndShowPinOrLogout();
      }
    }
  }

  void _refreshSubscriptionState() {
    try {
      // Refresh subscription provider to check for changes
      ref.invalidate(subscriptionProvider);
      debugPrint('Subscription state refreshed on app resume');
    } catch (e) {
      debugPrint('Warning: Failed to refresh subscription state: $e');
    }
  }

  void _checkTimeoutAndShowPinOrLogout() async {
    final shouldLogout = await ref
        .read(pinLockProvider.notifier)
        .shouldLogoutDueToTimeout();

    if (shouldLogout) {
      // Timeout exceeded - logout user
      _handleTimeoutLogout();
    } else {
      // Timeout not exceeded - show PIN unlock
      _showPinUnlock();
    }
  }

  void _handleTimeoutLogout() {
    Future.delayed(Duration.zero, () async {
      final ctx = navigatorKey.currentContext;
      if (mounted && ctx != null) {
        // Show message to user
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
              'For your security, you have been logged out due to inactivity',
            ),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Logout user
        await AuthService().signOut();

        // Clear PIN lock state
        await ref.read(pinLockProvider.notifier).refresh();
      }
    });
  }

  void _showPinUnlock() {
    Future.delayed(Duration.zero, () {
      final ctx = navigatorKey.currentContext;
      if (mounted && ctx != null) {
        Navigator.of(ctx).pushNamed(
          AppRoutes.pinUnlock,
          arguments: {
            'onUnlocked': () async {
              await ref.read(pinLockProvider.notifier).unlock();
              if (!mounted) return;
              final ctx2 = navigatorKey.currentContext;
              if (ctx2 != null) {
                Navigator.of(ctx2).pop(true);
              }
            },
          },
        );
      }
    });
  }

  void _setupAuthListener() {
    // Listen for auth state changes (including email verification)
    SupabaseService().client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      debugPrint('Auth event: $event');

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        debugPrint('User signed in - email verified');
        // Initialize subscription for this user
        try {
          await SubscriptionService().login(session!.user.id);
          debugPrint('SubscriptionService logged in for user: ${session.user.id}');
        } catch (e) {
          debugPrint('Warning: SubscriptionService login failed: $e');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('User signed out');
        // Clean up subscription state
        try {
          await SubscriptionService().logout();
          debugPrint('SubscriptionService logged out');
        } catch (e) {
          debugPrint('Warning: SubscriptionService logout failed: $e');
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('Token refreshed');
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Define seed color - Primary brand color
    const seedColor = AppColors.primary; // Coral Sunset

    // Generate light and dark color schemes from seed
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      title: 'Lovely',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: lightColorScheme.surface,
          foregroundColor: AppColors.lightAppBarForeground,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: Color(0xFF1A1A1A), // Lighter than #121212
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Color(0xFF242424), // Lighter than #1E1E1E
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: AppColors.darkAppBarForeground,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Restored to system
      navigatorKey: navigatorKey,
      home: FutureBuilder<void>(
        future: _pinCheckFuture,
        builder: (context, snapshot) {
          // While checking PIN, show loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          // PIN check complete
          // If PIN enabled and not yet unlocked, show PIN screen
          if (_pinEnabled && !_pinUnlocked) {
            debugPrint('Showing PIN unlock screen (initial)');
            return PinUnlockScreen(
              onUnlocked: () {
                debugPrint('PIN unlocked via callback');
                if (mounted) {
                  setState(() {
                    _pinUnlocked = true;
                    debugPrint('PIN state updated: _pinUnlocked = true');
                  });
                }
              },
            );
          }

          // PIN unlocked or not enabled, show main app
          debugPrint('Showing AuthGate');
          return const AuthGate();
        },
      ),
    );
  }
}
