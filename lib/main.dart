import 'package:flutter/material.dart';

// PAGE IMPORTS
import 'package:datatricksai/pages/landing_page.dart';
import 'package:datatricksai/pages/auth_page.dart';
import 'package:datatricksai/pages/careers_page.dart'; // NEW IMPORT

void main() {
  runApp(const DataTricksApp());
}

class DataTricksApp extends StatelessWidget {
  const DataTricksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataTricks AI | The Human Intelligence Layer',
      debugShowCheckedModeBanner: false,
      
      // THEME CONFIGURATION
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020408),
        primaryColor: const Color(0xFF6366F1), // Indigo
        fontFamily: 'Inter',
        useMaterial3: true,
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFEC4899), // Pink
          surface: Color(0xFF0F172A),
          background: Color(0xFF020408),
        ),
        
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 76,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.0,
            height: 1.05,
            color: Colors.white,
          ),
          displayMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Color(0xFF94A3B8), // Slate 400
            height: 1.6,
          ),
        ),
      ),

      // ROUTES
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/auth': (context) => const AuthPage(),
        '/careers': (context) => const CareersPage(), // ADDED ROUTE
      },
    );
  }
}