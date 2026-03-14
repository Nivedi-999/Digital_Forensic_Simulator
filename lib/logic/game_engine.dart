// lib/logic/game_engine.dart
//
// CaseEngine — single source of truth for all in-case state.
//
// NEW in this version:
//   • hintsUsed counter  — incremented by recordHintUsed()
//   • irrelevantEvidenceCount — derived from collected vs correctEvidenceIds
//   • Timer support (hard/advanced only) — start/stop via startTimer()
//   • computeFinalXp() — base XP minus hint and irrelevant evidence penalties
//   • resolveOutcome() now penalises selecting ALL evidence (spam collect)

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/case.dart';
import '../models/evidence.dart';
import '../models/suspect.dart';
import 'branching_logic.dart';

// ── Collected evidence record ────────────────────────────────

class CollectedEvidence {
  final String panelId;
  final String itemId;
  final String label;
  final DateTime collectedAt;

  const CollectedEvidence({
    required this.panelId,
    required this.itemId,
    required this.label,
    required this.collectedAt,
  });
}

// ── Engine ───────────────────────────────────────────────────

class CaseEngine extends ChangeNotifier {
  final CaseFile caseFile;
  final BranchingLogic _branching;

  CaseEngine(this.caseFile)
      : _branching = BranchingLogic(caseFile) {
    _initSuspicionLevels();
  }

  // ── Core state ───────────────────────────────────────────

  final List<CollectedEvidence> _collected = [];
  final Set<String> _solvedMinigames = {};
  final Set<String> _unlockedHiddenItems = {};
  final Map<String, double> _suspicion = {};

  bool _caseClosed = false;
  String? _accusedSuspectId;
  OutcomeType? _outcomeType;

  // ── Hint tracking ────────────────────────────────────────
  // Each call to recordHintUsed() increments the counter.
  // The outcome screen reads this to calculate XP penalties.
  int _hintsUsed = 0;
  int get hintsUsed => _hintsUsed;

  /// Call this from the mini-game screen every time the player
  /// taps a hint button.
  void recordHintUsed() {
    _hintsUsed++;
    notifyListeners();
  }

  // ── Timer (hard / advanced only) ────────────────────────
  // timeLimitSeconds comes from the case JSON.
  // The timer starts when startTimer() is called (on hub load).

  Timer? _ticker;
  int _elapsedSeconds = 0;

  int get elapsedSeconds => _elapsedSeconds;

  bool get hasTimer {
    final diff = caseFile.difficulty.toLowerCase();
    return (diff == 'hard' || diff == 'advanced') &&
        caseFile.timeLimitSeconds != null;
  }

  int? get timeLimitSeconds => caseFile.timeLimitSeconds;

  /// Remaining seconds. Returns null if no timer.
  int? get remainingSeconds {
    if (!hasTimer) return null;
    final remaining = timeLimitSeconds! - _elapsedSeconds;
    return remaining.clamp(0, timeLimitSeconds!);
  }

  /// 0.0–1.0 progress of time used. 1.0 = time up.
  double get timerProgress {
    if (!hasTimer) return 0.0;
    return (_elapsedSeconds / timeLimitSeconds!).clamp(0.0, 1.0);
  }

  bool get isTimeUp => hasTimer && _elapsedSeconds >= timeLimitSeconds!;

  void startTimer() {
    if (!hasTimer || _ticker != null || _caseClosed) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
      if (isTimeUp) _ticker?.cancel();
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ── Read-only accessors ──────────────────────────────────

  List<CollectedEvidence> get collectedEvidence =>
      List.unmodifiable(_collected);

  Set<String> get solvedMinigames => Set.unmodifiable(_solvedMinigames);

  Set<String> get unlockedHiddenItems =>
      Set.unmodifiable(_unlockedHiddenItems);

  bool get caseClosed => _caseClosed;
  String? get accusedSuspectId => _accusedSuspectId;
  OutcomeType? get outcomeType => _outcomeType;

  double suspicionFor(String suspectId) => _suspicion[suspectId] ?? 0.0;

  bool isMinigameSolved(String minigameId) =>
      _solvedMinigames.contains(minigameId);

  bool isHiddenItemUnlocked(String itemId) =>
      _unlockedHiddenItems.contains(itemId);

  bool isEvidenceCollected(String itemId) =>
      _collected.any((e) => e.itemId == itemId);

  // ── Derived helpers ──────────────────────────────────────

  int get correctEvidenceCount => _collected
      .where((e) => caseFile.correctEvidenceIds.contains(e.itemId))
      .length;

  /// Evidence collected by the player that is NOT in correctEvidenceIds.
  int get irrelevantEvidenceCount => _collected
      .where((e) => !caseFile.correctEvidenceIds.contains(e.itemId))
      .length;

  List<Suspect> get suspectsByThreat {
    final sorted = List<Suspect>.from(caseFile.suspects);
    sorted.sort((a, b) =>
        suspicionFor(b.id).compareTo(suspicionFor(a.id)));
    return sorted;
  }

  bool get canAccuse =>
      correctEvidenceCount >= caseFile.winCondition.minCorrectEvidence;

  List<EvidenceItem> visibleItemsForPanel(String panelId) {
    final panel = caseFile.panelById(panelId);
    if (panel == null) return [];
    final items = List<EvidenceItem>.from(panel.items);
    final hidden = panel.hiddenItem;
    if (hidden != null &&
        hidden.unlockedByMinigameId != null &&
        _solvedMinigames.contains(hidden.unlockedByMinigameId)) {
      items.add(hidden);
    }
    return items;
  }

  // ── XP calculation ───────────────────────────────────────
  //
  // Called by the outcome screen to get the final adjusted XP.
  //
  // Penalties:
  //   −1 XP per hint used (max penalty = base XP − 1)
  //   −1 XP per irrelevant evidence item collected
  //   Timer penalty (hard/advanced only):
  //     • Used 60–90% of time → −2 XP
  //     • Used 90–100% of time → −4 XP
  //     • Overtime (time ran out) → −6 XP
  //
  // XP floor: minimum 1 XP on a win (never drops to 0).

  int computeFinalXp(int baseXp) {
    int xp = baseXp;

    // Hint penalty
    xp -= _hintsUsed;

    // Irrelevant evidence penalty
    xp -= irrelevantEvidenceCount;

    // Timer penalty (hard/advanced only)
    if (hasTimer && timeLimitSeconds != null && timeLimitSeconds! > 0) {
      final ratio = _elapsedSeconds / timeLimitSeconds!;
      if (ratio > 1.0) {
        xp -= 6; // overtime
      } else if (ratio > 0.9) {
        xp -= 4;
      } else if (ratio > 0.6) {
        xp -= 2;
      }
    }

    return xp.clamp(1, baseXp); // floor 1, ceiling = base
  }

  // ── XP breakdown for the outcome screen ─────────────────
  //
  // Returns a list of (label, delta) pairs so the UI can show
  // exactly why XP was added or deducted.

  List<XpBreakdownItem> xpBreakdown(int baseXp) {
    final items = <XpBreakdownItem>[];
    items.add(XpBreakdownItem('Base XP', baseXp, positive: true));

    if (_hintsUsed > 0) {
      items.add(XpBreakdownItem(
          'Hints used (×$_hintsUsed)', -_hintsUsed,
          positive: false));
    }

    if (irrelevantEvidenceCount > 0) {
      items.add(XpBreakdownItem(
          'Irrelevant evidence (×$irrelevantEvidenceCount)',
          -irrelevantEvidenceCount,
          positive: false));
    }

    if (hasTimer && timeLimitSeconds != null && timeLimitSeconds! > 0) {
      final ratio = _elapsedSeconds / timeLimitSeconds!;
      if (ratio > 1.0) {
        items.add(const XpBreakdownItem('Time ran out', -6, positive: false));
      } else if (ratio > 0.9) {
        items.add(const XpBreakdownItem('Tight finish (>90% time)', -4, positive: false));
      } else if (ratio > 0.6) {
        items.add(const XpBreakdownItem('Slow solve (>60% time)', -2, positive: false));
      }
    }

    return items;
  }

  // ── Mutations ────────────────────────────────────────────

  void collectEvidence(String panelId, String itemId) {
    if (_caseClosed) return;
    if (isEvidenceCollected(itemId)) return;

    final panel = caseFile.panelById(panelId);
    final item = panel?.items.firstWhere(
          (i) => i.id == itemId,
      orElse: () => panel.hiddenItem ?? _sentinel,
    );
    if (item == null || item.id == '__sentinel__') return;

    _collected.add(CollectedEvidence(
      panelId: panelId,
      itemId: itemId,
      label: item.label,
      collectedAt: DateTime.now(),
    ));

    _branching.applyEvidenceEffects(itemId, _suspicion);
    notifyListeners();
  }

  void removeEvidence(String itemId) {
    if (_caseClosed) return;
    final before = _collected.length;
    _collected.removeWhere((e) => e.itemId == itemId);
    if (_collected.length != before) notifyListeners();
  }

  void clearEvidence() {
    if (_caseClosed) return;
    _collected.clear();
    _initSuspicionLevels();
    notifyListeners();
  }

  void solveMinigame(String minigameId) {
    if (_solvedMinigames.contains(minigameId)) return;
    _solvedMinigames.add(minigameId);

    for (final panel in caseFile.evidencePanels) {
      final mg = panel.minigame;
      if (mg != null && mg.id == minigameId) {
        final hiddenId = mg.unlocksHiddenItemId;
        if (hiddenId != null) {
          _unlockedHiddenItems.add(hiddenId);
        }
        break;
      }
    }

    _branching.applyMinigameEffects(minigameId, _suspicion);
    notifyListeners();
  }

  OutcomeType accuse(String suspectId) {
    if (_caseClosed) return _outcomeType!;

    _stopTimer();
    _accusedSuspectId = suspectId;
    _caseClosed = true;

    _outcomeType = _branching.resolveOutcome(
      accusedSuspectId: suspectId,
      correctEvidenceCount: correctEvidenceCount,
      irrelevantEvidenceCount: irrelevantEvidenceCount,
      totalEvidenceCount: _collected.length,
      totalAvailableEvidence: _totalAvailableEvidenceCount(),
      winCondition: caseFile.winCondition,
      isTimeUp: isTimeUp,
    );

    notifyListeners();
    return _outcomeType!;
  }

  OutcomeConfig? get resolvedOutcomeConfig {
    if (_outcomeType == null) return null;
    return caseFile.outcomes[_outcomeType];
  }

  // ── Private helpers ──────────────────────────────────────

  void _initSuspicionLevels() {
    _suspicion.clear();
    for (final suspect in caseFile.suspects) {
      _suspicion[suspect.id] = _branching.initialSuspicion(suspect.riskLevel);
    }
  }

  /// Count of all evidence items the player COULD collect in this case.
  int _totalAvailableEvidenceCount() {
    int count = 0;
    for (final panel in caseFile.evidencePanels) {
      count += panel.items.length;
      if (panel.hiddenItem != null) count++;
    }
    return count;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  static final EvidenceItem _sentinel = const EvidenceItem(
    id: '__sentinel__',
    label: '',
    detail: '',
  );
}

// ── XP breakdown item ─────────────────────────────────────────

class XpBreakdownItem {
  final String label;
  final int delta;
  final bool positive;
  const XpBreakdownItem(this.label, this.delta, {required this.positive});
}