// lib/main.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — Entry Point (with Firebase Auth)
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'theme/cyber_theme.dart';
import 'firebase_options.dart';
import 'Auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so background shows through
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CyberColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CyberInvestigatorApp());
}

class CyberInvestigatorApp extends StatelessWidget {
  const CyberInvestigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyber Investigator',

      // Apply the new cyber theme
      theme: buildCyberTheme(),

      // Smooth page transitions globally
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => const MainMenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        );
      },

      // 🔐 Auth gate — shows login screen if not logged in,
      // game home screen if already logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still connecting to Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF05070D),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F0FF),
                ),
              ),
            );
          }

          // User is logged in → go to game
          if (snapshot.hasData) {
            return const MainMenuScreen();
          }

          // Not logged in → show auth screen
          return const AuthScreen();
        },
      ),
    );
  }
}