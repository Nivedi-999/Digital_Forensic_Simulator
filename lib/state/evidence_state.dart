// lib/state/evidence_state.dart
import 'package:flutter/material.dart';

class EvidenceMark {
  final String category; // 'chat', 'files', 'meta', 'ip'
  final String itemName; // e.g. 'finance_report_q3.pdf' or 'Origin IP'
  final bool isRelevant;

  EvidenceMark({
    required this.category,
    required this.itemName,
    required this.isRelevant,
  });
}

class EvidenceState extends ChangeNotifier {
  final List<EvidenceMark> _markedEvidence = [];

  List<EvidenceMark> get markedEvidence => _markedEvidence;

  void markEvidence(String category, String itemName, bool relevant) {
    // Remove old mark for same item if exists
    _markedEvidence.removeWhere((e) =>
    e.category == category && e.itemName == itemName);

    _markedEvidence.add(EvidenceMark(
      category: category,
      itemName: itemName,
      isRelevant: relevant,
    ));

    notifyListeners();
  }

  List<EvidenceMark> get relevantItems =>
      _markedEvidence.where((e) => e.isRelevant).toList();
}