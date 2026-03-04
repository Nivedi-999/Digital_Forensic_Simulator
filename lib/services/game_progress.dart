// lib/services/game_progress.dart
// ═══════════════════════════════════════════════════════════════
//  GAME PROGRESS — XP, Rank, Title, Unlock State
// ═══════════════════════════════════════════════════════════════

/// Tracks the player's progression across all cases.
///
/// Operation GhostTrace is Case #1 → starting title is 'Beginner'.
/// Winning any case grants +10 XP.
/// Title/rank updates automatically as XP crosses thresholds.
class GameProgress {
  GameProgress._();

  // ── XP ──────────────────────────────────────────────────────
  static int _xp = 0;
  static int get xp => _xp;

  /// Add [amount] XP and return the new total.
  static int addXp(int amount) {
    _xp += amount;
    return _xp;
  }

  /// Reset XP (e.g. for testing).
  static void resetXp() => _xp = 0;

  // ── Cases solved ────────────────────────────────────────────
  static int _casesSolved = 0;
  static int get casesSolved => _casesSolved;

  static void incrementCasesSolved() => _casesSolved++;

  // ── Title & Rank ─────────────────────────────────────────────
  /// The player's current title based on XP.
  ///
  /// Thresholds:
  ///   0–9   XP → Beginner        (Case 1 start)
  ///  10–29  XP → Junior Analyst  (after winning Case 1)
  ///  30–59  XP → Analyst
  ///  60–99  XP → Senior Analyst
  /// 100+    XP → Lead Investigator
  static String get title {
    if (_xp >= 100) return 'Lead Investigator';
    if (_xp >= 60)  return 'Senior Analyst';
    if (_xp >= 30)  return 'Analyst';
    if (_xp >= 10)  return 'Junior Analyst';
    return 'Beginner'; // ← Default for Operation GhostTrace (Case #1)
  }

  /// Alias kept for backward compatibility with existing screens.
  static String get rankName => title;

  /// XP needed to reach the next rank from current XP.
  static int get xpToNextRank {
    if (_xp >= 100) return 0;
    if (_xp >= 60)  return 100 - _xp;
    if (_xp >= 30)  return 60 - _xp;
    if (_xp >= 10)  return 30 - _xp;
    return 10 - _xp;
  }

  /// Next rank name (for display in progress bar label).
  static String get nextRankName {
    if (_xp >= 100) return 'Max Rank';
    if (_xp >= 60)  return 'Lead Investigator';
    if (_xp >= 30)  return 'Senior Analyst';
    if (_xp >= 10)  return 'Analyst';
    return 'Junior Analyst';
  }

  /// XP cap of the current rank band (used for progress bar).
  static int get currentRankCap {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 100;
    if (_xp >= 30)  return 60;
    if (_xp >= 10)  return 30;
    return 10;
  }

  /// XP base of the current rank band (used for progress bar).
  static int get currentRankBase {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 60;
    if (_xp >= 30)  return 30;
    if (_xp >= 10)  return 10;
    return 0;
  }

  /// Progress within the current rank band as 0.0–1.0.
  static double get rankProgress {
    final base = currentRankBase;
    final cap  = currentRankCap;
    if (cap == base) return 1.0;
    return ((_xp - base) / (cap - base)).clamp(0.0, 1.0);
  }

  // ── Unlocks ──────────────────────────────────────────────────
  static bool _briefingUnlocked = false;
  static bool get isBriefingUnlocked => _briefingUnlocked;

  static void unlockBriefing() => _briefingUnlocked = true;

  /// Reset all state (called when returning to home after case ends).
  static void resetForNewCase() {
    _briefingUnlocked = false;
    // XP and cases solved persist across sessions intentionally.
  }
}