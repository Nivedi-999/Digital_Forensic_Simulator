import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Simple terminal logger — uses dart:developer so output appears in the
// Flutter / Dart DevTools console and in `flutter run` terminal output.
// All messages are prefixed with [ProgressService] for easy filtering.
// ---------------------------------------------------------------------------


void _log(String msg) => print('[ProgressService] $msg');
void _logOk(String msg) => print('[ProgressService] ✅ $msg');
void _logErr(String msg, Object error) => print('[ProgressService] ❌ $msg | error: $error');
void _logWarn(String msg) => print('[ProgressService] ⚠️  $msg');

/// Represents a single case's progress record.
class CaseProgress {
  final String caseId;
  final bool completed;
  final int score;       // stars earned (0–3)
  final int attempts;
  final DateTime? completedAt;

  const CaseProgress({
    required this.caseId,
    required this.completed,
    required this.score,
    required this.attempts,
    this.completedAt,
  });

  CaseProgress copyWith({
    bool? completed,
    int? score,
    int? attempts,
    DateTime? completedAt,
  }) =>
      CaseProgress(
        caseId: caseId,
        completed: completed ?? this.completed,
        score: score ?? this.score,
        attempts: attempts ?? this.attempts,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toMap() => {
    'completed': completed,
    'score': score,
    'attempts': attempts,
    'completedAt':
    completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };

  factory CaseProgress.fromMap(String caseId, Map<String, dynamic> map) =>
      CaseProgress(
        caseId: caseId,
        completed: map['completed'] as bool? ?? false,
        score: map['score'] as int? ?? 0,
        attempts: map['attempts'] as int? ?? 0,
        completedAt: map['completedAt'] != null
            ? (map['completedAt'] as Timestamp).toDate()
            : null,
      );

  /// Flat key used in SharedPreferences: e.g. "case_1001_completed"
  static String _prefKey(String caseId, String field) =>
      'case_${caseId}_$field';

  Future<void> saveLocal(SharedPreferences prefs) async {
    await prefs.setBool(_prefKey(caseId, 'completed'), completed);
    await prefs.setInt(_prefKey(caseId, 'score'), score);
    await prefs.setInt(_prefKey(caseId, 'attempts'), attempts);
    if (completedAt != null) {
      await prefs.setString(
          _prefKey(caseId, 'completedAt'), completedAt!.toIso8601String());
    }
  }

  static CaseProgress loadLocal(String caseId, SharedPreferences prefs) =>
      CaseProgress(
        caseId: caseId,
        completed: prefs.getBool(_prefKey(caseId, 'completed')) ?? false,
        score: prefs.getInt(_prefKey(caseId, 'score')) ?? 0,
        attempts: prefs.getInt(_prefKey(caseId, 'attempts')) ?? 0,
        completedAt: prefs.getString(_prefKey(caseId, 'completedAt')) != null
            ? DateTime.tryParse(
            prefs.getString(_prefKey(caseId, 'completedAt'))!)
            : null,
      );
}

/// Aggregated stats stored at users/{uid}/stats
class PlayerStats {
  final int totalCompleted;
  final int easyCompleted;
  final int mediumCompleted;
  final int hardCompleted;
  final int advancedCompleted;
  final int totalStars;

  const PlayerStats({
    this.totalCompleted = 0,
    this.easyCompleted = 0,
    this.mediumCompleted = 0,
    this.hardCompleted = 0,
    this.advancedCompleted = 0,
    this.totalStars = 0,
  });

  Map<String, dynamic> toMap() => {
    'totalCompleted': totalCompleted,
    'easyCompleted': easyCompleted,
    'mediumCompleted': mediumCompleted,
    'hardCompleted': hardCompleted,
    'advancedCompleted': advancedCompleted,
    'totalStars': totalStars,
  };

  factory PlayerStats.fromMap(Map<String, dynamic> map) => PlayerStats(
    totalCompleted: map['totalCompleted'] as int? ?? 0,
    easyCompleted: map['easyCompleted'] as int? ?? 0,
    mediumCompleted: map['mediumCompleted'] as int? ?? 0,
    hardCompleted: map['hardCompleted'] as int? ?? 0,
    advancedCompleted: map['advancedCompleted'] as int? ?? 0,
    totalStars: map['totalStars'] as int? ?? 0,
  );
}

// ---------------------------------------------------------------------------
// Case ID → difficulty band mapping
// ---------------------------------------------------------------------------
enum Difficulty { easy, medium, hard, advanced }

Difficulty _difficultyOf(String caseId) {
  final id = int.tryParse(caseId) ?? 0;
  if (id >= 1000 && id < 2000) return Difficulty.easy;
  if (id >= 2000 && id < 3000) return Difficulty.medium;
  if (id >= 3000 && id < 4000) return Difficulty.hard;
  return Difficulty.advanced;
}

// ---------------------------------------------------------------------------
// ProgressService
// ---------------------------------------------------------------------------

/// Central service for reading and writing case progress.
///
/// Strategy:
///   • All writes go to SharedPreferences first (instant, offline-safe).
///   • If the user is signed in, writes are also mirrored to Firestore.
///   • On app start, [init] loads local cache then tries to reconcile with
///     Firestore (remote wins on conflict so a user's cloud data is restored
///     when they reinstall or switch devices).
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SharedPreferences? _prefs;

  // In-memory cache: caseId → CaseProgress
  final Map<String, CaseProgress> _cache = {};

  PlayerStats _stats = const PlayerStats();
  PlayerStats get stats => _stats;

  String? get _uid => _auth.currentUser?.uid;

  // Firestore collection references
  CollectionReference<Map<String, dynamic>>? get _progressCol => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('progress');

  DocumentReference<Map<String, dynamic>>? get _statsDoc => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('stats').doc('summary');

  DocumentReference<Map<String, dynamic>>? get _profileDoc => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('profile').doc('info');

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  /// Call once in main() or in your root widget's initState.
  /// Loads local cache, then reconciles with Firestore if signed in.
  Future<void> init() async {
    _log('Initialising...');
    _prefs = await SharedPreferences.getInstance();
    _loadAllLocal();

    if (_uid != null) {
      _log('User signed in (uid: $_uid) — reconciling with Firestore...');
      await _reconcileWithFirestore();
    } else {
      _logWarn('No signed-in user — running in local-only mode.');
    }

    // Re-sync whenever auth state changes (sign-in / sign-out)
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _log('Auth state changed — user signed in (uid: ${user.uid}). Reconciling...');
        await _reconcileWithFirestore();
      } else {
        _logWarn('Auth state changed — user signed out. Firestore sync disabled.');
      }
    });
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns the progress for a specific case (from in-memory cache).
  CaseProgress getCase(String caseId) =>
      _cache[caseId] ??
          CaseProgress(caseId: caseId, completed: false, score: 0, attempts: 0);

  /// Returns true if the case has been completed at least once.
  bool isCompleted(String caseId) => getCase(caseId).completed;

  /// Records a case attempt. Call this when the player submits a verdict.
  ///
  /// [score] is the star rating (0–3).
  /// [solved] is whether the player chose the correct verdict.
  Future<void> recordAttempt({
    required String caseId,
    required int score,
    required bool solved,
  }) async {
    final existing = getCase(caseId);
    final updated = existing.copyWith(
      completed: existing.completed || solved,
      score: score > existing.score ? score : existing.score,
      attempts: existing.attempts + 1,
      completedAt: solved && existing.completedAt == null
          ? DateTime.now()
          : existing.completedAt,
    );

    final difficulty = _difficultyOf(caseId).name.toUpperCase();
    _log('Recording attempt — case: $caseId ($difficulty) | '
        'solved: $solved | score: $score★ | attempt #${updated.attempts}');

    // 1. Update in-memory cache
    _cache[caseId] = updated;

    // 2. Save locally (always works offline)
    await updated.saveLocal(_prefs!);
    _log('Case $caseId saved to SharedPreferences.');

    // 3. Recompute stats
    _recomputeStats();
    await _saveStatsLocal();

    // 4. Mirror to Firestore if online & signed in
    if (_uid != null) {
      await _writeCaseToFirestore(updated);
      await _writeStatsToFirestore();
    } else {
      _logWarn('Case $caseId NOT synced to Firestore — no signed-in user.');
    }
  }

  /// Saves the player's chosen avatar locally and to Firestore.
  Future<void> saveAvatar(String avatarKey) async {
    await _prefs!.setString('player_avatar', avatarKey);
    if (_uid != null) {
      try {
        await _profileDoc?.set({'avatar': avatarKey}, SetOptions(merge: true));
        _logOk('Avatar "$avatarKey" saved to Firestore (uid: $_uid).');
      } catch (e) {
        _logErr('Failed to save avatar to Firestore.', e);
      }
    } else {
      _logWarn('Avatar saved locally only — no signed-in user.');
    }
  }

  String get savedAvatar => _prefs?.getString('player_avatar') ?? 'default';

  /// Saves the player's display name.
  Future<void> saveDisplayName(String name) async {
    await _prefs!.setString('player_name', name);
    if (_uid != null) {
      try {
        await _profileDoc?.set({'displayName': name}, SetOptions(merge: true));
        _logOk('Display name "$name" saved to Firestore (uid: $_uid).');
      } catch (e) {
        _logErr('Failed to save display name to Firestore.', e);
      }
    } else {
      _logWarn('Display name saved locally only — no signed-in user.');
    }
  }

  String get savedDisplayName => _prefs?.getString('player_name') ?? 'Agent';

  /// Wipes all local progress. Does NOT delete Firestore data.
  Future<void> clearLocalProgress() async {
    _log('Clearing all local progress from SharedPreferences...');
    _cache.clear();
    final keys = _prefs!.getKeys().where((k) => k.startsWith('case_'));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    _stats = const PlayerStats();
    _logOk('Local progress cleared.');
  }

  // -------------------------------------------------------------------------
  // Local helpers
  // -------------------------------------------------------------------------

  void _loadAllLocal() {
    const allCaseIds = [
      // Easy
      '1001', '1002', '1003', '1004', '1005', '1006', '1007', '1008',
      // Medium
      '2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009',
      // Hard
      '3001', '3002', '3003', '3004', '3005', '3006', '3007',
      // Advanced
      '4001', '4002', '4003', '4004', '4005', '4006', '4007',
    ];

    for (final id in allCaseIds) {
      _cache[id] = CaseProgress.loadLocal(id, _prefs!);
    }

    _recomputeStats();

    final completedCount = _cache.values.where((p) => p.completed).length;
    _logOk('Local cache loaded — $completedCount / ${allCaseIds.length} cases completed.');
  }

  void _recomputeStats() {
    int total = 0, easy = 0, medium = 0, hard = 0, advanced = 0, stars = 0;
    for (final p in _cache.values) {
      if (p.completed) {
        total++;
        stars += p.score;
        switch (_difficultyOf(p.caseId)) {
          case Difficulty.easy:
            easy++;
            break;
          case Difficulty.medium:
            medium++;
            break;
          case Difficulty.hard:
            hard++;
            break;
          case Difficulty.advanced:
            advanced++;
            break;
        }
      }
    }
    _stats = PlayerStats(
      totalCompleted: total,
      easyCompleted: easy,
      mediumCompleted: medium,
      hardCompleted: hard,
      advancedCompleted: advanced,
      totalStars: stars,
    );
  }

  Future<void> _saveStatsLocal() async {
    await _prefs!.setInt('stats_totalCompleted', _stats.totalCompleted);
    await _prefs!.setInt('stats_easyCompleted', _stats.easyCompleted);
    await _prefs!.setInt('stats_mediumCompleted', _stats.mediumCompleted);
    await _prefs!.setInt('stats_hardCompleted', _stats.hardCompleted);
    await _prefs!.setInt('stats_advancedCompleted', _stats.advancedCompleted);
    await _prefs!.setInt('stats_totalStars', _stats.totalStars);
  }

  // -------------------------------------------------------------------------
  // Firestore helpers
  // -------------------------------------------------------------------------

  Future<void> _writeCaseToFirestore(CaseProgress p) async {
    final path = 'users/$_uid/progress/${p.caseId}';
    _log('Writing case ${p.caseId} to Firestore → $path ...');
    try {
      await _progressCol!.doc(p.caseId).set(p.toMap(), SetOptions(merge: true));
      _logOk('Case ${p.caseId} logged to Firestore '
          '(completed: ${p.completed} | score: ${p.score}★ | attempts: ${p.attempts}).');
    } catch (e) {
      _logErr('Failed to write case ${p.caseId} to Firestore. '
          'Progress is saved locally and will NOT be retried automatically.', e);
    }
  }

  Future<void> _writeStatsToFirestore() async {
    final path = 'users/$_uid/stats/summary';
    _log('Writing stats to Firestore → $path ...');
    try {
      await _statsDoc!.set(_stats.toMap(), SetOptions(merge: true));
      _logOk('Stats logged to Firestore '
          '(total: ${_stats.totalCompleted} | stars: ${_stats.totalStars}).');
    } catch (e) {
      _logErr('Failed to write stats to Firestore.', e);
    }
  }

  /// Pulls Firestore data and merges into local cache.
  /// Remote data wins only if the remote score is higher or the case is
  /// completed remotely but not locally (covers reinstall / new device).
  Future<void> _reconcileWithFirestore() async {
    _log('Starting Firestore reconciliation for uid: $_uid ...');
    try {
      final snapshot = await _progressCol!.get();
      _log('Fetched ${snapshot.docs.length} remote case(s) from Firestore.');

      int mergedCount = 0;
      for (final doc in snapshot.docs) {
        final remote = CaseProgress.fromMap(doc.id, doc.data());
        final local = _cache[doc.id] ??
            CaseProgress(caseId: doc.id, completed: false, score: 0, attempts: 0);

        final merged = local.copyWith(
          completed: local.completed || remote.completed,
          score: remote.score > local.score ? remote.score : local.score,
          attempts: remote.attempts > local.attempts ? remote.attempts : local.attempts,
          completedAt: local.completedAt ?? remote.completedAt,
        );

        if (merged.score != local.score ||
            merged.completed != local.completed ||
            merged.attempts != local.attempts) {
          _log('Case ${doc.id} updated from Firestore '
              '(score: ${local.score}→${merged.score}★ | '
              'completed: ${local.completed}→${merged.completed}).');
          mergedCount++;
        }

        _cache[doc.id] = merged;
        await merged.saveLocal(_prefs!);
      }

      _recomputeStats();
      await _saveStatsLocal();
      _logOk('Reconciliation complete — $mergedCount case(s) updated from Firestore.');
    } catch (e) {
      _logErr('Firestore reconciliation failed. Falling back to local data.', e);
    }
  }
}