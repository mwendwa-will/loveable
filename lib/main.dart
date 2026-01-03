import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/screens/auth/auth_gate.dart';
import 'package:lovely/screens/security/pin_unlock_screen.dart';
import 'package:lovely/services/supabase_service.dart';
import 'package:lovely/services/notification_service.dart';
import 'package:lovely/providers/pin_lock_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('📱 App starting...');

  // Initialize Firebase
  try {
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization warning: $e');
  }

  // Initialize Notifications (Awesome + FCM)
  try {
    debugPrint('🔔 Initializing Notification Service...');
    await NotificationService().initialize();
    debugPrint('✅ Notification Service initialized');
  } catch (e) {
    debugPrint('⚠️ Notification Service initialization warning: $e');
  }

  // Initialize Supabase with timeout
  try {
    debugPrint('🚀 Initializing Supabase (10s timeout)...');
    
    // Set 10 second timeout for Supabase init
    try {
      await SupabaseService.initialize().timeout(
        const Duration(seconds: 10),
      );
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      if (e is Exception && e.toString().contains('timeout')) {
        debugPrint('⏱️ Supabase initialization timed out - continuing without it');
      } else {
        rethrow;
      }
    }
  } catch (e, stack) {
    debugPrint('❌ Error during Supabase init: $e');
    debugPrint('Stack: $stack');
  }

  debugPrint('🎨 Launching app...');
  runApp(const ProviderScope(child: LovelyApp()));
}

// Global navigation key for auth redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LovelyApp extends ConsumerStatefulWidget {
  const LovelyApp({super.key});

  @override
  ConsumerState<LovelyApp> createState() => _LovelyAppState();
}

class _LovelyAppState extends ConsumerState<LovelyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final pinState = ref.read(pinLockProvider);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - lock it
      if (pinState.isEnabled) {
        ref.read(pinLockProvider.notifier).lock();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground - check timeout first
      if (pinState.isLocked && pinState.isEnabled) {
        _checkTimeoutAndShowPinOrLogout();
      }
    }
  }

  void _checkTimeoutAndShowPinOrLogout() async {
    final shouldLogout = await ref.read(pinLockProvider.notifier).shouldLogoutDueToTimeout();
    
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
      if (mounted && navigatorKey.currentContext != null) {
        // Show message to user
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('For your security, you have been logged out due to inactivity'),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Logout user
        await SupabaseService().signOut();
        
        // Clear PIN lock state
        await ref.read(pinLockProvider.notifier).refresh();
      }
    });
  }

  void _showPinUnlock() {
    Future.delayed(Duration.zero, () {
      if (mounted && navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => const PinUnlockScreen(),
            fullscreenDialog: true,
          ),
        ).then((unlocked) {
          if (unlocked == true) {
            ref.read(pinLockProvider.notifier).unlock();
          }
        });
      }
    });
  }

  void _setupAuthListener() {
    // Listen for auth state changes (including email verification)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('🔐 Auth event: $event');

      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in - email verified');
        // User has verified their email and signed in
        // AuthGate will automatically handle navigation
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token refreshed');
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
      home: const AuthGate(),
    );
  }
}
