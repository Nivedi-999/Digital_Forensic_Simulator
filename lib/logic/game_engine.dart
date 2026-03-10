// lib/logic/game_engine.dart
//
// CaseEngine is the single source of truth for everything that
// changes during a case:  which evidence is collected, which
// mini-games are solved, suspicion levels, and the final outcome.
//
// Screens never hold case state themselves — they read from the
// engine and call its methods in response to player actions.
//
// Usage
// -----
//   final engine = CaseEngine(caseFile);
//
//   // in a screen:
//   engine.collectEvidence('file_finance');
//   engine.solveMinigame('decryption');
//   final outcome = engine.evaluateAccusation('ankita_e');

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

  // ── State ────────────────────────────────────────────────

  /// Evidence items the player has marked as relevant.
  final List<CollectedEvidence> _collected = [];

  /// Mini-game IDs that have been successfully completed.
  final Set<String> _solvedMinigames = {};

  /// Hidden item IDs that have been unlocked via mini-games.
  final Set<String> _unlockedHiddenItems = {};

  /// Suspicion level (0.0–1.0) per suspect id.
  final Map<String, double> _suspicion = {};

  /// Whether the player has made a final accusation.
  bool _caseClosed = false;
  String? _accusedSuspectId;
  OutcomeType? _outcomeType;

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

  /// How many of the player's collected items are "correct" per the case def.
  int get correctEvidenceCount {
    return _collected
        .where((e) => caseFile.correctEvidenceIds.contains(e.itemId))
        .length;
  }

  /// All suspects ordered by risk level: high → medium → low.
  /// Uses the static riskLevel from the case JSON so the order
  /// never changes as evidence is collected.
  List<Suspect> get suspectsByThreat {
    int _priority(String riskLevel) {
      switch (riskLevel.toLowerCase()) {
        case 'high':   return 0;
        case 'medium': return 1;
        default:       return 2;
      }
    }
    final sorted = List<Suspect>.from(caseFile.suspects);
    sorted.sort((a, b) =>
        _priority(a.riskLevel).compareTo(_priority(b.riskLevel)));
    return sorted;
  }

  /// Whether the player has collected enough evidence to make an accusation.
  bool get canAccuse =>
      correctEvidenceCount >= caseFile.winCondition.minCorrectEvidence;

  /// All evidence items visible to the player for a given panel
  /// (respects hidden-item unlock state).
  List<EvidenceItem> visibleItemsForPanel(String panelId) {
    final panel = caseFile.panelById(panelId);
    if (panel == null) return [];

    final items = List<EvidenceItem>.from(panel.items);

    // Append hidden item if its mini-game has been solved
    final hidden = panel.hiddenItem;
    if (hidden != null &&
        hidden.unlockedByMinigameId != null &&
        _solvedMinigames.contains(hidden.unlockedByMinigameId)) {
      items.add(hidden);
    }

    return items;
  }

  // ── Mutations ────────────────────────────────────────────

  /// Mark an evidence item as collected.
  /// Safe to call multiple times — duplicates are ignored.
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

    notifyListeners();
  }

  /// Remove a previously collected evidence item.
  void removeEvidence(String itemId) {
    if (_caseClosed) return;
    final before = _collected.length;
    _collected.removeWhere((e) => e.itemId == itemId);
    if (_collected.length != before) notifyListeners();
  }

  /// Clear all collected evidence (e.g. "Clear All" button).
  void clearEvidence() {
    if (_caseClosed) return;
    _collected.clear();
    _initSuspicionLevels(); // reset suspicion too
    notifyListeners();
  }

  /// Record a successful mini-game completion.
  /// Applies any unlock side-effects defined in the case JSON.
  void solveMinigame(String minigameId) {
    if (_solvedMinigames.contains(minigameId)) return;
    _solvedMinigames.add(minigameId);

    // Check if this mini-game unlocks a hidden evidence item
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

    notifyListeners();
  }

  /// Make a final accusation. Returns the resolved OutcomeType.
  /// After calling this the engine is locked (caseClosed = true).
  OutcomeType accuse(String suspectId) {
    if (_caseClosed) return _outcomeType!;

    _accusedSuspectId = suspectId;
    _caseClosed = true;

    _outcomeType = _branching.resolveOutcome(
      accusedSuspectId: suspectId,
      correctEvidenceCount: correctEvidenceCount,
      winCondition: caseFile.winCondition,
    );

    notifyListeners();
    return _outcomeType!;
  }

  /// Get the full OutcomeConfig for the resolved outcome type.
  OutcomeConfig? get resolvedOutcomeConfig {
    if (_outcomeType == null) return null;
    return caseFile.outcomes[_outcomeType];
  }

  // ── Private helpers ──────────────────────────────────────

  void _initSuspicionLevels() {
    _suspicion.clear();
    for (final suspect in caseFile.suspects) {
      // Seed from risk level so the UI looks alive before any evidence
      _suspicion[suspect.id] = _branching.initialSuspicion(suspect.riskLevel);
    }
  }

  // Sentinel used to avoid nullable gymnastics in collectEvidence
  static final EvidenceItem _sentinel = const EvidenceItem(
    id: '__sentinel__',
    label: '',
    detail: '',
  );
}