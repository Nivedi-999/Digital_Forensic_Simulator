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
  static final Set<String> _completedCaseIds = {};

  /// Returns the XP actually awarded (after penalties), or 0 if already completed.
  static int completeCaseWithXp(String caseId, int baseXp) {
    if (_completedCaseIds.contains(caseId)) return 0;
    _completedCaseIds.add(caseId);
    final awarded = baseXp.clamp(0, 999);
    _xp += awarded;
    _casesSolved++;
    return awarded;
  }

  static bool isCaseCompleted(String caseId) =>
      _completedCaseIds.contains(caseId);

  // ── Case unlock logic ────────────────────────────────────────
  //
  // A case is playable if:
  //   (a) it is the FIRST case in its difficulty tier, OR
  //   (b) the case immediately before it in the same tier is completed.
  //
  // The ordered list per tier is supplied by CaseRepository so
  // GameProgress stays decoupled from asset paths.

  static bool isCaseUnlocked(String caseId, List<String> orderedTierIds) {
    if (orderedTierIds.isEmpty) return false;
    // First case in tier is always unlocked
    if (orderedTierIds.first == caseId) return true;
    final idx = orderedTierIds.indexOf(caseId);
    if (idx <= 0) return false;
    // Unlocked if the previous case in the same tier is completed
    return _completedCaseIds.contains(orderedTierIds[idx - 1]);
  }

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
  static String get title {
    if (_xp >= 100) return 'Lead Investigator';
    if (_xp >= 60)  return 'Senior Analyst';
    if (_casesSolved >= 4) return 'Junior Analyst';
    if (_casesSolved >= 1) return 'Analyst Trainee';
    return 'Beginner';
  }

  static String get avatarInitials {
    switch (title) {
      case 'Lead Investigator': return 'LI';
      case 'Senior Analyst':    return 'SA';
      case 'Junior Analyst':    return 'JA';
      case 'Analyst Trainee':   return 'AT';
      default:                  return 'BE';
    }
  }

  static String get rankName => title;

  static int get xpToNextRank {
    if (_xp >= 100) return 0;
    if (_xp >= 60)  return 100 - _xp;
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

  // ── Reset ────────────────────────────────────────────────────
  static void resetForNewCase() {
    _briefingUnlocked = false;
  }

  static void resetAll() {
    _xp = 0;
    _casesSolved = 0;
    _totalFlags = 0;
    _correctFlags = 0;
    _completedCaseIds.clear();
    _briefingUnlocked = false;
  }
}