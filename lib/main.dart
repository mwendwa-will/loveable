import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovely/screens/welcome_screen.dart';
import 'package:lovely/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lovely',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F61), // Coral Sunset
          primary: const Color(0xFFFF6F61), // Vibrant Coral
          secondary: const Color(0xFFFF8F7A), // Soft Coral
          tertiary: const Color(0xFFFFB3A0), // Peachy Pink
          surface: const Color(0xFFFFE5D4), // Very Light Peach
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFE5D4),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFFFFE5D4),
          foregroundColor: Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8F7A), // Coral for dark mode
          primary: const Color(0xFFFF8F7A), // Soft Coral
          secondary: const Color(0xFFFFB3A0), // Peachy Pink
          tertiary: const Color(0xFFFFCCB6), // Light Peach
          surface: const Color(0xFF1E1E1E), // Dark Surface
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF121212),
          foregroundColor: Color(0xFFE1E1E1),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const WelcomeScreen(),
    );
  }
}

