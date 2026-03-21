// lib/screens/home_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — DARK OPS TERMINAL HOME SCREEN
//  Concept: Classified intelligence terminal boot sequence.
//  Features:
//    • Animated hexagonal grid background (CustomPainter)
//    • Boot sequence typewriter with blinking cursor
//    • Rotating threat-ring logo with pulse animation
//    • Scrolling threat ticker (top bar)
//    • Agent dossier card (live GameProgress data)
//    • Two mission-brief CTAs with press animations
//    • Scan line overlay + corner brackets
//    • System status bar
//    • Staggered entry animations
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import '../services/game_progress.dart';
import '../screens/case_list_screen.dart';

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────
  late AnimationController _hexCtrl;
  late AnimationController _bootCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _btnCtrl;

  // ── Animations ───────────────────────────────────────────
  late Animation<double> _fadeIn;
  late Animation<double> _ringRotation;
  late Animation<double> _glowPulse;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _btn1Fade;
  late Animation<double> _btn2Fade;
  late Animation<Offset> _btn1Slide;
  late Animation<Offset> _btn2Slide;

  // ── Boot sequence ────────────────────────────────────────
  final List<String> _bootLines = [
    'CYBEROPS INTEL SYSTEM v4.2.1',
    'ESTABLISHING SECURE CHANNEL...',
    'THREAT DATABASE: ONLINE',
    'AGENT VERIFICATION: COMPLETE',
    'AWAITING OPERATIVE INPUT.',
  ];
  int _currentLine = 0;
  int _currentChar = 0;
  String _displayedText = '';
  bool _bootComplete = false;
  Timer? _typeTimer;
  Timer? _lineTimer;

  // ── Threat ticker ────────────────────────────────────────
  int _tickerOffset = 0;
  Timer? _tickerTimer;
  static const String _tickerContent =
      'THREAT LEVEL: ELEVATED  ·  ACTIVE BREACHES: 7  ·  SUSPECTS FLAGGED: 23  ·  CASES OPEN: 12  ·  CLEARANCE: ALPHA  ·  ';

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _startBootSequence();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (mounted) setState(() => _tickerOffset = (_tickerOffset + 1) % _tickerContent.length);
    });
  }

  void _setupControllers() {
    _hexCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    _bootCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeIn = CurvedAnimation(parent: _bootCtrl, curve: Curves.easeOut);
    _bootCtrl.forward();

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _ringRotation = Tween<double>(begin: 0, end: 2 * pi).animate(_ringCtrl);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _btn1Fade = CurvedAnimation(parent: _btnCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _btn2Fade = CurvedAnimation(parent: _btnCtrl, curve: const Interval(0.25, 0.85, curve: Curves.easeOut));
    _btn1Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));
    _btn2Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic)));
  }

  void _startBootSequence() {
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _typeNextChar(); });
  }

  void _typeNextChar() {
    if (!mounted) return;
    if (_currentLine >= _bootLines.length) {
      setState(() => _bootComplete = true);
      _cardCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _btnCtrl.forward(); });
      return;
    }
    final line = _bootLines[_currentLine];
    if (_currentChar <= line.length) {
      setState(() { _displayedText = line.substring(0, _currentChar); _currentChar++; });
      _typeTimer = Timer(Duration(milliseconds: _currentChar == 1 ? 0 : 28), _typeNextChar);
    } else {
      _lineTimer = Timer(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        setState(() { _currentLine++; _currentChar = 0; _displayedText = ''; });
        _typeNextChar();
      });
    }
  }

  @override
  void dispose() {
    _hexCtrl.dispose(); _bootCtrl.dispose(); _ringCtrl.dispose();
    _pulseCtrl.dispose(); _cardCtrl.dispose(); _btnCtrl.dispose();
    _typeTimer?.cancel(); _lineTimer?.cancel(); _tickerTimer?.cancel();
    super.dispose();
  }

  PageRouteBuilder _slideRoute(Widget screen) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => screen,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(children: [
          // Layer 1: Animated hex grid
          Positioned.fill(child: AnimatedBuilder(
            animation: _hexCtrl,
            builder: (_, __) => CustomPaint(painter: _HexGridPainter(progress: _hexCtrl.value)),
          )),
          // Layer 2: Radial vignette
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
                center: Alignment.center, radius: 1.2,
                colors: [Colors.transparent, const Color(0xFF040A0F).withOpacity(0.72)],
                stops: const [0.4, 1.0]),
          ))),
          // Layer 3: Scan lines
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanLinePainter()))),
          // Layer 4: Corner brackets
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CornerBracketPainter()))),
          // Layer 5: Ticker
          Positioned(top: 0, left: 0, right: 0,
              child: _ThreatTicker(content: _tickerContent, offset: _tickerOffset)),
          // Layer 6: Main content
          SafeArea(child: Column(children: [
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _BootTerminal(
                  lines: _bootLines,
                  currentLine: _currentLine,
                  displayedText: _displayedText,
                  bootComplete: _bootComplete,
                )),
            const SizedBox(height: 18),
            _AnimatedLogo(rotation: _ringRotation, glow: _glowPulse),
            const SizedBox(height: 16),
            _TitleWordmark(),
            const SizedBox(height: 20),
            SlideTransition(position: _cardSlide, child: FadeTransition(opacity: _cardFade,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _AgentDossierCard()))),
            const Spacer(),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Column(children: [
              SlideTransition(position: _btn1Slide, child: FadeTransition(opacity: _btn1Fade,
                  child: _MissionButton(
                      label: 'NEW INVESTIGATION', sublabel: 'BEGIN MISSION',
                      icon: Icons.radar, isPrimary: true,
                      onTap: () { HapticFeedback.mediumImpact(); Navigator.push(context, _slideRoute(const CaseListScreen())); }))),
              const SizedBox(height: 12),
              SlideTransition(position: _btn2Slide, child: FadeTransition(opacity: _btn2Fade,
                  child: _MissionButton(
                      label: 'ACTIVE CASES', sublabel: 'CONTINUE MISSION',
                      icon: Icons.folder_open_outlined, isPrimary: false,
                      onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, _slideRoute(const CaseListScreen())); }))),
            ])),
            const SizedBox(height: 20),
            _StatusBar(),
            const SizedBox(height: 14),
          ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEX GRID PAINTER — sparse drifting honeycomb
// ─────────────────────────────────────────────────────────────

class _HexGridPainter extends CustomPainter {
  final double progress;
  _HexGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const double hexSize = 32.0;
    const double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * sqrt(3);
    final double driftX = sin(progress * 2 * pi) * 8;
    final double driftY = cos(progress * 2 * pi * 0.7) * 6;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;
    final int cols = (size.width / hexWidth).ceil() + 2;
    final int rows = (size.height / hexHeight).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final int seed = row * 1000 + col;
        if (Random(seed).nextDouble() > 0.4) continue;
        final double cx = col * hexWidth * 0.75 + driftX;
        final double cy = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0) + driftY;
        final double shimmer = sin(progress * 2 * pi + seed * 0.3) * 0.5 + 0.5;
        paint.color = CyberColors.neonCyan.withOpacity(0.03 + shimmer * 0.07);
        _drawHex(canvas, Offset(cx, cy), hexSize * 0.85, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  SCAN LINE + CORNER PAINTERS
// ─────────────────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.06)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_ScanLinePainter _) => false;
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.35)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const double len = 24.0, m = 16.0;
    canvas.drawPath(Path()..moveTo(m, m+len)..lineTo(m, m)..lineTo(m+len, m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, m)..lineTo(size.width-m, m)..lineTo(size.width-m, m+len), p);
    canvas.drawPath(Path()..moveTo(m, size.height-m-len)..lineTo(m, size.height-m)..lineTo(m+len, size.height-m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, size.height-m)..lineTo(size.width-m, size.height-m)..lineTo(size.width-m, size.height-m-len), p);
  }
  @override bool shouldRepaint(_CornerBracketPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  THREAT TICKER
// ─────────────────────────────────────────────────────────────

class _ThreatTicker extends StatelessWidget {
  final String content;
  final int offset;
  const _ThreatTicker({required this.content, required this.offset});

  @override
  Widget build(BuildContext context) {
    final String rotated = content.substring(offset) + content.substring(0, offset);
    return Container(
      height: 26,
      decoration: BoxDecoration(
          color: const Color(0xFF081208),
          border: Border(bottom: BorderSide(color: CyberColors.neonGreen.withOpacity(0.35), width: 1))),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: CyberColors.neonGreen.withOpacity(0.12),
            child: Row(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: CyberColors.neonGreen,
                  boxShadow: [BoxShadow(color: CyberColors.neonGreen.withOpacity(0.8), blurRadius: 4)])),
              const SizedBox(width: 5),
              Text('LIVE', style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: CyberColors.neonGreen, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ])),
        Expanded(child: ClipRect(child: Align(alignment: Alignment.centerLeft,
            child: Text(rotated, maxLines: 1, overflow: TextOverflow.clip,
                style: GoogleFonts.shareTechMono(
                    fontSize: 9, color: CyberColors.neonGreen.withOpacity(0.65), letterSpacing: 1.2))))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOOT TERMINAL
// ─────────────────────────────────────────────────────────────

class _BootTerminal extends StatelessWidget {
  final List<String> lines;
  final int currentLine;
  final String displayedText;
  final bool bootComplete;

  const _BootTerminal({
    required this.lines, required this.currentLine,
    required this.displayedText, required this.bootComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF040A0F).withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CyberColors.neonCyan.withOpacity(0.15), width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('// CYBEROPS TERMINAL', style: GoogleFonts.shareTechMono(
              fontSize: 9, color: CyberColors.neonCyan.withOpacity(0.4), letterSpacing: 1.5)),
          const Spacer(),
          Text(bootComplete ? 'READY' : 'BOOTING...',
              style: GoogleFonts.shareTechMono(fontSize: 9,
                  color: bootComplete ? CyberColors.neonGreen : CyberColors.neonAmber, letterSpacing: 1.5)),
        ]),
        Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 6),
            color: CyberColors.neonCyan.withOpacity(0.1)),
        // Completed lines
        ...List.generate(currentLine.clamp(0, lines.length), (i) {
          final isLast = i == lines.length - 1 && bootComplete;
          return Padding(padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                Text('> ', style: GoogleFonts.shareTechMono(
                    fontSize: 10, color: CyberColors.neonCyan.withOpacity(0.5))),
                Text(lines[i], style: GoogleFonts.shareTechMono(fontSize: 10,
                    color: isLast ? CyberColors.neonGreen : CyberColors.textSecondary,
                    letterSpacing: 0.5)),
                if (isLast) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: CyberColors.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: CyberColors.neonGreen.withOpacity(0.4))),
                      child: Text('OK', style: GoogleFonts.shareTechMono(
                          fontSize: 8, color: CyberColors.neonGreen, fontWeight: FontWeight.bold))),
                ],
              ]));
        }),
        // Currently typing
        if (!bootComplete && currentLine < lines.length)
          Row(children: [
            Text('> ', style: GoogleFonts.shareTechMono(
                fontSize: 10, color: CyberColors.neonCyan.withOpacity(0.5))),
            Text(displayedText, style: GoogleFonts.shareTechMono(
                fontSize: 10, color: CyberColors.neonCyan, letterSpacing: 0.5)),
            _BlinkingCursor(),
          ]),
      ]),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}
class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(opacity: _ctrl.value,
          child: Container(width: 7, height: 12, color: CyberColors.neonCyan)));
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED LOGO — rotating rings + pulsing core
// ─────────────────────────────────────────────────────────────

class _AnimatedLogo extends StatelessWidget {
  final Animation<double> rotation;
  final Animation<double> glow;
  const _AnimatedLogo({required this.rotation, required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: Listenable.merge([rotation, glow]),
        builder: (_, __) => SizedBox(width: 120, height: 120,
            child: Stack(alignment: Alignment.center, children: [
              // Outer rotating dashed ring
              Transform.rotate(angle: rotation.value,
                  child: CustomPaint(size: const Size(120, 120),
                      painter: _RingPainter(radius: 56,
                          color: CyberColors.neonCyan.withOpacity(0.3), dashCount: 16, strokeWidth: 1.5))),
              // Inner counter-rotating ring
              Transform.rotate(angle: -rotation.value * 0.6,
                  child: CustomPaint(size: const Size(120, 120),
                      painter: _RingPainter(radius: 46,
                          color: CyberColors.neonPurple.withOpacity(0.25), dashCount: 8, strokeWidth: 1.0))),
              // Glow backdrop
              Container(width: 72, height: 72, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: CyberColors.neonCyan.withOpacity(0.35 * glow.value), blurRadius: 30, spreadRadius: 4),
                    BoxShadow(color: CyberColors.neonPurple.withOpacity(0.15 * glow.value), blurRadius: 50, spreadRadius: 8),
                  ])),
              // Core circle
              Container(width: 68, height: 68, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF040A0F),
                  border: Border.all(color: CyberColors.neonCyan.withOpacity(0.5 + glow.value * 0.3), width: 1.5)),
                  child: Center(child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [CyberColors.neonCyan, CyberColors.neonPurple]).createShader(bounds),
                      child: const Icon(Icons.shield_outlined, size: 34, color: Colors.white)))),
              // 4 orbit dots
              ...List.generate(4, (i) {
                final angle = rotation.value + (pi / 2) * i;
                return Positioned(
                    left: 60 + cos(angle) * 56 - 3,
                    top: 60 + sin(angle) * 56 - 3,
                    child: Container(width: 6, height: 6, decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CyberColors.neonCyan.withOpacity(0.6 + glow.value * 0.4),
                        boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.8), blurRadius: 6)])));
              }),
            ])));
  }
}

class _RingPainter extends CustomPainter {
  final double radius;
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _RingPainter({required this.radius, required this.color,
    required this.dashCount, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final double dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          dashAngle * i, dashAngle * 0.65, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
//  TITLE WORDMARK
// ─────────────────────────────────────────────────────────────

class _TitleWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerLeft, end: Alignment.centerRight,
              colors: [CyberColors.neonCyan, Color(0xFF7FFFFF), CyberColors.neonPurple],
              stops: [0.0, 0.5, 1.0]).createShader(bounds),
          child: Text('CYBER', style: GoogleFonts.orbitron(
              fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 10))),
      const SizedBox(height: 3),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 20, height: 1, color: CyberColors.neonCyan.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text('I N V E S T I G A T O R', style: GoogleFonts.shareTechMono(
            fontSize: 11, color: CyberColors.textSecondary, letterSpacing: 4)),
        const SizedBox(width: 8),
        Container(width: 20, height: 1, color: CyberColors.neonCyan.withOpacity(0.5)),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  AGENT DOSSIER CARD — live GameProgress data
// ─────────────────────────────────────────────────────────────

class _AgentDossierCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = GameProgress.title;
    final initials = GameProgress.avatarInitials;
    final xp = GameProgress.xp;
    final cases = GameProgress.casesSolved;
    final accuracy = GameProgress.accuracy;
    final rankProgress = GameProgress.rankProgress;
    final nextRank = GameProgress.nextRankName;
    final xpToNext = GameProgress.xpToNextRank;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF060D14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.05), blurRadius: 20)]),
      child: Row(children: [
        // Agent ID badge
        Container(width: 52, height: 52,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [CyberColors.neonCyan.withOpacity(0.2), CyberColors.neonPurple.withOpacity(0.1)]),
                border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4), width: 1)),
            child: Center(child: Text(initials, style: GoogleFonts.orbitron(
                fontSize: 16, fontWeight: FontWeight.w800, color: CyberColors.neonCyan)))),
        const SizedBox(width: 12),
        // Info + XP bar
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('AGENT RANK:', style: GoogleFonts.shareTechMono(
                fontSize: 8, color: CyberColors.textMuted, letterSpacing: 1.5)),
            const SizedBox(width: 6),
            Text(title.toUpperCase(), style: GoogleFonts.shareTechMono(
                fontSize: 9, color: CyberColors.neonCyan, letterSpacing: 1, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Stack(children: [
            Container(height: 3, width: double.infinity,
                decoration: BoxDecoration(color: CyberColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
            FractionallySizedBox(widthFactor: rankProgress.clamp(0.0, 1.0),
                child: Container(height: 3,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(colors: [CyberColors.neonCyan, CyberColors.neonPurple]),
                        boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.6), blurRadius: 4)]))),
          ]),
          const SizedBox(height: 4),
          Text(xpToNext > 0 ? '$xp XP  ·  $xpToNext to $nextRank' : '$xp XP  ·  MAX RANK',
              style: GoogleFonts.shareTechMono(fontSize: 8, color: CyberColors.textMuted, letterSpacing: 0.5)),
        ])),
        const SizedBox(width: 12),
        // Stats
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _MiniStat(label: 'CASES', value: '$cases'),
          const SizedBox(height: 6),
          _MiniStat(label: 'ACC', value: '${accuracy.toStringAsFixed(0)}%', highlight: accuracy >= 80),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _MiniStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(label, style: GoogleFonts.shareTechMono(fontSize: 7, color: CyberColors.textMuted, letterSpacing: 1)),
    Text(value, style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w700,
        color: highlight ? CyberColors.neonGreen : CyberColors.neonCyan)),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  MISSION BUTTON — press scale animation
// ─────────────────────────────────────────────────────────────

class _MissionButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MissionButton({required this.label, required this.sublabel,
    required this.icon, required this.isPrimary, required this.onTap});

  @override
  State<_MissionButton> createState() => _MissionButtonState();
}

class _MissionButtonState extends State<_MissionButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }
  @override void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isPrimary ? CyberColors.neonCyan : CyberColors.neonPurple;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform.scale(scale: _pressAnim.value, child: child),
        child: Container(
          width: double.infinity, height: 64,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: widget.isPrimary ? LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [CyberColors.neonCyan.withOpacity(0.18), CyberColors.neonPurple.withOpacity(0.12)]) : null,
              border: Border.all(color: accent.withOpacity(widget.isPrimary ? 0.6 : 0.3),
                  width: widget.isPrimary ? 1.5 : 1),
              boxShadow: widget.isPrimary ? [BoxShadow(
                  color: CyberColors.neonCyan.withOpacity(0.12), blurRadius: 20)] : null),
          child: Stack(children: [
            // Left accent bar
            Positioned(left: 0, top: 8, bottom: 8, child: Container(width: 3,
                decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2), bottomRight: Radius.circular(2)),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.8), blurRadius: 6)]))),
            // Content
            Padding(padding: const EdgeInsets.only(left: 18, right: 16),
                child: Row(children: [
                  Icon(widget.icon, color: accent, size: 22),
                  const SizedBox(width: 14),
                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.sublabel, style: GoogleFonts.shareTechMono(
                            fontSize: 8, color: accent.withOpacity(0.6), letterSpacing: 2)),
                        const SizedBox(height: 2),
                        Text(widget.label, style: GoogleFonts.orbitron(
                            fontSize: 14, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1.5)),
                      ])),
                  Icon(Icons.chevron_right, color: accent.withOpacity(0.5), size: 20),
                ])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SYSTEM STATUS BAR
// ─────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(children: [
          _StatusDot(label: 'NETWORK', active: true),
          const SizedBox(width: 16),
          _StatusDot(label: 'DATABASE', active: true),
          const SizedBox(width: 16),
          _StatusDot(label: 'ENCRYPTION', active: true),
          const Spacer(),
          Text('BUILD 4.2.1', style: GoogleFonts.shareTechMono(
              fontSize: 8, color: CyberColors.textMuted, letterSpacing: 1)),
        ]));
  }
}

class _StatusDot extends StatefulWidget {
  final String label;
  final bool active;
  const _StatusDot({required this.label, required this.active});
  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.active ? CyberColors.neonGreen : CyberColors.neonRed;
    return AnimatedBuilder(animation: _anim, builder: (_, __) => Row(children: [
      Container(width: 5, height: 5, decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(_anim.value),
          boxShadow: [BoxShadow(color: color.withOpacity(_anim.value * 0.8), blurRadius: 4)])),
      const SizedBox(width: 4),
      Text(widget.label, style: GoogleFonts.shareTechMono(
          fontSize: 8, color: CyberColors.textMuted, letterSpacing: 1)),
    ]));
  }
}