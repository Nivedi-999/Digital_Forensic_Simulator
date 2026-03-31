// lib/services/game_progress.dart
class GameProgress {
  GameProgress._();

  static int _xp = 0;
  static int get xp => _xp;

  static int _casesSolved = 0;
  static int get casesSolved => _casesSolved;

  static final Set<String> _completedCaseIds = {};

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

  static bool isCaseUnlocked(String caseId, List<String> orderedTierIds) {
    if (orderedTierIds.isEmpty) return false;
    if (orderedTierIds.first == caseId) return true;
    final idx = orderedTierIds.indexOf(caseId);
    if (idx <= 0) return false;
    return _completedCaseIds.contains(orderedTierIds[idx - 1]);
  }

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

  // ── Title & Rank — unified XP-based tiers ────────────────
  static String get title {
    if (_xp >= 100) return 'Lead Investigator';
    if (_xp >= 60)  return 'Senior Analyst';
    if (_xp >= 30)  return 'Junior Analyst';
    if (_xp >= 10)  return 'Analyst Trainee';
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
    if (_xp >= 30)  return 60 - _xp;
    if (_xp >= 10)  return 30 - _xp;
    return 10 - _xp;
  }

  static String get nextRankName {
    if (_xp >= 100) return 'Max Rank';
    if (_xp >= 60)  return 'Lead Investigator';
    if (_xp >= 30)  return 'Senior Analyst';
    if (_xp >= 10)  return 'Junior Analyst';
    return 'Analyst Trainee';
  }

  static int get currentRankCap {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 100;
    if (_xp >= 30)  return 60;
    if (_xp >= 10)  return 30;
    return 10;
  }

  static int get currentRankBase {
    if (_xp >= 100) return 100;
    if (_xp >= 60)  return 60;
    if (_xp >= 30)  return 30;
    if (_xp >= 10)  return 10;
    return 0;
  }

  static double get rankProgress {
    final base = currentRankBase;
    final cap  = currentRankCap;
    if (cap == base) return 1.0;
    return ((_xp - base) / (cap - base)).clamp(0.0, 1.0);
  }

  static bool _briefingUnlocked = false;
  static bool get isBriefingUnlocked => _briefingUnlocked;
  static void unlockBriefing() => _briefingUnlocked = true;

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