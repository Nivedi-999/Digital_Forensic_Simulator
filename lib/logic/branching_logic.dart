// lib/logic/branching_logic.dart

import '../models/case.dart';

class BranchingLogic {
  final CaseFile caseFile;

  BranchingLogic(this.caseFile);

  // ── 1. Initial suspicion seeds ───────────────────────────

  double initialSuspicion(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return 0.35;
      case 'medium': return 0.20;
      default:       return 0.10;
    }
  }

  // ── 2. Evidence effects ──────────────────────────────────

  static const Map<String, Map<String, double>> _evidenceEffects = {
    'file_finance':      {'ankita_e': 0.20, 'dhruv_a': 0.05},
    'file_debug':        {'ankita_e': 0.15},
    'file_cache':        {'ankita_e': 0.10},
    'file_credentials':  {'ankita_e': 0.25, 'dhruv_a': -0.10},
    'meta_lastuser':     {'ankita_e': 0.20, 'manav_r': -0.05, 'ayon_k': -0.05},
    'ip_internal':       {'ankita_e': 0.15},
    'ip_external':       {'ankita_e': 0.15, 'dhruv_a': -0.10},
    'file_patch':        {'dhruv_a': 0.10},
    'chat_finance':      {'ankita_e': 0.10},
    'chat_offshore':     {'ankita_e': 0.10},
  };

  void applyEvidenceEffects(String evidenceId, Map<String, double> suspicion) {
    final effects = _evidenceEffects[evidenceId];
    if (effects == null) return;
    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 3. Mini-game effects ─────────────────────────────────

  static const Map<String, Map<String, double>> _minigameEffects = {
    'decryption': {
      'ankita_e': 0.10,
      'dhruv_a': -0.15,
      'manav_r': -0.05,
      'ayon_k': -0.05,
    },
  };

  void applyMinigameEffects(String minigameId, Map<String, double> suspicion) {
    final effects = _minigameEffects[minigameId];
    if (effects == null) return;
    for (final entry in effects.entries) {
      final current = suspicion[entry.key] ?? 0.0;
      suspicion[entry.key] = (current + entry.value).clamp(0.0, 1.0);
    }
  }

  // ── 4. Outcome resolution ────────────────────────────────
  //
  // BUG FIX: collecting ALL evidence no longer guarantees perfect.
  //
  // Rule: if the player collected ≥ 80% of all available evidence,
  // we treat it as evidence spam — the correct count still needs to
  // meet minCorrectEvidence, but the outcome is capped at 'partial'
  // (not perfect), because they didn't demonstrate actual deduction.
  //
  // Timer overtime: if time ran out, perfect is also capped to partial.

  OutcomeType resolveOutcome({
    required String accusedSuspectId,
    required int correctEvidenceCount,
    required int irrelevantEvidenceCount,
    required int totalEvidenceCount,
    required int totalAvailableEvidence,
    required WinCondition winCondition,
    bool isTimeUp = false,
  }) {
    final isCorrect = accusedSuspectId == winCondition.guiltySuspectId;

    if (!isCorrect) return OutcomeType.wrongAccusation;

    if (correctEvidenceCount == 0) return OutcomeType.coldCase;

    if (correctEvidenceCount < winCondition.minCorrectEvidence) {
      return OutcomeType.partial;
    }

    // Spam-collect check: flagged ≥80% of all available evidence
    final spamming = totalAvailableEvidence > 0 &&
        totalEvidenceCount / totalAvailableEvidence >= 0.8;

    // Timer overtime check
    if (spamming || isTimeUp) return OutcomeType.partial;

    return OutcomeType.perfect;
  }
}