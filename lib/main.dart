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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      theme: buildCyberTheme(),
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => const MainMenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF05070D),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
              ),
            );
          }
          if (snapshot.hasData) return const MainMenuScreen();
          return const SignupScreen();
        },
      ),
    );
  }
}