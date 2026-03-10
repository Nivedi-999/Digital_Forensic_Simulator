// lib/state/active_case.dart
// ═══════════════════════════════════════════════════════════════
//  ActiveCase — a simple singleton that holds the currently-running
//  CaseEngine so any screen can reach it regardless of widget tree.
//
//  WHY: The CaseEngineProvider (InheritedWidget) only covers the
//  subtree that was wrapped in case_story_screen.dart.  When
//  AppShell's bottom-nav pushes EvidencesCollectedScreen or
//  ProfileScreen as brand-new routes those routes land OUTSIDE
//  the InheritedWidget subtree → "CaseEngineProvider.of() called
//  with no CaseEngineProvider in tree" crash.
//
//  This singleton solves it cleanly without rewriting navigation:
//    • case_story_screen sets ActiveCase.engine when the player starts
//    • Every screen calls ActiveCase.engine instead of
//      CaseEngineProvider.of(context)
//    • CaseEngineProvider is kept for reactive rebuilds where needed
// ═══════════════════════════════════════════════════════════════

import '../logic/game_engine.dart';

class ActiveCase {
  ActiveCase._();

  static CaseEngine? _engine;

  /// Set when the player launches an investigation.
  static void set(CaseEngine engine) => _engine = engine;

  /// Clear when the player returns to the main menu.
  static void clear() => _engine = null;

  /// The active engine. Throws if called before a case is started.
  static CaseEngine get engine {
    assert(_engine != null,
    'ActiveCase.engine accessed before a case was started.');
    return _engine!;
  }

  /// True while a case is in progress.
  static bool get isActive => _engine != null;
}