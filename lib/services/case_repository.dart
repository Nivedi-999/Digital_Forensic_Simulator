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
    'assets/cases/case_leaked_roster.json',       // replaces case_lost_usb
    'assets/cases/case_altered_image.json',

    // ── MEDIUM ────────────────────────────────────────────
    'assets/cases/case_phantomtransaction.json',
    'assets/cases/case_attendancehack.json',
    'assets/cases/case_socialengineer.json',
    'assets/cases/case_lastlogin.json',
    'assets/cases/case_clouddrain.json',
    'assets/cases/case_missing_logs.json',
    'assets/cases/case_cloned_credential.json',   // replaces case_deleted_documents
    'assets/cases/case_midnight_timeline.json',

    // ── HARD ──────────────────────────────────────────────
    'assets/cases/case_deaddrop.json',
    'assets/cases/case_echoesoftomorrow.json',
    'assets/cases/case_echowithoutavoice.json',
    'assets/cases/case_darkproxyattack.json',
    'assets/cases/case_poisonedpatch.json',
    'assets/cases/case_unknown_usb.json',
    'assets/cases/case_borrowed_badge.json',      // replaces case_disguised_file

    // ── ADVANCED ──────────────────────────────────────────
    'assets/cases/case_vanishingvault.json',
    'assets/cases/case_mirrorprotocol.json',
    'assets/cases/case_zeropointentry.json',
    'assets/cases/case_ghostnetwork.json',
    'assets/cases/case_doubleagent.json',
    'assets/cases/case_phantom_process.json',
    'assets/cases/case_double_identity.json',
  ];

  // Key: filename stem (e.g. "case_ghosttrace"), Value: loaded CaseFile
  final Map<String, CaseFile> _cache = {};
  bool _loaded = false;

  static String _keyFromPath(String path) =>
      path.split('/').last.replaceAll('.json', '');

  Future<void> loadAll() async {
    if (_loaded) return;
    for (final path in _casePaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        final caseFile = CaseFile.fromJson(jsonMap);
        _cache[_keyFromPath(path)] = caseFile;
      } catch (e) {
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
      .map((p) => _cache[_keyFromPath(p)])
      .whereType<CaseFile>()
      .toList();

  /// Filter by difficulty tier.
  List<CaseFile> byDifficulty(String difficulty) =>
      all.where((c) => c.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();

  /// Look up by filename stem (e.g. 'case_ghosttrace').
  CaseFile? byId(String id) => _cache[id];

  /// First loaded case — used by StorylineScreen when no caseId is passed.
  CaseFile? get first => all.isNotEmpty ? all.first : null;
}