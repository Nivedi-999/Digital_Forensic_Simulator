// lib/services/case_timer.dart
// ═══════════════════════════════════════════════════════════════
//  CASE TIMER — Stopwatch wrapper with a per-second tick stream
//
//  Usage:
//    final timer = CaseTimer();
//    timer.start();                    // begin / resume
//    timer.elapsedSeconds              // current value
//    timer.formattedTime               // "MM:SS"
//    timer.stop();                     // freeze (returns elapsed)
//    timer.dispose();                  // cancel internal ticker
// ═══════════════════════════════════════════════════════════════

import 'dart:async';

class CaseTimer {
  final Stopwatch _sw = Stopwatch();
  late final StreamController<int> _controller;
  Timer? _ticker;

  /// Broadcasts elapsed seconds — rebuilds the UI every second.
  late final Stream<int> secondStream;

  CaseTimer() {
    _controller = StreamController<int>.broadcast();
    secondStream = _controller.stream;
  }

  // ── Public API ─────────────────────────────────────────────

  /// Start (or resume after pause).
  void start() {
    if (_sw.isRunning) return;
    _sw.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_controller.isClosed) {
        _controller.add(_sw.elapsed.inSeconds);
      }
    });
  }

  /// Pause the timer without resetting it.
  void pause() {
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
  }

  /// Stop permanently and return elapsed seconds.
  int stop() {
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
    return _sw.elapsed.inSeconds;
  }

  /// Reset to zero (does not restart automatically).
  void reset() {
    stop();
    _sw.reset();
  }

  /// Current elapsed time in whole seconds.
  int get elapsedSeconds => _sw.elapsed.inSeconds;

  /// Whether the timer is actively counting.
  bool get isRunning => _sw.isRunning;

  /// "MM:SS" formatted string — safe to call every frame.
  String get formattedTime {
    final total = elapsedSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Release resources. Call in the host widget's dispose().
  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }
}