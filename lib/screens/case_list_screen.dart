// lib/screens/case_list_screen.dart
// ═══════════════════════════════════════════════════════════════
//  MISSION PATH — Hex node zigzag through 4 difficulty zones
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import '../models/case.dart';
import '../services/case_repository.dart';
import '../services/game_progress.dart';
import 'case_story_screen.dart';

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});
  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<CaseFile> _cases = [];

  // Maps difficulty → ordered list of case IDs for unlock calculation
  final Map<String, List<String>> _tierOrder = {};

  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadCases();
  }

  Future<void> _loadCases() async {
    await CaseRepository.instance.loadAll();
    if (!mounted) return;

    final all = CaseRepository.instance.all;

    // Build tier order from the cases that actually loaded, preserving
    // registration order so the first case per tier is always index 0.
    for (final diff in ['easy', 'medium', 'hard', 'advanced']) {
      _tierOrder[diff] = all
          .where((c) => c.difficulty.toLowerCase() == diff)
          .map((c) => c.id)
          .toList();
    }

    setState(() {
      _cases = all;
      _loading = false;
    });
  }

  /// Returns true when this case should be playable.
  /// The very first case in each difficulty tier is ALWAYS unlocked so
  /// players always have something to start with, even if earlier cases
  /// from the same tier failed to load.
  bool _isUnlocked(CaseFile c) {
    final tier = _tierOrder[c.difficulty.toLowerCase()] ?? [];
    if (tier.isEmpty) return false;

    // First case in tier is always unlocked
    if (tier.first == c.id) return true;

    return GameProgress.isCaseUnlocked(c.id, tier);
  }

  bool _isCompleted(CaseFile c) => GameProgress.isCaseCompleted(c.id);

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showBrief(BuildContext context, CaseFile c) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _MissionBriefSheet(
          caseFile: c,
          isUnlocked: _isUnlocked(c),
          isCompleted: _isCompleted(c),
          onLaunch: () {
            Navigator.pop(context);
            Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      StorylineScreen(caseId: c.id),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration:
                  const Duration(milliseconds: 400),
                )).then((_) => setState(() {}));
          },
        ));
  }

  PageRouteBuilder _slideRoute(Widget screen) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => screen,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(1.0, 0), end: Offset.zero)
            .animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.3,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF040A0F).withOpacity(0.55)
                            ],
                            stops: const [
                              0.5,
                              1.0
                            ])))),
            SafeArea(
                child: Column(children: [
                  _TopBar(onBack: () => Navigator.pop(context)),
                  Expanded(
                      child: _loading
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: CyberColors.neonCyan, strokeWidth: 2))
                          : _cases.isEmpty
                          ? _buildEmptyState()
                          : _buildPath(context)),
                ])),
          ])),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.folder_off_outlined,
              color: CyberColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text('No cases loaded.',
              style: GoogleFonts.orbitron(
                  color: CyberColors.textMuted,
                  fontSize: 16,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'Make sure your case JSON files are placed in\nassets/cases/ and declared in pubspec.yaml.',
            style: GoogleFonts.shareTechMono(
                color: CyberColors.textMuted, fontSize: 11, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildPath(BuildContext context) {
    final tiers = ['easy', 'medium', 'hard', 'advanced'];
    final items = <_Item>[];

    for (final tier in tiers) {
      final tierCases = _cases
          .where((c) => c.difficulty.toLowerCase() == tier)
          .toList();
      if (tierCases.isEmpty) continue;
      items.add(_Item.header(tier));
      for (int i = 0; i < tierCases.length; i++) {
        final c = tierCases[i];
        items.add(_Item.node(c, i, _isUnlocked(c), _isCompleted(c)));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        if (item.isHeader) return _TierHeader(tier: item.tier!);
        final isEven = item.posIndex! % 2 == 0;
        final hasNext =
            idx + 1 < items.length && !items[idx + 1].isHeader;
        return _NodeRow(
          item: item,
          isLeft: isEven,
          pulse: _pulse,
          hasConnector: hasNext,
          onTap: () => _showBrief(ctx, item.c!),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────

class _Item {
  final bool isHeader;
  final String? tier;
  final CaseFile? c;
  final int? posIndex;
  final bool unlocked;
  final bool completed;

  const _Item._(
      {required this.isHeader,
        this.tier,
        this.c,
        this.posIndex,
        this.unlocked = false,
        this.completed = false});

  factory _Item.header(String tier) => _Item._(isHeader: true, tier: tier);
  factory _Item.node(CaseFile c, int i, bool u, bool done) =>
      _Item._(isHeader: false, c: c, posIndex: i, unlocked: u, completed: done);
}

Color _tierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'easy':
      return CyberColors.neonGreen;
    case 'medium':
      return CyberColors.neonAmber;
    case 'hard':
      return CyberColors.neonRed;
    case 'advanced':
      return CyberColors.neonPurple;
    default:
      return CyberColors.neonCyan;
  }
}

String _tierName(String tier) {
  switch (tier.toLowerCase()) {
    case 'easy':
      return 'TRAINING OPS';
    case 'medium':
      return 'FIELD OPS';
    case 'hard':
      return 'BLACK OPS';
    case 'advanced':
      return 'ADVANCED';
    default:
      return tier.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: CyberColors.neonCyan.withOpacity(0.1), width: 1))),
        child: Row(children: [
          GestureDetector(
              onTap: onBack,
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: CyberColors.neonCyan.withOpacity(0.3))),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: CyberColors.neonCyan, size: 16))),
          const SizedBox(width: 14),
          Text('MISSION SELECT',
              style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CyberColors.neonCyan,
                  letterSpacing: 2)),
          const Spacer(),
          _Dot(color: CyberColors.neonGreen, label: 'EASY'),
          const SizedBox(width: 10),
          _Dot(color: CyberColors.neonAmber, label: 'MED'),
          const SizedBox(width: 10),
          _Dot(color: CyberColors.neonRed, label: 'HARD'),
          const SizedBox(width: 10),
          _Dot(color: CyberColors.neonPurple, label: 'ADV'),
        ]));
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 3),
    Text(label,
        style: GoogleFonts.shareTechMono(
            fontSize: 8, color: color.withOpacity(0.7))),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  TIER HEADER
// ─────────────────────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final String tier;
  const _TierHeader({required this.tier});

  IconData get _icon {
    switch (tier) {
      case 'easy':
        return Icons.shield_outlined;
      case 'medium':
        return Icons.security;
      case 'hard':
        return Icons.dangerous_outlined;
      default:
        return Icons.gpp_bad_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    return Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.22), width: 1)),
        child: Row(children: [
          Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.8), blurRadius: 5)
                  ])),
          const SizedBox(width: 10),
          Icon(_icon, color: color, size: 15),
          const SizedBox(width: 7),
          Text(_tierName(tier),
              style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          const Spacer(),
          Text('ZONE',
              style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: color.withOpacity(0.45), letterSpacing: 2)),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  NODE ROW
// ─────────────────────────────────────────────────────────────

class _NodeRow extends StatelessWidget {
  final _Item item;
  final bool isLeft;
  final Animation<double> pulse;
  final bool hasConnector;
  final VoidCallback onTap;

  const _NodeRow(
      {required this.item,
        required this.isLeft,
        required this.pulse,
        required this.hasConnector,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const nodeSize = 72.0;
    final nodeLeft = isLeft ? w * 0.22 : w * 0.78 - nodeSize;
    final color = _tierColor(item.c!.difficulty);

    return SizedBox(
        height: 108,
        child: Stack(children: [
          if (hasConnector)
            Positioned.fill(
                child: CustomPaint(
                    painter: _ConnectorPainter(
                        color: item.unlocked
                            ? color.withOpacity(0.28)
                            : CyberColors.borderSubtle.withOpacity(0.4),
                        isLeft: isLeft,
                        screenW: w,
                        nodeLeft: nodeLeft,
                        nodeSize: nodeSize))),
          Positioned(
              left: isLeft ? nodeLeft + nodeSize + 10 : 16,
              right: isLeft ? 16 : w - nodeLeft + 10,
              top: 14,
              child: _NodeLabel(item: item, color: color)),
          Positioned(
              left: nodeLeft,
              top: 14,
              child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => GestureDetector(
                      onTap: onTap,
                      child: _HexNode(
                          item: item,
                          color: color,
                          size: nodeSize,
                          pulseVal: pulse.value)))),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  NODE LABEL
// ─────────────────────────────────────────────────────────────

class _NodeLabel extends StatelessWidget {
  final _Item item;
  final Color color;
  const _NodeLabel({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = item.c!;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Text('#${c.caseNumber}',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 8, color: color, letterSpacing: 1))),
          const SizedBox(height: 4),
          Text(c.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.unlocked
                      ? CyberColors.textPrimary
                      : CyberColors.textMuted,
                  letterSpacing: 0.2)),
          const SizedBox(height: 3),
          if (item.completed)
            Row(children: [
              const Icon(Icons.check_circle,
                  color: CyberColors.neonGreen, size: 10),
              const SizedBox(width: 3),
              Text('SOLVED',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 8,
                      color: CyberColors.neonGreen,
                      letterSpacing: 1)),
            ])
          else if (item.unlocked)
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.8), blurRadius: 4)
                      ])),
              const SizedBox(width: 4),
              Text('ACTIVE',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 8, color: color, letterSpacing: 1)),
            ])
          else
            Row(children: [
              const Icon(Icons.lock_outline,
                  color: CyberColors.textMuted, size: 10),
              const SizedBox(width: 3),
              Text('LOCKED',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 8,
                      color: CyberColors.textMuted,
                      letterSpacing: 1)),
            ]),
        ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  HEX NODE
// ─────────────────────────────────────────────────────────────

class _HexNode extends StatelessWidget {
  final _Item item;
  final Color color;
  final double size;
  final double pulseVal;
  const _HexNode(
      {required this.item,
        required this.color,
        required this.size,
        required this.pulseVal});

  @override
  Widget build(BuildContext context) {
    final activeColor = item.completed
        ? CyberColors.neonGreen
        : item.unlocked
        ? color
        : CyberColors.borderSubtle;

    return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          if (item.unlocked && !item.completed)
            CustomPaint(
                size: Size(size, size),
                painter: _HexOutlinePainter(
                    color: color.withOpacity(0.12 + pulseVal * 0.2),
                    scale: 1.0 + pulseVal * 0.1)),
          CustomPaint(
              size: Size(size, size),
              painter: _HexBodyPainter(
                  fill: item.completed
                      ? CyberColors.neonGreen.withOpacity(0.12)
                      : item.unlocked
                      ? color.withOpacity(0.12)
                      : const Color(0xFF080F18),
                  stroke: activeColor,
                  strokeW: item.unlocked ? 1.5 : 1.0)),
          if (item.completed)
            Icon(Icons.check_rounded,
                color: CyberColors.neonGreen,
                size: size * 0.38,
                shadows: const [
                  Shadow(color: CyberColors.neonGreen, blurRadius: 8)
                ])
          else if (item.unlocked)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.manage_search_outlined,
                  color: color, size: size * 0.28),
              const SizedBox(height: 1),
              Text(item.c!.caseNumber,
                  style: GoogleFonts.shareTechMono(
                      fontSize: 8, color: color.withOpacity(0.8))),
            ])
          else
            Icon(Icons.lock_outline,
                color: CyberColors.textMuted.withOpacity(0.35),
                size: size * 0.30),
        ]));
  }
}

class _HexBodyPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeW;
  const _HexBodyPainter(
      {required this.fill, required this.stroke, required this.strokeW});

  Path _hex(Offset c, double r) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final a = (pi / 3) * i - pi / 6;
      final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      if (i == 0) p.moveTo(pt.dx, pt.dy); else p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.86;
    final p = _hex(c, r);
    canvas.drawPath(p, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(
        p,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW);
  }

  @override
  bool shouldRepaint(_HexBodyPainter _) => false;
}

class _HexOutlinePainter extends CustomPainter {
  final Color color;
  final double scale;
  const _HexOutlinePainter({required this.color, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.86 * scale;
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final a = (pi / 3) * i - pi / 6;
      final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      if (i == 0) p.moveTo(pt.dx, pt.dy); else p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HexOutlinePainter old) =>
      old.color != color || old.scale != scale;
}

// ─────────────────────────────────────────────────────────────
//  CONNECTOR PAINTER
// ─────────────────────────────────────────────────────────────

class _ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  final double screenW;
  final double nodeLeft;
  final double nodeSize;

  const _ConnectorPainter(
      {required this.color,
        required this.isLeft,
        required this.screenW,
        required this.nodeLeft,
        required this.nodeSize});

  @override
  void paint(Canvas canvas, Size size) {
    final startX = nodeLeft + nodeSize / 2;
    final nextNodeLeft =
    isLeft ? screenW * 0.78 - nodeSize : screenW * 0.22;
    final endX = nextNodeLeft + nodeSize / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.35, endX, size.height * 0.65,
          endX, size.height);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (double t = 0.25; t < 0.85; t += 0.3) {
      final mt = 1 - t;
      final x = mt * mt * mt * startX +
          3 * mt * mt * t * startX +
          3 * mt * t * t * endX +
          t * t * t * endX;
      final y = mt * mt * mt * 0 +
          3 * mt * mt * t * (size.height * 0.35) +
          3 * mt * t * t * (size.height * 0.65) +
          t * t * t * size.height;
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  GRID PAINTER
// ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.035)
      ..strokeWidth = 0.5;
    const s = 30.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  MISSION BRIEF BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _MissionBriefSheet extends StatelessWidget {
  final CaseFile caseFile;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback onLaunch;
  const _MissionBriefSheet(
      {required this.caseFile,
        required this.isUnlocked,
        required this.isCompleted,
        required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(caseFile.difficulty);
    return Container(
        decoration: BoxDecoration(
            color: const Color(0xFF060D14),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: color.withOpacity(0.3))),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Row(children: [
                _Tag('#${caseFile.caseNumber}', color),
                const SizedBox(width: 8),
                _Tag(caseFile.difficulty.toUpperCase(), color),
                const Spacer(),
                Text(caseFile.estimatedDuration,
                    style: GoogleFonts.shareTechMono(
                        fontSize: 9, color: CyberColors.textMuted)),
              ]),
              const SizedBox(height: 10),
              Text(caseFile.title,
                  style: GoogleFonts.orbitron(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(caseFile.theme,
                  style: GoogleFonts.shareTechMono(
                      fontSize: 10,
                      color: CyberColors.textSecondary,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(color: color.withOpacity(0.14))),
                  child: Text(caseFile.shortDescription,
                      style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          color: CyberColors.textSecondary,
                          height: 1.6))),
              const SizedBox(height: 12),
              Row(children: [
                _StatChip(Icons.people_outline,
                    '${caseFile.suspects.length} SUSPECTS', color),
                const SizedBox(width: 8),
                _StatChip(Icons.folder_outlined,
                    '${caseFile.evidencePanels.length} PANELS', color),
                if (caseFile.timeLimitSeconds != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(Icons.timer_outlined, 'TIMED',
                      CyberColors.neonRed),
                ],
              ]),
              const SizedBox(height: 18),
              if (!isUnlocked)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: CyberColors.borderSubtle.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CyberColors.borderSubtle)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline,
                              color: CyberColors.textMuted, size: 14),
                          const SizedBox(width: 8),
                          Text('COMPLETE PREVIOUS CASE TO UNLOCK',
                              style: GoogleFonts.shareTechMono(
                                  fontSize: 9,
                                  color: CyberColors.textMuted,
                                  letterSpacing: 1)),
                        ]))
              else
                GestureDetector(
                    onTap: onLaunch,
                    child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  color.withOpacity(0.22),
                                  color.withOpacity(0.10)
                                ]),
                            border: Border.all(
                                color: color.withOpacity(0.55), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 14)
                            ]),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  isCompleted
                                      ? Icons.replay_outlined
                                      : Icons.play_arrow_outlined,
                                  color: color,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text(
                                  isCompleted
                                      ? 'REPLAY MISSION'
                                      : 'BEGIN MISSION',
                                  style: GoogleFonts.orbitron(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 1.5)),
                            ]))),
            ]));
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.35))),
      child: Text(text,
          style: GoogleFonts.shareTechMono(
              fontSize: 9, color: color, letterSpacing: 1)));
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.22))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.shareTechMono(
                fontSize: 8, color: color, letterSpacing: 0.5)),
      ]));
}