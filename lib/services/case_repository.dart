// lib/services/case_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/case.dart';

class CaseRepository {
  CaseRepository._();
  static final CaseRepository instance = CaseRepository._();

  static const List<String> _casePaths = [
    // ── EASY ──────────────────────────────────────────────
    'assets/cases/case_passwordheist.json',
    'assets/cases/case_wifithief.json',
    'assets/cases/case_fakereview.json',
    'assets/cases/case_ghosttrace.json',
    'assets/cases/case_jobscam.json',
    'assets/cases/case_vanishing_report.json',
    'assets/cases/case_leaked_roster.json',
    'assets/cases/case_altered_image.json',

    // ── MEDIUM ────────────────────────────────────────────
    'assets/cases/case_phantomtransaction.json',
    'assets/cases/case_attendancehack.json',
    'assets/cases/case_socialengineer.json',
    'assets/cases/case_lastlogin.json',
    'assets/cases/case_clouddrain.json',
    'assets/cases/case_missing_logs.json',
    'assets/cases/case_cloned_credential.json',
    'assets/cases/case_midnight_timeline.json',

    // ── HARD ──────────────────────────────────────────────
    'assets/cases/case_deaddrop.json',
    'assets/cases/case_echoesoftomorrow.json',
    'assets/cases/case_echowithoutavoice.json',
    'assets/cases/case_darkproxyattack.json',
    'assets/cases/case_poisonedpatch.json',
    'assets/cases/case_unknown_usb.json',
    'assets/cases/case_borrowed_badge.json',

    // ── ADVANCED ──────────────────────────────────────────
    'assets/cases/case_vanishingvault.json',
    'assets/cases/case_mirrorprotocol.json',
    'assets/cases/case_zeropointentry.json',
    'assets/cases/case_ghostnetwork.json',
    'assets/cases/case_doubleagent.json',
    'assets/cases/case_phantom_process.json',
    'assets/cases/case_double_identity.json',
  ];

  // Key: JSON id field (e.g. "case_ghosttrace"), Value: loaded CaseFile
  final Map<String, CaseFile> _cache = {};

  // Preserves the original registration order for cases that loaded successfully
  final List<String> _loadedIds = [];

  bool _loaded = false;

  static String _keyFromPath(String path) =>
      path.split('/').last.replaceAll('.json', '');

  Future<List<String>> _discoverCasePathsFromAssetManifest() async {
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is! Map<String, dynamic>) return const [];

      final discovered = decoded.keys
          .where((p) => p.startsWith('assets/cases/') && p.endsWith('.json'))
          .toSet()
          .toList()
        ..sort();
      return discovered;
    } catch (_) {
      return const [];
    }
  }

  Future<void> loadAll() async {
    if (_loaded) return;
    _cache.clear();
    _loadedIds.clear();

    final discoveredPaths = await _discoverCasePathsFromAssetManifest();
    final pathsToLoad = [..._casePaths];
    for (final path in discoveredPaths) {
      if (!pathsToLoad.contains(path)) {
        pathsToLoad.add(path);
      }
    }

    for (final path in pathsToLoad) {
      final key = _keyFromPath(path);
      try {
        final raw = await rootBundle.loadString(path);
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final caseFile = CaseFile.fromJson(jsonMap);
        _cache[caseFile.id] = caseFile;
        _loadedIds.add(caseFile.id);
      } catch (e) {
        // Print a clear error so the developer knows which file is missing
        // ignore: avoid_print
        print('[CaseRepository] ⚠️  Failed to load "$path": $e');
      }
    }

    _loaded = true;

    // Summary log so it is easy to spot missing cases
    // ignore: avoid_print
    print('[CaseRepository] Loaded ${_cache.length}/${pathsToLoad.length} cases.');
  }

  /// All loaded cases in registration order.
  List<CaseFile> get all => _loadedIds
      .map((id) => _cache[id])
      .whereType<CaseFile>()
      .toList();

  /// Filter by difficulty tier, in registration order.
  List<CaseFile> byDifficulty(String difficulty) =>
      all.where((c) => c.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();

  /// Look up by the JSON id field (e.g. 'case_ghosttrace').
  CaseFile? byId(String id) => _cache[id];

  /// First loaded case — used by StorylineScreen when no caseId is passed.
  CaseFile? get first => all.isNotEmpty ? all.first : null;
}