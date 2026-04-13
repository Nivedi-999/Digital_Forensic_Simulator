// lib/screens/mini_game.dart
// Routes: caesar_cipher | ip_trace | code_crack | phishing_analysis | metadata_correlation | alibi_verify

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
  State<DecryptionMiniGameScreen> createState() => _DecryptionMiniGameScreenState();
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
      return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
          child: const Center(child: Text('No mini-game found.')));
    }
    switch (mg.type) {
      case 'base64_decode': return _Base64DecodeGame(panelId: widget.panelId, minigame: mg);
      case 'ip_trace': return _IpTraceGame(panelId: widget.panelId, minigame: mg);
      case 'code_crack': return _CodeCrackGame(panelId: widget.panelId, minigame: mg);
      case 'phishing_analysis': return _PhishingGame(panelId: widget.panelId, minigame: mg);
      case 'metadata_correlation': return _MetadataCorrelationGame(panelId: widget.panelId, minigame: mg);
      case 'alibi_verify': return _AlibiVerifyGame(panelId: widget.panelId, minigame: mg);
      case 'caesar_cipher':return _CaesarCipherGame(panelId: widget.panelId, minigame: mg);
      default: return _UnsupportedMiniGame(panelId: widget.panelId, minigame: mg);
    }
  }
  @override
  Widget buildAriaLayer({void Function()? onDismiss}) => const SizedBox.shrink();
}


class _UnsupportedMiniGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _UnsupportedMiniGame({required this.panelId, required this.minigame});

  @override
  State<_UnsupportedMiniGame> createState() => _UnsupportedMiniGameState();
}

class _UnsupportedMiniGameState extends State<_UnsupportedMiniGame> {
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  void _complete(CaseEngine engine) {
    engine.solveMinigame(widget.minigame.id);
    setState(() => _success = true);
  }

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
      child: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NeonContainer(
              borderColor: CyberColors.neonAmber,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonAmber)),
                const SizedBox(height: 8),
                Text('This challenge type (${mg.type}) is now rendered in compatibility mode.',
                    style: CyberText.bodySmall),
                if ((mg.instruction ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(mg.instruction!, style: CyberText.bodySmall.copyWith(height: 1.5)),
                ],
              ]),
            ),
            if (_hintText.isNotEmpty) ...[
              const SizedBox(height: 12),
              NeonContainer(
                borderColor: CyberColors.neonPurple,
                child: Text(_hintText, style: CyberText.bodySmall),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: [
              CyberButton(
                label: 'Complete Challenge',
                icon: Icons.check_outlined,
                onTap: () => _complete(engine),
              ),
              CyberButton(
                label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                icon: Icons.lightbulb_outline,
                isOutlined: true,
                isSmall: true,
                accentColor: CyberColors.neonAmber,
                onTap: _hintsUsed < mg.hints.length ? () => _useHint(engine) : null,
              ),
            ]),
          ]),
        ),
        if (_success)
          _SuccessOverlay(
            message: mg.successMessage ?? 'Challenge completed.',
            onContinue: () => Navigator.pop(context),
          ),
      ]),
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

class _SuccessOverlayState extends State<_SuccessOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Animated success ring
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  builder: (_, v, __) => CustomPaint(
                    size: const Size(110, 110),
                    painter: _SuccessRingPainter(progress: v),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('SUCCESS', style: TextStyle(
                    fontFamily: 'DotMatrix', color: CyberColors.neonGreen,
                    fontSize: 32, letterSpacing: 4,
                    shadows: [Shadow(color: CyberColors.neonGreen, blurRadius: 20)])),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: CyberColors.neonGreen.withOpacity(0.08),
                    borderRadius: CyberRadius.medium,
                    border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Text(widget.message,
                      style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary, height: 1.6),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 28),
                CyberButton(label: 'Continue Investigation',
                    icon: Icons.arrow_forward_outlined, onTap: widget.onContinue),
              ]),
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
    final bgPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 4
      ..color = CyberColors.neonGreen.withOpacity(0.15);
    final fgPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 4
      ..color = CyberColors.neonGreen..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -pi / 2, 2 * pi * progress, false, fgPaint);
    // Check icon
    if (progress > 0.7) {
      final checkPaint = Paint()..style = PaintingStyle.stroke
        ..strokeWidth = 3.5..color = CyberColors.neonGreen..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
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
//  Two concentric rotating rings — outer (ciphertext), inner (plaintext)
// ═══════════════════════════════════════════════════════════════

class _CaesarCipherGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CaesarCipherGame({required this.panelId, required this.minigame});
  @override
  State<_CaesarCipherGame> createState() => _CaesarCipherGameState();
}

class _CaesarCipherGameState extends State<_CaesarCipherGame> with TickerProviderStateMixin {
  // Rotary wheel state
  int _shift = 0; // 0-25
  double _dragStartAngle = 0;
  int _dragStartShift = 0;

  // Text input fallback
  final TextEditingController _ctrl = TextEditingController();
  String _feedback = '';
  int _hintsUsed = 0;
  bool _success = false;
  bool _useWheel = true;

  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _glow;

  static const List<String> _alpha = ['A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
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
      if (_alpha.contains(upper)) {
        final idx = (_alpha.indexOf(upper) - shift + 26) % 26;
        return c == c.toUpperCase() ? _alpha[idx] : _alpha[idx].toLowerCase();
      }
      return c;
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
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  void _onWheelDragStart(DragStartDetails d, Offset center) {
    final dx = d.localPosition.dx - center.dx;
    final dy = d.localPosition.dy - center.dy;
    _dragStartAngle = atan2(dy, dx);
    _dragStartShift = _shift;
  }

  void _onWheelDragUpdate(DragUpdateDetails d, Offset center) {
    final dx = d.localPosition.dx - center.dx;
    final dy = d.localPosition.dy - center.dy;
    final angle = atan2(dy, dx);
    final delta = angle - _dragStartAngle;
    final steps = (delta / (2 * pi / 26) * 2).round();
    final newShift = (_dragStartShift + steps + 26) % 26;
    if (newShift != _shift) {
      HapticFeedback.selectionClick();
      setState(() => _shift = newShift);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final cipherText = mg.cipherText ?? '';
    final decoded = _decode(cipherText, _shift);

    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          FadeTransition(opacity: _fadeIn, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              NeonContainer(borderColor: CyberColors.neonPurple, padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 48, height: 48,
                        decoration: BoxDecoration(color: CyberColors.neonPurple.withOpacity(0.12),
                            borderRadius: CyberRadius.small,
                            border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4))),
                        child: const Icon(Icons.rotate_right, color: CyberColors.neonPurple, size: 26)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonPurple)),
                      if (mg.hint != null) ...[const SizedBox(height: 4),
                        Text(mg.hint!, style: CyberText.bodySmall.copyWith(fontSize: 12))],
                    ])),
                  ])),

              const SizedBox(height: 20),

              // Cipher text display
              NeonContainer(padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ENCODED', style: CyberText.caption.copyWith(letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(cipherText, style: const TextStyle(fontFamily: 'DotMatrix', fontSize: 24,
                        color: CyberColors.neonAmber, letterSpacing: 3,
                        shadows: [Shadow(color: CyberColors.neonAmber, blurRadius: 10)])),
                  ])),

              const SizedBox(height: 20),

              // ── ROTARY CIPHER WHEEL ──
              Center(child: Column(children: [
                Text('ROTATE TO DECODE', style: CyberText.caption.copyWith(letterSpacing: 2, color: CyberColors.neonPurple)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (ctx, constraints) {
                  const double size = 280;
                  final center = Offset(size / 2, size / 2);
                  return SizedBox(width: size, height: size,
                    child: GestureDetector(
                      onPanStart: (d) => _onWheelDragStart(d, center),
                      onPanUpdate: (d) => _onWheelDragUpdate(d, center),
                      child: AnimatedBuilder(
                        animation: _glow,
                        builder: (_, __) => CustomPaint(
                          size: const Size(size, size),
                          painter: _CipherWheelPainter(shift: _shift, glowIntensity: _glow.value),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _WheelArrow(direction: -1, onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _shift = (_shift - 1 + 26) % 26);
                  }),
                  const SizedBox(width: 20),
                  Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(color: CyberColors.neonPurple.withOpacity(0.12),
                          borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4))),
                      child: Text('Shift: $_shift', textAlign: TextAlign.center,
                          style: const TextStyle(color: CyberColors.neonPurple, fontSize: 13, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 20),
                  _WheelArrow(direction: 1, onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _shift = (_shift + 1) % 26);
                  }),
                ]),
              ])),

              const SizedBox(height: 20),

              // Decoded preview
              NeonContainer(padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DECODED', style: CyberText.caption.copyWith(letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(decoded, style: const TextStyle(fontFamily: 'DotMatrix', fontSize: 22,
                        color: CyberColors.neonCyan, letterSpacing: 2,
                        shadows: [Shadow(color: CyberColors.neonCyan, blurRadius: 8)])),
                  ])),

              if (_feedback.isNotEmpty) ...[const SizedBox(height: 12),
                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                        borderRadius: CyberRadius.small,
                        border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: CyberColors.neonAmber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_feedback,
                          style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13))),
                    ]))],

              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: CyberButton(
                      label: 'Submit Decode',
                      icon: Icons.check_outlined,
                      onTap: () => _check(engine),
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
                      onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null,
                    ),
                  ),
                ],
              ),
              Row(children: [
                Expanded(child: CyberButton(label: 'Submit Decode',
                    icon: Icons.check_outlined, onTap: () => _check(engine))),
                const SizedBox(width: 12),
                CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                    icon: Icons.lightbulb_outline, isOutlined: true, isSmall: true,
                    accentColor: CyberColors.neonAmber,
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
              ]),
            ]),
          )),
          if (_success) _SuccessOverlay(
              message: mg.successMessage ?? 'Hidden evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
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
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: CyberColors.neonPurple.withOpacity(0.12),
        borderRadius: CyberRadius.small,
        border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4)),
      ),
      child: Icon(
          direction < 0 ? Icons.chevron_left : Icons.chevron_right,
          color: CyberColors.neonPurple, size: 22),
    ),
  );
}

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
    final decoded = encoded.isEmpty ? 'No encoded payload found for this challenge.' : _decodedPreview(encoded);

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
                      Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonPurple)),
                      if ((mg.instruction ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(mg.instruction!, style: CyberText.bodySmall.copyWith(height: 1.5)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ENCODED JWT', style: CyberText.caption.copyWith(letterSpacing: 2)),
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
                  ]),
                ),
                const SizedBox(height: 16),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DECODED PAYLOAD', style: CyberText.caption.copyWith(letterSpacing: 2)),
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
                      Text('IAT: ${mg.iatHumanReadable!}', style: CyberText.bodySmall),
                    ],
                  ]),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3)),
                    ),
                    child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)),
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
                      onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null,
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

class _CipherWheelPainter extends CustomPainter {
  final int shift;
  final double glowIntensity;
  _CipherWheelPainter({required this.shift, required this.glowIntensity});

  static const List<String> _alpha = ['A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 10;
    final innerR = size.width / 2 - 55;
    final midR = size.width / 2 - 32;

    // Background rings
    _paintRing(canvas, c, outerR, CyberColors.neonAmber.withOpacity(0.08), CyberColors.neonAmber.withOpacity(0.25), 2);
    _paintRing(canvas, c, innerR, CyberColors.neonCyan.withOpacity(0.08), CyberColors.neonCyan.withOpacity(0.25), 2);

    // Separator track
    final trackPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1
      ..color = CyberColors.borderSubtle.withOpacity(0.5);
    canvas.drawCircle(c, midR, trackPaint);

    // Outer ring letters (ciphertext — fixed)
    for (int i = 0; i < 26; i++) {
      final angle = (2 * pi * i / 26) - pi / 2;
      final isActive = i == 0;
      final letterPos = Offset(c.dx + outerR * 0.82 * cos(angle), c.dy + outerR * 0.82 * sin(angle));
      _drawRingLetter(canvas, _alpha[i], letterPos, CyberColors.neonAmber, isActive, 12);
      // Tick mark
      final tickStart = Offset(c.dx + (outerR - 6) * cos(angle), c.dy + (outerR - 6) * sin(angle));
      final tickEnd = Offset(c.dx + (outerR - 14) * cos(angle), c.dy + (outerR - 14) * sin(angle));
      final tickPaint = Paint()..strokeWidth = isActive ? 2 : 0.8
        ..color = CyberColors.neonAmber.withOpacity(isActive ? 0.8 : 0.3);
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }

    // Inner ring letters (decoded — rotates with shift)
    for (int i = 0; i < 26; i++) {
      final angle = (2 * pi * i / 26) - pi / 2;
      final decodedIdx = (i - shift + 26) % 26;
      final isActive = i == 0;
      final letterPos = Offset(c.dx + innerR * 0.82 * cos(angle), c.dy + innerR * 0.82 * sin(angle));
      _drawRingLetter(canvas, _alpha[decodedIdx], letterPos, CyberColors.neonCyan, isActive, 12);
    }

    // Active indicator arrow at top
    final arrowPaint = Paint()..color = CyberColors.neonGreen..style = PaintingStyle.fill;
    final arrowPath = Path();
    arrowPath.moveTo(c.dx, c.dy - outerR + 2);
    arrowPath.lineTo(c.dx - 8, c.dy - outerR + 16);
    arrowPath.lineTo(c.dx + 8, c.dy - outerR + 16);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Center hub
    final hubPaint = Paint()..color = CyberColors.bgCard;
    canvas.drawCircle(c, innerR * 0.25, hubPaint);
    final hubBorder = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5
      ..color = CyberColors.neonCyan.withOpacity(0.4);
    canvas.drawCircle(c, innerR * 0.25, hubBorder);

    // Shift indicator in center
    final tp = TextPainter(
        text: TextSpan(text: '$shift', style: TextStyle(
            color: CyberColors.neonCyan.withOpacity(0.8 + glowIntensity * 0.2),
            fontSize: 16, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));

    // Glow around active indicator
    final glowPaint = Paint()..color = CyberColors.neonGreen.withOpacity(0.15 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(c.dx, c.dy - outerR + 10), 12, glowPaint);
  }

  void _paintRing(Canvas canvas, Offset c, double r, Color fill, Color stroke, double strokeW) {
    canvas.drawCircle(c, r, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawCircle(c, r, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = strokeW);
  }

  void _drawRingLetter(Canvas canvas, String letter, Offset pos, Color color, bool active, double size) {
    final tp = TextPainter(
        text: TextSpan(text: letter, style: TextStyle(
            color: active ? color : color.withOpacity(0.45),
            fontSize: active ? size + 1 : size,
            fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_CipherWheelPainter old) => old.shift != shift || old.glowIntensity != glowIntensity;
}

// ═══════════════════════════════════════════════════════════════
//  2. IP TRACE — ANIMATED NETWORK GRAPH
//  Nodes light up as player traces hops
// ═══════════════════════════════════════════════════════════════

class _IpTraceGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _IpTraceGame({required this.panelId, required this.minigame});
  @override
  State<_IpTraceGame> createState() => _IpTraceGameState();
}

class _IpTraceGameState extends State<_IpTraceGame> with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    final mg = widget.minigame;
    _ipList = List<String>.from(mg.decoys);
    if (!_ipList.contains(mg.solution)) _ipList.add(mg.solution ?? '');
    _ipList.shuffle();
    _correctIndex = _ipList.indexWhere((ip) => ip == mg.solution);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scan = CurvedAnimation(parent: _scanCtrl, curve: Curves.linear);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remaining--);
      if (_remaining <= 0) { t.cancel(); setState(() => _failed = true); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); _scanCtrl.dispose(); super.dispose(); }

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
      setState(() { _feedback = 'Wrong node. Keep scanning.'; _selectedNodeIndex = null; });
      HapticFeedback.heavyImpact();
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; _highlightedIndex = _correctIndex; });
      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _highlightedIndex = -1); });
    }
  }

  void _tap(String char) {
    if (_success || _failed) return;
    setState(() {
      if (char == '⌫') { if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1); }
      else if (char == '✓') { _submit(); }
      else if (_typed.length < 15) { _typed += char; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final progress = _remaining / _totalSeconds;
    final timerColor = _remaining > 20 ? CyberColors.neonGreen
        : _remaining > 10 ? CyberColors.neonAmber : CyberColors.neonRed;

    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          Column(children: [
            // Timer bar
            AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                child: LinearProgressIndicator(value: progress,
                    backgroundColor: CyberColors.borderSubtle,
                    valueColor: AlwaysStoppedAnimation(timerColor), minHeight: 6)),
            // Tab toggles
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              _TabButton(label: 'Network Map', active: _showGraph, onTap: () => setState(() => _showGraph = true)),
              const SizedBox(width: 8),
              _TabButton(label: 'Manual Entry', active: !_showGraph, onTap: () => setState(() => _showGraph = false)),
              const Spacer(),
              AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.1 * _pulse.value),
                      borderRadius: CyberRadius.pill,
                      border: Border.all(color: timerColor.withOpacity(0.5))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, color: timerColor, size: 14),
                    const SizedBox(width: 4),
                    Text('$_remaining s', style: TextStyle(color: timerColor,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                  ]))),
            ])),
            Expanded(child: _showGraph ? _buildGraph(engine, mg) : _buildManual(engine, mg)),
          ]),
          if (_success) _SuccessOverlay(
              message: mg.successMessage ?? 'IP traced. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
          if (_failed && !_success) _TimeoutOverlay(onRetry: () {
            setState(() { _typed = ''; _feedback = ''; _failed = false; _remaining = _totalSeconds; _selectedNodeIndex = null; });
            _startTimer();
          }, onBack: () => Navigator.pop(context)),
        ]));
  }

  Widget _buildGraph(CaseEngine engine, MinigameConfig mg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        // Network graph visualization
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
        Text('TAP A NODE TO TRACE THE HOP', style: CyberText.caption.copyWith(
            color: CyberColors.neonCyan.withOpacity(0.6), letterSpacing: 1.5)),
        const SizedBox(height: 12),
        // IP node buttons
        Wrap(spacing: 8, runSpacing: 8,
            children: _ipList.asMap().entries.map((entry) {
              final i = entry.key; final ip = entry.value;
              final isSelected = i == _selectedNodeIndex;
              final isHighlighted = i == _highlightedIndex;
              return GestureDetector(
                onTap: () => _selectNode(i),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: isSelected ? CyberColors.neonCyan.withOpacity(0.15)
                            : isHighlighted ? CyberColors.neonAmber.withOpacity(0.1 + _pulse.value * 0.08)
                            : CyberColors.bgCard,
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                            color: isSelected ? CyberColors.neonCyan
                                : isHighlighted ? CyberColors.neonAmber.withOpacity(0.7)
                                : CyberColors.borderSubtle,
                            width: isSelected || isHighlighted ? 1.5 : 1),
                        boxShadow: isSelected ? [BoxShadow(
                            color: CyberColors.neonCyan.withOpacity(0.2), blurRadius: 8)] : null),
                    child: Text(ip, style: TextStyle(
                        fontFamily: 'DotMatrix',
                        color: isSelected ? CyberColors.neonCyan
                            : isHighlighted ? CyberColors.neonAmber
                            : CyberColors.textPrimary,
                        fontSize: 13, letterSpacing: 1)),
                  ),
                ),
              );
            }).toList()),
        if (_feedback.isNotEmpty) ...[const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                  borderRadius: CyberRadius.small,
                  border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
              child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 12)))],
        const SizedBox(height: 12),
        CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)',
            icon: Icons.lightbulb_outline, isOutlined: true, isSmall: true,
            accentColor: CyberColors.neonAmber,
            onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
      ]),
    );
  }

  Widget _buildManual(CaseEngine engine, MinigameConfig mg) {
    return Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          // IP display
          Container(margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
                  borderRadius: CyberRadius.small,
                  border: Border.all(color: CyberColors.neonCyan.withOpacity(0.5))),
              child: Row(children: [
                Expanded(child: Text(_typed.isEmpty ? 'Enter IP address...' : _typed,
                    style: TextStyle(fontFamily: 'DotMatrix',
                        color: _typed.isEmpty ? CyberColors.textMuted : CyberColors.neonCyan,
                        fontSize: 18, letterSpacing: 2))),
              ])),
          if (_feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 12))),
          const SizedBox(height: 12),
          _NumericKeypad(onTap: _tap),
          const SizedBox(height: 8),
          CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)',
              icon: Icons.lightbulb_outline, isOutlined: true, isSmall: true,
              accentColor: CyberColors.neonAmber,
              onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
        ]),
      )),
    ]);
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: active ? CyberColors.neonCyan.withOpacity(0.15) : Colors.transparent,
            borderRadius: CyberRadius.pill,
            border: Border.all(color: active ? CyberColors.neonCyan : CyberColors.borderSubtle)),
        child: Text(label, style: TextStyle(
            color: active ? CyberColors.neonCyan : CyberColors.textMuted,
            fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal))),
  );
}

class _NetworkGraphPainter extends CustomPainter {
  final List<String> ipList;
  final int correctIndex;
  final int? selectedIndex;
  final int highlightedIndex;
  final double pulseValue;
  final double scanValue;

  _NetworkGraphPainter({required this.ipList, required this.correctIndex,
    this.selectedIndex, required this.highlightedIndex,
    required this.pulseValue, required this.scanValue});

  @override
  void paint(Canvas canvas, Size size) {
    final n = ipList.length;
    if (n == 0) return;

    // Source node (YOU)
    final sourcePos = Offset(size.width / 2, 30);

    // Arrange IP nodes in an arc
    final List<Offset> positions = [];
    for (int i = 0; i < n; i++) {
      final t = (i + 0.5) / n;
      final x = size.width * (0.1 + t * 0.8);
      final y = size.height - 40;
      positions.add(Offset(x, y));
    }

    // Scan line sweep
    final scanX = size.width * scanValue;
    final scanPaint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(scanX - 30, 0, 60, size.height), scanPaint);

    // Lines from source to each node
    for (int i = 0; i < n; i++) {
      final isSelected = i == selectedIndex;
      final isHighlighted = i == highlightedIndex;
      final linePaint = Paint()
        ..strokeWidth = isSelected ? 2 : 1
        ..color = isSelected ? CyberColors.neonCyan.withOpacity(0.8)
            : isHighlighted ? CyberColors.neonAmber.withOpacity(0.5)
            : CyberColors.borderSubtle.withOpacity(0.4)
        ..style = PaintingStyle.stroke;

      // Dashed line
      _drawDashedLine(canvas, sourcePos, positions[i], linePaint, isSelected ? 8 : 12);
    }

    // Source node
    _drawNode(canvas, sourcePos, 'YOU', CyberColors.neonGreen, 20, pulseValue, false);

    // IP nodes
    for (int i = 0; i < n; i++) {
      final isSelected = i == selectedIndex;
      final isHighlighted = i == highlightedIndex;
      final color = isSelected ? CyberColors.neonCyan
          : isHighlighted ? CyberColors.neonAmber : CyberColors.neonPurple;
      _drawNode(canvas, positions[i], 'NODE', color, 16, isSelected ? pulseValue : 0.3, isSelected);

      // IP label below node
      final tp = TextPainter(
          text: TextSpan(text: ipList[i].length > 12 ? '${ipList[i].substring(0, 11)}…' : ipList[i],
              style: TextStyle(color: color.withOpacity(isSelected ? 1 : 0.6),
                  fontSize: 9, fontFamily: 'DotMatrix', letterSpacing: 0.5)),
          textDirection: TextDirection.ltr);
      tp.layout(maxWidth: 80);
      tp.paint(canvas, positions[i] + Offset(-tp.width / 2, 20));
    }
  }

  void _drawNode(Canvas canvas, Offset pos, String label, Color color, double r,
      double glowVal, bool selected) {
    if (selected || glowVal > 0.5) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.15 * glowVal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, r + 8, glowPaint);
    }
    canvas.drawCircle(pos, r,
        Paint()..color = color.withOpacity(0.15)..style = PaintingStyle.fill);
    canvas.drawCircle(pos, r,
        Paint()..color = color.withOpacity(selected ? 0.9 : 0.5)
          ..style = PaintingStyle.stroke..strokeWidth = selected ? 2 : 1);
    // Inner dot
    canvas.drawCircle(pos, r * 0.3,
        Paint()..color = color.withOpacity(0.7 * glowVal));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dashLen) {
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
      old.selectedIndex != selectedIndex || old.highlightedIndex != highlightedIndex ||
          old.pulseValue != pulseValue || old.scanValue != scanValue;
}

class _TimeoutOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _TimeoutOverlay({required this.onRetry, required this.onBack});
  @override
  Widget build(BuildContext context) => Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer_off_outlined, color: CyberColors.neonRed, size: 64),
        const SizedBox(height: 16),
        const Text('TIME OUT', style: TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonRed, fontSize: 28, letterSpacing: 3)),
        const SizedBox(height: 12),
        Text('The trace window expired.', style: CyberText.bodySmall),
        const SizedBox(height: 24),
        CyberButton(label: 'Try Again', icon: Icons.replay, accentColor: CyberColors.neonRed, onTap: onRetry),
        const SizedBox(height: 12),
        CyberButton(label: 'Go Back', icon: Icons.arrow_back, isOutlined: true, onTap: onBack),
      ]))));
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onTap;
  const _NumericKeypad({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final keys = [['1','2','3'],['4','5','6'],['7','8','9'],['.','0','⌫'],['✓']];
    return Column(children: keys.map((row) => Row(children: row.map((key) {
      final isSubmit = key == '✓'; final isDelete = key == '⌫';
      return Expanded(child: Padding(padding: const EdgeInsets.all(4),
          child: Material(color: isSubmit ? CyberColors.neonCyan.withOpacity(0.15) : CyberColors.neonCyan.withOpacity(0.05),
              borderRadius: CyberRadius.small,
              child: InkWell(borderRadius: CyberRadius.small, onTap: () => onTap(key),
                  child: Container(height: 48,
                      decoration: BoxDecoration(borderRadius: CyberRadius.small,
                          border: Border.all(color: isSubmit ? CyberColors.neonCyan.withOpacity(0.5) : CyberColors.borderSubtle)),
                      child: Center(child: isDelete
                          ? const Icon(Icons.backspace_outlined, color: CyberColors.neonRed, size: 20)
                          : isSubmit ? const Icon(Icons.check_rounded, color: CyberColors.neonCyan, size: 22)
                          : Text(key, style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.textPrimary, fontSize: 18))))))));
      }).toList())).toList());
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. CODE CRACK — SLOT MACHINE REELS with spin animation
// ═══════════════════════════════════════════════════════════════

class _CodeCrackGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CodeCrackGame({required this.panelId, required this.minigame});
  @override
  State<_CodeCrackGame> createState() => _CodeCrackGameState();
}

class _CodeCrackGameState extends State<_CodeCrackGame> with TickerProviderStateMixin {
  static const List<String> _chars = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'];
  late List<int> _currentIndices;
  late List<AnimationController> _spinCtrls;
  late List<Animation<double>> _spinAnims;
  late List<bool> _isSpinning;
  bool _success = false;
  int _hintsUsed = 0;
  String _feedback = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    final reelCount = _reelCount;
    _currentIndices = List<int>.filled(reelCount, 0);
    _isSpinning = List<bool>.filled(reelCount, false);
    _spinCtrls = List.generate(reelCount, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600)));
    _spinAnims = _spinCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOutBack)).toList();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
      _currentIndices[reel] = (_currentIndices[reel] + dir + _chars.length) % _chars.length;
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
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final solution = mg.solution ?? '???';

    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), child: Column(children: [
            // Terminal header
            NeonContainer(borderColor: CyberColors.neonRed, padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.terminal, color: CyberColors.neonRed, size: 20),
                    const SizedBox(width: 10),
                    Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonRed))]),
                  const SizedBox(height: 10),
                  _TerminalLine('> ACCESSING SYSTEM...', CyberColors.neonRed),
                  _TerminalLine('> BYPASSING FIREWALL...', CyberColors.neonAmber),
                  _TerminalLine('> MATCH THE 3-CHARACTER CODE TO PROCEED.', CyberColors.neonCyan),
                ])),

            const SizedBox(height: 24),

            // Target display
            Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
              const Text('TARGET:  ', style: TextStyle(color: CyberColors.textSecondary, fontSize: 13)),
              ...solution.split('').map((c) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4), width: 46, height: 46,
                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.1),
                      borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.5))),
                  child: Center(child: Text(c, style: const TextStyle(fontFamily: 'DotMatrix',
                      color: CyberColors.neonAmber, fontSize: 24,
                      shadows: [Shadow(color: CyberColors.neonAmber, blurRadius: 8)]))))),
            ]),

            const SizedBox(height: 32),

            // SLOT MACHINE REELS
            AnimatedBuilder(
              animation: _shake,
              builder: (_, child) => Transform.translate(
                  offset: Offset(_success ? 0 : sin(_shake.value * pi * 6) * 6 * (1 - _shake.value), 0),
                  child: child),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: List.generate(_reelCount, (reel) => _buildReel(reel)),
              ),
            ),

            const SizedBox(height: 10),
            Text('Scroll reels to match the target code',
                style: CyberText.caption.copyWith(color: CyberColors.textMuted)),

            if (_feedback.isNotEmpty) ...[const SizedBox(height: 16),
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                      borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined, color: CyberColors.neonAmber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13))),
                  ]))],

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
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null,
                  ),
                ),
              ],
            ),
          ])),
          if (_success) _SuccessOverlay(
              message: mg.successMessage ?? 'System breached. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }

  Widget _buildReel(int reel) {
    final cur = _chars[_currentIndices[reel]];
    final prv = _chars[(_currentIndices[reel] - 1 + _chars.length) % _chars.length];
    final nxt = _chars[(_currentIndices[reel] + 1) % _chars.length];

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
      // Up button — tap to spin up
      GestureDetector(
          onTap: () => _spin(reel, -1),
          child: AnimatedBuilder(
            animation: _spinAnims[reel],
            builder: (_, __) => Container(
                width: 72, height: 56,
                decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.keyboard_arrow_up, color: CyberColors.neonCyan, size: 24),
                  Transform.translate(
                      offset: _isSpinning[reel] ? Offset(0, 8 * _spinAnims[reel].value) : Offset.zero,
                      child: Text(prv, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(
                          color: CyberColors.textMuted.withOpacity(0.6),
                          fontSize: 14, fontFamily: 'DotMatrix'))),
                ])),
          )),

      // Main reel display
      AnimatedBuilder(
          animation: _spinAnims[reel],
          builder: (_, __) {
            final bounce = _isSpinning[reel] ? _spinAnims[reel].value : 1.0;
            return Container(
                width: 72, height: 80,
                decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.12),
                    border: Border.all(color: CyberColors.neonCyan, width: 2),
                    boxShadow: [BoxShadow(
                        color: CyberColors.neonCyan.withOpacity(0.35 * bounce),
                        blurRadius: 16, spreadRadius: 0)]),
                child: Center(child: Transform.scale(
                    scale: 0.8 + 0.2 * bounce,
                    child: Text(cur, style: TextStyle(
                        fontFamily: 'DotMatrix', fontSize: 38,
                        color: CyberColors.neonCyan.withOpacity(bounce),
                        shadows: [Shadow(color: CyberColors.neonCyan, blurRadius: 12 * bounce)])))));
          }),

      // Down button
      GestureDetector(
          onTap: () => _spin(reel, 1),
          child: AnimatedBuilder(
            animation: _spinAnims[reel],
            builder: (_, __) => Container(
                width: 72, height: 56,
                decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Transform.translate(
                      offset: _isSpinning[reel] ? Offset(0, -8 * _spinAnims[reel].value) : Offset.zero,
                      child: Text(nxt, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(
                          color: CyberColors.textMuted.withOpacity(0.6),
                          fontSize: 14, fontFamily: 'DotMatrix'))),
                  const Icon(Icons.keyboard_arrow_down, color: CyberColors.neonCyan, size: 24),
                ])),
          )),
    ]));
  }
}

class _TerminalLine extends StatelessWidget {
  final String text;
  final Color color;
  const _TerminalLine(this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontFamily: 'DotMatrix', color: color, fontSize: 12, letterSpacing: 0.5)));
}

// ═══════════════════════════════════════════════════════════════
//  4. PHISHING ANALYSIS — EMAIL CLIENT MOCK-UP
//  Looks like a real inbox, red flags animate in as detected
// ═══════════════════════════════════════════════════════════════

class _PhishingGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _PhishingGame({required this.panelId, required this.minigame});
  @override
  State<_PhishingGame> createState() => _PhishingGameState();
}

class _PhishingGameState extends State<_PhishingGame> with TickerProviderStateMixin {
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

    _emailOpenCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _emailOpenAnim = CurvedAnimation(parent: _emailOpenCtrl, curve: Curves.easeOutCubic);

    for (int i = 0; i < flagCount; i++) {
      _flagCtrls.add(AnimationController(vsync: this,
          duration: const Duration(milliseconds: 350)));
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
    // Animate flags appearing one by one
    for (int i = 0; i < _flagVisible.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _flagVisible[i] = true);
        _flagCtrls[i].forward();
      }
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
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  void _toggleFlag(int i) {
    setState(() {
      if (_flagged.contains(i)) _flagged.remove(i); else _flagged.add(i);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;

    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          Column(children: [
            // Email client chrome
            _EmailClientChrome(showInbox: _showInbox,
                onInboxTap: () => setState(() => _showInbox = true),
                onAnalysisTap: _emailOpen ? () => setState(() => _showInbox = false) : null),

            Expanded(child: _showInbox ? _buildInbox(mg) : _buildAnalysis(engine, mg)),

            // Action bar
            if (_emailOpen)
              _EmailActionBar(
                  wrongChoice: _wrongChoice,
                  onReport: () => _choose('report', engine),
                  onDelete: () => _choose('delete', engine),
                  onHint: _hintsUsed < mg.hints.length ? () => _hint(engine) : null,
                  hintsLeft: mg.hints.length - _hintsUsed,
                  hintText: _hintText),
          ]),
          if (_success) _SuccessOverlay(
              message: mg.successMessage ?? 'Phishing email flagged.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }

  Widget _buildInbox(MinigameConfig mg) {
    return SingleChildScrollView(
      child: Column(children: [
        // Inbox rows
        _InboxRow(
            sender: 'Security Team', subject: 'Q4 Security Report', time: '09:14',
            isRead: true, isHighlighted: false, onTap: () {}),
        _InboxRow(
            sender: mg.emailFrom ?? 'Unknown', subject: mg.emailSubject ?? 'Important',
            time: '09:47', isRead: false, isHighlighted: true,
            onTap: () { _openEmail(); setState(() => _showInbox = false); }),
        _InboxRow(
            sender: 'IT Support', subject: 'Password reset confirmation', time: '08:30',
            isRead: true, isHighlighted: false, onTap: () {}),
        _InboxRow(
            sender: 'HR Department', subject: 'Monthly newsletter', time: 'Yesterday',
            isRead: true, isHighlighted: false, onTap: () {}),

        const SizedBox(height: 20),
        if (!_emailOpen) Padding(
            padding: const EdgeInsets.all(16),
            child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: CyberColors.neonAmber.withOpacity(0.08),
                    borderRadius: CyberRadius.medium,
                    border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.touch_app_outlined, color: CyberColors.neonAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Tap the suspicious email to open and analyse it.',
                      style: CyberText.bodySmall.copyWith(color: CyberColors.neonAmber))),
                ]))),
      ]),
    );
  }

  Widget _buildAnalysis(CaseEngine engine, MinigameConfig mg) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(_emailOpenAnim),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Email view
          Container(
              decoration: BoxDecoration(
                  color: CyberColors.bgCard,
                  borderRadius: CyberRadius.medium,
                  border: Border.all(color: CyberColors.neonRed.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Email header
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: CyberColors.neonRed.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        border: Border(bottom: BorderSide(color: CyberColors.neonRed.withOpacity(0.2)))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _EmailMetaRow(label: 'FROM', value: mg.emailFrom ?? '', highlight: true),
                      const SizedBox(height: 6),
                      _EmailMetaRow(label: 'TO', value: 'investigator@cybercell.in', highlight: false),
                      const SizedBox(height: 6),
                      _EmailMetaRow(label: 'SUBJECT', value: mg.emailSubject ?? '', highlight: false),
                    ])),
                // Email body
                Padding(padding: const EdgeInsets.all(16),
                    child: Text(mg.emailBody ?? '',
                        style: CyberText.bodySmall.copyWith(height: 1.7, fontSize: 13))),
              ])),

          const SizedBox(height: 16),

          // Red flags section
          Row(children: [
            const Icon(Icons.flag_outlined, color: CyberColors.neonRed, size: 16),
            const SizedBox(width: 6),
            Text('RED FLAGS DETECTED', style: CyberText.caption.copyWith(
                color: CyberColors.neonRed, letterSpacing: 1.5)),
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: CyberColors.neonRed.withOpacity(0.12),
                    borderRadius: CyberRadius.pill,
                    border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                child: Text('${_flagged.length}/${mg.redFlags.length} flagged',
                    style: const TextStyle(color: CyberColors.neonRed, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 10),

          ...mg.redFlags.asMap().entries.map((entry) {
            final i = entry.key; final flag = entry.value;
            if (!_flagVisible[i]) return const SizedBox.shrink();
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _flagCtrls[i], curve: Curves.easeOutCubic)),
              child: FadeTransition(
                opacity: _flagCtrls[i],
                child: GestureDetector(
                  onTap: () => _toggleFlag(i),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: _flagged.contains(i) ? CyberColors.neonRed.withOpacity(0.12) : Colors.transparent,
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                              color: _flagged.contains(i) ? CyberColors.neonRed.withOpacity(0.5) : CyberColors.borderSubtle,
                              width: _flagged.contains(i) ? 1.5 : 1)),
                      child: Row(children: [
                        AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                            child: Icon(
                                _flagged.contains(i) ? Icons.flag : Icons.flag_outlined,
                                key: ValueKey(_flagged.contains(i)),
                                color: _flagged.contains(i) ? CyberColors.neonRed : CyberColors.textMuted,
                                size: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(flag, style: TextStyle(
                            color: _flagged.contains(i) ? CyberColors.textPrimary : CyberColors.textSecondary,
                            fontSize: 13))),
                      ])),
                ),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

class _EmailClientChrome extends StatelessWidget {
  final bool showInbox;
  final VoidCallback onInboxTap;
  final VoidCallback? onAnalysisTap;
  const _EmailClientChrome({required this.showInbox, required this.onInboxTap, this.onAnalysisTap});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(
            color: CyberColors.bgCard,
            border: Border(bottom: BorderSide(color: CyberColors.borderSubtle))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.mail_outlined, color: CyberColors.neonAmber, size: 18),
            const SizedBox(width: 8),
            Text('SECURE MAIL CLIENT', style: CyberText.caption.copyWith(
                color: CyberColors.neonAmber, letterSpacing: 1.5)),
            const Spacer(),
            Container(width: 8, height: 8, decoration: const BoxDecoration(
                shape: BoxShape.circle, color: CyberColors.neonGreen)),
            const SizedBox(width: 4),
            Text('ONLINE', style: CyberText.caption.copyWith(color: CyberColors.neonGreen, fontSize: 9)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _ChromeTab(label: 'Inbox', active: showInbox, onTap: onInboxTap),
            const SizedBox(width: 4),
            _ChromeTab(label: 'Analyse', active: !showInbox,
                onTap: onAnalysisTap, disabled: onAnalysisTap == null),
          ]),
        ]));
  }
}

class _ChromeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool disabled;
  const _ChromeTab({required this.label, required this.active, this.onTap, this.disabled = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: disabled ? null : onTap,
    child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: active ? CyberColors.bgBase : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: active ? Border.all(color: CyberColors.borderSubtle) : null),
        child: Text(label, style: TextStyle(
            color: active ? CyberColors.neonCyan : (disabled ? CyberColors.textMuted.withOpacity(0.4) : CyberColors.textMuted),
            fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal))),
  );
}

class _InboxRow extends StatelessWidget {
  final String sender, subject, time;
  final bool isRead, isHighlighted;
  final VoidCallback onTap;
  const _InboxRow({required this.sender, required this.subject, required this.time,
    required this.isRead, required this.isHighlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted ? CyberColors.neonRed.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: CyberColors.borderSubtle, width: 0.5)),
                color: isHighlighted ? CyberColors.neonRed.withOpacity(0.04) : null),
            child: Row(children: [
              // Unread dot
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !isRead ? (isHighlighted ? CyberColors.neonRed : CyberColors.neonCyan)
                          : Colors.transparent)),
              // Content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(sender, style: TextStyle(
                      color: isHighlighted ? CyberColors.neonRed : CyberColors.textPrimary,
                      fontSize: 13, fontWeight: isRead ? FontWeight.normal : FontWeight.w600))),
                  Text(time, style: CyberText.caption),
                  if (isHighlighted) ...[const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: CyberColors.neonRed.withOpacity(0.12),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                        child: const Text('SUSPICIOUS', style: TextStyle(
                            color: CyberColors.neonRed, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)))],
                ]),
                const SizedBox(height: 2),
                Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: CyberText.bodySmall.copyWith(fontSize: 12)),
              ])),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: CyberColors.textMuted.withOpacity(0.5), size: 16),
            ])),
      ),
    );
  }
}

class _EmailMetaRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _EmailMetaRow({required this.label, required this.value, required this.highlight});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 60,
        child: Text(label, style: CyberText.caption.copyWith(fontSize: 10, letterSpacing: 0.8))),
    Expanded(child: Text(value, style: TextStyle(
        color: highlight ? CyberColors.neonRed : CyberColors.textPrimary,
        fontSize: 12, fontWeight: highlight ? FontWeight.w600 : FontWeight.normal))),
  ]);
}

class _EmailActionBar extends StatelessWidget {
  final bool wrongChoice;
  final VoidCallback onReport, onDelete;
  final VoidCallback? onHint;
  final int hintsLeft;
  final String hintText;
  const _EmailActionBar({required this.wrongChoice, required this.onReport,
    required this.onDelete, this.onHint, required this.hintsLeft, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
            color: CyberColors.bgCard,
            border: Border(top: BorderSide(color: CyberColors.borderSubtle))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (hintText.isNotEmpty) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                    borderRadius: CyberRadius.small,
                    border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                child: Text(hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 12))),
          ],
          if (wrongChoice) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.08),
                    borderRadius: CyberRadius.small,
                    border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                child: const Text('Wrong decision. Analyse more carefully.',
                    style: TextStyle(color: CyberColors.neonRed, fontSize: 12))),
          ],
          Row(children: [
            Expanded(child: _ActionButton(label: 'Report Phishing',
                icon: Icons.report_outlined, color: CyberColors.neonCyan, onTap: onReport)),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton(label: 'Delete',
                icon: Icons.delete_outline, color: CyberColors.neonRed, onTap: onDelete)),
            const SizedBox(width: 8),
            _HintButton(hintsLeft: hintsLeft, onTap: onHint),
          ]),
        ]));
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
            border: Border.all(color: CyberColors.neonAmber.withOpacity(onTap != null ? 0.5 : 0.2))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lightbulb_outline, color: CyberColors.neonAmber.withOpacity(onTap != null ? 1 : 0.3), size: 18),
          const SizedBox(height: 2),
          Text('$hintsLeft', style: TextStyle(
              color: CyberColors.neonAmber.withOpacity(onTap != null ? 1 : 0.3),
              fontSize: 10, fontWeight: FontWeight.bold)),
        ])),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: color.withOpacity(0.1),
      borderRadius: CyberRadius.medium,
      child: InkWell(borderRadius: CyberRadius.medium, onTap: onTap,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(borderRadius: CyberRadius.medium,
                  border: Border.all(color: color.withOpacity(0.4), width: 1.2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: color, size: 16), const SizedBox(width: 6),
                Flexible(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold,
                    fontSize: 12), overflow: TextOverflow.ellipsis)),
              ]))));
}

// ═══════════════════════════════════════════════════════════════
//  5. METADATA CORRELATION — unchanged (uses dropdowns, already functional)
// ═══════════════════════════════════════════════════════════════

class _MetadataCorrelationGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _MetadataCorrelationGame({required this.panelId, required this.minigame});
  @override
  State<_MetadataCorrelationGame> createState() => _MetadataCorrelationGameState();
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
    for (final f in widget.minigame.fragments) { _selections[f.id] = null; _revealed[f.id] = false; }
  }

  void _submit(CaseEngine engine) {
    final mg = widget.minigame;
    bool allCorrect = true;
    for (final f in mg.fragments) {
      if (_selections[f.id] != f.correctSuspectId) allCorrect = false;
      _revealed[f.id] = true;
    }
    setState(() => _submitted = true);
    if (allCorrect) { engine.solveMinigame(mg.id); setState(() => _success = true); }
    else HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  void _reset() {
    setState(() {
      for (final f in widget.minigame.fragments) { _selections[f.id] = null; _revealed[f.id] = false; }
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NeonContainer(borderColor: CyberColors.neonAmber, padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.data_object, color: CyberColors.neonAmber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonAmber)))]),
                      const SizedBox(height: 8),
                      Text(mg.instruction ?? mg.hint ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 20),
                ...mg.fragments.map((frag) {
                  final sel = _selections[frag.id];
                  final revealed = _revealed[frag.id] ?? false;
                  final isCorrect = revealed && sel == frag.correctSuspectId;
                  final isWrong = revealed && sel != frag.correctSuspectId;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isCorrect) borderCol = CyberColors.neonGreen;
                  if (isWrong) borderCol = CyberColors.neonRed;
                  return Padding(padding: const EdgeInsets.only(bottom: 16),
                      child: NeonContainer(borderColor: borderCol, padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.1),
                                      borderRadius: CyberRadius.pill,
                                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.4))),
                                  child: Text(frag.label, style: const TextStyle(color: CyberColors.neonAmber,
                                      fontSize: 11, fontWeight: FontWeight.bold))),
                              if (isCorrect) ...[const SizedBox(width: 8),
                                const Icon(Icons.check_circle, color: CyberColors.neonGreen, size: 16)],
                              if (isWrong) ...[const SizedBox(width: 8),
                                const Icon(Icons.cancel, color: CyberColors.neonRed, size: 16)],
                            ]),
                            const SizedBox(height: 8),
                            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3),
                                    borderRadius: CyberRadius.small,
                                    border: Border.all(color: CyberColors.borderSubtle)),
                                child: Text(frag.value, style: const TextStyle(fontFamily: 'DotMatrix',
                                    color: CyberColors.textPrimary, fontSize: 13, letterSpacing: 0.3))),
                            const SizedBox(height: 10),
                            Text('POINTS TO:', style: CyberText.caption.copyWith(letterSpacing: 1.2)),
                            const SizedBox(height: 6),
                            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(color: CyberColors.bgCard,
                                    borderRadius: CyberRadius.small,
                                    border: Border.all(color: isCorrect ? CyberColors.neonGreen.withOpacity(0.5)
                                        : isWrong ? CyberColors.neonRed.withOpacity(0.5) : CyberColors.neonCyan.withOpacity(0.3))),
                                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                                    value: sel, hint: Text('Select suspect...', style: TextStyle(color: CyberColors.textMuted, fontSize: 13)),
                                    dropdownColor: CyberColors.bgCard, style: const TextStyle(color: CyberColors.textPrimary, fontSize: 13),
                                    isExpanded: true, onChanged: _submitted ? null : (val) => setState(() => _selections[frag.id] = val),
                                    items: mg.metaSuspects.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['label'] ?? ''))).toList()))),
                            if (revealed) ...[const SizedBox(height: 10),
                              Container(width: double.infinity, padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: isCorrect ? CyberColors.neonGreen.withOpacity(0.08) : CyberColors.neonRed.withOpacity(0.08),
                                      borderRadius: CyberRadius.small,
                                      border: Border.all(color: isCorrect ? CyberColors.neonGreen.withOpacity(0.3) : CyberColors.neonRed.withOpacity(0.3))),
                                  child: Text(isCorrect ? frag.explanation : 'Incorrect. ${frag.explanation}',
                                      style: TextStyle(color: isCorrect ? CyberColors.neonGreen : CyberColors.neonRed, fontSize: 12, height: 1.5)))],
                          ])));
                }),
                if (_hintText.isNotEmpty) ...[const SizedBox(height: 4),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: Text(_hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: CyberButton(label: _submitted ? 'Try Again' : 'Submit',
                      icon: _submitted ? Icons.replay : Icons.check_outlined, accentColor: CyberColors.neonAmber,
                      onTap: _submitted ? _reset : () => _submit(engine))),
                  const SizedBox(width: 12),
                  CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                      icon: Icons.lightbulb_outline, isOutlined: true, isSmall: true,
                      accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
                ]),
              ])),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Metadata correlated. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}

// ═══════════════════════════════════════════════════════════════
//  6. ALIBI VERIFICATION — unchanged (interaction model works well)
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

  void _select(String alibiId, CaseEngine engine) {
    if (_submitted) return;
    final alibi = widget.minigame.alibis.firstWhere((a) => a.id == alibiId);
    setState(() { _selectedAlibiId = alibiId; _submitted = true; });
    if (alibi.isContradicted) {
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _wrong = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _submitted = false; _wrong = false; _selectedAlibiId = null; });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final timeline = mg.timelineEvent;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NeonContainer(borderColor: CyberColors.neonRed, padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.gavel_outlined, color: CyberColors.neonRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonRed)))]),
                      const SizedBox(height: 8),
                      Text(mg.instruction ?? mg.hint ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 16),
                if (timeline != null) Container(width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.06),
                        borderRadius: CyberRadius.small,
                        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.access_time, color: CyberColors.neonCyan, size: 14),
                        const SizedBox(width: 6),
                        Text('CONFIRMED EVENT', style: CyberText.caption.copyWith(color: CyberColors.neonCyan, letterSpacing: 1.2))]),
                      const SizedBox(height: 6),
                      Text(timeline['time'] ?? '', style: const TextStyle(fontFamily: 'DotMatrix',
                          color: CyberColors.neonCyan, fontSize: 14, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(timeline['event'] ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 20),
                Text('WHICH ALIBI IS CONTRADICTED BY THIS EVIDENCE?',
                    style: CyberText.caption.copyWith(letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...mg.alibis.map((alibi) {
                  final isSel = _selectedAlibiId == alibi.id;
                  final isContra = isSel && _submitted && alibi.isContradicted;
                  final isWrongPick = isSel && _wrong && !alibi.isContradicted;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isContra) borderCol = CyberColors.neonRed;
                  if (isWrongPick) borderCol = CyberColors.neonAmber;
                  return Padding(padding: const EdgeInsets.only(bottom: 14),
                      child: Material(color: Colors.transparent, child: InkWell(borderRadius: CyberRadius.medium,
                          onTap: _submitted ? null : () => _select(alibi.id, engine),
                          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: isContra ? CyberColors.neonRed.withOpacity(0.08)
                                      : isWrongPick ? CyberColors.neonAmber.withOpacity(0.06) : CyberColors.bgCard,
                                  borderRadius: CyberRadius.medium,
                                  border: Border.all(color: borderCol, width: 1.5)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: CyberColors.neonCyan.withOpacity(0.1),
                                      border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4))),
                                      child: Center(child: Text(
                                          alibi.suspectName.isNotEmpty ? alibi.suspectName[0] : '?',
                                          style: const TextStyle(color: CyberColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14)))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(alibi.suspectName, style: const TextStyle(
                                      color: CyberColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
                                  if (isContra) const Icon(Icons.flag, color: CyberColors.neonRed, size: 18),
                                ]),
                                const SizedBox(height: 10),
                                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2),
                                        borderRadius: CyberRadius.small,
                                        border: Border.all(color: CyberColors.borderSubtle)),
                                    child: Text('"${alibi.alibi}"', style: CyberText.bodySmall.copyWith(fontStyle: FontStyle.italic, height: 1.6))),
                                if (isContra && alibi.contradiction.isNotEmpty) ...[const SizedBox(height: 10),
                                  Container(width: double.infinity, padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.08),
                                          borderRadius: CyberRadius.small,
                                          border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Icon(Icons.warning_amber, color: CyberColors.neonRed, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(alibi.contradiction, style: const TextStyle(
                                            color: CyberColors.neonRed, fontSize: 12, height: 1.5))),
                                      ]))],
                              ])))));
                }),
                if (_wrong) ...[const SizedBox(height: 4),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: const Text('That alibi holds up. Look more carefully at the timeline.',
                          style: TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                if (_hintText.isNotEmpty) ...[const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                          borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: Text(_hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                const SizedBox(height: 16),
                CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)',
                    icon: Icons.lightbulb_outline, isOutlined: true, isSmall: true,
                    accentColor: CyberColors.neonAmber,
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
              ])),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Alibi contradicted. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}