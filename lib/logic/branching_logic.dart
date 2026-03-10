// lib/logic/branching_logic.dart
//
// BranchingLogic owns two responsibilities:
//
//   1. Suspicion effects — when the player collects evidence or
//      solves a mini-game, how does each suspect's suspicion level
//      change?  Rules live in this class, NOT in the JSON, because
//      they are pure game-logic not presentation data.
//
//   2. Outcome resolution — given the accused suspect and the
//      number of correct evidence items, which OutcomeType fires?
//
// Adding a new case only requires subclassing BranchingLogic (or
// extending the rule tables below) — no screen code changes.

import '../models/case.dart';

class BranchingLogic {
  final CaseFile caseFile;

  BranchingLogic(this.caseFile);

  // ── 1. Initial suspicion seeds ───────────────────────────
  //
  // These give the suspicion bars a plausible starting position
  // before the player has collected any evidence.

  double initialSuspicion(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 0.35;
      case 'medium':
        return 0.20;
      default:
        return 0.10;
    }
  }

  // ── 2. Evidence effects ──────────────────────────────────
  //
  // Maps evidence item id → delta per suspect id.
  // Positive = more suspicious, negative = less suspicious.
  // Values are clamped to [0.0, 1.0] after application.
  //
  // Design rule: only key evidence items should move the needle
  // significantly. Red-herring items may slightly raise a wrong
  // suspect then drop them when contradicted later.

  static const Map<String, Map<String, double>> _evidenceEffects = {
    // finance_report_q3.pdf — directly modified by Ankita E
    'file_finance': {
      'ankita_e': 0.20,
      'dhruv_a': 0.05, // suspicious but not conclusive
    },

    // debug_log.txt — credential export from FIN-WS-114
    'file_debug': {
      'ankita_e': 0.15,
    },

    // cache_dump.bin — exfil path through FIN-WS-114
    'file_cache': {
      'ankita_e': 0.10,
    },

    // credentials.pdf (hidden, unlocked via decryption mini-game)
    'file_credentials': {
      'ankita_e': 0.25,
      'dhruv_a': -0.10, // reduces Admin suspicion
    },

    // meta — last login was Ankita E
    'meta_lastuser': {
      'ankita_e': 0.20,
      'manav_r': -0.05,
      'ayon_k': -0.05,
    },

    // ip_internal — internal origin is FIN-WS-114
    'ip_internal': {
      'ankita_e': 0.15,
    },

    // ip_external — cafe WiFi hop matches Ankita's known location
    'ip_external': {
      'ankita_e': 0.15,
      'dhruv_a': -0.10,
    },

    // system_patch.exe — raises Dhruv briefly, then context clears him
    'file_patch': {
      'dhruv_a': 0.10,
    },

    // chat messages pointing at finance workstation
    'chat_finance': {
      'ankita_e': 0.10,
    },
    'chat_offshore': {
      'ankita_e': 0.10,
    },
  };

  /// Apply suspicion deltas for a collected evidence item.
  void applyEvidenceEffects(
      String evidenceId, Map<String, double> suspicion) {
    final effects = _evidenceEffects[evidenceId];
    if (effects == null) return;

    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 3. Mini-game effects ─────────────────────────────────
  //
  // Solving a mini-game can also shift suspicion —
  // typically it clears a red herring or confirms a direction.

  static const Map<String, Map<String, double>> _minigameEffects = {
    // Decryption unlocks credentials.pdf which strongly confirms Ankita E
    'decryption': {
      'ankita_e': 0.10,
      'dhruv_a': -0.15,
      'manav_r': -0.05,
      'ayon_k': -0.05,
    },
  };

  /// Apply suspicion deltas for a completed mini-game.
  void applyMinigameEffects(
      String minigameId, Map<String, double> suspicion) {
    final effects = _minigameEffects[minigameId];
    if (effects == null) return;

    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 4. Outcome resolution ────────────────────────────────

  OutcomeType resolveOutcome({
    required String accusedSuspectId,
    required int correctEvidenceCount,
    required WinCondition winCondition,
  }) {
    final isCorrect = accusedSuspectId == winCondition.guiltySuspectId;

    if (!isCorrect) {
      return OutcomeType.wrongAccusation;
    }

    if (correctEvidenceCount == 0) {
      return OutcomeType.coldCase;
    }

    if (correctEvidenceCount >= winCondition.minCorrectEvidence) {
      return OutcomeType.perfect;
    }

    return OutcomeType.partial;
  }
}