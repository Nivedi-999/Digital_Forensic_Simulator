// lib/models/evidence.dart

class EvidenceRow {
  final String key;
  final String value;
  final bool highlight;

  const EvidenceRow({
    required this.key,
    required this.value,
    this.highlight = false,
  });

  factory EvidenceRow.fromJson(Map<String, dynamic> json) {
    return EvidenceRow(
      key: json['key'] as String,
      value: json['value'] as String,
      highlight: json['highlight'] as bool? ?? false,
    );
  }
}

class FileMetadata {
  final String size;
  final String modifier;
  final String modifiedAt;

  const FileMetadata({
    required this.size,
    required this.modifier,
    required this.modifiedAt,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      size: json['size'] as String,
      modifier: json['modifier'] as String,
      modifiedAt: json['modifiedAt'] as String,
    );
  }
}

/// Used by metadata_correlation mini-game.
/// mini_game.dart accesses: id, label, value, hint, correctSuspectId, explanation
class MetadataFragment {
  final String id;
  final String label;
  final String value;
  final String hint;
  final String correctSuspectId;
  final String explanation;

  const MetadataFragment({
    required this.id,
    required this.label,
    required this.value,
    required this.hint,
    required this.correctSuspectId,
    required this.explanation,
  });

  factory MetadataFragment.fromJson(Map<String, dynamic> json) =>
      MetadataFragment(
        id: json['id'] as String,
        label: json['label'] as String,
        value: json['value'] as String,
        hint: json['hint'] as String? ?? '',
        correctSuspectId: json['correctSuspectId'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );
}

/// Used by alibi_verify mini-game.
/// mini_game.dart accesses: id, suspectId, suspectName, alibi, isContradicted, contradiction
class AlibiEntry {
  final String id;
  final String suspectId;
  final String suspectName;
  final String alibi;
  final bool isContradicted;
  final String contradiction;

  const AlibiEntry({
    required this.id,
    required this.suspectId,
    required this.suspectName,
    required this.alibi,
    required this.isContradicted,
    this.contradiction = '',
  });

  factory AlibiEntry.fromJson(Map<String, dynamic> json) => AlibiEntry(
    id: json['id'] as String? ?? json['suspectId'] as String,
    suspectId: json['suspectId'] as String,
    suspectName: json['suspectName'] as String,
    alibi: json['alibi'] as String,
    isContradicted: json['isContradicted'] as bool? ?? false,
    contradiction: json['contradiction'] as String? ?? '',
  );
}

class MinigameConfig {
  final String id;
  final String type;
  final String title;
  final int maxHints;
  final List<String> hints;
  final String? hint;
  final String? unlocksHiddenItemId;
  final String? unlocksHiddenSuspectId;
  final String? successMessage;

  // caesar_cipher
  final String? cipherText;
  final String? solution;
  final String? jwtEncoded;
  final Map<String, dynamic>? decodedPayload;
  final String? iatHumanReadable;

  // ip_trace
  final List<String> decoys;

  // phishing_analysis
  final String? emailFrom;
  final String? emailSubject;
  final String? emailBody;
  final List<String> redFlags;
  final String? correctAction;

  // metadata_correlation
  final String? instruction;
  final List<MetadataFragment> fragments;
  final List<Map<String, String>> metaSuspects;

  // alibi_verify
  final List<AlibiEntry> alibis;
  final Map<String, String>? timelineEvent;
  final Map<String, double> suspicionEffectsOnSolve;

  // Raw JSON — used by new game types to access custom fields not in the typed model.
  final Map<String, dynamic> rawJson;

  const MinigameConfig({
    required this.id,
    required this.type,
    required this.title,
    this.maxHints = 3,
    this.hints = const [],
    this.hint,
    this.unlocksHiddenItemId,
    this.unlocksHiddenSuspectId,
    this.successMessage,
    this.cipherText,
    this.solution,
    this.jwtEncoded,
    this.decodedPayload,
    this.iatHumanReadable,
    this.decoys = const [],
    this.emailFrom,
    this.emailSubject,
    this.emailBody,
    this.redFlags = const [],
    this.correctAction,
    this.instruction,
    this.fragments = const [],
    this.metaSuspects = const [],
    this.alibis = const [],
    this.timelineEvent,
    this.suspicionEffectsOnSolve = const {},
    this.rawJson = const {},
  });

  factory MinigameConfig.fromJson(Map<String, dynamic> json) {
    final onSuccess = json['onSuccess'] as Map<String, dynamic>?;
    return MinigameConfig(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      maxHints: json['maxHints'] as int? ?? 3,
      hints: (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      hint: json['hint'] as String?,
      unlocksHiddenItemId: onSuccess?['unlocksHiddenItem'] as String?,
      unlocksHiddenSuspectId: onSuccess?['unlocksHiddenSuspect'] as String?,
      successMessage: onSuccess?['message'] as String?,
      cipherText: json['cipherText'] as String?,
      solution: json['solution'] as String?,
      jwtEncoded: json['jwtEncoded'] as String?,
      decodedPayload: json['decodedPayload'] is Map<String, dynamic>
          ? json['decodedPayload'] as Map<String, dynamic>
          : null,
      iatHumanReadable: json['iatHumanReadable'] as String?,
      decoys: (json['decoys'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      emailFrom: json['emailFrom'] as String?,
      emailSubject: json['emailSubject'] as String?,
      emailBody: json['emailBody'] as String?,
      redFlags: (json['redFlags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      correctAction: json['correctAction'] as String?,
      instruction: json['instruction'] as String?,
      fragments: (json['fragments'] as List<dynamic>?)
          ?.map((e) => MetadataFragment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      metaSuspects: (json['suspects'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      alibis: (json['alibis'] as List<dynamic>?)
          ?.map((e) => AlibiEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      timelineEvent: json['timelineEvent'] != null
          ? Map<String, String>.from(json['timelineEvent'] as Map)
          : null,
      suspicionEffectsOnSolve:
      (json['suspicionEffectsOnSolve'] is Map)
          ? Map<String, dynamic>.from(
        json['suspicionEffectsOnSolve'] as Map,
      ).map((k, v) => MapEntry(k, (v as num).toDouble()))
          : const {},
      rawJson: Map<String, dynamic>.from(json),
    );
  }
}

class EvidenceItem {
  final String id;
  final String label;
  final String detail;
  final bool isKeyEvidence;
  final String? pointsToSuspectId;
  final String? irrelevantReason;
  final String? sender;
  final bool isSuspectMessage;
  final FileMetadata? metadata;
  final List<EvidenceRow> rows;
  final bool isHidden;
  final String? unlockedByMinigameId;
  final Map<String, double> suspicionEffects;

  const EvidenceItem({
    required this.id,
    required this.label,
    required this.detail,
    this.isKeyEvidence = false,
    this.pointsToSuspectId,
    this.irrelevantReason,
    this.sender,
    this.isSuspectMessage = false,
    this.metadata,
    this.rows = const [],
    this.isHidden = false,
    this.unlockedByMinigameId,
    this.suspicionEffects = const {},
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json,
      {bool isHidden = false}) {
    return EvidenceItem(
      id: json['id'] as String,
      label: json['label'] as String,
      detail: json['detail'] as String,
      isKeyEvidence: json['isKeyEvidence'] as bool? ?? false,
      pointsToSuspectId: json['pointsToSuspect'] as String?,
      irrelevantReason: json['irrelevantReason'] as String?,
      sender: json['sender'] as String?,
      isSuspectMessage: json['isSuspect'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? FileMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((r) => EvidenceRow.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      isHidden: isHidden,
      unlockedByMinigameId: json['unlockedByMinigame'] as String?,
      suspicionEffects: (json['suspicionEffects'] is Map)
          ? Map<String, dynamic>.from(json['suspicionEffects'] as Map)
          .map((k, v) => MapEntry(k, (v as num).toDouble()))
          : const {},
    );
  }
}

class EvidencePanel {
  final String id;
  final String label;
  final String iconName;
  final String evidenceType;
  final String? unlockedBy;
  final List<EvidenceItem> items;
  final EvidenceItem? hiddenItem;
  final MinigameConfig? minigame;

  const EvidencePanel({
    required this.id,
    required this.label,
    required this.iconName,
    required this.evidenceType,
    this.unlockedBy,
    required this.items,
    this.hiddenItem,
    this.minigame,
  });

  factory EvidencePanel.fromJson(Map<String, dynamic> json) {
    final hiddenJson = json['hiddenItem'] as Map<String, dynamic>?;
    final minigameJson = json['minigame'] as Map<String, dynamic>?;
    return EvidencePanel(
      id: json['id'] as String,
      label: json['label'] as String,
      iconName: json['icon'] as String,
      evidenceType: json['evidenceType'] as String,
      unlockedBy: json['unlockedBy'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((i) => EvidenceItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      hiddenItem: hiddenJson != null
          ? EvidenceItem.fromJson(hiddenJson, isHidden: true)
          : null,
      minigame: minigameJson != null
          ? MinigameConfig.fromJson(minigameJson)
          : null,
    );
  }
}