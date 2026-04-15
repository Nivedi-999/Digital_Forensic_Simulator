// lib/services/progress_service.dart
// ═══════════════════════════════════════════════════════════════
//  PROGRESS SERVICE — local + Firestore progress tracking
//  v2: adds timeTakenSeconds to CaseProgress and writes to
//      top-level leaderboard/{caseId}/scores/{uid} on win.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_progress.dart';

void _log(String msg)              => print('[ProgressService] $msg');
void _logOk(String msg)            => print('[ProgressService] ✅ $msg');
void _logErr(String msg, Object e) => print('[ProgressService] ❌ $msg | error: $e');
void _logWarn(String msg)          => print('[ProgressService] ⚠️  $msg');

// ─────────────────────────────────────────────────────────────
//  CaseProgress model
// ─────────────────────────────────────────────────────────────

class CaseProgress {
  final String caseId;
  final bool completed;
  final int score;            // stars earned (0–3)
  final int attempts;
  final DateTime? completedAt;

  /// Best (fastest) solve time in seconds. null = never solved.
  final int? timeTakenSeconds;

  const CaseProgress({
    required this.caseId,
    required this.completed,
    required this.score,
    required this.attempts,
    this.completedAt,
    this.timeTakenSeconds,
  });

  CaseProgress copyWith({
    bool? completed,
    int? score,
    int? attempts,
    DateTime? completedAt,
    int? timeTakenSeconds,
  }) =>
      CaseProgress(
        caseId: caseId,
        completed: completed ?? this.completed,
        score: score ?? this.score,
        attempts: attempts ?? this.attempts,
        completedAt: completedAt ?? this.completedAt,
        // Only update best time when a faster time is provided
        timeTakenSeconds: _bestTime(this.timeTakenSeconds, timeTakenSeconds),
      );

  /// Returns the smaller (faster) of two nullable times.
  static int? _bestTime(int? existing, int? incoming) {
    if (incoming == null) return existing;
    if (existing == null) return incoming;
    return incoming < existing ? incoming : existing;
  }

  Map<String, dynamic> toMap() => {
    'completed': completed,
    'score': score,
    'attempts': attempts,
    'completedAt':
    completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'timeTakenSeconds': timeTakenSeconds,
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
        timeTakenSeconds: map['timeTakenSeconds'] as int?,
      );

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
    if (timeTakenSeconds != null) {
      await prefs.setInt(_prefKey(caseId, 'timeTakenSeconds'), timeTakenSeconds!);
    }
  }

  static CaseProgress loadLocal(String caseId, SharedPreferences prefs) {
    final timeKey = _prefKey(caseId, 'timeTakenSeconds');
    return CaseProgress(
      caseId: caseId,
      completed: prefs.getBool(_prefKey(caseId, 'completed')) ?? false,
      score: prefs.getInt(_prefKey(caseId, 'score')) ?? 0,
      attempts: prefs.getInt(_prefKey(caseId, 'attempts')) ?? 0,
      completedAt: prefs.getString(_prefKey(caseId, 'completedAt')) != null
          ? DateTime.tryParse(prefs.getString(_prefKey(caseId, 'completedAt'))!)
          : null,
      timeTakenSeconds: prefs.containsKey(timeKey)
          ? prefs.getInt(timeKey)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PlayerStats model
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
//  Difficulty helper
// ─────────────────────────────────────────────────────────────

enum Difficulty { easy, medium, hard, advanced }

Difficulty _difficultyOf(String caseId) {
  final id = int.tryParse(caseId) ?? 0;
  if (id >= 1000 && id < 2000) return Difficulty.easy;
  if (id >= 2000 && id < 3000) return Difficulty.medium;
  if (id >= 3000 && id < 4000) return Difficulty.hard;
  return Difficulty.advanced;
}

// ─────────────────────────────────────────────────────────────
//  Leaderboard entry model (used by LeaderboardScreen)
// ─────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int timeTakenSeconds;
  final int score;          // stars
  final DateTime solvedAt;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.timeTakenSeconds,
    required this.score,
    required this.solvedAt,
  });

  factory LeaderboardEntry.fromDoc(String uid, Map<String, dynamic> data) =>
      LeaderboardEntry(
        uid: uid,
        displayName: data['displayName'] as String? ?? 'Agent',
        timeTakenSeconds: data['timeTakenSeconds'] as int? ?? 999999,
        score: data['score'] as int? ?? 0,
        solvedAt: data['solvedAt'] != null
            ? (data['solvedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  String get formattedTime {
    final m = timeTakenSeconds ~/ 60;
    final s = timeTakenSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────
//  ProgressService
// ─────────────────────────────────────────────────────────────

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  SharedPreferences? _prefs;

  final Map<String, CaseProgress> _cache = {};

  PlayerStats _stats = const PlayerStats();
  PlayerStats get stats => _stats;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _progressCol => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('progress');

  DocumentReference<Map<String, dynamic>>? get _statsDoc => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('stats').doc('summary');

  DocumentReference<Map<String, dynamic>>? get _profileDoc => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('profile').doc('info');

  // ── Leaderboard collection reference ───────────────────────
  // Path: leaderboard/{caseId}/scores/{uid}
  CollectionReference<Map<String, dynamic>> _leaderboardScores(String caseId) =>
      _db.collection('leaderboard').doc(caseId).collection('scores');

  // ── Real-time stream for a case's leaderboard ──────────────
  /// Returns a live stream of the top 100 entries, sorted fastest-first.
  Stream<List<LeaderboardEntry>> leaderboardStream(String caseId) =>
      _leaderboardScores(caseId)
          .orderBy('timeTakenSeconds')
          .limit(100)
          .snapshots()
          .map((snap) => snap.docs
          .map((doc) => LeaderboardEntry.fromDoc(doc.id, doc.data()))
          .toList());

  // ── Init ───────────────────────────────────────────────────

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

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _log('Auth changed — user signed in (uid: ${user.uid}). Reconciling...');
        await _reconcileWithFirestore();
      } else {
        _logWarn('Auth changed — signed out. Firestore sync disabled.');
      }
    });
  }

  // ── Public API ─────────────────────────────────────────────

  CaseProgress getCase(String caseId) =>
      _cache[caseId] ??
          CaseProgress(caseId: caseId, completed: false, score: 0, attempts: 0);

  bool isCompleted(String caseId) => getCase(caseId).completed;

  /// Records a case attempt.
  ///
  /// [timeTakenSeconds] — elapsed wall-clock seconds for this solve.
  ///   Pass null for failed/cold-case attempts.
  Future<void> recordAttempt({
    required String caseId,
    required int score,
    required bool solved,
    int? timeTakenSeconds,
  }) async {
    final existing = getCase(caseId);
    final updated = existing.copyWith(
      completed: existing.completed || solved,
      score: score > existing.score ? score : existing.score,
      attempts: existing.attempts + 1,
      completedAt: solved && existing.completedAt == null
          ? DateTime.now()
          : existing.completedAt,
      // copyWith internally picks the faster time
      timeTakenSeconds: solved ? timeTakenSeconds : null,
    );


    final difficulty = _difficultyOf(caseId).name.toUpperCase();
    final timeStr = timeTakenSeconds != null ? '${timeTakenSeconds}s' : 'n/a';
    _log('Recording attempt — case: $caseId ($difficulty) | '
        'solved: $solved | score: $score★ | time: $timeStr | '
        'attempt #${updated.attempts}');

    _cache[caseId] = updated;
    await updated.saveLocal(_prefs!);
    _log('Case $caseId saved to SharedPreferences.');

    _recomputeStats();
    await _saveStatsLocal();

    if (_uid != null) {
      await _writeCaseToFirestore(updated);
      await _writeStatsToFirestore();

      // Push to leaderboard only on a win with a timed result
      if (solved && timeTakenSeconds != null) {
        await _updateLeaderboard(
          caseId: caseId,
          timeTakenSeconds: timeTakenSeconds,
          score: updated.score,
        );
      }
    } else {
      _logWarn('Case $caseId NOT synced to Firestore — no signed-in user.');
    }
  }
  /// Expose completed case IDs for GameProgress restoration.
  Set<String> get completedCaseIds =>
      _cache.entries
          .where((e) => e.value.completed)
          .map((e) => e.key)
          .toSet();

  // ── Avatar / display name ──────────────────────────────────

  Future<void> saveAvatar(String avatarKey) async {
    await _prefs!.setString('player_avatar', avatarKey);
    if (_uid != null) {
      try {
        await _profileDoc?.set({'avatar': avatarKey}, SetOptions(merge: true));
        _logOk('Avatar "$avatarKey" saved to Firestore.');
      } catch (e) {
        _logErr('Failed to save avatar to Firestore.', e);
      }
    }
  }

  String get savedAvatar => _prefs?.getString('player_avatar') ?? 'default';

  Future<void> saveDisplayName(String name) async {
    await _prefs!.setString('player_name', name);
    if (_uid != null) {
      try {
        await _profileDoc?.set({'displayName': name}, SetOptions(merge: true));
        _logOk('Display name "$name" saved to Firestore.');
      } catch (e) {
        _logErr('Failed to save display name to Firestore.', e);
      }
    }
  }

  String get savedDisplayName => _prefs?.getString('player_name') ?? 'Agent';

  Future<void> clearLocalProgress() async {
    _log('Clearing all local progress...');
    _cache.clear();
    final keys = _prefs!.getKeys().where((k) => k.startsWith('case_'));
    for (final key in keys) await _prefs!.remove(key);
    _stats = const PlayerStats();
    _logOk('Local progress cleared.');
  }

  // ── Local helpers ──────────────────────────────────────────

  void _loadAllLocal() {
    const allCaseIds = [
      '1001', '1002', '1003', '1004', '1005', '1006', '1007', '1008',
      '2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009',
      '3001', '3002', '3003', '3004', '3005', '3006', '3007',
      '4001', '4002', '4003', '4004', '4005', '4006', '4007',
    ];
    for (final id in allCaseIds) {
      _cache[id] = CaseProgress.loadLocal(id, _prefs!);
    }
    _recomputeStats();
    final done = _cache.values.where((p) => p.completed).length;
    _logOk('Local cache loaded — $done / ${allCaseIds.length} cases completed.');
  }

  void _recomputeStats() {
    int total = 0, easy = 0, medium = 0, hard = 0, advanced = 0, stars = 0;
    for (final p in _cache.values) {
      if (p.completed) {
        total++;
        stars += p.score;
        switch (_difficultyOf(p.caseId)) {
          case Difficulty.easy:     easy++;     break;
          case Difficulty.medium:   medium++;   break;
          case Difficulty.hard:     hard++;     break;
          case Difficulty.advanced: advanced++; break;
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
    await _prefs!.setInt('stats_totalCompleted',    _stats.totalCompleted);
    await _prefs!.setInt('stats_easyCompleted',     _stats.easyCompleted);
    await _prefs!.setInt('stats_mediumCompleted',   _stats.mediumCompleted);
    await _prefs!.setInt('stats_hardCompleted',     _stats.hardCompleted);
    await _prefs!.setInt('stats_advancedCompleted', _stats.advancedCompleted);
    await _prefs!.setInt('stats_totalStars',        _stats.totalStars);
  }

  // ── Firestore helpers ──────────────────────────────────────

  Future<void> _writeCaseToFirestore(CaseProgress p) async {
    _log('Writing case ${p.caseId} to Firestore...');
    try {
      await _progressCol!.doc(p.caseId).set(p.toMap(), SetOptions(merge: true));
      _logOk('Case ${p.caseId} written '
          '(completed: ${p.completed} | score: ${p.score}★ | '
          'time: ${p.timeTakenSeconds ?? 'n/a'}s).');
    } catch (e) {
      _logErr('Failed to write case ${p.caseId} to Firestore.', e);
    }
  }

  Future<void> _writeStatsToFirestore() async {
    try {
      await _statsDoc!.set(_stats.toMap(), SetOptions(merge: true));
      _logOk('Stats written (total: ${_stats.totalCompleted} | '
          'stars: ${_stats.totalStars}).');
    } catch (e) {
      _logErr('Failed to write stats to Firestore.', e);
    }
  }

  /// Writes/updates the leaderboard entry for this user on this case.
  ///
  /// Only updates if this is a new personal best (faster time).
  /// Structure: leaderboard/{caseId}/scores/{uid}
  Future<void> _updateLeaderboard({
    required String caseId,
    required int timeTakenSeconds,
    required int score,
  }) async {
    if (_uid == null) return;

    final scoresCol = _leaderboardScores(caseId);
    final myDoc = scoresCol.doc(_uid);

    _log('Checking leaderboard for case $caseId (uid: $_uid)...');
    try {
      final existing = await myDoc.get();

      // If a faster personal best already exists, don't overwrite
      if (existing.exists) {
        final currentBest = existing.data()?['timeTakenSeconds'] as int? ?? 999999;
        if (timeTakenSeconds >= currentBest) {
          _log('Leaderboard not updated — existing best ${currentBest}s '
              'is faster than ${timeTakenSeconds}s.');
          return;
        }
      }

      final displayName = savedDisplayName;
      await myDoc.set({
        'displayName': displayName,
        'timeTakenSeconds': timeTakenSeconds,
        'score': score,
        'solvedAt': Timestamp.fromDate(DateTime.now()),
        'uid': _uid,
      });

      _logOk('Leaderboard updated — case $caseId | '
          'uid: $_uid | time: ${timeTakenSeconds}s | name: $displayName');
    } catch (e) {
      _logErr('Failed to update leaderboard for case $caseId.', e);
    }
  }

  Future<void> _reconcileWithFirestore() async {
    _log('Starting Firestore reconciliation for uid: $_uid...');
    try {
      final snapshot = await _progressCol!.get();
      _log('Fetched ${snapshot.docs.length} remote case(s).');

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
          // Take the faster time between local and remote
          timeTakenSeconds: CaseProgress._bestTime(
              local.timeTakenSeconds, remote.timeTakenSeconds),
        );

        if (merged.score != local.score ||
            merged.completed != local.completed ||
            merged.attempts != local.attempts ||
            merged.timeTakenSeconds != local.timeTakenSeconds) {
          _log('Case ${doc.id} updated from Firestore '
              '(score: ${local.score}→${merged.score}★ | '
              'time: ${local.timeTakenSeconds}→${merged.timeTakenSeconds}s).');
          mergedCount++;
        }

        _cache[doc.id] = merged;
        await merged.saveLocal(_prefs!);
      }

      _recomputeStats();
      await _saveStatsLocal();
      final completedIds = _cache.entries
          .where((e) => e.value.completed)
          .map((e) => e.key)
          .toSet();
      GameProgress.loadFromStats(_stats, completedIds);
      _logOk('Reconciliation complete — $mergedCount case(s) updated.');
    } catch (e) {
      _logErr('Firestore reconciliation failed. Falling back to local data.', e);
    }
  }
}