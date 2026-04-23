// Routes: caesar_cipher | ip_trace | code_crack | phishing_analysis | metadata_correlation | alibi_verify
//         base64_decode | hash_validation | pattern_match | timestamp_anomaly | event_sort
//         command_classify | timeline_reconstruct | vad_scan | process_tree | socket_map
//         image_zoom_detect | serial_decode | registry_nav | window_correlate
//         fingerprint_compare | session_timeline

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';

// ── Entry point ──────────────────────────────────────────────

class DecryptionMiniGameScreen extends StatefulWidget {
  final String panelId;
  const DecryptionMiniGameScreen({super.key, required this.panelId});
  @override
  State<DecryptionMiniGameScreen> createState() =>
      _DecryptionMiniGameScreenState();
}

class _DecryptionMiniGameScreenState extends State<DecryptionMiniGameScreen> {
  MinigameConfig? _minigame;
  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final panel = engine.caseFile.panelById(widget.panelId);
    _minigame ??= panel?.minigame;
    final mg = _minigame;
    if (mg == null) {
      return AppShell(
        title: 'Mini-Game',
        showBack: true,
        showBottomNav: false,
        child: const Center(child: Text('No mini-game found.')),
      );
    }
    switch (mg.type) {
      case 'base64_decode':
        return _Base64DecodeGame(panelId: widget.panelId, minigame: mg);
      case 'ip_trace':
        return _IpTraceGame(panelId: widget.panelId, minigame: mg);
      case 'code_crack':
        return _CodeCrackGame(panelId: widget.panelId, minigame: mg);
      case 'phishing_analysis':
        return _PhishingGame(panelId: widget.panelId, minigame: mg);
      case 'metadata_correlation':
        return _MetadataCorrelationGame(panelId: widget.panelId, minigame: mg);
      case 'alibi_verify':
        return _AlibiVerifyGame(panelId: widget.panelId, minigame: mg);
      case 'caesar_cipher':
        return _CaesarCipherGame(panelId: widget.panelId, minigame: mg);
      case 'hash_validation':
        return _HashValidationGame(panelId: widget.panelId, minigame: mg);
      case 'pattern_match':
        return _PatternMatchGame(panelId: widget.panelId, minigame: mg);
      case 'timestamp_anomaly':
        return _TimestampAnomalyGame(panelId: widget.panelId, minigame: mg);
      case 'event_sort':
        return _EventSortGame(panelId: widget.panelId, minigame: mg);
      case 'command_classify':
        return _CommandClassifyGame(panelId: widget.panelId, minigame: mg);
      case 'timeline_reconstruct':
        return _TimelineReconstructGame(panelId: widget.panelId, minigame: mg);
      case 'vad_scan':
        return _VadScanGame(panelId: widget.panelId, minigame: mg);
      case 'process_tree':
        return _ProcessTreeGame(panelId: widget.panelId, minigame: mg);
      case 'socket_map':
        return _SocketMapGame(panelId: widget.panelId, minigame: mg);
      case 'image_zoom_detect':
        return _ImageZoomDetectGame(panelId: widget.panelId, minigame: mg);
      case 'serial_decode':
        return _SerialDecodeGame(panelId: widget.panelId, minigame: mg);
      case 'registry_nav':
        return _RegistryNavGame(panelId: widget.panelId, minigame: mg);
      case 'window_correlate':
        return _WindowCorrelateGame(panelId: widget.panelId, minigame: mg);
      case 'fingerprint_compare':
        return _FingerprintCompareGame(panelId: widget.panelId, minigame: mg);
      case 'session_timeline':
        return _SessionTimelineGame(panelId: widget.panelId, minigame: mg);
      default:
        return _UnsupportedMiniGame(panelId: widget.panelId, minigame: mg);
    }
  }
}

class _UnsupportedMiniGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _UnsupportedMiniGame({required this.panelId, required this.minigame});

  @override
  State<_UnsupportedMiniGame> createState() => _UnsupportedMiniGameState();
}

class _UnsupportedMiniGameState extends State<_UnsupportedMiniGame> {
  int _hintsUsed = 0;
  String _hintText = '';

  void _useHint(CaseEngine engine) {
    final hints = widget.minigame.hints;
    if (_hintsUsed < hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonAmber,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mg.title,
                        style: CyberText.sectionTitle.copyWith(
                          color: CyberColors.neonAmber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This challenge type (${mg.type}) is now rendered in compatibility mode.',
                        style: CyberText.bodySmall,
                      ),
                      if ((mg.instruction ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          mg.instruction!,
                          style: CyberText.bodySmall.copyWith(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  NeonContainer(
                    borderColor: CyberColors.neonPurple,
                    child: Text(_hintText, style: CyberText.bodySmall),
                  ),
                ],
                const SizedBox(height: 20),
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.lock_outline,
                        color: CyberColors.neonRed,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This challenge is not yet available.',
                          style: TextStyle(
                            color: CyberColors.neonRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _useHint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SUCCESS OVERLAY
// ═══════════════════════════════════════════════════════════════

class _SuccessOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onContinue;
  const _SuccessOverlay({required this.message, required this.onContinue});
  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (_, v, __) => CustomPaint(
                      size: const Size(110, 110),
                      painter: _SuccessRingPainter(progress: v),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SUCCESS',
                    style: TextStyle(
                      fontFamily: 'DotMatrix',
                      color: CyberColors.neonGreen,
                      fontSize: 32,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: CyberColors.neonGreen, blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CyberColors.neonGreen.withOpacity(0.08),
                      borderRadius: CyberRadius.medium,
                      border: Border.all(
                        color: CyberColors.neonGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.message,
                      style: CyberText.bodySmall.copyWith(
                        color: CyberColors.textPrimary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CyberButton(
                    label: 'Continue Investigation',
                    icon: Icons.arrow_forward_outlined,
                    onTap: widget.onContinue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessRingPainter extends CustomPainter {
  final double progress;
  _SuccessRingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = CyberColors.neonGreen.withOpacity(0.15);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = CyberColors.neonGreen
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
    if (progress > 0.7) {
      final checkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = CyberColors.neonGreen
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final checkProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final path = Path();
      path.moveTo(c.dx - 18, c.dy);
      path.lineTo(c.dx - 4, c.dy + 14);
      path.lineTo(c.dx + 20, c.dy - 16);
      final PathMetrics metrics = path.computeMetrics();
      for (final m in metrics) {
        canvas.drawPath(m.extractPath(0, m.length * checkProgress), checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SuccessRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  1. CAESAR CIPHER — ROTARY WHEEL UPGRADE
// ═══════════════════════════════════════════════════════════════

class _CaesarCipherGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CaesarCipherGame({required this.panelId, required this.minigame});
  @override
  State<_CaesarCipherGame> createState() => _CaesarCipherGameState();
}

class _CaesarCipherGameState extends State<_CaesarCipherGame>
    with TickerProviderStateMixin {
  int _shift = 0;
  double _dragStartAngle = 0;
  int _dragStartShift = 0;

  final TextEditingController _ctrl = TextEditingController();
  String _feedback = '';
  int _hintsUsed = 0;
  bool _success = false;
  bool _useWheel = true;

  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _glow;

  static const List<String> _alpha = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  String _decode(String cipher, int shift) {
    return cipher.split('').map((c) {
      if (c == ' ') return ' ';
      final upper = c.toUpperCase();
      if (!_alpha.contains(upper)) return c;
      final idx = (_alpha.indexOf(upper) - shift + 26) % 26;
      return c == c.toUpperCase() ? _alpha[idx] : _alpha[idx].toLowerCase();
    }).join();
  }

  void _check(CaseEngine engine) {
    final decoded = _useWheel
        ? _decode(widget.minigame.cipherText ?? '', _shift)
        : _ctrl.text.trim();
    final solution = (widget.minigame.solution ?? '').toLowerCase();
    if (decoded.toLowerCase() == solution) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(() => _feedback = 'Incorrect. Try rotating the wheel.');
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _feedback = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  void _onWheelDragStart(DragStartDetails d, Offset center) {
    final dx = d.localPosition.dx - center.dx;
    final dy = d.localPosition.dy - center.dy;
    _dragStartAngle = atan2(dy, dx);
    _dragStartShift = _shift;
  }

  void _onWheelDragUpdate(DragUpdateDetails d, Offset center) {
    if (d.delta.distance < 8) return;
    final dx = d.localPosition.dx - center.dx;
    final dy = d.localPosition.dy - center.dy;
    final angle = atan2(dy, dx);
    var delta = angle - _dragStartAngle;
    if (delta > pi) delta -= (2 * pi);
    if (delta < -pi) delta += (2 * pi);
    final rawSteps = (delta / (2 * pi / 26)).round();
    final steps = rawSteps.clamp(-1, 1);
    if (steps == 0) return;
    final newShift = (_shift + steps + 26) % 26;
    if (newShift != _shift) {
      HapticFeedback.selectionClick();
      setState(() => _shift = newShift);
      _dragStartAngle = angle;
      _dragStartShift = _shift;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final cipherText = mg.cipherText ?? '';
    final decoded = _decode(cipherText, _shift);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeonContainer(
                    borderColor: CyberColors.neonPurple,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: CyberColors.neonPurple.withOpacity(0.12),
                            borderRadius: CyberRadius.small,
                            border: Border.all(
                              color: CyberColors.neonPurple.withOpacity(0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.rotate_right,
                            color: CyberColors.neonPurple,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mg.title,
                                style: CyberText.sectionTitle.copyWith(
                                  color: CyberColors.neonPurple,
                                ),
                              ),
                              if (mg.hint != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  mg.hint!,
                                  style: CyberText.bodySmall.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  NeonContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENCODED',
                          style: CyberText.caption.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cipherText,
                          style: const TextStyle(
                            fontFamily: 'DotMatrix',
                            fontSize: 24,
                            color: CyberColors.neonAmber,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: CyberColors.neonAmber,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ROTATE TO DECODE',
                          style: CyberText.caption.copyWith(
                            letterSpacing: 2,
                            color: CyberColors.neonPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            const double size = 280;
                            final center = Offset(size / 2, size / 2);
                            return SizedBox(
                              width: size,
                              height: size,
                              child: GestureDetector(
                                onPanStart: (d) => _onWheelDragStart(d, center),
                                onPanUpdate: (d) =>
                                    _onWheelDragUpdate(d, center),
                                child: AnimatedBuilder(
                                  animation: _glow,
                                  builder: (_, __) => CustomPaint(
                                    size: const Size(size, size),
                                    painter: _CipherWheelPainter(
                                      shift: _shift,
                                      glowIntensity: _glow.value,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _WheelArrow(
                              direction: -1,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _shift = (_shift - 1 + 26) % 26);
                              },
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: CyberColors.neonPurple.withOpacity(0.12),
                                borderRadius: CyberRadius.small,
                                border: Border.all(
                                  color: CyberColors.neonPurple.withOpacity(
                                    0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Shift: $_shift',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: CyberColors.neonPurple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            _WheelArrow(
                              direction: 1,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _shift = (_shift + 1) % 26);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  NeonContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DECODED',
                          style: CyberText.caption.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          decoded,
                          style: const TextStyle(
                            fontFamily: 'DotMatrix',
                            fontSize: 22,
                            color: CyberColors.neonCyan,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: CyberColors.neonCyan,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_feedback.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CyberColors.neonAmber.withOpacity(0.08),
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: CyberColors.neonAmber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: CyberColors.neonAmber,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _feedback,
                              style: const TextStyle(
                                color: CyberColors.neonAmber,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        child: CyberButton(
                          label: 'Submit Decode',
                          icon: Icons.check_outlined,
                          onTap: () => _check(engine),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: CyberButton(
                          label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                          icon: Icons.lightbulb_outline,
                          isOutlined: true,
                          isSmall: true,
                          accentColor: CyberColors.neonAmber,
                          onTap: _hintsUsed < mg.hints.length
                              ? () => _hint(engine)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Hidden evidence unlocked.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _WheelArrow extends StatelessWidget {
  final int direction;
  final VoidCallback onTap;
  const _WheelArrow({required this.direction, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CyberColors.neonPurple.withOpacity(0.12),
        borderRadius: CyberRadius.small,
        border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4)),
      ),
      child: Icon(
        direction < 0 ? Icons.chevron_left : Icons.chevron_right,
        color: CyberColors.neonPurple,
        size: 22,
      ),
    ),
  );
}

class _CipherWheelPainter extends CustomPainter {
  final int shift;
  final double glowIntensity;
  _CipherWheelPainter({required this.shift, required this.glowIntensity});

  static const List<String> _alpha = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 10;
    final innerR = size.width / 2 - 55;
    final midR = size.width / 2 - 32;

    _paintRing(
      canvas,
      c,
      outerR,
      CyberColors.neonAmber.withOpacity(0.08),
      CyberColors.neonAmber.withOpacity(0.25),
      2,
    );
    _paintRing(
      canvas,
      c,
      innerR,
      CyberColors.neonCyan.withOpacity(0.08),
      CyberColors.neonCyan.withOpacity(0.25),
      2,
    );

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CyberColors.borderSubtle.withOpacity(0.5);
    canvas.drawCircle(c, midR, trackPaint);

    for (int i = 0; i < 26; i++) {
      final angle = (2 * pi * i / 26) - pi / 2;
      final isActive = i == 0;
      final letterPos = Offset(
        c.dx + outerR * 0.82 * cos(angle),
        c.dy + outerR * 0.82 * sin(angle),
      );
      _drawRingLetter(
        canvas,
        _alpha[i],
        letterPos,
        CyberColors.neonAmber,
        isActive,
        12,
      );
      final tickStart = Offset(
        c.dx + (outerR - 6) * cos(angle),
        c.dy + (outerR - 6) * sin(angle),
      );
      final tickEnd = Offset(
        c.dx + (outerR - 14) * cos(angle),
        c.dy + (outerR - 14) * sin(angle),
      );
      final tickPaint = Paint()
        ..strokeWidth = isActive ? 2 : 0.8
        ..color = CyberColors.neonAmber.withOpacity(isActive ? 0.8 : 0.3);
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }

    for (int i = 0; i < 26; i++) {
      final angle = (2 * pi * i / 26) - pi / 2;
      final decodedIdx = (i - shift + 26) % 26;
      final isActive = i == 0;
      final letterPos = Offset(
        c.dx + innerR * 0.82 * cos(angle),
        c.dy + innerR * 0.82 * sin(angle),
      );
      _drawRingLetter(
        canvas,
        _alpha[decodedIdx],
        letterPos,
        CyberColors.neonCyan,
        isActive,
        12,
      );
    }

    final arrowPaint = Paint()
      ..color = CyberColors.neonGreen
      ..style = PaintingStyle.fill;
    final arrowPath = Path();
    arrowPath.moveTo(c.dx, c.dy - outerR + 2);
    arrowPath.lineTo(c.dx - 8, c.dy - outerR + 16);
    arrowPath.lineTo(c.dx + 8, c.dy - outerR + 16);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    final hubPaint = Paint()..color = CyberColors.bgCard;
    canvas.drawCircle(c, innerR * 0.25, hubPaint);
    final hubBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = CyberColors.neonCyan.withOpacity(0.4);
    canvas.drawCircle(c, innerR * 0.25, hubBorder);

    final tp = TextPainter(
      text: TextSpan(
        text: '$shift',
        style: TextStyle(
          color: CyberColors.neonCyan.withOpacity(0.8 + glowIntensity * 0.2),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));

    final glowPaint = Paint()
      ..color = CyberColors.neonGreen.withOpacity(0.15 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(c.dx, c.dy - outerR + 10), 12, glowPaint);
  }

  void _paintRing(
    Canvas canvas,
    Offset c,
    double r,
    Color fill,
    Color stroke,
    double strokeW,
  ) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
  }

  void _drawRingLetter(
    Canvas canvas,
    String letter,
    Offset pos,
    Color color,
    bool active,
    double size,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: active ? color : color.withOpacity(0.45),
          fontSize: active ? size + 1 : size,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_CipherWheelPainter old) =>
      old.shift != shift || old.glowIntensity != glowIntensity;
}

// ═══════════════════════════════════════════════════════════════
//  2. BASE64 DECODE
// ═══════════════════════════════════════════════════════════════

class _Base64DecodeGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _Base64DecodeGame({required this.panelId, required this.minigame});

  @override
  State<_Base64DecodeGame> createState() => _Base64DecodeGameState();
}

class _Base64DecodeGameState extends State<_Base64DecodeGame> {
  bool _success = false;
  int _hintsUsed = 0;
  String _feedback = '';

  String _decodedPreview(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return 'Invalid JWT format';
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final bytes = base64Url.decode(normalized);
      return utf8.decode(bytes);
    } catch (_) {
      return 'Unable to decode payload. Check JWT format.';
    }
  }

  void _submit(CaseEngine engine) {
    engine.solveMinigame(widget.minigame.id);
    setState(() => _success = true);
    HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final hints = widget.minigame.hints;
    if (_hintsUsed < hints.length) {
      engine.recordHintUsed();
      setState(() {
        _feedback = hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final encoded = (mg.jwtEncoded ?? '').trim();
    final decoded = encoded.isEmpty
        ? 'No encoded payload found for this challenge.'
        : _decodedPreview(encoded);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonPurple,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mg.title,
                        style: CyberText.sectionTitle.copyWith(
                          color: CyberColors.neonPurple,
                        ),
                      ),
                      if ((mg.instruction ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          mg.instruction!,
                          style: CyberText.bodySmall.copyWith(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENCODED JWT',
                        style: CyberText.caption.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        encoded.isEmpty ? 'N/A' : encoded,
                        style: const TextStyle(
                          fontFamily: 'DotMatrix',
                          fontSize: 17,
                          color: CyberColors.neonAmber,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DECODED PAYLOAD',
                        style: CyberText.caption.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        decoded,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: CyberColors.neonCyan,
                          height: 1.4,
                        ),
                      ),
                      if ((mg.iatHumanReadable ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'IAT: ${mg.iatHumanReadable!}',
                          style: CyberText.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Confirm Findings',
                      icon: Icons.check_outlined,
                      onTap: () => _submit(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Decoded successfully.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. IP TRACE — ANIMATED NETWORK GRAPH
// ═══════════════════════════════════════════════════════════════

class _IpTraceGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _IpTraceGame({required this.panelId, required this.minigame});
  @override
  State<_IpTraceGame> createState() => _IpTraceGameState();
}

class _IpTraceGameState extends State<_IpTraceGame>
    with TickerProviderStateMixin {
  String _typed = '';
  bool _success = false;
  bool _failed = false;
  int _hintsUsed = 0;
  String _feedback = '';
  int _highlightedIndex = -1;
  static const int _totalSeconds = 45;
  int _remaining = _totalSeconds;
  Timer? _timer;
  late List<String> _ipList;
  late int _correctIndex;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late Animation<double> _pulse;
  late Animation<double> _scan;
  int? _selectedNodeIndex;
  bool _showGraph = true;
  bool _invalidConfig = false;
  bool _loggedInvalidConfig = false;

  @override
  void initState() {
    super.initState();
    final mg = widget.minigame;
    if (mg.solution == null || mg.solution!.trim().isEmpty) {
      _invalidConfig = true;
      return;
    }
    _ipList = List<String>.from(mg.decoys);
    if (!_ipList.contains(mg.solution)) _ipList.add(mg.solution!);
    _ipList.shuffle();
    _correctIndex = _ipList.indexWhere((ip) => ip == mg.solution);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scan = CurvedAnimation(parent: _scanCtrl, curve: Curves.linear);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _failed = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_invalidConfig) {
      _pulseCtrl.dispose();
      _scanCtrl.dispose();
    }
    super.dispose();
  }

  void _selectNode(int index) {
    if (_success || _failed) return;
    setState(() {
      _selectedNodeIndex = index;
      _typed = _ipList[index];
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _submit();
    });
  }

  void _submit() {
    final solution = widget.minigame.solution ?? '';
    if (_typed.trim() == solution) {
      _timer?.cancel();
      final engine = CaseEngineProvider.read(context);
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(() {
        _feedback = 'Wrong node. Keep scanning.';
        _selectedNodeIndex = null;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _feedback = mg.hints[_hintsUsed];
        _hintsUsed++;
        _highlightedIndex = _correctIndex;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightedIndex = -1);
      });
    }
  }

  void _tap(String char) {
    if (_success || _failed) return;
    setState(() {
      if (char == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (char == '✓') {
        _submit();
      } else if (_typed.length < 15) {
        _typed += char;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    if (_invalidConfig) {
      if (!_loggedInvalidConfig) {
        _loggedInvalidConfig = true;
        debugPrint(
          '[IP_TRACE] Invalid config: empty solution for case=${engine.caseFile.id}, panel=${widget.panelId}, minigame=${mg.id}',
        );
      }
      return AppShell(
        title: 'Mini-Game',
        showBack: true,
        showBottomNav: false,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This challenge is misconfigured and cannot be loaded yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final progress = _remaining / _totalSeconds;
    final timerColor = _remaining > 20
        ? CyberColors.neonGreen
        : _remaining > 10
        ? CyberColors.neonAmber
        : CyberColors.neonRed;

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CyberColors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation(timerColor),
                  minHeight: 6,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Network Map',
                      active: _showGraph,
                      onTap: () => setState(() => _showGraph = true),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Manual Entry',
                      active: !_showGraph,
                      onTap: () => setState(() => _showGraph = false),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.1 * _pulse.value),
                          borderRadius: CyberRadius.pill,
                          border: Border.all(
                            color: timerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: timerColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_remaining s',
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _showGraph
                    ? _buildGraph(engine, mg)
                    : _buildManual(engine, mg),
              ),
            ],
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'IP traced. Evidence unlocked.',
              onContinue: () => Navigator.pop(context),
            ),
          if (_failed && !_success)
            _TimeoutOverlay(
              onRetry: () {
                setState(() {
                  _typed = '';
                  _feedback = '';
                  _failed = false;
                  _remaining = _totalSeconds;
                  _selectedNodeIndex = null;
                });
                _startTimer();
              },
              onBack: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildGraph(CaseEngine engine, MinigameConfig mg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_pulseCtrl, _scanCtrl]),
            builder: (_, __) => CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 32, 220),
              painter: _NetworkGraphPainter(
                ipList: _ipList,
                correctIndex: _correctIndex,
                selectedIndex: _selectedNodeIndex,
                highlightedIndex: _highlightedIndex,
                pulseValue: _pulse.value,
                scanValue: _scan.value,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TAP A NODE TO TRACE THE HOP',
            style: CyberText.caption.copyWith(
              color: CyberColors.neonCyan.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ipList.asMap().entries.map((entry) {
              final i = entry.key;
              final ip = entry.value;
              final isSelected = i == _selectedNodeIndex;
              final isHighlighted = i == _highlightedIndex;
              return GestureDetector(
                onTap: () => _selectNode(i),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CyberColors.neonCyan.withOpacity(0.15)
                          : isHighlighted
                          ? CyberColors.neonAmber.withOpacity(
                              0.1 + _pulse.value * 0.08,
                            )
                          : CyberColors.bgCard,
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: isSelected
                            ? CyberColors.neonCyan
                            : isHighlighted
                            ? CyberColors.neonAmber.withOpacity(0.7)
                            : CyberColors.borderSubtle,
                        width: isSelected || isHighlighted ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: CyberColors.neonCyan.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      ip,
                      style: TextStyle(
                        fontFamily: 'DotMatrix',
                        color: isSelected
                            ? CyberColors.neonCyan
                            : isHighlighted
                            ? CyberColors.neonAmber
                            : CyberColors.textPrimary,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CyberColors.neonAmber.withOpacity(0.08),
                borderRadius: CyberRadius.small,
                border: Border.all(
                  color: CyberColors.neonAmber.withOpacity(0.3),
                ),
              ),
              child: Text(
                _feedback,
                style: const TextStyle(
                  color: CyberColors.neonAmber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          CyberButton(
            label: 'Hint (${mg.hints.length - _hintsUsed} left)',
            icon: Icons.lightbulb_outline,
            isOutlined: true,
            isSmall: true,
            accentColor: CyberColors.neonAmber,
            onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildManual(CaseEngine engine, MinigameConfig mg) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: CyberRadius.small,
                    border: Border.all(
                      color: CyberColors.neonCyan.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _typed.isEmpty ? 'Enter IP address...' : _typed,
                          style: TextStyle(
                            fontFamily: 'DotMatrix',
                            color: _typed.isEmpty
                                ? CyberColors.textMuted
                                : CyberColors.neonCyan,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_feedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _NumericKeypad(onTap: _tap),
                const SizedBox(height: 8),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? CyberColors.neonCyan.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: CyberRadius.pill,
        border: Border.all(
          color: active ? CyberColors.neonCyan : CyberColors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? CyberColors.neonCyan : CyberColors.textMuted,
          fontSize: 11,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}

class _NetworkGraphPainter extends CustomPainter {
  final List<String> ipList;
  final int correctIndex;
  final int? selectedIndex;
  final int highlightedIndex;
  final double pulseValue;
  final double scanValue;

  _NetworkGraphPainter({
    required this.ipList,
    required this.correctIndex,
    this.selectedIndex,
    required this.highlightedIndex,
    required this.pulseValue,
    required this.scanValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = ipList.length;
    if (n == 0) return;
    final sourcePos = Offset(size.width / 2, 30);
    final List<Offset> positions = [];
    for (int i = 0; i < n; i++) {
      final t = (i + 0.5) / n;
      final x = size.width * (0.1 + t * 0.8);
      final y = size.height - 40;
      positions.add(Offset(x, y));
    }
    final scanX = size.width * scanValue;
    final scanPaint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(scanX - 30, 0, 60, size.height), scanPaint);
    for (int i = 0; i < n; i++) {
      final isSelected = i == selectedIndex;
      final isHighlighted = i == highlightedIndex;
      final linePaint = Paint()
        ..strokeWidth = isSelected ? 2 : 1
        ..color = isSelected
            ? CyberColors.neonCyan.withOpacity(0.8)
            : isHighlighted
            ? CyberColors.neonAmber.withOpacity(0.5)
            : CyberColors.borderSubtle.withOpacity(0.4)
        ..style = PaintingStyle.stroke;
      _drawDashedLine(
        canvas,
        sourcePos,
        positions[i],
        linePaint,
        isSelected ? 8 : 12,
      );
    }
    _drawNode(
      canvas,
      sourcePos,
      'YOU',
      CyberColors.neonGreen,
      20,
      pulseValue,
      false,
    );
    for (int i = 0; i < n; i++) {
      final isSelected = i == selectedIndex;
      final isHighlighted = i == highlightedIndex;
      final color = isSelected
          ? CyberColors.neonCyan
          : isHighlighted
          ? CyberColors.neonAmber
          : CyberColors.neonPurple;
      _drawNode(
        canvas,
        positions[i],
        'NODE',
        color,
        16,
        isSelected ? pulseValue : 0.3,
        isSelected,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: ipList[i].length > 12
              ? '${ipList[i].substring(0, 11)}…'
              : ipList[i],
          style: TextStyle(
            color: color.withOpacity(isSelected ? 1 : 0.6),
            fontSize: 9,
            fontFamily: 'DotMatrix',
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: 80);
      tp.paint(canvas, positions[i] + Offset(-tp.width / 2, 20));
    }
  }

  void _drawNode(
    Canvas canvas,
    Offset pos,
    String label,
    Color color,
    double r,
    double glowVal,
    bool selected,
  ) {
    if (selected || glowVal > 0.5) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.15 * glowVal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, r + 8, glowPaint);
    }
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = color.withOpacity(selected ? 0.9 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1,
    );
    canvas.drawCircle(
      pos,
      r * 0.3,
      Paint()..color = color.withOpacity(0.7 * glowVal),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    double dashLen,
  ) {
    final dist = (p2 - p1).distance;
    final dir = (p2 - p1) / dist;
    double d = 0;
    while (d < dist) {
      final start = p1 + dir * d;
      final end = p1 + dir * (d + dashLen * 0.6).clamp(0, dist);
      canvas.drawLine(start, end, paint);
      d += dashLen;
    }
  }

  @override
  bool shouldRepaint(_NetworkGraphPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.highlightedIndex != highlightedIndex ||
      old.pulseValue != pulseValue ||
      old.scanValue != scanValue;
}

class _TimeoutOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _TimeoutOverlay({required this.onRetry, required this.onBack});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withOpacity(0.9),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_off_outlined,
              color: CyberColors.neonRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'TIME OUT',
              style: TextStyle(
                fontFamily: 'DotMatrix',
                color: CyberColors.neonRed,
                fontSize: 28,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text('The trace window expired.', style: CyberText.bodySmall),
            const SizedBox(height: 24),
            CyberButton(
              label: 'Try Again',
              icon: Icons.replay,
              accentColor: CyberColors.neonRed,
              onTap: onRetry,
            ),
            const SizedBox(height: 12),
            CyberButton(
              label: 'Go Back',
              icon: Icons.arrow_back,
              isOutlined: true,
              onTap: onBack,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onTap;
  const _NumericKeypad({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
      ['✓'],
    ];
    return Column(
      children: keys
          .map(
            (row) => Row(
              children: row.map((key) {
                final isSubmit = key == '✓';
                final isDelete = key == '⌫';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: isSubmit
                          ? CyberColors.neonCyan.withOpacity(0.15)
                          : CyberColors.neonCyan.withOpacity(0.05),
                      borderRadius: CyberRadius.small,
                      child: InkWell(
                        borderRadius: CyberRadius.small,
                        onTap: () => onTap(key),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: CyberRadius.small,
                            border: Border.all(
                              color: isSubmit
                                  ? CyberColors.neonCyan.withOpacity(0.5)
                                  : CyberColors.borderSubtle,
                            ),
                          ),
                          child: Center(
                            child: isDelete
                                ? const Icon(
                                    Icons.backspace_outlined,
                                    color: CyberColors.neonRed,
                                    size: 20,
                                  )
                                : isSubmit
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: CyberColors.neonCyan,
                                    size: 22,
                                  )
                                : Text(
                                    key,
                                    style: const TextStyle(
                                      fontFamily: 'DotMatrix',
                                      color: CyberColors.textPrimary,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  4. CODE CRACK — SLOT MACHINE REELS
// ═══════════════════════════════════════════════════════════════

class _CodeCrackGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CodeCrackGame({required this.panelId, required this.minigame});
  @override
  State<_CodeCrackGame> createState() => _CodeCrackGameState();
}

class _CodeCrackGameState extends State<_CodeCrackGame>
    with TickerProviderStateMixin {
  static const List<String> _chars = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
  ];
  late List<int> _currentIndices;
  late List<AnimationController> _spinCtrls;
  late List<Animation<double>> _spinAnims;
  late List<bool> _isSpinning;
  bool _success = false;
  int _hintsUsed = 0;
  String _feedback = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  bool _loggedInvalidSolution = false;

  @override
  void initState() {
    super.initState();
    final reelCount = _reelCount;
    _currentIndices = List<int>.filled(reelCount, 0);
    _isSpinning = List<bool>.filled(reelCount, false);
    _spinCtrls = List.generate(
      reelCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _spinAnims = _spinCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack))
        .toList();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    for (final c in _spinCtrls) c.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _spin(int reel, int dir) async {
    if (_success || _isSpinning[reel]) return;
    HapticFeedback.selectionClick();
    setState(() => _isSpinning[reel] = true);
    _spinCtrls[reel].reset();
    await _spinCtrls[reel].forward();
    setState(() {
      _currentIndices[reel] =
          (_currentIndices[reel] + dir + _chars.length) % _chars.length;
      _isSpinning[reel] = false;
    });
    HapticFeedback.lightImpact();
  }

  int get _reelCount {
    final solution = (widget.minigame.solution ?? '').trim();
    if (solution.isEmpty) return 3;
    return solution.length.clamp(1, 6);
  }

  void _submit(CaseEngine engine) {
    final solution = widget.minigame.solution ?? '';
    final current = _currentIndices.map((i) => _chars[i]).join();
    if (current == solution) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      _shakeCtrl.reset();
      _shakeCtrl.forward();
      setState(() => _feedback = 'Code mismatch. Keep cracking.');
      HapticFeedback.heavyImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      final solution = mg.solution ?? '';
      if (_hintsUsed < solution.length) {
        final idx = _chars.indexOf(solution[_hintsUsed].toUpperCase());
        if (idx >= 0) setState(() => _currentIndices[_hintsUsed] = idx);
      }
      setState(() {
        _feedback = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final trimmedSolution = (mg.solution ?? '').trim();
    if (trimmedSolution.isEmpty) {
      if (!_loggedInvalidSolution) {
        final caseId = engine.caseFile.id;
        debugPrint(
          '[CODE_CRACK] Invalid config: empty solution for case=$caseId, panel=${widget.panelId}, minigame=${mg.id}',
        );
        _loggedInvalidSolution = true;
      }
      return _UnsupportedMiniGame(panelId: widget.panelId, minigame: mg);
    }
    final solution = mg.solution ?? '???';

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            color: CyberColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            mg.title,
                            style: CyberText.sectionTitle.copyWith(
                              color: CyberColors.neonRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TerminalLine(
                        '> ACCESSING SYSTEM...',
                        CyberColors.neonRed,
                      ),
                      _TerminalLine(
                        '> BYPASSING FIREWALL...',
                        CyberColors.neonAmber,
                      ),
                      _TerminalLine(
                        '> MATCH THE ${_reelCount}-CHARACTER CODE TO PROCEED.',
                        CyberColors.neonCyan,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'TARGET:  ',
                      style: TextStyle(
                        color: CyberColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    ...solution
                        .split('')
                        .map(
                          (c) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: CyberColors.neonAmber.withOpacity(0.1),
                              borderRadius: CyberRadius.small,
                              border: Border.all(
                                color: CyberColors.neonAmber.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontFamily: 'DotMatrix',
                                  color: CyberColors.neonAmber,
                                  fontSize: 24,
                                  shadows: [
                                    Shadow(
                                      color: CyberColors.neonAmber,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      _success
                          ? 0
                          : sin(_shake.value * pi * 6) * 6 * (1 - _shake.value),
                      0,
                    ),
                    child: child,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 8,
                    children: List.generate(
                      _reelCount,
                      (reel) => _buildReel(reel),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scroll reels to match the target code',
                  style: CyberText.caption.copyWith(
                    color: CyberColors.textMuted,
                  ),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: CyberColors.neonAmber,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _feedback,
                            style: const TextStyle(
                              color: CyberColors.neonAmber,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      child: CyberButton(
                        label: 'CRACK CODE',
                        icon: Icons.lock_open_outlined,
                        accentColor: CyberColors.neonRed,
                        onTap: () => _submit(engine),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: CyberButton(
                        label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                        icon: Icons.lightbulb_outline,
                        isOutlined: true,
                        isSmall: true,
                        accentColor: CyberColors.neonAmber,
                        onTap: _hintsUsed < mg.hints.length
                            ? () => _hint(engine)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message:
                  mg.successMessage ?? 'System breached. Evidence unlocked.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildReel(int reel) {
    final cur = _chars[_currentIndices[reel]];
    final prv =
        _chars[(_currentIndices[reel] - 1 + _chars.length) % _chars.length];
    final nxt = _chars[(_currentIndices[reel] + 1) % _chars.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _spin(reel, -1),
            child: AnimatedBuilder(
              animation: _spinAnims[reel],
              builder: (_, __) => Container(
                width: 72,
                height: 56,
                decoration: BoxDecoration(
                  color: CyberColors.neonCyan.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: CyberColors.neonCyan.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: CyberColors.neonCyan,
                      size: 24,
                    ),
                    Transform.translate(
                      offset: _isSpinning[reel]
                          ? Offset(
                              0,
                              (8 * _spinAnims[reel].value).roundToDouble(),
                            )
                          : Offset.zero,
                      child: Text(
                        prv,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: CyberColors.textMuted.withOpacity(0.6),
                          fontSize: 14,
                          fontFamily: 'DotMatrix',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _spinAnims[reel],
            builder: (_, __) {
              final rawBounce = _isSpinning[reel]
                  ? _spinAnims[reel].value
                  : 1.0;
              final bounce = rawBounce.clamp(0.0, 1.0).toDouble();
              return Container(
                width: 72,
                height: 80,
                decoration: BoxDecoration(
                  color: CyberColors.neonCyan.withOpacity(0.12),
                  border: Border.all(color: CyberColors.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CyberColors.neonCyan.withOpacity(0.35 * bounce),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * bounce,
                    child: Text(
                      cur,
                      style: TextStyle(
                        fontFamily: 'DotMatrix',
                        fontSize: 38,
                        color: CyberColors.neonCyan.withOpacity(bounce),
                        shadows: [
                          Shadow(
                            color: CyberColors.neonCyan,
                            blurRadius: 12 * bounce,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => _spin(reel, 1),
            child: AnimatedBuilder(
              animation: _spinAnims[reel],
              builder: (_, __) => Container(
                width: 72,
                height: 56,
                decoration: BoxDecoration(
                  color: CyberColors.neonCyan.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: CyberColors.neonCyan.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: _isSpinning[reel]
                          ? Offset(
                              0,
                              (-8 * _spinAnims[reel].value).roundToDouble(),
                            )
                          : Offset.zero,
                      child: Text(
                        nxt,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: CyberColors.textMuted.withOpacity(0.6),
                          fontSize: 14,
                          fontFamily: 'DotMatrix',
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: CyberColors.neonCyan,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLine extends StatelessWidget {
  final String text;
  final Color color;
  const _TerminalLine(this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'DotMatrix',
        color: color,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  5. PHISHING ANALYSIS — EMAIL CLIENT MOCK-UP
// ═══════════════════════════════════════════════════════════════

class _PhishingGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _PhishingGame({required this.panelId, required this.minigame});
  @override
  State<_PhishingGame> createState() => _PhishingGameState();
}

class _PhishingGameState extends State<_PhishingGame>
    with TickerProviderStateMixin {
  bool _success = false;
  bool _wrongChoice = false;
  final Set<int> _flagged = {};
  final List<bool> _flagVisible = [];
  int _hintsUsed = 0;
  String _hintText = '';
  bool _showInbox = true;
  bool _emailOpen = false;
  late AnimationController _emailOpenCtrl;
  late Animation<double> _emailOpenAnim;
  final List<AnimationController> _flagCtrls = [];

  @override
  void initState() {
    super.initState();
    final flagCount = widget.minigame.redFlags.length;
    _flagVisible.addAll(List.filled(flagCount, false));
    _emailOpenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _emailOpenAnim = CurvedAnimation(
      parent: _emailOpenCtrl,
      curve: Curves.easeOutCubic,
    );
    for (int i = 0; i < flagCount; i++) {
      _flagCtrls.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailOpenCtrl.dispose();
    for (final c in _flagCtrls) c.dispose();
    super.dispose();
  }

  void _openEmail() async {
    setState(() => _emailOpen = true);
    await _emailOpenCtrl.forward();
    if (!mounted) return;
    for (int i = 0; i < _flagVisible.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _flagVisible[i] = true);
      _flagCtrls[i].forward();
    }
  }

  void _choose(String action, CaseEngine engine) {
    final correct = widget.minigame.correctAction ?? 'report';
    if (action == correct) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(() => _wrongChoice = true);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _wrongChoice = false);
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  void _toggleFlag(int i) {
    setState(() {
      if (_flagged.contains(i))
        _flagged.remove(i);
      else
        _flagged.add(i);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          Column(
            children: [
              _EmailClientChrome(
                showInbox: _showInbox,
                onInboxTap: () => setState(() => _showInbox = true),
                onAnalysisTap: _emailOpen
                    ? () => setState(() => _showInbox = false)
                    : null,
              ),
              Expanded(
                child: _showInbox
                    ? _buildInbox(mg)
                    : _buildAnalysis(engine, mg),
              ),
              if (_emailOpen)
                _EmailActionBar(
                  wrongChoice: _wrongChoice,
                  onReport: () => _choose('report', engine),
                  onDelete: () => _choose('delete', engine),
                  onHint: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                  hintsLeft: mg.hints.length - _hintsUsed,
                  hintText: _hintText,
                ),
            ],
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Phishing email flagged.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildInbox(MinigameConfig mg) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InboxRow(
            sender: 'Security Team',
            subject: 'Q4 Security Report',
            time: '09:14',
            isRead: true,
            isHighlighted: false,
            onTap: () {},
          ),
          _InboxRow(
            sender: mg.emailFrom ?? 'Unknown',
            subject: mg.emailSubject ?? 'Important',
            time: '09:47',
            isRead: false,
            isHighlighted: true,
            onTap: () {
              _openEmail();
              setState(() => _showInbox = false);
            },
          ),
          _InboxRow(
            sender: 'IT Support',
            subject: 'Password reset confirmation',
            time: '08:30',
            isRead: true,
            isHighlighted: false,
            onTap: () {},
          ),
          _InboxRow(
            sender: 'HR Department',
            subject: 'Monthly newsletter',
            time: 'Yesterday',
            isRead: true,
            isHighlighted: false,
            onTap: () {},
          ),
          const SizedBox(height: 20),
          if (!_emailOpen)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CyberColors.neonAmber.withOpacity(0.08),
                  borderRadius: CyberRadius.medium,
                  border: Border.all(
                    color: CyberColors.neonAmber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: CyberColors.neonAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap the suspicious email to open and analyse it.',
                        style: CyberText.bodySmall.copyWith(
                          color: CyberColors.neonAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysis(CaseEngine engine, MinigameConfig mg) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_emailOpenAnim),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: CyberColors.bgCard,
                borderRadius: CyberRadius.medium,
                border: Border.all(color: CyberColors.neonRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: CyberColors.neonRed.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EmailMetaRow(
                          label: 'FROM',
                          value: mg.emailFrom ?? '',
                          highlight: true,
                        ),
                        const SizedBox(height: 6),
                        _EmailMetaRow(
                          label: 'TO',
                          value: 'investigator@cybercell.in',
                          highlight: false,
                        ),
                        const SizedBox(height: 6),
                        _EmailMetaRow(
                          label: 'SUBJECT',
                          value: mg.emailSubject ?? '',
                          highlight: false,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      mg.emailBody ?? '',
                      style: CyberText.bodySmall.copyWith(
                        height: 1.7,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  color: CyberColors.neonRed,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'RED FLAGS DETECTED',
                  style: CyberText.caption.copyWith(
                    color: CyberColors.neonRed,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CyberColors.neonRed.withOpacity(0.12),
                    borderRadius: CyberRadius.pill,
                    border: Border.all(
                      color: CyberColors.neonRed.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    '${_flagged.length}/${mg.redFlags.length} flagged',
                    style: const TextStyle(
                      color: CyberColors.neonRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...mg.redFlags.asMap().entries.map((entry) {
              final i = entry.key;
              final flag = entry.value;
              if (!_flagVisible[i]) return const SizedBox.shrink();
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-0.3, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _flagCtrls[i],
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: FadeTransition(
                  opacity: _flagCtrls[i],
                  child: GestureDetector(
                    onTap: () => _toggleFlag(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _flagged.contains(i)
                            ? CyberColors.neonRed.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: _flagged.contains(i)
                              ? CyberColors.neonRed.withOpacity(0.5)
                              : CyberColors.borderSubtle,
                          width: _flagged.contains(i) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _flagged.contains(i)
                                  ? Icons.flag
                                  : Icons.flag_outlined,
                              key: ValueKey(_flagged.contains(i)),
                              color: _flagged.contains(i)
                                  ? CyberColors.neonRed
                                  : CyberColors.textMuted,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              flag,
                              style: TextStyle(
                                color: _flagged.contains(i)
                                    ? CyberColors.textPrimary
                                    : CyberColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmailClientChrome extends StatelessWidget {
  final bool showInbox;
  final VoidCallback onInboxTap;
  final VoidCallback? onAnalysisTap;
  const _EmailClientChrome({
    required this.showInbox,
    required this.onInboxTap,
    this.onAnalysisTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        border: Border(bottom: BorderSide(color: CyberColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mail_outlined,
                color: CyberColors.neonAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SECURE MAIL CLIENT',
                style: CyberText.caption.copyWith(
                  color: CyberColors.neonAmber,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CyberColors.neonGreen,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'ONLINE',
                style: CyberText.caption.copyWith(
                  color: CyberColors.neonGreen,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChromeTab(label: 'Inbox', active: showInbox, onTap: onInboxTap),
              const SizedBox(width: 4),
              _ChromeTab(
                label: 'Analyse',
                active: !showInbox,
                onTap: onAnalysisTap,
                disabled: onAnalysisTap == null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChromeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool disabled;
  const _ChromeTab({
    required this.label,
    required this.active,
    this.onTap,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: disabled ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? CyberColors.bgBase : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: active ? Border.all(color: CyberColors.borderSubtle) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? CyberColors.neonCyan
              : (disabled
                    ? CyberColors.textMuted.withOpacity(0.4)
                    : CyberColors.textMuted),
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}

class _InboxRow extends StatelessWidget {
  final String sender, subject, time;
  final bool isRead, isHighlighted;
  final VoidCallback onTap;
  const _InboxRow({
    required this.sender,
    required this.subject,
    required this.time,
    required this.isRead,
    required this.isHighlighted,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted
          ? CyberColors.neonRed.withOpacity(0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CyberColors.borderSubtle, width: 0.5),
            ),
            color: isHighlighted ? CyberColors.neonRed.withOpacity(0.04) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !isRead
                      ? (isHighlighted
                            ? CyberColors.neonRed
                            : CyberColors.neonCyan)
                      : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender,
                            style: TextStyle(
                              color: isHighlighted
                                  ? CyberColors.neonRed
                                  : CyberColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(time, style: CyberText.caption),
                        if (isHighlighted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: CyberColors.neonRed.withOpacity(0.12),
                              borderRadius: CyberRadius.pill,
                              border: Border.all(
                                color: CyberColors.neonRed.withOpacity(0.4),
                              ),
                            ),
                            child: const Text(
                              'SUSPICIOUS',
                              style: TextStyle(
                                color: CyberColors.neonRed,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CyberText.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: CyberColors.textMuted.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailMetaRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _EmailMetaRow({
    required this.label,
    required this.value,
    required this.highlight,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 60,
        child: Text(
          label,
          style: CyberText.caption.copyWith(fontSize: 10, letterSpacing: 0.8),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: highlight ? CyberColors.neonRed : CyberColors.textPrimary,
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}

class _EmailActionBar extends StatelessWidget {
  final bool wrongChoice;
  final VoidCallback onReport, onDelete;
  final VoidCallback? onHint;
  final int hintsLeft;
  final String hintText;
  const _EmailActionBar({
    required this.wrongChoice,
    required this.onReport,
    required this.onDelete,
    this.onHint,
    required this.hintsLeft,
    required this.hintText,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        border: Border(top: BorderSide(color: CyberColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hintText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: CyberColors.neonAmber.withOpacity(0.08),
                borderRadius: CyberRadius.small,
                border: Border.all(
                  color: CyberColors.neonAmber.withOpacity(0.3),
                ),
              ),
              child: Text(
                hintText,
                style: const TextStyle(
                  color: CyberColors.neonAmber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (wrongChoice) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: CyberColors.neonRed.withOpacity(0.08),
                borderRadius: CyberRadius.small,
                border: Border.all(color: CyberColors.neonRed.withOpacity(0.4)),
              ),
              child: const Text(
                'Wrong decision. Analyse more carefully.',
                style: TextStyle(color: CyberColors.neonRed, fontSize: 12),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Report Phishing',
                  icon: Icons.report_outlined,
                  color: CyberColors.neonCyan,
                  onTap: onReport,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: CyberColors.neonRed,
                  onTap: onDelete,
                ),
              ),
              const SizedBox(width: 8),
              _HintButton(hintsLeft: hintsLeft, onTap: onHint),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  final int hintsLeft;
  final VoidCallback? onTap;
  const _HintButton({required this.hintsLeft, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CyberColors.neonAmber.withOpacity(onTap != null ? 0.1 : 0.04),
        borderRadius: CyberRadius.medium,
        border: Border.all(
          color: CyberColors.neonAmber.withOpacity(onTap != null ? 0.5 : 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: CyberColors.neonAmber.withOpacity(onTap != null ? 1 : 0.3),
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            '$hintsLeft',
            style: TextStyle(
              color: CyberColors.neonAmber.withOpacity(onTap != null ? 1 : 0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color.withOpacity(0.1),
    borderRadius: CyberRadius.medium,
    child: InkWell(
      borderRadius: CyberRadius.medium,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: CyberRadius.medium,
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  6. METADATA CORRELATION
// ═══════════════════════════════════════════════════════════════

class _MetadataCorrelationGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _MetadataCorrelationGame({
    required this.panelId,
    required this.minigame,
  });
  @override
  State<_MetadataCorrelationGame> createState() =>
      _MetadataCorrelationGameState();
}

class _MetadataCorrelationGameState extends State<_MetadataCorrelationGame> {
  final Map<String, String?> _selections = {};
  final Map<String, bool> _revealed = {};
  bool _submitted = false;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    _selections.clear();
    _revealed.clear();
    for (final f in widget.minigame.fragments) {
      _selections[f.id] = null;
      _revealed[f.id] = false;
    }
  }

  void _submit(CaseEngine engine) {
    final mg = widget.minigame;
    bool allCorrect = true;
    for (final f in mg.fragments) {
      if (_selections[f.id] != f.correctSuspectId) allCorrect = false;
      _revealed[f.id] = true;
    }
    setState(() => _submitted = true);
    if (allCorrect) {
      engine.solveMinigame(mg.id);
      setState(() => _success = true);
    } else
      HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  void _reset() {
    setState(() {
      _selections.clear();
      _revealed.clear();
      for (final f in widget.minigame.fragments) {
        _selections[f.id] = null;
        _revealed[f.id] = false;
      }
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonAmber,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.data_object,
                            color: CyberColors.neonAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.instruction ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...mg.fragments.map((frag) {
                  final sel = _selections[frag.id];
                  final revealed = _revealed[frag.id] ?? false;
                  final isCorrect = revealed && sel == frag.correctSuspectId;
                  final isWrong = revealed && sel != frag.correctSuspectId;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isCorrect) borderCol = CyberColors.neonGreen;
                  if (isWrong) borderCol = CyberColors.neonRed;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NeonContainer(
                      borderColor: borderCol,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: CyberColors.neonAmber.withOpacity(0.1),
                                  borderRadius: CyberRadius.pill,
                                  border: Border.all(
                                    color: CyberColors.neonAmber.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  frag.label,
                                  style: const TextStyle(
                                    color: CyberColors.neonAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isCorrect) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: CyberColors.neonGreen,
                                  size: 16,
                                ),
                              ],
                              if (isWrong) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.cancel,
                                  color: CyberColors.neonRed,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: CyberRadius.small,
                              border: Border.all(
                                color: CyberColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              frag.value,
                              style: const TextStyle(
                                fontFamily: 'DotMatrix',
                                color: CyberColors.textPrimary,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'POINTS TO:',
                            style: CyberText.caption.copyWith(
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CyberColors.bgCard,
                              borderRadius: CyberRadius.small,
                              border: Border.all(
                                color: isCorrect
                                    ? CyberColors.neonGreen.withOpacity(0.5)
                                    : isWrong
                                    ? CyberColors.neonRed.withOpacity(0.5)
                                    : CyberColors.neonCyan.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: sel,
                                hint: Text(
                                  'Select suspect...',
                                  style: TextStyle(
                                    color: CyberColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                dropdownColor: CyberColors.bgCard,
                                style: const TextStyle(
                                  color: CyberColors.textPrimary,
                                  fontSize: 13,
                                ),
                                isExpanded: true,
                                onChanged: _submitted
                                    ? null
                                    : (val) => setState(
                                        () => _selections[frag.id] = val,
                                      ),
                                items: mg.metaSuspects
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s['id'],
                                        child: Text(s['label'] ?? ''),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          if (revealed) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? CyberColors.neonGreen.withOpacity(0.08)
                                    : CyberColors.neonRed.withOpacity(0.08),
                                borderRadius: CyberRadius.small,
                                border: Border.all(
                                  color: isCorrect
                                      ? CyberColors.neonGreen.withOpacity(0.3)
                                      : CyberColors.neonRed.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isCorrect
                                    ? frag.explanation
                                    : 'Incorrect. ${frag.explanation}',
                                style: TextStyle(
                                  color: isCorrect
                                      ? CyberColors.neonGreen
                                      : CyberColors.neonRed,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CyberButton(
                        label: _submitted ? 'Try Again' : 'Submit',
                        icon: _submitted ? Icons.replay : Icons.check_outlined,
                        accentColor: CyberColors.neonAmber,
                        onTap: _submitted ? _reset : () => _submit(engine),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message:
                  mg.successMessage ??
                  'Metadata correlated. Evidence unlocked.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  7. ALIBI VERIFICATION
// ═══════════════════════════════════════════════════════════════

class _AlibiVerifyGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _AlibiVerifyGame({required this.panelId, required this.minigame});
  @override
  State<_AlibiVerifyGame> createState() => _AlibiVerifyGameState();
}

class _AlibiVerifyGameState extends State<_AlibiVerifyGame> {
  String? _selectedAlibiId;
  bool _submitted = false;
  bool _success = false;
  bool _wrong = false;
  int _hintsUsed = 0;
  String _hintText = '';
  bool _isDisposed = false;

  void _select(String alibiId, CaseEngine engine) {
    if (_submitted) return;
    final alibi = widget.minigame.alibis.firstWhere((a) => a.id == alibiId);
    setState(() {
      _selectedAlibiId = alibiId;
      _submitted = true;
    });
    if (alibi.isContradicted) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _wrong = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || _isDisposed) return;
        setState(() {
          _submitted = false;
          _wrong = false;
          _selectedAlibiId = null;
        });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final timeline = mg.timelineEvent;
    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.gavel_outlined,
                            color: CyberColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.instruction ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (timeline != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CyberColors.neonCyan.withOpacity(0.06),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: CyberColors.neonCyan,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CONFIRMED EVENT',
                              style: CyberText.caption.copyWith(
                                color: CyberColors.neonCyan,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeline['time'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'DotMatrix',
                            color: CyberColors.neonCyan,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeline['event'] ?? '',
                          style: CyberText.bodySmall.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'WHICH ALIBI IS CONTRADICTED BY THIS EVIDENCE?',
                  style: CyberText.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                ...mg.alibis.map((alibi) {
                  final isSel = _selectedAlibiId == alibi.id;
                  final isContra = isSel && _submitted && alibi.isContradicted;
                  final isWrongPick = isSel && _wrong && !alibi.isContradicted;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isContra) borderCol = CyberColors.neonRed;
                  if (isWrongPick) borderCol = CyberColors.neonAmber;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: CyberRadius.medium,
                        onTap: _submitted
                            ? null
                            : () => _select(alibi.id, engine),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isContra
                                ? CyberColors.neonRed.withOpacity(0.08)
                                : isWrongPick
                                ? CyberColors.neonAmber.withOpacity(0.06)
                                : CyberColors.bgCard,
                            borderRadius: CyberRadius.medium,
                            border: Border.all(color: borderCol, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CyberColors.neonCyan.withOpacity(
                                        0.1,
                                      ),
                                      border: Border.all(
                                        color: CyberColors.neonCyan.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        alibi.suspectName.isNotEmpty
                                            ? alibi.suspectName[0]
                                            : '?',
                                        style: const TextStyle(
                                          color: CyberColors.neonCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      alibi.suspectName,
                                      style: const TextStyle(
                                        color: CyberColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (isContra)
                                    const Icon(
                                      Icons.flag,
                                      color: CyberColors.neonRed,
                                      size: 18,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: CyberRadius.small,
                                  border: Border.all(
                                    color: CyberColors.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  '"${alibi.alibi}"',
                                  style: CyberText.bodySmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              if (isContra &&
                                  alibi.contradiction.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: CyberColors.neonRed.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: CyberRadius.small,
                                    border: Border.all(
                                      color: CyberColors.neonRed.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber,
                                        color: CyberColors.neonRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alibi.contradiction,
                                          style: const TextStyle(
                                            color: CyberColors.neonRed,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (_wrong) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'That alibi holds up. Look more carefully at the timeline.',
                      style: TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message:
                  mg.successMessage ?? 'Alibi contradicted. Evidence unlocked.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HASH VALIDATION — compare two SHA-256 hashes character by character
// ═══════════════════════════════════════════════════════════════

class _HashValidationGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _HashValidationGame({required this.panelId, required this.minigame});
  @override
  State<_HashValidationGame> createState() => _HashValidationGameState();
}

class _HashValidationGameState extends State<_HashValidationGame> {
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  final TextEditingController _divergenceCtrl = TextEditingController();
  String _feedback = '';

  void _confirm(CaseEngine engine) {
    final mg = widget.minigame;
    final hashA = mg.rawJson['hashA'] as String? ?? '';
    final hashB = mg.rawJson['hashB'] as String? ?? '';

    int divergeAt = -1;
    for (int i = 0; i < hashA.length && i < hashB.length; i++) {
      if (hashA[i] != hashB[i]) {
        divergeAt = i;
        break;
      }
    }
    if (divergeAt == -1 && hashA.length != hashB.length) {
      divergeAt = min(hashA.length, hashB.length);
    }

    final entered = int.tryParse(_divergenceCtrl.text.trim());
    final expected = divergeAt >= 0 ? divergeAt + 1 : 0;
    if (entered == expected && divergeAt >= 0) {
      engine.solveMinigame(widget.minigame.id);
      setState(() {
        _feedback = '';
        _success = true;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _feedback = divergeAt >= 0
          ? 'Not quite. Enter the first mismatch position as a number.'
          : 'These hashes do not diverge. Recheck the evidence.';
    });
    HapticFeedback.lightImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  void dispose() {
    _divergenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final hashA = mg.rawJson['hashA'] as String? ?? '';
    final hashB = mg.rawJson['hashB'] as String? ?? '';
    int divergeAt = -1;
    for (int i = 0; i < hashA.length && i < hashB.length; i++) {
      if (hashA[i] != hashB[i]) {
        divergeAt = i;
        break;
      }
    }

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonPurple,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.fingerprint,
                            color: CyberColors.neonPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['description'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _HashRow(
                  label: 'HASH A (Upload)',
                  hash: hashA,
                  compareHash: hashB,
                  color: CyberColors.neonCyan,
                ),
                const SizedBox(height: 12),
                _HashRow(
                  label: 'HASH B (Current)',
                  hash: hashB,
                  compareHash: hashA,
                  color: CyberColors.neonAmber,
                ),
                const SizedBox(height: 16),
                if (divergeAt >= 0)
                  NeonContainer(
                    borderColor: CyberColors.neonRed,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: CyberColors.neonRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hashes diverge at position ${divergeAt + 1} — file was modified after upload.',
                            style: const TextStyle(
                              color: CyberColors.neonRed,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  NeonContainer(
                    borderColor: CyberColors.neonGreen,
                    padding: const EdgeInsets.all(14),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: CyberColors.neonGreen,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hashes match — file is unmodified.',
                            style: TextStyle(
                              color: CyberColors.neonGreen,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  'ENTER FIRST MISMATCH POSITION',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _divergenceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: CyberColors.neonCyan,
                    fontFamily: 'DotMatrix',
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 1',
                    hintStyle: TextStyle(
                      color: CyberColors.textMuted.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: CyberColors.neonCyan.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: BorderSide(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: BorderSide(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: const BorderSide(color: CyberColors.neonCyan),
                    ),
                  ),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Submit Position',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonPurple,
                      onTap: () => _confirm(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Hash mismatch confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _HashRow extends StatelessWidget {
  final String label, hash, compareHash;
  final Color color;
  const _HashRow({
    required this.label,
    required this.hash,
    required this.compareHash,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CyberText.caption.copyWith(letterSpacing: 1.5, color: color),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: CyberRadius.small,
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Wrap(
            children: List.generate(hash.length, (i) {
              final isDiff =
                  i < compareHash.length && hash[i] != compareHash[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Text(
                  hash[i],
                  style: TextStyle(
                    fontFamily: 'DotMatrix',
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: isDiff
                        ? CyberColors.neonRed
                        : color.withOpacity(0.7),
                    fontWeight: isDiff ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PATTERN MATCH — read clues, type the correct pattern answer
// ═══════════════════════════════════════════════════════════════

class _PatternMatchGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _PatternMatchGame({required this.panelId, required this.minigame});
  @override
  State<_PatternMatchGame> createState() => _PatternMatchGameState();
}

class _PatternMatchGameState extends State<_PatternMatchGame> {
  final TextEditingController _ctrl = TextEditingController();
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';
  String? _selectedChoice;

  void _submit(CaseEngine engine) {
    final answer = _ctrl.text.trim().toLowerCase();
    final solution = (widget.minigame.solution ?? '').toLowerCase();
    final acceptedAnswers = <String>{
      solution,
      ...((widget.minigame.rawJson['acceptedAnswers'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase().trim())),
    };

    if (acceptedAnswers.contains(answer)) {
      engine.solveMinigame(widget.minigame.id);
      setState(() {
        _feedback = '';
        _success = true;
      });
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback = 'Incorrect pattern. Analyse the evidence again.',
      );
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final description = mg.rawJson['description'] as String? ?? mg.hint ?? '';
    final instruction = mg.instruction ?? mg.rawJson['instruction'] as String?;
    final choices = (mg.rawJson['choices'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonCyan,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.pattern,
                            color: CyberColors.neonCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                      if (instruction != null &&
                          instruction.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CyberColors.neonAmber.withOpacity(0.08),
                            borderRadius: CyberRadius.small,
                            border: Border.all(
                              color: CyberColors.neonAmber.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              color: CyberColors.neonAmber,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (choices.isNotEmpty) ...[
                  Text(
                    'SELECT A PATTERN LABEL',
                    style: CyberText.caption.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: choices.map((choice) {
                      final selected = _selectedChoice == choice;
                      return ChoiceChip(
                        label: Text(choice.toUpperCase()),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedChoice = choice;
                            _ctrl.text = choice;
                          });
                        },
                        selectedColor: CyberColors.neonCyan.withOpacity(0.25),
                        backgroundColor: CyberColors.bgCard,
                        side: BorderSide(
                          color: selected
                              ? CyberColors.neonCyan
                              : CyberColors.borderSubtle,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? CyberColors.neonCyan
                              : CyberColors.textPrimary,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],
                if (mg.hints.isNotEmpty) ...[
                  Text(
                    'EVIDENCE CLUES',
                    style: CyberText.caption.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  ...mg.hints
                      .take(3)
                      .map(
                        (h) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CyberColors.bgCard,
                            borderRadius: CyberRadius.small,
                            border: Border.all(color: CyberColors.borderSubtle),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_right,
                                color: CyberColors.neonCyan,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  h,
                                  style: CyberText.bodySmall.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'ENTER IDENTIFIED PATTERN',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  style: const TextStyle(
                    color: CyberColors.neonCyan,
                    fontFamily: 'DotMatrix',
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your answer...',
                    hintStyle: TextStyle(
                      color: CyberColors.textMuted.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: CyberColors.neonCyan.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: BorderSide(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: BorderSide(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: CyberRadius.small,
                      borderSide: const BorderSide(color: CyberColors.neonCyan),
                    ),
                  ),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Submit Pattern',
                      icon: Icons.check_outlined,
                      onTap: () => _submit(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Pattern identified.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TIMESTAMP ANOMALY — tap suspicious timestamps to flag them
// ═══════════════════════════════════════════════════════════════

class _TimestampAnomalyGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _TimestampAnomalyGame({required this.panelId, required this.minigame});
  @override
  State<_TimestampAnomalyGame> createState() => _TimestampAnomalyGameState();
}

class _TimestampAnomalyGameState extends State<_TimestampAnomalyGame> {
  final Set<String> _flagged = {};
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  void _toggle(String key) {
    setState(() {
      if (_flagged.contains(key))
        _flagged.remove(key);
      else
        _flagged.add(key);
    });
    HapticFeedback.selectionClick();
  }

  void _submit(CaseEngine engine) {
    final files = (widget.minigame.rawJson['files'] as List<dynamic>? ?? []);
    final Set<String> correctKeys = {};
    for (final file in files) {
      final fname = file['name'] as String;
      final timestamps = file['timestamps'] as List<dynamic>? ?? [];
      for (final ts in timestamps) {
        final key = '$fname:${ts['field']}';
        if (ts['isSuspicious'] == true) correctKeys.add(key);
      }
    }
    if (_flagged.containsAll(correctKeys) &&
        correctKeys.containsAll(_flagged)) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'Not quite. Check the timestamps again — look for the suspicious window.',
      );
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final files = (mg.rawJson['files'] as List<dynamic>? ?? []);
    final description = mg.rawJson['description'] as String? ?? mg.hint ?? '';

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonAmber,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_filled,
                            color: CyberColors.neonAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.07),
                    borderRadius: CyberRadius.small,
                    border: Border.all(
                      color: CyberColors.neonCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        color: CyberColors.neonCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tap a timestamp row to flag it as suspicious.',
                          style: TextStyle(
                            color: CyberColors.neonCyan,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...files.map((file) {
                  final fname = file['name'] as String;
                  final timestamps = file['timestamps'] as List<dynamic>? ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NeonContainer(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_outlined,
                                  color: CyberColors.neonCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  fname,
                                  style: const TextStyle(
                                    color: CyberColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...timestamps.map((ts) {
                            final key = '$fname:${ts['field']}';
                            final isFlagged = _flagged.contains(key);
                            return GestureDetector(
                              onTap: () => _toggle(key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isFlagged
                                      ? CyberColors.neonRed.withOpacity(0.10)
                                      : Colors.transparent,
                                  border: Border(
                                    top: BorderSide(
                                      color: CyberColors.borderSubtle,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        ts['field'] as String,
                                        style: CyberText.caption.copyWith(
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        ts['value'] as String,
                                        style: TextStyle(
                                          fontFamily: 'DotMatrix',
                                          fontSize: 13,
                                          color: isFlagged
                                              ? CyberColors.neonRed
                                              : CyberColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        isFlagged
                                            ? Icons.flag
                                            : Icons.flag_outlined,
                                        key: ValueKey(isFlagged),
                                        color: isFlagged
                                            ? CyberColors.neonRed
                                            : CyberColors.textMuted,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Submit Flags',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonAmber,
                      onTap: () => _submit(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Anomaly confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EVENT SORT — drag events into correct chronological order
// ═══════════════════════════════════════════════════════════════

class _EventSortGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _EventSortGame({required this.panelId, required this.minigame});
  @override
  State<_EventSortGame> createState() => _EventSortGameState();
}

class _EventSortGameState extends State<_EventSortGame> {
  late List<Map<String, dynamic>> _events;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    final raw = (widget.minigame.rawJson['events'] as List<dynamic>? ?? []);
    _events = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _events.shuffle();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _events.removeAt(oldIndex);
      _events.insert(newIndex, item);
    });
  }

  void _submit(CaseEngine engine) {
    final chronological = _isChronologicalOrder(_events);
    bool isCorrect = chronological ?? false;
    if (chronological == null) {
      // Fallback for legacy configurations with non-time based solutions.
      final solutionOrder =
          (widget.minigame.rawJson['solution_order'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList();
      final currentOrder = _events.map((e) => e['id'] as String).toList();
      isCorrect = currentOrder.join(',') == solutionOrder.join(',');
    }

    if (isCorrect) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'Order incorrect. Arrange the events in chronological order.',
      );
      HapticFeedback.lightImpact();
    }
  }

  bool? _isChronologicalOrder(List<Map<String, dynamic>> events) {
    final minutes = <int>[];
    for (final e in events) {
      final raw = (e['time'] as String?)?.trim() ?? '';
      final parsed = _parseTimeToMinutes(raw);
      if (parsed == null) return null;
      minutes.add(parsed);
    }
    for (int i = 1; i < minutes.length; i++) {
      // Same-minute events can appear in any order.
      if (minutes[i] < minutes[i - 1]) return false;
    }
    return true;
  }

  int? _parseTimeToMinutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h * 60) + m;
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NeonContainer(
                      borderColor: CyberColors.neonCyan,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.sort,
                                color: CyberColors.neonCyan,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mg.title,
                                  style: CyberText.sectionTitle.copyWith(
                                    color: CyberColors.neonCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mg.rawJson['description'] as String? ??
                                mg.hint ??
                                '',
                            style: CyberText.bodySmall.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CyberColors.neonCyan.withOpacity(0.07),
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: CyberColors.neonCyan.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.drag_handle,
                            color: CyberColors.neonCyan,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drag events into the correct chronological order.',
                              style: TextStyle(
                                color: CyberColors.neonCyan,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: _events.length,
                  onReorder: _reorder,
                  itemBuilder: (ctx, i) {
                    final ev = _events[i];
                    return Container(
                      key: ValueKey(ev['id']),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CyberColors.bgCard,
                        borderRadius: CyberRadius.small,
                        border: Border.all(color: CyberColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CyberColors.neonCyan.withOpacity(0.1),
                              borderRadius: CyberRadius.pill,
                              border: Border.all(
                                color: CyberColors.neonCyan.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              ev['time'] as String? ?? '',
                              style: const TextStyle(
                                fontFamily: 'DotMatrix',
                                color: CyberColors.neonCyan,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ev['label'] as String? ?? '',
                              style: CyberText.bodySmall.copyWith(fontSize: 13),
                            ),
                          ),
                          const Icon(
                            Icons.drag_handle,
                            color: CyberColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    if (_feedback.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: CyberColors.neonRed.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: CyberColors.neonRed.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _feedback,
                          style: const TextStyle(
                            color: CyberColors.neonRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    if (_hintText.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: CyberColors.neonAmber.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: CyberColors.neonAmber.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _hintText,
                          style: const TextStyle(
                            color: CyberColors.neonAmber,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        CyberButton(
                          label: 'Submit Order',
                          icon: Icons.check_outlined,
                          accentColor: CyberColors.neonCyan,
                          onTap: () => _submit(engine),
                        ),
                        CyberButton(
                          label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                          icon: Icons.lightbulb_outline,
                          isOutlined: true,
                          isSmall: true,
                          accentColor: CyberColors.neonAmber,
                          onTap: _hintsUsed < mg.hints.length
                              ? () => _hint(engine)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Sequence reconstructed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COMMAND CLASSIFY — select flags proving manual execution
// ═══════════════════════════════════════════════════════════════

class _CommandClassifyGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CommandClassifyGame({required this.panelId, required this.minigame});
  @override
  State<_CommandClassifyGame> createState() => _CommandClassifyGameState();
}

class _CommandClassifyGameState extends State<_CommandClassifyGame> {
  final Set<String> _selected = {};
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id))
        _selected.remove(id);
      else
        _selected.add(id);
    });
    HapticFeedback.selectionClick();
  }

  void _submit(CaseEngine engine) {
    final correctFlags =
        (widget.minigame.rawJson['correctFlags'] as List<dynamic>? ?? []);
    final correctIds = correctFlags
        .where((f) => (f as Map)['isCorrect'] == true)
        .map((f) => (f as Map)['id'] as String)
        .toSet();
    if (_selected.containsAll(correctIds) &&
        correctIds.containsAll(_selected)) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'Some flags are wrong. Compare the command against the cron schedule carefully.',
      );
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final compData =
        mg.rawJson['comparisonData'] as Map<String, dynamic>? ?? {};
    final cronEntries = (compData['cronEntries'] as List<dynamic>? ?? []);
    final detected = compData['detectedCommand'] as Map<String, dynamic>? ?? {};
    final correctFlags = (mg.rawJson['correctFlags'] as List<dynamic>? ?? []);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.terminal,
                            color: CyberColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DETECTED COMMAND',
                  style: CyberText.caption.copyWith(
                    letterSpacing: 1.5,
                    color: CyberColors.neonRed,
                  ),
                ),
                const SizedBox(height: 8),
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CmdRow(
                        'Time',
                        detected['time'] as String? ?? '',
                        CyberColors.neonRed,
                      ),
                      const SizedBox(height: 6),
                      _CmdRow(
                        'Command',
                        detected['command'] as String? ?? '',
                        CyberColors.neonAmber,
                      ),
                      const SizedBox(height: 6),
                      _CmdRow(
                        'Session User',
                        detected['sessionUser'] as String? ?? '',
                        CyberColors.textPrimary,
                      ),
                      const SizedBox(height: 6),
                      _CmdRow(
                        'Type',
                        detected['type'] as String? ?? '',
                        CyberColors.neonRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CRON SCHEDULE',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                ...cronEntries.map((entry) {
                  final e = entry as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.bgCard,
                      borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['time'] as String? ?? '',
                                style: const TextStyle(
                                  fontFamily: 'DotMatrix',
                                  color: CyberColors.neonCyan,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e['command'] as String? ?? '',
                                style: CyberText.bodySmall.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CyberColors.neonGreen.withOpacity(0.1),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(
                              color: CyberColors.neonGreen.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            e['type'] as String? ?? 'Scheduled',
                            style: const TextStyle(
                              color: CyberColors.neonGreen,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'SELECT ALL FLAGS THAT PROVE MANUAL EXECUTION',
                  style: CyberText.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                ...correctFlags.map((flag) {
                  final f = flag as Map<String, dynamic>;
                  final id = f['id'] as String;
                  final label = f['label'] as String? ?? '';
                  final isSel = _selected.contains(id);
                  return GestureDetector(
                    onTap: () => _toggle(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? CyberColors.neonCyan.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: isSel
                              ? CyberColors.neonCyan
                              : CyberColors.borderSubtle,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: isSel
                                ? CyberColors.neonCyan
                                : CyberColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSel
                                    ? CyberColors.textPrimary
                                    : CyberColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Submit Flags',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonRed,
                      onTap: () => _submit(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Manual execution confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _CmdRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CmdRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 90,
        child: Text(label, style: CyberText.caption.copyWith(fontSize: 11)),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontFamily: 'DotMatrix',
            color: color,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════
//  TIMELINE RECONSTRUCT — place events into correct time slots
// ═══════════════════════════════════════════════════════════════

class _TimelineReconstructGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _TimelineReconstructGame({
    required this.panelId,
    required this.minigame,
  });
  @override
  State<_TimelineReconstructGame> createState() =>
      _TimelineReconstructGameState();
}

class _TimelineReconstructGameState extends State<_TimelineReconstructGame> {
  late List<Map<String, dynamic>> _unplaced;
  final List<String> _slotKeys = [];
  final Map<String, String> _slotLabelByKey = {};
  final Map<String, int> _slotCapacity = {};
  final Map<String, List<String>> _slots = {};
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    final raw = (widget.minigame.rawJson['events'] as List<dynamic>? ?? []);
    _unplaced = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final slotsRaw =
        (widget.minigame.rawJson['timeSlots'] as List<dynamic>? ?? []);

    for (int i = 0; i < slotsRaw.length; i++) {
      final slot = slotsRaw[i];
      if (slot is Map) {
        final slotMap = Map<String, dynamic>.from(slot as Map);
        final slotId = slotMap['id'] as String? ?? 'slot_${i + 1}';
        final label = slotMap['label'] as String? ?? slotId;
        _slotKeys.add(slotId);
        _slotLabelByKey[slotId] = label;
        _slots[slotId] = <String>[];
      } else {
        final label = slot.toString();
        final key = '$label#$i';
        _slotKeys.add(key);
        _slotLabelByKey[key] = label;
        _slots[key] = <String>[];
      }
    }

    final requiredByLabel = <String, int>{};
    for (final e in raw) {
      final ev = Map<String, dynamic>.from(e as Map);
      if (ev['isDecoy'] == true) continue;
      final label = ev['correctSlot'] as String?;
      if (label == null || label.isEmpty) continue;
      requiredByLabel[label] = (requiredByLabel[label] ?? 0) + 1;
    }

    final keysByLabel = <String, List<String>>{};
    for (final key in _slotKeys) {
      final label = _slotLabelByKey[key]!;
      keysByLabel.putIfAbsent(label, () => <String>[]).add(key);
    }
    for (final entry in keysByLabel.entries) {
      final keys = entry.value;
      final required = requiredByLabel[entry.key] ?? 0;
      for (final key in keys) {
        _slotCapacity[key] = 1;
      }
      if (required > keys.length && keys.isNotEmpty) {
        _slotCapacity[keys.first] = 1 + (required - keys.length);
      }
    }
  }

  Map<String, dynamic>? _eventById(String eventId) {
    final rawEvents =
        (widget.minigame.rawJson['events'] as List<dynamic>? ?? []);
    for (final e in rawEvents) {
      final ev = Map<String, dynamic>.from(e as Map);
      if (ev['id'] == eventId) return ev;
    }
    return null;
  }

  void _removeEventEverywhere(String eventId) {
    _unplaced.removeWhere((e) => e['id'] == eventId);
    for (final key in _slotKeys) {
      _slots[key]!.remove(eventId);
    }
  }

  void _returnToTop(String eventId) {
    final ev = _eventById(eventId);
    if (ev == null) return;
    setState(() {
      _removeEventEverywhere(eventId);
      _unplaced.insert(0, ev);
    });
    HapticFeedback.selectionClick();
  }

  void _place(String slotKey, String eventId) {
    setState(() {
      _removeEventEverywhere(eventId);
      final slotEvents = _slots[slotKey]!;
      slotEvents.add(eventId);
      final cap = _slotCapacity[slotKey] ?? 1;
      while (slotEvents.length > cap) {
        final evictedId = slotEvents.removeAt(0);
        final evictedEvent = _eventById(evictedId);
        if (evictedEvent != null) {
          _unplaced.insert(0, evictedEvent);
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  void _submit(CaseEngine engine) {
    final events = (widget.minigame.rawJson['events'] as List<dynamic>? ?? []);
    bool allCorrect = true;
    for (final e in events) {
      final ev = e as Map<String, dynamic>;
      if (ev['isDecoy'] == true) continue;
      final correctSlotLabel = ev['correctSlot'] as String?;
      if (correctSlotLabel == null || correctSlotLabel.isEmpty) {
        allCorrect = false;
        break;
      }
      String? placedSlotLabel;
      for (final key in _slotKeys) {
        if (_slots[key]!.contains(ev['id'])) {
          placedSlotLabel = _slotLabelByKey[key];
          break;
        }
      }
      if (placedSlotLabel != correctSlotLabel) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect && _unplaced.every((e) => e['isDecoy'] == true)) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'Some events are misplaced. Check the timestamps again.',
      );
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonPurple,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timeline,
                            color: CyberColors.neonPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AVAILABLE EVENTS',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _unplaced
                      .map(
                        (ev) => Draggable<String>(
                          data: ev['id'] as String,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CyberColors.neonPurple.withOpacity(0.3),
                                borderRadius: CyberRadius.small,
                                border: Border.all(
                                  color: CyberColors.neonPurple,
                                ),
                              ),
                              child: Text(
                                ev['label'] as String? ?? '',
                                style: const TextStyle(
                                  color: CyberColors.neonPurple,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _EventChip(
                              label: ev['label'] as String? ?? '',
                            ),
                          ),
                          child: _EventChip(
                            label: ev['label'] as String? ?? '',
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'TIMELINE - DRAG EVENTS TO THEIR SLOT',
                  style: CyberText.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                ..._slotKeys.map((slotKey) {
                  final slotLabel = _slotLabelByKey[slotKey] ?? slotKey;
                  final placedIds = _slots[slotKey]!;
                  return DragTarget<String>(
                    onAcceptWithDetails: (details) =>
                        _place(slotKey, details.data),
                    builder: (ctx, candidateData, _) {
                      final isHovering = candidateData.isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isHovering
                              ? CyberColors.neonPurple.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: isHovering
                                ? CyberColors.neonPurple
                                : CyberColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: CyberColors.neonCyan.withOpacity(0.08),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(6),
                                ),
                              ),
                              child: Text(
                                slotLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'DotMatrix',
                                  color: CyberColors.neonCyan,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: placedIds.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: placedIds.map((eventId) {
                                          final placedEvent = _eventById(
                                            eventId,
                                          );
                                          final label =
                                              placedEvent?['label']
                                                  as String? ??
                                              eventId;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CyberColors.bgCard,
                                              borderRadius: CyberRadius.small,
                                              border: Border.all(
                                                color: CyberColors.borderSubtle,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    label,
                                                    style: const TextStyle(
                                                      color: CyberColors
                                                          .textPrimary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Tooltip(
                                                  message:
                                                      'Return to available events',
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () =>
                                                        _returnToTop(eventId),
                                                    child: SizedBox(
                                                      width: 30,
                                                      height: 30,
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: CyberColors
                                                            .textMuted,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : Text(
                                        'Drop event here',
                                        style: TextStyle(
                                          color: CyberColors.textMuted
                                              .withOpacity(0.5),
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Submit Timeline',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonPurple,
                      onTap: () => _submit(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Timeline reconstructed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  final String label;
  const _EventChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: CyberColors.neonPurple.withOpacity(0.1),
      borderRadius: CyberRadius.small,
      border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: const TextStyle(color: CyberColors.neonPurple, fontSize: 12),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  VAD SCAN — select the suspicious memory region
// ═══════════════════════════════════════════════════════════════

class _VadScanGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _VadScanGame({required this.panelId, required this.minigame});
  @override
  State<_VadScanGame> createState() => _VadScanGameState();
}

class _VadScanGameState extends State<_VadScanGame> {
  String? _selected;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  void _select(String addr, CaseEngine engine) {
    setState(() => _selected = addr);
    final correct =
        widget.minigame.rawJson['correctSelection'] as String? ?? '';
    if (addr == correct) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () =>
            _feedback = 'That region looks normal. Check the protection flags.',
      );
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _feedback = '';
            _selected = null;
          });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final entries = (mg.rawJson['vadEntries'] as List<dynamic>? ?? []);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.memory,
                            color: CyberColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  color: CyberColors.neonRed.withOpacity(0.05),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          'START ADDR',
                          style: TextStyle(
                            color: CyberColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          'FLAGS',
                          style: TextStyle(
                            color: CyberColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          'TYPE',
                          style: TextStyle(
                            color: CyberColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'BINARY',
                          style: TextStyle(
                            color: CyberColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...entries.map((entry) {
                  final e = entry as Map<String, dynamic>;
                  final addr = e['startAddress'] as String? ?? '';
                  final isSelected = _selected == addr;
                  final flags = e['protectionFlags'] as String? ?? '';
                  final hasRwx = flags == 'RWX';
                  return GestureDetector(
                    onTap: () => _select(addr, engine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CyberColors.neonRed.withOpacity(0.12)
                            : Colors.transparent,
                        border: Border(
                          top: BorderSide(
                            color: CyberColors.borderSubtle,
                            width: 0.5,
                          ),
                          left: isSelected
                              ? const BorderSide(
                                  color: CyberColors.neonRed,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              addr,
                              style: const TextStyle(
                                fontFamily: 'DotMatrix',
                                color: CyberColors.neonCyan,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: hasRwx
                                    ? CyberColors.neonRed.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: CyberRadius.pill,
                                border: hasRwx
                                    ? Border.all(
                                        color: CyberColors.neonRed.withOpacity(
                                          0.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Text(
                                flags,
                                style: TextStyle(
                                  fontFamily: 'DotMatrix',
                                  fontSize: 11,
                                  color: hasRwx
                                      ? CyberColors.neonRed
                                      : CyberColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              e['type'] as String? ?? '',
                              style: CyberText.bodySmall.copyWith(fontSize: 11),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e['mappedFile'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 11,
                                color:
                                    (e['mappedFile'] as String? ?? '') == 'NONE'
                                    ? CyberColors.neonRed
                                    : CyberColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Injected region identified.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROCESS TREE — select the suspicious process/thread
// ═══════════════════════════════════════════════════════════════

class _ProcessTreeGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _ProcessTreeGame({required this.panelId, required this.minigame});
  @override
  State<_ProcessTreeGame> createState() => _ProcessTreeGameState();
}

class _ProcessTreeGameState extends State<_ProcessTreeGame> {
  int? _selected;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  void _select(int index, CaseEngine engine) {
    setState(() => _selected = index);
    final processes =
        (widget.minigame.rawJson['processes'] as List<dynamic>? ?? []);
    final entry = processes[index] as Map<String, dynamic>;
    final isSuspicious = entry['isSuspicious'] == true;
    if (isSuspicious) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'That process looks legitimate. Check which entry has no on-disk binary.',
      );
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _feedback = '';
            _selected = null;
          });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final processes = (mg.rawJson['processes'] as List<dynamic>? ?? []);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_tree_outlined,
                            color: CyberColors.neonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...processes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final proc = entry.value as Map<String, dynamic>;
                  final isSelected = _selected == i;
                  final hasBinary =
                      (proc['onDiskBinary'] as String? ?? '') != 'NONE';
                  return GestureDetector(
                    onTap: () => _select(i, engine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CyberColors.neonRed.withOpacity(0.10)
                            : CyberColors.bgCard,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: isSelected
                              ? CyberColors.neonRed
                              : (!hasBinary
                                    ? CyberColors.neonRed.withOpacity(0.3)
                                    : CyberColors.borderSubtle),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings_applications_outlined,
                                color: hasBinary
                                    ? CyberColors.neonCyan
                                    : CyberColors.neonRed,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  proc['name'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: hasBinary
                                        ? CyberColors.textPrimary
                                        : CyberColors.neonRed,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CyberColors.neonCyan.withOpacity(0.1),
                                  borderRadius: CyberRadius.pill,
                                ),
                                child: Text(
                                  'PID ${proc['pid']}',
                                  style: const TextStyle(
                                    fontFamily: 'DotMatrix',
                                    color: CyberColors.neonCyan,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ProcRow('Parent', proc['parent'] as String? ?? ''),
                          _ProcRow('Memory', '${proc['memoryMB']} MB'),
                          _ProcRow(
                            'On-Disk Binary',
                            proc['onDiskBinary'] as String? ?? 'NONE',
                            valueColor: hasBinary ? null : CyberColors.neonRed,
                          ),
                          if (proc['thread'] != null)
                            _ProcRow(
                              'Thread',
                              '${proc['thread']}',
                              valueColor: CyberColors.neonAmber,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Phantom process identified.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _ProcRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ProcRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: CyberText.caption.copyWith(fontSize: 11)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'DotMatrix',
              fontSize: 11,
              color: valueColor ?? CyberColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  SOCKET MAP — select the suspicious network connection
// ═══════════════════════════════════════════════════════════════

class _SocketMapGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _SocketMapGame({required this.panelId, required this.minigame});
  @override
  State<_SocketMapGame> createState() => _SocketMapGameState();
}

class _SocketMapGameState extends State<_SocketMapGame> {
  int? _selected;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';

  void _select(int index, CaseEngine engine) {
    setState(() => _selected = index);
    final connections =
        (widget.minigame.rawJson['connections'] as List<dynamic>? ?? []);
    final conn = connections[index] as Map<String, dynamic>;
    if (conn['isSuspicious'] == true) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'That connection is legitimate. Look for one with no on-disk binary.',
      );
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _feedback = '';
            _selected = null;
          });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final connections = (mg.rawJson['connections'] as List<dynamic>? ?? []);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonCyan,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lan_outlined,
                            color: CyberColors.neonCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...connections.asMap().entries.map((entry) {
                  final i = entry.key;
                  final conn = entry.value as Map<String, dynamic>;
                  final isSelected = _selected == i;
                  final noBinary =
                      (conn['onDiskBinary'] as String? ?? '') == 'NONE';
                  return GestureDetector(
                    onTap: () => _select(i, engine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CyberColors.neonRed.withOpacity(0.10)
                            : CyberColors.bgCard,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: isSelected
                              ? CyberColors.neonRed
                              : (noBinary
                                    ? CyberColors.neonRed.withOpacity(0.25)
                                    : CyberColors.borderSubtle),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CyberColors.neonCyan.withOpacity(0.1),
                                  borderRadius: CyberRadius.pill,
                                  border: Border.all(
                                    color: CyberColors.neonCyan.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  conn['protocol'] as String? ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'DotMatrix',
                                    color: CyberColors.neonCyan,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  conn['processName'] as String? ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ProcRow(
                            'Local',
                            conn['localAddress'] as String? ?? '',
                          ),
                          _ProcRow(
                            'Remote',
                            conn['remoteAddress'] as String? ?? '',
                          ),
                          _ProcRow(
                            'Binary',
                            conn['onDiskBinary'] as String? ?? 'NONE',
                            valueColor: noBinary ? CyberColors.neonRed : null,
                          ),
                          _ProcRow(
                            'Class',
                            conn['classification'] as String? ?? '',
                            valueColor: noBinary
                                ? CyberColors.neonRed
                                : CyberColors.neonGreen,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'C2 channel identified.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  IMAGE ZOOM DETECT — select the region with compositing artifacts
// ═══════════════════════════════════════════════════════════════

class _ImageZoomDetectGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _ImageZoomDetectGame({required this.panelId, required this.minigame});
  @override
  State<_ImageZoomDetectGame> createState() => _ImageZoomDetectGameState();
}

class _ImageZoomDetectGameState extends State<_ImageZoomDetectGame> {
  String? _selected;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';
  double _contrast = 0.5;

  void _select(String id, bool isCorrect, CaseEngine engine) {
    setState(() => _selected = id);
    if (isCorrect) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'Wrong region. Increase contrast and look at the edges of the subject.',
      );
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _feedback = '';
            _selected = null;
          });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final regions = (mg.rawJson['targetRegions'] as List<dynamic>? ?? []);

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonAmber,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.image_search,
                            color: CyberColors.neonAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: CyberRadius.medium,
                    border: Border.all(
                      color: CyberColors.neonAmber.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Opacity(
                          opacity: _contrast,
                          child: CustomPaint(
                            size: const Size(200, 160),
                            painter: _ArtifactPainter(contrast: _contrast),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.brightness_6,
                              color: CyberColors.neonAmber,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                  activeTrackColor: CyberColors.neonAmber,
                                  inactiveTrackColor: CyberColors.neonAmber
                                      .withOpacity(0.2),
                                  thumbColor: CyberColors.neonAmber,
                                ),
                                child: Slider(
                                  value: _contrast,
                                  onChanged: (v) =>
                                      setState(() => _contrast = v),
                                ),
                              ),
                            ),
                            Text(
                              '${(_contrast * 100).round()}%',
                              style: const TextStyle(
                                color: CyberColors.neonAmber,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SELECT THE REGION WITH COMPOSITING ARTIFACTS',
                  style: CyberText.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                ...regions.map((r) {
                  final region = r as Map<String, dynamic>;
                  final id = region['id'] as String;
                  final label = region['label'] as String? ?? '';
                  final isCorrect = region['isCorrect'] == true;
                  final isSelected = _selected == id;
                  return GestureDetector(
                    onTap: () => _select(id, isCorrect, engine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CyberColors.neonAmber.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: isSelected
                              ? CyberColors.neonAmber
                              : CyberColors.borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? CyberColors.neonAmber
                                : CyberColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? CyberColors.textPrimary
                                  : CyberColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonRed.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Compositing artifact confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _ArtifactPainter extends CustomPainter {
  final double contrast;
  _ArtifactPainter({required this.contrast});
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = CyberColors.neonAmber.withOpacity(0.15 + contrast * 0.2);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.35,
        10,
        size.width * 0.3,
        size.height * 0.25,
      ),
      bodyPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.32,
        size.width * 0.5,
        size.height * 0.6,
      ),
      bodyPaint,
    );
    if (contrast > 0.4) {
      final artifactPaint = Paint()
        ..color = CyberColors.neonRed.withOpacity((contrast - 0.4) * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * 0.3,
          15,
          size.width * 0.4,
          size.height * 0.22,
        ),
        3.14,
        3.14,
        false,
        artifactPaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.25, size.height * 0.32),
        Offset(size.width * 0.27, size.height * 0.28),
        artifactPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArtifactPainter old) => old.contrast != contrast;
}

// ═══════════════════════════════════════════════════════════════
//  SERIAL DECODE — reveal and check USB serial segments
// ═══════════════════════════════════════════════════════════════

class _SerialDecodeGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _SerialDecodeGame({required this.panelId, required this.minigame});
  @override
  State<_SerialDecodeGame> createState() => _SerialDecodeGameState();
}

class _SerialDecodeGameState extends State<_SerialDecodeGame> {
  final Set<int> _revealed = {};
  bool _checkedAsset = false;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  void _reveal(int index) => setState(() => _revealed.add(index));

  void _checkAsset(CaseEngine engine) {
    setState(() => _checkedAsset = true);
    final assetCheck =
        widget.minigame.rawJson['assetRegisterCheck']
            as Map<String, dynamic>? ??
        {};
    final found = assetCheck['found'] as bool? ?? false;
    if (!found) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final serial = mg.rawJson['serialNumber'] as String? ?? '';
    final formatKey = (mg.rawJson['formatKey'] as List<dynamic>? ?? []);
    final assetCheck =
        mg.rawJson['assetRegisterCheck'] as Map<String, dynamic>? ?? {};

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonPurple,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.usb,
                            color: CyberColors.neonPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['description'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DEVICE SERIAL NUMBER',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CyberColors.neonPurple.withOpacity(0.06),
                    borderRadius: CyberRadius.small,
                    border: Border.all(
                      color: CyberColors.neonPurple.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    serial,
                    style: const TextStyle(
                      fontFamily: 'DotMatrix',
                      color: CyberColors.neonPurple,
                      fontSize: 22,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'FORMAT KEY — TAP EACH SEGMENT TO DECODE',
                  style: CyberText.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                ...formatKey.asMap().entries.map((entry) {
                  final i = entry.key;
                  final seg = entry.value as Map<String, dynamic>;
                  final isRevealed = _revealed.contains(i);
                  return GestureDetector(
                    onTap: () => _reveal(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRevealed
                            ? CyberColors.neonPurple.withOpacity(0.10)
                            : CyberColors.bgCard,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: isRevealed
                              ? CyberColors.neonPurple
                              : CyberColors.borderSubtle,
                          width: isRevealed ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CyberColors.neonCyan.withOpacity(0.1),
                                  borderRadius: CyberRadius.pill,
                                ),
                                child: Text(
                                  'Pos ${seg['positions']}',
                                  style: const TextStyle(
                                    fontFamily: 'DotMatrix',
                                    color: CyberColors.neonCyan,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                seg['field'] as String? ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isRevealed ? 'DECODED' : 'TAP TO DECODE',
                                style: TextStyle(
                                  color: isRevealed
                                      ? CyberColors.neonGreen
                                      : CyberColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Value: ${seg['value']}',
                            style: const TextStyle(
                              fontFamily: 'DotMatrix',
                              color: CyberColors.neonAmber,
                              fontSize: 13,
                            ),
                          ),
                          if (isRevealed) ...[
                            const SizedBox(height: 6),
                            Text(
                              '→ ${seg['decoded']}',
                              style: const TextStyle(
                                color: CyberColors.neonGreen,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _checkedAsset
                        ? CyberColors.neonRed.withOpacity(0.08)
                        : CyberColors.bgCard,
                    borderRadius: CyberRadius.small,
                    border: Border.all(
                      color: _checkedAsset
                          ? CyberColors.neonRed.withOpacity(0.5)
                          : CyberColors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storage,
                            color: CyberColors.neonCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ASSET REGISTER CHECK',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Serial: ${assetCheck['serialNumber'] ?? serial}',
                        style: const TextStyle(
                          fontFamily: 'DotMatrix',
                          fontSize: 12,
                          color: CyberColors.textSecondary,
                        ),
                      ),
                      if (_checkedAsset) ...[
                        const SizedBox(height: 8),
                        Text(
                          assetCheck['result'] as String? ?? 'NOT FOUND',
                          style: const TextStyle(
                            color: CyberColors.neonRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Run Asset Check',
                      icon: Icons.search,
                      accentColor: CyberColors.neonPurple,
                      onTap: () => _checkAsset(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Device identified as personal.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  REGISTRY NAV — expandable tree to find the target key
// ═══════════════════════════════════════════════════════════════

class _RegistryNavGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _RegistryNavGame({required this.panelId, required this.minigame});
  @override
  State<_RegistryNavGame> createState() => _RegistryNavGameState();
}

class _RegistryNavGameState extends State<_RegistryNavGame> {
  final Set<String> _expanded = {};
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  CaseEngine? _engine;

  void _toggle(String path) => setState(() {
    if (_expanded.contains(path))
      _expanded.remove(path);
    else
      _expanded.add(path);
  });

  void _onLeafTap(Map<String, dynamic> node, CaseEngine engine) {
    if (node['_target'] == true) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  List<Widget> _buildTree(Map<String, dynamic> node, String path, int depth) {
    final result = <Widget>[];
    for (final key in node.keys) {
      if (key.startsWith('_')) continue;
      final value = node[key];
      final fullPath = '$path/$key';
      final isLeaf = value is Map && value['_leaf'] == true;
      final isTarget = value is Map && value['_target'] == true;
      final isExpanded = _expanded.contains(fullPath);
      if (value is Map && !isLeaf) {
        result.add(
          GestureDetector(
            onTap: () => _toggle(fullPath),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: EdgeInsets.only(
                left: 12.0 + depth * 16,
                top: 8,
                bottom: 8,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: isExpanded
                    ? CyberColors.neonCyan.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: CyberRadius.small,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: CyberColors.neonCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.folder_outlined,
                    color: CyberColors.neonAmber,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      key,
                      style: const TextStyle(
                        color: CyberColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (isExpanded) {
          result.addAll(
            _buildTree(value as Map<String, dynamic>, fullPath, depth + 1),
          );
        }
      } else if (isLeaf || isTarget) {
        final extra = (value as Map<String, dynamic>).entries
            .where((e) => !e.key.startsWith('_'))
            .map((e) => '${e.key}: ${e.value}')
            .join('  |  ');
        result.add(
          GestureDetector(
            onTap: () {
              if (_engine != null) _onLeafTap(value, _engine!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 2),
              padding: EdgeInsets.only(
                left: 12.0 + depth * 16,
                top: 10,
                bottom: 10,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: isTarget
                    ? CyberColors.neonGreen.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: CyberRadius.small,
                border: isTarget
                    ? Border.all(color: CyberColors.neonGreen.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.vpn_key_outlined,
                        color: isTarget
                            ? CyberColors.neonGreen
                            : CyberColors.neonPurple,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            color: isTarget
                                ? CyberColors.neonGreen
                                : CyberColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isTarget
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.only(left: 22),
                      child: Text(
                        extra,
                        style: const TextStyle(
                          fontFamily: 'DotMatrix',
                          fontSize: 10,
                          color: CyberColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    _engine = CaseEngineProvider.of(context);
    final engine = _engine!;
    final mg = widget.minigame;
    final tree = mg.rawJson['tree'] as Map<String, dynamic>? ?? {};
    final targetPath = mg.rawJson['targetPath'] as String? ?? '';

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NeonContainer(
                      borderColor: CyberColors.neonGreen,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.device_hub,
                                color: CyberColors.neonGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mg.title,
                                  style: CyberText.sectionTitle.copyWith(
                                    color: CyberColors.neonGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mg.rawJson['description'] as String? ??
                                mg.hint ??
                                '',
                            style: CyberText.bodySmall.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CyberColors.neonAmber.withOpacity(0.07),
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                          color: CyberColors.neonAmber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: CyberColors.neonAmber,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Target: $targetPath',
                              style: const TextStyle(
                                color: CyberColors.neonAmber,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildTree(tree, '', 0),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    if (_hintText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: CyberColors.neonAmber.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: CyberColors.neonAmber.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _hintText,
                          style: const TextStyle(
                            color: CyberColors.neonAmber,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Registry key found.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WINDOW CORRELATE — view events and confirm overlap window
// ═══════════════════════════════════════════════════════════════

class _WindowCorrelateGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _WindowCorrelateGame({required this.panelId, required this.minigame});
  @override
  State<_WindowCorrelateGame> createState() => _WindowCorrelateGameState();
}

class _WindowCorrelateGameState extends State<_WindowCorrelateGame> {
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  void _confirm(CaseEngine engine) {
    engine.solveMinigame(widget.minigame.id);
    setState(() => _success = true);
    HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final events = (mg.rawJson['events'] as List<dynamic>? ?? []);
    final overlap = mg.rawJson['overlapWindow'] as Map<String, dynamic>? ?? {};
    final description = mg.rawJson['description'] as String? ?? mg.hint ?? '';

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonCyan,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.compare_arrows,
                            color: CyberColors.neonCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (overlap.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CyberColors.neonGreen.withOpacity(0.07),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: CyberColors.neonGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'USB CONNECTION WINDOW',
                              style: TextStyle(
                                color: CyberColors.neonGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${overlap['start']} — ${overlap['end']}',
                              style: const TextStyle(
                                fontFamily: 'DotMatrix',
                                color: CyberColors.neonGreen,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'EVENT LOG',
                  style: CyberText.caption.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                ...events.asMap().entries.map((entry) {
                  final ev = entry.value as Map<String, dynamic>;
                  final time = ev['time'] as String? ?? '';
                  final label = ev['label'] as String? ?? '';
                  final source = ev['source'] as String? ?? '';
                  final isConnect = label.toLowerCase().contains('connect');
                  final isDisconnect = label.toLowerCase().contains(
                    'disconnect',
                  );
                  final color = isConnect
                      ? CyberColors.neonGreen
                      : isDisconnect
                      ? CyberColors.neonRed
                      : CyberColors.neonCyan;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CyberColors.bgCard,
                      borderRadius: CyberRadius.small,
                      border: Border(
                        bottom: BorderSide(color: CyberColors.borderSubtle),
                        left: BorderSide(color: color, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            time,
                            style: TextStyle(
                              fontFamily: 'DotMatrix',
                              color: color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                source,
                                style: CyberText.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Confirm Overlap',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonCyan,
                      onTap: () => _confirm(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Copy operation confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FINGERPRINT COMPARE — match/mismatch fields side by side
// ═══════════════════════════════════════════════════════════════

class _FingerprintCompareGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _FingerprintCompareGame({
    required this.panelId,
    required this.minigame,
  });
  @override
  State<_FingerprintCompareGame> createState() =>
      _FingerprintCompareGameState();
}

class _FingerprintCompareGameState extends State<_FingerprintCompareGame> {
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  void _confirm(CaseEngine engine) {
    engine.solveMinigame(widget.minigame.id);
    setState(() => _success = true);
    HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final fingerprints =
        mg.rawJson['fingerprints'] as Map<String, dynamic>? ?? {};
    final legit = fingerprints['legitimate'] as Map<String, dynamic>? ?? {};
    final attacker = fingerprints['attacker'] as Map<String, dynamic>? ?? {};
    final mismatchFields =
        (mg.rawJson['mismatchFields'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toSet();
    final fields = legit.keys.where((k) => k != 'label').toList();

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonPurple,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.compare,
                            color: CyberColors.neonPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mg.rawJson['instruction'] as String? ?? mg.hint ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 110),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CyberColors.neonCyan.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: CyberColors.neonCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          legit['label'] as String? ?? 'Legitimate',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: CyberColors.neonCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CyberColors.neonRed.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                            color: CyberColors.neonRed.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          attacker['label'] as String? ?? 'Attacker',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: CyberColors.neonRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...fields.map((field) {
                  final legitVal = legit[field]?.toString() ?? '';
                  final attackerVal = attacker[field]?.toString() ?? '';
                  final isMismatch = mismatchFields.contains(field);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMismatch
                          ? CyberColors.neonRed.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: CyberRadius.small,
                      border: isMismatch
                          ? Border.all(
                              color: CyberColors.neonRed.withOpacity(0.2),
                            )
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            _formatFieldName(field),
                            style: CyberText.caption.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CyberColors.neonCyan.withOpacity(0.06),
                              borderRadius: CyberRadius.small,
                            ),
                            child: Text(
                              legitVal,
                              style: TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 11,
                                color: isMismatch
                                    ? CyberColors.neonCyan
                                    : CyberColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isMismatch
                                  ? CyberColors.neonRed.withOpacity(0.12)
                                  : CyberColors.neonCyan.withOpacity(0.06),
                              borderRadius: CyberRadius.small,
                              border: isMismatch
                                  ? Border.all(
                                      color: CyberColors.neonRed.withOpacity(
                                        0.4,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              attackerVal,
                              style: TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 11,
                                color: isMismatch
                                    ? CyberColors.neonRed
                                    : CyberColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isMismatch ? Icons.close : Icons.check,
                          color: isMismatch
                              ? CyberColors.neonRed
                              : CyberColors.neonGreen,
                          size: 16,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                NeonContainer(
                  borderColor: CyberColors.neonRed,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: CyberColors.neonRed,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${mismatchFields.length} field(s) do not match — session was hijacked.',
                          style: const TextStyle(
                            color: CyberColors.neonRed,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CyberButton(
                      label: 'Confirm Mismatch',
                      icon: Icons.check_outlined,
                      accentColor: CyberColors.neonPurple,
                      onTap: () => _confirm(engine),
                    ),
                    CyberButton(
                      label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline,
                      isOutlined: true,
                      isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length
                          ? () => _hint(engine)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Fingerprint mismatch confirmed.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  String _formatFieldName(String field) {
    return field
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim()
        .toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════
//  SESSION TIMELINE — review login sessions, confirm anomaly
// ═══════════════════════════════════════════════════════════════

class _SessionTimelineGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _SessionTimelineGame({required this.panelId, required this.minigame});
  @override
  State<_SessionTimelineGame> createState() => _SessionTimelineGameState();
}

class _SessionTimelineGameState extends State<_SessionTimelineGame>
    with TickerProviderStateMixin {
  int? _selectedSession;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';
  String _feedback = '';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _select(int index, CaseEngine engine) {
    final sessions =
        (widget.minigame.rawJson['sessions'] as List<dynamic>? ?? []);
    final session = sessions[index] as Map<String, dynamic>;
    setState(() => _selectedSession = index);

    if (session['isSuspicious'] == true) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      setState(
        () => _feedback =
            'That session looks normal. Check the IP geolocation and timing.',
      );
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            _feedback = '';
            _selectedSession = null;
          });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() {
        _hintText = mg.hints[_hintsUsed];
        _hintsUsed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final sessions = (mg.rawJson['sessions'] as List<dynamic>? ?? []);
    final description = mg.rawJson['description'] as String? ?? mg.hint ?? '';

    return AppShell(
      title: 'Mini-Game',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeonContainer(
                  borderColor: CyberColors.neonCyan,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.manage_history,
                            color: CyberColors.neonCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mg.title,
                              style: CyberText.sectionTitle.copyWith(
                                color: CyberColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: CyberText.bodySmall.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.07),
                    borderRadius: CyberRadius.small,
                    border: Border.all(
                      color: CyberColors.neonCyan.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        color: CyberColors.neonCyan,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the session that does not belong to the account owner.',
                          style: TextStyle(
                            color: CyberColors.neonCyan,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Session cards
                ...sessions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final session = entry.value as Map<String, dynamic>;
                  final isSelected = _selectedSession == i;
                  final isSuspicious = session['isSuspicious'] == true;
                  final events = (session['events'] as List<dynamic>? ?? []);

                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => GestureDetector(
                      onTap: () => _select(i, engine),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isSuspicious
                                    ? CyberColors.neonRed.withOpacity(0.10)
                                    : CyberColors.neonAmber.withOpacity(0.08))
                              : CyberColors.bgCard,
                          borderRadius: CyberRadius.medium,
                          border: Border.all(
                            color: isSelected
                                ? (isSuspicious
                                      ? CyberColors.neonRed
                                      : CyberColors.neonAmber)
                                : CyberColors.borderSubtle,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected && isSuspicious
                              ? [
                                  BoxShadow(
                                    color: CyberColors.neonRed.withOpacity(
                                      0.15 * _pulse.value,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session header
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CyberColors.bgCard,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: CyberColors.borderSubtle,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CyberColors.neonCyan.withOpacity(
                                        0.1,
                                      ),
                                      border: Border.all(
                                        color: CyberColors.neonCyan.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${i + 1}',
                                        style: const TextStyle(
                                          color: CyberColors.neonCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['date'] as String? ??
                                              'Unknown date',
                                          style: const TextStyle(
                                            fontFamily: 'DotMatrix',
                                            color: CyberColors.neonCyan,
                                            fontSize: 13,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              color: CyberColors.textMuted,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              session['location'] as String? ??
                                                  '',
                                              style: CyberText.caption.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // IP badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CyberColors.neonPurple.withOpacity(
                                        0.10,
                                      ),
                                      borderRadius: CyberRadius.pill,
                                      border: Border.all(
                                        color: CyberColors.neonPurple
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      session['ipAddress'] as String? ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'DotMatrix',
                                        color: CyberColors.neonPurple,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Session meta row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  _SessionMeta(
                                    label: 'DEVICE',
                                    value: session['device'] as String? ?? '',
                                  ),
                                  const SizedBox(width: 16),
                                  _SessionMeta(
                                    label: 'DURATION',
                                    value: session['duration'] as String? ?? '',
                                  ),
                                  const SizedBox(width: 16),
                                  _SessionMeta(
                                    label: 'AUTH',
                                    value:
                                        session['authMethod'] as String? ?? '',
                                  ),
                                ],
                              ),
                            ),

                            // Events inside session
                            if (events.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: CyberRadius.small,
                                  border: Border.all(
                                    color: CyberColors.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  children: events.asMap().entries.map((ev) {
                                    final e = ev.value as Map<String, dynamic>;
                                    final evTime = e['time'] as String? ?? '';
                                    final evLabel =
                                        e['action'] as String? ?? '';
                                    final evFlag = e['flag'] as String? ?? '';
                                    final isAnomaly = evFlag == 'anomaly';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: ev.key == 0
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color:
                                                      CyberColors.borderSubtle,
                                                  width: 0.5,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            child: Text(
                                              evTime,
                                              style: TextStyle(
                                                fontFamily: 'DotMatrix',
                                                fontSize: 10,
                                                color: isAnomaly
                                                    ? CyberColors.neonRed
                                                    : CyberColors.textMuted,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isAnomaly
                                                ? Icons.warning_amber_outlined
                                                : Icons.chevron_right,
                                            color: isAnomaly
                                                ? CyberColors.neonRed
                                                : CyberColors.textMuted,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              evLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isAnomaly
                                                    ? CyberColors.neonRed
                                                    : CyberColors.textSecondary,
                                                fontWeight: isAnomaly
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isAnomaly)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: CyberColors.neonRed
                                                    .withOpacity(0.12),
                                                borderRadius: CyberRadius.pill,
                                                border: Border.all(
                                                  color: CyberColors.neonRed
                                                      .withOpacity(0.4),
                                                ),
                                              ),
                                              child: const Text(
                                                'ANOMALY',
                                                style: TextStyle(
                                                  color: CyberColors.neonRed,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _feedback,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _hintText,
                      style: const TextStyle(
                        color: CyberColors.neonAmber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CyberButton(
                  label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                  icon: Icons.lightbulb_outline,
                  isOutlined: true,
                  isSmall: true,
                  accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length
                      ? () => _hint(engine)
                      : null,
                ),
              ],
            ),
          ),
          if (_success)
            _SuccessOverlay(
              message: mg.successMessage ?? 'Suspicious session identified.',
              onContinue: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  final String label, value;
  const _SessionMeta({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CyberText.caption.copyWith(fontSize: 9, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: CyberColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
