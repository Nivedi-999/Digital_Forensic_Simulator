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
import 'services/progress_service.dart';
import 'services/game_progress.dart';

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
          if (snapshot.hasData){
            ProgressService.instance.init().then((_) {
              GameProgress.loadFromStats(
                ProgressService.instance.stats,
                ProgressService.instance.completedCaseIds,
              );
            });
            return const MainMenuScreen();
          } return const SignupScreen();
        },
      ),
    );
  }
}
//You are working on a Flutter mobile game called Cyber Investigator.
// It is a detective/forensics game where players investigate cybercrime
// cases by collecting evidence, solving mini-games, and accusing suspects.
//
// Below are the specific code bugs that need to be fixed. Fix all of them
// carefully without breaking existing functionality. After each fix, add a
// short comment explaining what was changed and why.
//
// Here are the files you will need to work with:
// - lib/screens/mini_game.dart (primary file for all fixes)
// - Check if any other files might need changes after the fixes in mini_game.dart file
//
// ---
//
// BUG 1 — Dead Code Removal
// In `_DecryptionMiniGameScreenState`, there is a method called
// `buildAriaLayer` that returns `const SizedBox.shrink()`. This is dead
// code from a deleted feature. Remove this method entirely.
//
// ---
//
// BUG 2 — Free Unlock Exploit in _UnsupportedMiniGame
// The `_UnsupportedMiniGame` widget has a "Complete Challenge" button that
// calls `engine.solveMinigame()` without requiring any actual player input.
// This means any unimplemented mini-game type gives a free evidence unlock.
//
// Fix: Replace the "Complete Challenge" button with a locked state UI that
// shows a message like "This challenge is not yet available" and does NOT
// call solveMinigame(). The hint button should still work. Do not remove the
// widget entirely as it serves as a fallback renderer.
//
// ---
//
// BUG 3 — Caesar Cipher Drag Desync
// In `_CaesarCipherGameState`, the methods `_onWheelDragStart` and
// `_onWheelDragUpdate` use `_dragStartAngle` captured at pan start. Rapid
// swipes cause the visual wheel to show a different shift than the actual
// `_shift` state variable because the angle delta accumulates floating point
// error across multiple drag events.
//
// Fix: On each `_onWheelDragUpdate` call, clamp the computed `steps` to a
// maximum of ±1 per frame to prevent large jumps. Also add a minimum
// distance threshold (at least 8 pixels of drag delta magnitude) before
// registering a shift change.
//
// ---
//
// BUG 4 — Code Crack Unsolvable When Solution Is Empty
// In `_CodeCrackGameState`, the `_reelCount` getter returns
// `solution.length.clamp(1, 6)`. When `mg.solution` is null or empty,
// `_reelCount` becomes 1 (minimum clamp) but the solution string remains
// empty, making the game impossible to solve because no combination of reels
// can match an empty string.
//
// Fix: Add a guard in the `build` method of `_CodeCrackGame`. If
// `mg.solution` is null or empty after trim, render the `_UnsupportedMiniGame`
// fallback widget instead of the slot machine UI. Add a debug print statement
// logging which case/panel has an empty solution so developers can fix the
// JSON.
//
// ---
//
// BUG 5 — IP Trace Timer Leak on Dispose
// In `_IpTraceGameState`, `_startTimer()` is called from `initState` and
// creates a `Timer.periodic`. The timer closure checks `if (!mounted)`
// before calling setState, but the closure captures `this` and can still
// fire once after `dispose()` is called because `mounted` becomes false only
// after the frame following dispose.
//
// Fix: Store the timer in `_timer` (already done) and in `dispose()`, call
// `_timer?.cancel()` BEFORE calling `super.dispose()`. Also add a null check
// guard at the top of the timer callback: `if (!mounted) { t.cancel();
// return; }` — this pattern is already partially there but make sure it is
// the very first line of the callback before any setState call.
//
// ---
//
// BUG 6 — Metadata Correlation Ghost State on Reset
// In `_MetadataCorrelationGameState`, the `_reset()` method sets
// `_submitted = false` and calls setState, but it only iterates over
// `widget.minigame.fragments` to reset `_selections` and `_revealed`. If
// the fragments list has changed between builds (hot reload or engine
// update), old keys remain in both maps causing ghost state where previously
// selected values reappear.
//
// Fix: In `_reset()`, call `_selections.clear()` and `_revealed.clear()`
// BEFORE repopulating them from `mg.fragments`. Also call these clears in
// `initState` before the loop to ensure a clean slate on first build.
//
// ---
//
// BUG 7 — Alibi Verify setState After Dispose
// In `_AlibiVerifyGameState`, when a wrong answer is selected, a
// `Future.delayed(Duration(seconds: 2))` fires and calls setState to reset
// the selection. If the user navigates away during those 2 seconds, the
// widget is disposed but setState is still called, throwing a
// "setState called after dispose" error.
//
// Fix: Store a boolean `_isDisposed = false` flag. In `dispose()`, set
// `_isDisposed = true` before calling `super.dispose()`. In the
// `Future.delayed` callback, check `if (!mounted || _isDisposed) return;`
// before calling setState.
//
// ---
//
// BUG 8 — Phishing Game Animation After Dispose
// In `_PhishingGameState._openEmail()`, there is an async loop:
// ```dart
// for (int i = 0; i < _flagVisible.length; i++) {
//   await Future.delayed(const Duration(milliseconds: 300));
//   if (mounted) {
//     setState(() => _flagVisible[i] = true);
//     _flagCtrls[i].forward();
//   }
// }
// ```
// The `mounted` check happens AFTER the await, but `_flagCtrls[i].forward()`
// is called outside the mounted guard. If the widget disposes during the
// delay, `_flagCtrls[i]` has already been disposed and calling `.forward()`
// throws an error.
//
// Fix: Move `_flagCtrls[i].forward()` INSIDE the `if (mounted)` block. Also
// add a `return` statement after the mounted check fails so the loop exits
// early rather than continuing to await and check remaining flags.
//
// ---
//
// BUG 9 — IP Trace Invalid correctIndex When Solution Not In Decoys
// In `_IpTraceGameState.initState()`:
// ```dart
// _ipList = List<String>.from(mg.decoys);
// if (!_ipList.contains(mg.solution)) _ipList.add(mg.solution ?? '');
// _ipList.shuffle();
// _correctIndex = _ipList.indexWhere((ip) => ip == mg.solution);
// ```
// If `mg.solution` is null, `mg.solution ?? ''` adds an empty string to
// the list, and `_correctIndex` finds the empty string at some index. The
// graph painter and node tap logic then treat the empty string node as the
// correct answer, which is never selectable by the player since it renders
// as a blank label.
//
// Fix: Add a null/empty guard at the top of `initState`. If
// `mg.solution == null || mg.solution!.trim().isEmpty`, set a flag
// `_invalidConfig = true` and return early from initState. In the `build`
// method, if `_invalidConfig` is true, render an error state widget instead
// of the game. Log a debug warning identifying the panel and case.
//
// ---
//
// BUG 10 — Caesar Cipher Invalid Character Index
// In `_CaesarCipherGameState._decode()`:
// ```dart
// final idx = (_alpha.indexOf(upper) - shift + 26) % 26;
// ```
// If `upper` is not in `_alpha` (digits, punctuation, spaces — which can
// appear in cipher text), `_alpha.indexOf(upper)` returns -1. The
// calculation then becomes `(-1 - shift + 26) % 26` which is a valid but
// WRONG index, producing garbled output instead of passing the character
// through unchanged.
//
// Fix: The existing code has `if (_alpha.contains(upper))` guard which
// should catch this, but verify the full decode method reads:
// ```dart
// String _decode(String cipher, int shift) {
//   return cipher.split('').map((c) {
//     if (c == ' ') return ' ';
//     final upper = c.toUpperCase();
//     if (!_alpha.contains(upper)) return c; // pass through unchanged
//     final idx = (_alpha.indexOf(upper) - shift + 26) % 26;
//     return c == c.toUpperCase() ? _alpha[idx] : _alpha[idx].toLowerCase();
//   }).join();
// }
// ```
// Make sure this exact guard order is in place. If it already is, add a
// unit test comment showing the expected behavior for '!', '1', and ' '
// characters.
//
// ---
//
// After fixing all 10 bugs, do a final pass and ensure:
// - No new imports are needed (all fixes use existing Flutter/Dart APIs)
// - The `_UnsupportedMiniGame` widget is kept but made non-exploitable
// - All timer/async resources are properly cancelled in their respective
//   dispose() methods
// - No existing mini-game functionality (caesar, ip_trace, code_crack,
//   phishing, metadata_correlation, alibi_verify, base64_decode) is broken