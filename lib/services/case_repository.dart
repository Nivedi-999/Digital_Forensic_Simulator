// lib/services/case_repository.dart
//
// Loads CaseFile objects from bundled JSON assets.
// Add new cases by dropping a JSON file in assets/cases/
// and registering its path in _casePaths below.

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/case.dart';

class CaseRepository {
  CaseRepository._();
  static final CaseRepository instance = CaseRepository._();

  // ── Register all case asset paths here ──────────────────
  static const List<String> _casePaths = [
    'assets/cases/case_ghosttrace.json',
    // 'assets/cases/case_deaddropsignal.json',
    // 'assets/cases/case_echoesoftomorrow.json',
  ];

  // ── In-memory cache ──────────────────────────────────────
  final Map<String, CaseFile> _cache = {};
  bool _loaded = false;

  /// Load all registered cases from assets. Safe to call multiple times.
  Future<void> loadAll() async {
    if (_loaded) return;
    for (final path in _casePaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final caseFile = CaseFile.fromJson(json);
        _cache[caseFile.id] = caseFile;
      } catch (e) {
        // Log and skip malformed files so a bad JSON never crashes the app
        assert(() {
          // ignore: avoid_print
          print('[CaseRepository] Failed to load $path: $e');
          return true;
        }());
      }
    }
    _loaded = true;
  }

  /// All loaded cases in registration order.
  List<CaseFile> get all => _casePaths
      .map((p) {
    // derive id from filename: assets/cases/case_ghosttrace.json → case_ghosttrace
    final name =
    p.split('/').last.replaceAll('.json', '');
    return _cache[name];
  })
      .whereType<CaseFile>()
      .toList();

  /// Look up a case by its id field (e.g. 'case_ghosttrace').
  CaseFile? byId(String id) => _cache[id];

  /// Convenience — returns the first case; useful while only one exists.
  CaseFile? get first => _cache.values.isNotEmpty ? _cache.values.first : null;
}