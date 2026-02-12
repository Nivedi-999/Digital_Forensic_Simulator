// lib/services/evidence_collector.dart
class EvidenceCollector
{
  static final EvidenceCollector _instance = EvidenceCollector._internal();

  factory EvidenceCollector() => _instance;

  EvidenceCollector._internal();

  final List<Map<String, String>> _collected = [];

  List<Map<String, String>> get collected => List.unmodifiable(_collected);

  void addEvidence(String category, String itemName) {
    // Avoid duplicates
    final exists = _collected.any(
          (e) => e['category'] == category && e['item'] == itemName,
    );
    if (!exists) {
      _collected.add({
        'category': category,
        'item': itemName,
        'addedAt': DateTime.now().toString().substring(0, 19), // rough timestamp
      });
    }
  }

  void clearAll() {
    _collected.clear();
  }

  // Inside class EvidenceCollector

  void removeEvidence(String category, String itemName) {
    _collected.removeWhere(
          (e) => e['category'] == category && e['item'] == itemName,
    );
  }
}