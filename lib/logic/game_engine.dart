// lib/logic/game_engine.dart
//
// CaseEngine — single source of truth for all in-case state.
//
// UPDATED: Integrated CaseTimer bridge for centralized time tracking.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/case.dart';
import '../models/evidence.dart';
import '../models/suspect.dart';
import 'branching_logic.dart';
import '../services/case_timer.dart';

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
  final Set<String> _unlockedSuspects = {};
  final Map<String, double> _suspicion = {};

  bool _caseClosed = false;
  String? _accusedSuspectId;
  OutcomeType? _outcomeType;

  // ── Hint tracking ────────────────────────────────────────
  int _hintsUsed = 0;
  int get hintsUsed => _hintsUsed;

  void recordHintUsed() {
    _hintsUsed++;
    notifyListeners();
  }

  // ── Timer bridge ─────────────────────────────────────────
  //
  // InvestigationHubScreen creates a CaseTimer, starts it, then calls
  // attachTimer() so the engine owns the reference. The outcome screen
  // calls stopTimer() to freeze the clock and read the final time.

  CaseTimer? _timer;

  /// Hand off the running timer from InvestigationHubScreen.
  void attachTimer(CaseTimer timer) => _timer = timer;

  /// Freeze the timer and return elapsed seconds. Safe to call multiple times.
  int stopTimer() => _timer?.stop() ?? 0;

  /// Current elapsed seconds (live while running, frozen after stop).
  int get elapsedSeconds => _timer?.elapsedSeconds ?? 0;

  /// True once attachTimer() has been called.
  bool get hasTimer => _timer != null;

  /// Whether a hard time limit was exceeded.
  /// Extend this if you add per-case time limits to CaseFile.
  bool get isTimeUp => false;

  /// Per-case time limit in seconds, or null if unlimited.
  int? get timeLimitSeconds => caseFile.timeLimitSeconds;

  /// Remaining seconds before the time limit. null if no timer/limit.
  int? get remainingSeconds {
    if (!hasTimer || timeLimitSeconds == null) return null;
    final remaining = timeLimitSeconds! - elapsedSeconds;
    return remaining.clamp(0, timeLimitSeconds!);
  }

  /// 0.0–1.0 fraction of the time limit consumed. 0.0 if unlimited.
  double get timerProgress {
    if (!hasTimer || timeLimitSeconds == null || timeLimitSeconds == 0) return 0.0;
    return (elapsedSeconds / timeLimitSeconds!).clamp(0.0, 1.0);
  }

  // ── Read-only accessors ──────────────────────────────────

  List<CollectedEvidence> get collectedEvidence =>
      List.unmodifiable(_collected);

  Set<String> get solvedMinigames => Set.unmodifiable(_solvedMinigames);

  Set<String> get unlockedHiddenItems =>
      Set.unmodifiable(_unlockedHiddenItems);

  Set<String> get unlockedSuspects =>
      Set.unmodifiable(_unlockedSuspects);

  bool get caseClosed => _caseClosed;
  String? get accusedSuspectId => _accusedSuspectId;
  OutcomeType? get outcomeType => _outcomeType;

  double suspicionFor(String suspectId) => _suspicion[suspectId] ?? 0.0;

  bool isMinigameSolved(String minigameId) =>
      _solvedMinigames.contains(minigameId);

  bool isHiddenItemUnlocked(String itemId) =>
      _unlockedHiddenItems.contains(itemId);

  bool isSuspectUnlocked(String suspectId) {
    final suspect = caseFile.suspectById(suspectId);
    if (suspect == null || !suspect.isHidden) return true;
    return _unlockedSuspects.contains(suspectId);
  }

  bool isEvidenceCollected(String itemId) =>
      _collected.any((e) => e.itemId == itemId);

  // ── Derived helpers ──────────────────────────────────────

  int get correctEvidenceCount => _collected
      .where((e) => caseFile.correctEvidenceIds.contains(e.itemId))
      .length;

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

  int computeFinalXp(int baseXp) {
    final totalCorrect = caseFile.correctEvidenceIds.length;
    final double proportion =
    totalCorrect == 0 ? 0.0 : correctEvidenceCount / totalCorrect;
    int xp = (baseXp * proportion).round();

    xp -= _hintsUsed;
    xp -= irrelevantEvidenceCount;

    if (hasTimer && timeLimitSeconds != null && timeLimitSeconds! > 0) {
      final ratio = elapsedSeconds / timeLimitSeconds!;
      if (ratio > 1.0) {
        xp -= 6;
      } else if (ratio > 0.9) {
        xp -= 4;
      } else if (ratio > 0.6) {
        xp -= 2;
      }
    }

    return xp.clamp(1, baseXp);
  }

  // ── XP breakdown for the outcome screen ─────────────────

  List<XpBreakdownItem> xpBreakdown(int baseXp) {
    final totalCorrect = caseFile.correctEvidenceIds.length;
    final double proportion =
    totalCorrect == 0 ? 0.0 : correctEvidenceCount / totalCorrect;
    final int proportionalBase = (baseXp * proportion).round();

    final items = <XpBreakdownItem>[];
    items.add(XpBreakdownItem(
        'Evidence found ($correctEvidenceCount/$totalCorrect)',
        proportionalBase,
        positive: true));

    if (_hintsUsed > 0) {
      items.add(XpBreakdownItem(
          'Hints used (×$_hintsUsed)', -_hintsUsed, positive: false));
    }

    if (irrelevantEvidenceCount > 0) {
      items.add(XpBreakdownItem(
          'Wrong evidence (×$irrelevantEvidenceCount)',
          -irrelevantEvidenceCount,
          positive: false));
    }

    if (hasTimer && timeLimitSeconds != null && timeLimitSeconds! > 0) {
      final ratio = elapsedSeconds / timeLimitSeconds!;
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
        final hiddenSuspectId = mg.unlocksHiddenSuspectId;
        if (hiddenSuspectId != null) {
          _unlockedSuspects.add(hiddenSuspectId);
          final suspect = caseFile.suspectById(hiddenSuspectId);
          if (suspect != null && !_suspicion.containsKey(hiddenSuspectId)) {
            _suspicion[hiddenSuspectId] = suspect.initialSuspicion
                ?? _branching.initialSuspicion(suspect.riskLevel);
          }
        }
        break;
      }
    }

    _branching.applyMinigameEffects(minigameId, _suspicion);
    notifyListeners();
  }

  OutcomeType accuse(String suspectId) {
    if (_caseClosed) return _outcomeType!;

    stopTimer(); // Freeze the clock the moment accusation is submitted
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
      _suspicion[suspect.id] = suspect.initialSuspicion
          ?? _branching.initialSuspicion(suspect.riskLevel);
    }
  }

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
    stopTimer();
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