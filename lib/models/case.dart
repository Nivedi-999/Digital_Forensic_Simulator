// lib/models/case.dart

import 'evidence.dart';
import 'suspect.dart';

// ── Outcome definitions ──────────────────────────────────────

enum OutcomeType { perfect, partial, wrongAccusation, coldCase }

class OutcomeConfig {
  final OutcomeType type;
  final String title;
  final String subtitle;
  final String label;
  final int xp;

  const OutcomeConfig({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.xp,
  });

  factory OutcomeConfig.fromJson(
      OutcomeType type, Map<String, dynamic> json) {
    return OutcomeConfig(
      type: type,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      label: json['label'] as String,
      xp: json['xp'] as int,
    );
  }
}

// ── Win condition ────────────────────────────────────────────

class WinCondition {
  final String guiltySuspectId;
  final int minCorrectEvidence;

  const WinCondition({
    required this.guiltySuspectId,
    required this.minCorrectEvidence,
  });

  factory WinCondition.fromJson(Map<String, dynamic> json) {
    return WinCondition(
      guiltySuspectId: json['guiltySuspectId'] as String,
      minCorrectEvidence: json['minCorrectEvidence'] as int,
    );
  }
}

// ── Timeline event ───────────────────────────────────────────

class TimelineEvent {
  final String time;
  final String title;
  final String description;
  final String severity; // 'critical' | 'high' | 'medium' | 'low'

  const TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    this.severity = 'low',
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      time: json['time'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String? ?? 'low',
    );
  }
}

// ── Briefing text ────────────────────────────────────────────

class CaseBriefing {
  final String incidentSummary;
  final String missionText;

  const CaseBriefing({
    required this.incidentSummary,
    required this.missionText,
  });

  factory CaseBriefing.fromJson(Map<String, dynamic> json) {
    return CaseBriefing(
      incidentSummary: json['incidentSummary'] as String,
      missionText: json['missionText'] as String,
    );
  }
}

// ── Aria messages ────────────────────────────────────────────

class AriaMessages {
  final String welcomeToHub;
  final String exploreFeeds;
  final String viewEvidence;
  final String markEvidence;
  final String decryptionHint;
  final String flagSuspect;

  const AriaMessages({
    required this.welcomeToHub,
    required this.exploreFeeds,
    required this.viewEvidence,
    required this.markEvidence,
    required this.decryptionHint,
    required this.flagSuspect,
  });

  factory AriaMessages.fromJson(Map<String, dynamic> json) {
    return AriaMessages(
      welcomeToHub: json['welcomeToHub'] as String,
      exploreFeeds: json['exploreFeeds'] as String,
      viewEvidence: json['viewEvidence'] as String,
      markEvidence: json['markEvidence'] as String,
      decryptionHint: json['decryptionHint'] as String,
      flagSuspect: json['flagSuspect'] as String,
    );
  }
}

// ── Root CaseFile ────────────────────────────────────────────

class CaseFile {
  final String id;
  final String title;
  final String shortDescription;
  final String difficulty;
  final String theme;
  final String caseNumber;
  final String status;
  final String estimatedDuration;
  final bool tutorialEnabled;

  final CaseBriefing briefing;
  final List<Suspect> suspects;
  final List<EvidencePanel> evidencePanels;
  final List<TimelineEvent> timeline;
  final List<String> correctEvidenceIds;
  final WinCondition winCondition;

  final Map<OutcomeType, OutcomeConfig> outcomes;
  final AriaMessages? ariaMessages;

  const CaseFile({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.difficulty,
    required this.theme,
    required this.caseNumber,
    required this.status,
    required this.estimatedDuration,
    required this.tutorialEnabled,
    required this.briefing,
    required this.suspects,
    required this.evidencePanels,
    required this.timeline,
    required this.correctEvidenceIds,
    required this.winCondition,
    required this.outcomes,
    this.ariaMessages,
  });

  // ── Convenience lookups ──────────────────────────────────

  Suspect? suspectById(String id) {
    try {
      return suspects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  EvidencePanel? panelById(String id) {
    try {
      return evidencePanels.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  EvidenceItem? evidenceItemById(String id) {
    for (final panel in evidencePanels) {
      for (final item in panel.items) {
        if (item.id == id) return item;
      }
      if (panel.hiddenItem?.id == id) return panel.hiddenItem;
    }
    return null;
  }

  // ── fromJson ────────────────────────────────────────────

  factory CaseFile.fromJson(Map<String, dynamic> json) {
    // Parse suspects
    final suspects = (json['suspects'] as List<dynamic>)
        .map((s) => Suspect.fromJson(s as Map<String, dynamic>))
        .toList();

    // Parse evidence panels
    final panels = (json['evidencePanels'] as List<dynamic>)
        .map((p) => EvidencePanel.fromJson(p as Map<String, dynamic>))
        .toList();

    // Parse timeline
    final timeline = (json['timeline'] as List<dynamic>)
        .map((t) => TimelineEvent.fromJson(t as Map<String, dynamic>))
        .toList();

    // Parse win condition
    final winCondition =
    WinCondition.fromJson(json['winCondition'] as Map<String, dynamic>);

    // Parse correct evidence ids
    final correctIds = (json['correctEvidenceIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList();

    // Parse outcomes
    final outcomesJson = json['outcomes'] as Map<String, dynamic>;
    final outcomes = <OutcomeType, OutcomeConfig>{
      OutcomeType.perfect: OutcomeConfig.fromJson(
          OutcomeType.perfect,
          outcomesJson['perfect'] as Map<String, dynamic>),
      OutcomeType.partial: OutcomeConfig.fromJson(
          OutcomeType.partial,
          outcomesJson['partial'] as Map<String, dynamic>),
      OutcomeType.wrongAccusation: OutcomeConfig.fromJson(
          OutcomeType.wrongAccusation,
          outcomesJson['wrongAccusation'] as Map<String, dynamic>),
      OutcomeType.coldCase: OutcomeConfig.fromJson(
          OutcomeType.coldCase,
          outcomesJson['coldCase'] as Map<String, dynamic>),
    };

    // Parse briefing
    final briefing =
    CaseBriefing.fromJson(json['briefing'] as Map<String, dynamic>);

    // Parse aria messages (optional)
    final ariaJson = json['aria'] as Map<String, dynamic>?;
    final ariaMessages =
    ariaJson != null ? AriaMessages.fromJson(ariaJson) : null;

    return CaseFile(
      id: json['id'] as String,
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String,
      difficulty: json['difficulty'] as String,
      theme: json['theme'] as String,
      caseNumber: json['caseNumber'] as String,
      status: json['status'] as String,
      estimatedDuration: json['estimatedDuration'] as String,
      tutorialEnabled: json['tutorialEnabled'] as bool? ?? false,
      briefing: briefing,
      suspects: suspects,
      evidencePanels: panels,
      timeline: timeline,
      correctEvidenceIds: correctIds,
      winCondition: winCondition,
      outcomes: outcomes,
      ariaMessages: ariaMessages,
    );
  }
}