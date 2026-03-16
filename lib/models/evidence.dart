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

/// Minigame config — supports all 4 types:
///   caesar_cipher    — Easy
///   ip_trace         — Medium  (find IP from list)
///   code_crack       — Hard    (3-reel alphanumeric)
///   phishing_analysis — Advanced (report or delete email)
class MinigameConfig {
  final String id;
  final String type;
  final String title;
  final int maxHints;
  final List<String> hints;
  final String? hint;
  final String? unlocksHiddenItemId;
  final String? successMessage;

  // caesar_cipher
  final String? cipherText;
  final String? solution;

  // ip_trace
  final List<String> decoys; // list of IP addresses including the correct one

  // code_crack
  // uses solution field (3-char code e.g. "4F7")

  // phishing_analysis
  final String? emailFrom;
  final String? emailSubject;
  final String? emailBody;
  final List<String> redFlags;
  final String? correctAction; // 'report' | 'delete'

  const MinigameConfig({
    required this.id,
    required this.type,
    required this.title,
    this.maxHints = 3,
    this.hints = const [],
    this.hint,
    this.unlocksHiddenItemId,
    this.successMessage,
    this.cipherText,
    this.solution,
    this.decoys = const [],
    this.emailFrom,
    this.emailSubject,
    this.emailBody,
    this.redFlags = const [],
    this.correctAction,
  });

  factory MinigameConfig.fromJson(Map<String, dynamic> json) {
    final onSuccess = json['onSuccess'] as Map<String, dynamic>?;
    return MinigameConfig(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      maxHints: json['maxHints'] as int? ?? 3,
      hints: (json['hints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      hint: json['hint'] as String?,
      unlocksHiddenItemId: onSuccess?['unlocksHiddenItem'] as String?,
      successMessage: onSuccess?['message'] as String?,
      cipherText: json['cipherText'] as String?,
      solution: json['solution'] as String?,
      decoys: (json['decoys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      emailFrom: json['emailFrom'] as String?,
      emailSubject: json['emailSubject'] as String?,
      emailBody: json['emailBody'] as String?,
      redFlags: (json['redFlags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      correctAction: json['correctAction'] as String?,
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
          .toList() ??
          [],
      isHidden: isHidden,
      unlockedByMinigameId: json['unlockedByMinigame'] as String?,
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