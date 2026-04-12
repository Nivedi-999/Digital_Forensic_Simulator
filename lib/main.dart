// lib/main.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — Entry Point (with Firebase Auth)
//
//  Auth flow:
//    • Not logged in  →  SignupScreen  (first-time landing)
//    • Tap "ALREADY ENLISTED? ACCESS PORTAL"  →  LoginScreen
//    • Tap "NEW OPERATIVE? REQUEST ACCESS"     →  SignupScreen
//    • Successful auth  →  MainMenuScreen
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/cyber_theme.dart';
import 'firebase_options.dart';

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

      // Apply the cyber theme
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

      // 🔐 Auth gate:
      //   • Waiting for Firebase  →  loading spinner
      //   • Logged in             →  MainMenuScreen
      //   • Not logged in         →  SignupScreen (first screen new users see)
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

          // Not logged in → show signup screen first.
          // From there the user can tap "ALREADY ENLISTED? ACCESS PORTAL"
          // to navigate to LoginScreen.
          return const SignupScreen();
        },
      ),
    );
  }
}