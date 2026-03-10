// lib/services/game_progress.dart
// ═══════════════════════════════════════════════════════════════
//  GAME PROGRESS — XP, Rank, Title, Unlock State
// ═══════════════════════════════════════════════════════════════

class GameProgress {
  GameProgress._();

  // ── XP ──────────────────────────────────────────────────────
  static int _xp = 0;
  static int get xp => _xp;

  // ── Cases solved ────────────────────────────────────────────
  static int _casesSolved = 0;
  static int get casesSolved => _casesSolved;

  // ── Per-case completion guard ────────────────────────────────
  // Tracks which case IDs have already awarded XP so replaying
  // a case never grants XP a second time.
  static final Set<String> _completedCaseIds = {};

  /// Returns true if XP was awarded (i.e. case not previously completed).
  /// Returns false if the case was already completed — no XP granted.
  static bool completeCaseWithXp(String caseId, int xpAmount) {
    if (_completedCaseIds.contains(caseId)) return false;
    _completedCaseIds.add(caseId);
    _xp += xpAmount;
    _casesSolved++;
    return true;
  }

  /// Whether a case has already been won (used to show "already completed" badge).
  static bool isCaseCompleted(String caseId) =>
      _completedCaseIds.contains(caseId);

  // ── Accuracy ─────────────────────────────────────────────────
  static int _totalFlags = 0;
  static int _correctFlags = 0;

  static void recordFlag({required bool correct}) {
    _totalFlags++;
    if (correct) _correctFlags++;
  }

  static double get accuracy {
    if (_totalFlags == 0) return 0.0;
    return (_correctFlags / _totalFlags) * 100;
  }

  static int get totalFlags => _totalFlags;
  static int get correctFlags => _correctFlags;

  // ── Title & Rank ─────────────────────────────────────────────
  //
  // Rank is driven by BOTH xp AND cases solved so the profile
  // avatar initials and title are always consistent.
  //
  // Thresholds (cases solved takes priority over raw XP):
  //   0 cases  → Beginner         initials: BE
  //   1–3 cases → Analyst Trainee  initials: AT
  //   4+ cases  → Junior Analyst   initials: JA
  //   60+ XP   → Senior Analyst   initials: SA
  //  100+ XP   → Lead Investigator initials: LI

  static String get title {
    if (_xp >= 100) return 'Lead Investigator';
    if (_xp >= 60)  return 'Senior Analyst';
    if (_casesSolved >= 4) return 'Junior Analyst';
    if (_casesSolved >= 1) return 'Analyst Trainee';
    return 'Beginner';
  }

  /// Two-letter initials for the profile avatar, derived from title.
  static String get avatarInitials {
    switch (title) {
      case 'Lead Investigator': return 'LI';
      case 'Senior Analyst':    return 'SA';
      case 'Junior Analyst':    return 'JA';
      case 'Analyst Trainee':   return 'AT';
      default:                  return 'BE'; // Beginner
    }
  }

  static String get rankName => title;

  static int get xpToNextRank {
    if (_xp >= 100) return 0;
    if (_xp >= 60)  return 100 - _xp;
    // Below 60 XP the next meaningful threshold is 60
    return 60 - _xp;
  }

  static String get nextRankName {
    if (_xp >= 100) return 'Max Rank';
    if (_xp >= 60)  return 'Lead Investigator';
    return 'Senior Analyst';
  }

  static int get currentRankCap {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 100;
    return 60;
  }

  static int get currentRankBase {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 60;
    return 0;
  }

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

  // ── Reset (new session / testing) ────────────────────────────
  static void resetForNewCase() {
    _briefingUnlocked = false;
    // XP, cases, accuracy, and completedCaseIds persist across sessions.
  }

  /// Full reset — use only in testing / dev.
  static void resetAll() {
    _xp = 0;
    _casesSolved = 0;
    _totalFlags = 0;
    _correctFlags = 0;
    _completedCaseIds.clear();
    _briefingUnlocked = false;
  }
}