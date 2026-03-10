// lib/models/evidence.dart

/// A single row inside a metadata/IP evidence item (key-value pair).
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

/// Metadata attached to a file evidence item.
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

/// Configuration for the Caesar-cipher (or future) mini-game
/// embedded inside an evidence panel.
class MinigameConfig {
  final String id;
  final String type; // e.g. 'caesar_cipher', 'timeline_sort', 'route_trace'
  final String title;

  // caesar_cipher specific
  final String? cipherText;
  final String? solution;
  final int maxHints;
  final List<String> hints;
  final String? hint; // short hint shown below the cipher

  // What happens on success
  final String? unlocksHiddenItemId;
  final String? successMessage;

  const MinigameConfig({
    required this.id,
    required this.type,
    required this.title,
    this.cipherText,
    this.solution,
    this.maxHints = 3,
    this.hints = const [],
    this.hint,
    this.unlocksHiddenItemId,
    this.successMessage,
  });

  factory MinigameConfig.fromJson(Map<String, dynamic> json) {
    final onSuccess = json['onSuccess'] as Map<String, dynamic>?;
    return MinigameConfig(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      cipherText: json['cipherText'] as String?,
      solution: json['solution'] as String?,
      maxHints: json['maxHints'] as int? ?? 3,
      hints: (json['hints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      hint: json['hint'] as String?,
      unlocksHiddenItemId: onSuccess?['unlocksHiddenItem'] as String?,
      successMessage: onSuccess?['message'] as String?,
    );
  }
}

/// A single evidence item (chat message, file, metadata row, IP entry).
class EvidenceItem {
  final String id;
  final String label;
  final String detail;
  final bool isKeyEvidence;
  final String? pointsToSuspectId;

  /// Shown in the Case Analysis screen when this item is NOT key evidence.
  /// Explains why the player's intuition was off, or why it's a red herring.
  final String? irrelevantReason;

  // chat-specific
  final String? sender;
  final bool isSuspectMessage;

  // file-specific
  final FileMetadata? metadata;

  // metadata/ip-specific – ordered key-value rows
  final List<EvidenceRow> rows;

  // Whether this item is hidden behind a mini-game unlock
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

/// A panel grouping evidence items of one type (chat / files / meta / ip).
class EvidencePanel {
  final String id;
  final String label;
  final String iconName; // maps to IconData in UI
  final String evidenceType;
  final String? unlockedBy; // panel id that must be completed first, or null
  final List<EvidenceItem> items;
  final EvidenceItem? hiddenItem; // unlocked via mini-game
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