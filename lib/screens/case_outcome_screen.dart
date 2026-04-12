// lib/screens/case_outcome_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CASE OUTCOME — Three fully animated outcome screens
//
//  perfect/partial  → File slam + CASE CLOSED sticker slap
//  wrongAccusation  → Culprit smirk avatar + escape quote
//  coldCase         → Insufficient evidence briefing
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/game_progress.dart';
import '../services/case_repository.dart';
import '../services/progress_service.dart'; // ← ADDED: Firestore integration
import 'profile_screen.dart';
import 'case_analysis_screen.dart';

class CaseOutcomeScreen extends StatefulWidget {
  final String suspectId;
  const CaseOutcomeScreen({super.key, required this.suspectId});

  @override
  State<CaseOutcomeScreen> createState() => _CaseOutcomeScreenState();
}

class _CaseOutcomeScreenState extends State<CaseOutcomeScreen>
    with TickerProviderStateMixin {

  late OutcomeConfig _config;
  late OutcomeType _outcomeType;
  late bool _isWin;
  int _xpAwarded = 0;
  List<XpBreakdownItem> _breakdown = [];
  String? _nextUnlockedCaseTitle;
  bool _bootstrapped = false;

  // ── Win animation controllers ─────────────────────────────
  late AnimationController _fileDropCtrl;   // file falls from top
  late AnimationController _slamCtrl;       // slam impact + shake
  late AnimationController _stickerCtrl;    // sticker slap
  late AnimationController _contentCtrl;    // stats/xp panel fade in
  late AnimationController _barCtrl;        // XP bar fill

  late Animation<double> _fileDrop;
  late Animation<double> _fileRotate;
  late Animation<double> _slamShake;
  late Animation<double> _slamScale;
  late Animation<double> _stickerSlide;
  late Animation<double> _stickerRotate;
  late Animation<double> _stickerFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _barProgress;

  // ── Lose/escape animation controllers ─────────────────────
  late AnimationController _escapeCtrl;
  late Animation<double> _escapeFade;
  late Animation<double> _escapeScale;
  late Animation<Offset> _escapeSlide;
  late Animation<double> _quoteCtrl2;

  // ── Cold case animation ───────────────────────────────────
  late AnimationController _coldCtrl;
  late Animation<double> _coldFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // ── WIN sequence ──────────────────────────────────────

    // File drops from top (0→1 = off screen → resting position)
    _fileDropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fileDrop = CurvedAnimation(parent: _fileDropCtrl, curve: Curves.easeIn);
    _fileRotate = Tween<double>(begin: -0.08, end: 0.0)
        .animate(CurvedAnimation(parent: _fileDropCtrl, curve: Curves.easeOut));

    // Slam: quick scale punch + shake
    _slamCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slamShake = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slamCtrl, curve: Curves.elasticOut));
    _slamScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(_slamCtrl);

    // Sticker slaps in from upper-right, rotated
    _stickerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _stickerSlide = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _stickerCtrl, curve: Curves.easeOutBack));
    _stickerRotate = Tween<double>(begin: 0.3, end: -0.13)
        .animate(CurvedAnimation(parent: _stickerCtrl, curve: Curves.easeOutCubic));
    _stickerFade = CurvedAnimation(parent: _stickerCtrl, curve: Curves.easeIn);

    // Content fades in last
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    // XP bar
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _barProgress = const AlwaysStoppedAnimation(0.0); // set after bootstrap

    // ── ESCAPE sequence ───────────────────────────────────

    _escapeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _escapeFade = CurvedAnimation(parent: _escapeCtrl, curve: Curves.easeOut);
    _escapeScale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _escapeCtrl, curve: Curves.elasticOut));
    _escapeSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _escapeCtrl, curve: Curves.easeOutCubic));
    _quoteCtrl2 = CurvedAnimation(
        parent: _escapeCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    // ── COLD CASE ─────────────────────────────────────────
    _coldCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _coldFade = CurvedAnimation(parent: _coldCtrl, curve: Curves.easeOut);
  }

  void _bootstrapFromEngine(CaseEngine engine) {
    final outcomeType = engine.outcomeType;
    if (outcomeType == null) return;
    _outcomeType = outcomeType;
    _config = engine.resolvedOutcomeConfig!;
    _isWin = outcomeType == OutcomeType.perfect || outcomeType == OutcomeType.partial;

    if (_isWin) {
      final finalXp = engine.computeFinalXp(_config.xp);
      _breakdown = engine.xpBreakdown(_config.xp);
      _xpAwarded = GameProgress.completeCaseWithXp(engine.caseFile.id, finalXp);
      GameProgress.recordFlag(correct: true);
      _nextUnlockedCaseTitle = _findNextUnlockedCase(engine.caseFile);

      // ── ADDED: Persist win to Firestore ──────────────────
      // Derive a 0–3 star score from the XP breakdown:
      //   3 = perfect outcome with no deductions
      //   2 = partial or minor deductions
      //   1 = solved but heavily penalised
      final int score = (_outcomeType == OutcomeType.perfect
          ? (engine.irrelevantEvidenceCount == 0 && engine.hintsUsed == 0 ? 3 : 2)
          : 1).clamp(0, 3);

      ProgressService.instance.recordAttempt(
        caseId: engine.caseFile.id,
        solved: true,
        score: score,
      );
      // ─────────────────────────────────────────────────────

      _barProgress = Tween<double>(begin: 0.0, end: GameProgress.rankProgress)
          .animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));

      // Sequence: drop → slam → sticker → content
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _fileDropCtrl.forward().then((_) {
          HapticFeedback.heavyImpact();
          _slamCtrl.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!mounted) return;
              HapticFeedback.mediumImpact();
              _stickerCtrl.forward().then((_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  _contentCtrl.forward();
                  _barCtrl.forward();
                });
              });
            });
          });
        });
      });
    } else if (outcomeType == OutcomeType.wrongAccusation) {
      GameProgress.recordFlag(correct: false);

      // ── ADDED: Persist failed attempt to Firestore ────────
      ProgressService.instance.recordAttempt(
        caseId: engine.caseFile.id,
        solved: false,
        score: 0,
      );
      // ─────────────────────────────────────────────────────

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _escapeCtrl.forward();
      });
    } else {
      // cold case / partial with 0 evidence — no recordAttempt,
      // the player never actually submitted a suspect accusation.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _coldCtrl.forward();
      });
    }
  }

  String? _findNextUnlockedCase(CaseFile completed) {
    final allCases = CaseRepository.instance.all;
    final tier = allCases.where((c) => c.difficulty == completed.difficulty).toList();
    final idx = tier.indexWhere((c) => c.id == completed.id);
    if (idx < 0 || idx + 1 >= tier.length) return null;
    return tier[idx + 1].title;
  }

  @override
  void dispose() {
    _fileDropCtrl.dispose();
    _slamCtrl.dispose();
    _stickerCtrl.dispose();
    _contentCtrl.dispose();
    _barCtrl.dispose();
    _escapeCtrl.dispose();
    _coldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    if (!_bootstrapped) {
      _bootstrapFromEngine(engine);
      _bootstrapped = true;
    }

    switch (_outcomeType) {
      case OutcomeType.perfect:
      case OutcomeType.partial:
        return _buildWinScreen(context, engine);
      case OutcomeType.wrongAccusation:
        return _buildEscapeScreen(context, engine);
      case OutcomeType.coldCase:
        return _buildColdScreen(context, engine);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  WIN SCREEN — File slam + CASE CLOSED sticker
  // ════════════════════════════════════════════════════════════

  Widget _buildWinScreen(BuildContext context, CaseEngine engine) {
    final accusedSuspect = engine.caseFile.suspectById(widget.suspectId);
    final isPerfect = _outcomeType == OutcomeType.perfect;
    final accentColor = isPerfect ? CyberColors.neonGreen : CyberColors.neonAmber;

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──
          _OutcomeTopBar(title: 'CASE OUTCOME'),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(children: [

              const SizedBox(height: 20),

              // ── FILE SLAM ANIMATION ──
              AnimatedBuilder(
                animation: Listenable.merge([_fileDropCtrl, _slamCtrl, _stickerCtrl]),
                builder: (_, __) {
                  final dropY = Tween<double>(begin: -300.0, end: 0.0)
                      .evaluate(CurvedAnimation(parent: _fileDropCtrl, curve: Curves.easeIn));
                  final shakeX = sin(_slamShake.value * pi * 6) * 4 * (1 - _slamCtrl.value);

                  return Transform.translate(
                    offset: Offset(shakeX, dropY),
                    child: Transform.scale(
                      scale: _fileDropCtrl.isCompleted ? _slamScale.value : 1.0,
                      child: Transform.rotate(
                        angle: _fileRotate.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The file itself
                            _FileDossier(accentColor: accentColor, caseFile: engine.caseFile),
                            // CASE CLOSED sticker — appears after slam
                            if (_stickerCtrl.value > 0)
                              Transform.rotate(
                                angle: _stickerRotate.value,
                                child: Transform.scale(
                                  scale: _stickerSlide.value,
                                  child: Opacity(
                                    opacity: _stickerFade.value,
                                    child: _CaseClosedSticker(isPerfect: isPerfect),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Stats + XP — fade in after sticker ──
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(children: [
                    // Stats
                    _WinStatsPanel(
                      engine: engine,
                      suspectName: accusedSuspect?.name ?? '—',
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 20),
                    // XP Panel
                    _XpPanel(
                      xpAwarded: _xpAwarded,
                      baseXp: _config.xp,
                      breakdown: _breakdown,
                      barAnim: _barProgress,
                      nextTitle: _nextUnlockedCaseTitle,
                    ),
                    const SizedBox(height: 28),
                    // Buttons
                    _OutcomeButtons(
                      onAnalyze: () => Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const CaseAnalysisScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              SlideTransition(position: Tween<Offset>(
                                  begin: const Offset(1, 0), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                  child: child),
                          transitionDuration: const Duration(milliseconds: 350))),
                      onProfile: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    ),
                  ]),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ESCAPE SCREEN — Wrong culprit — suspect smirks
  // ════════════════════════════════════════════════════════════

  Widget _buildEscapeScreen(BuildContext context, CaseEngine engine) {
    final realCulprit = engine.caseFile.suspects.firstWhere(
            (s) => s.isGuilty, orElse: () => engine.caseFile.suspects.first);
    final wrongSuspect = engine.caseFile.suspectById(widget.suspectId);

    final escapeQuotes = [
      "Glad I wasn't caught.",
      "Wrong target, detective.",
      "Better luck next time.",
      "I escaped. For now.",
      "You had the wrong file.",
    ];
    final quote = escapeQuotes[realCulprit.name.length % escapeQuotes.length];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0408),
      body: SafeArea(
        child: Column(children: [
          _OutcomeTopBar(title: 'CASE OUTCOME'),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
            child: AnimatedBuilder(
              animation: _escapeCtrl,
              builder: (_, __) => Column(children: [
                // Wrong accusation banner
                FadeTransition(
                  opacity: _escapeFade,
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: CyberColors.neonRed.withOpacity(0.1),
                          border: Border(
                              bottom: BorderSide(color: CyberColors.neonRed.withOpacity(0.4)))),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: CyberColors.neonRed, size: 16),
                        const SizedBox(width: 8),
                        Text('WRONG ACCUSATION — CASE FAILED',
                            style: GoogleFonts.shareTechMono(
                                fontSize: 10, color: CyberColors.neonRed, letterSpacing: 1.5)),
                      ])),
                ),

                const SizedBox(height: 32),

                // Culprit smirk card
                Transform.scale(
                  scale: _escapeScale.value,
                  child: FadeTransition(
                    opacity: _escapeFade,
                    child: _CulpritEscapeCard(
                      culprit: realCulprit,
                      quote: quote,
                      quoteOpacity: _quoteCtrl2.value,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Wrong accusation detail
                FadeTransition(
                  opacity: _quoteCtrl2,
                  child: SlideTransition(
                    position: _escapeSlide,
                    child: Column(children: [
                      // You accused...
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF0A050A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: CyberColors.borderSubtle)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('YOUR ACCUSATION', style: GoogleFonts.shareTechMono(
                              fontSize: 8, color: CyberColors.textMuted, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person_outline, color: CyberColors.neonRed, size: 16),
                            const SizedBox(width: 8),
                            Text(wrongSuspect?.name ?? '—', style: GoogleFonts.orbitron(
                                fontSize: 14, color: CyberColors.neonRed, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: CyberColors.neonRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                                child: Text('INNOCENT', style: GoogleFonts.shareTechMono(
                                    fontSize: 8, color: CyberColors.neonRed, letterSpacing: 1))),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF050A08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('REAL CULPRIT', style: GoogleFonts.shareTechMono(
                              fontSize: 8, color: CyberColors.textMuted, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person, color: CyberColors.neonGreen, size: 16),
                            const SizedBox(width: 8),
                            Text(realCulprit.name, style: GoogleFonts.orbitron(
                                fontSize: 14, color: CyberColors.neonGreen, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: CyberColors.neonGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: CyberColors.neonGreen.withOpacity(0.4))),
                                child: Text('ESCAPED', style: GoogleFonts.shareTechMono(
                                    fontSize: 8, color: CyberColors.neonGreen, letterSpacing: 1))),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      _OutcomeButtons(
                        onAnalyze: () => Navigator.push(context, PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const CaseAnalysisScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 350))),
                        onProfile: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  COLD CASE SCREEN — Insufficient evidence
  // ════════════════════════════════════════════════════════════

  Widget _buildColdScreen(BuildContext context, CaseEngine engine) {
    return Scaffold(
      backgroundColor: const Color(0xFF040810),
      body: SafeArea(
        child: Column(children: [
          _OutcomeTopBar(title: 'CASE OUTCOME'),
          Expanded(child: FadeTransition(
            opacity: _coldFade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
              child: Column(children: [

                // Briefing failure visual
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                      color: const Color(0xFF060C18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withOpacity(0.3))),
                  child: Column(children: [
                    // Stamped COLD CASE indicator
                    Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueGrey.withOpacity(0.08),
                            border: Border.all(color: Colors.blueGrey.withOpacity(0.4), width: 2)),
                        child: const Icon(Icons.ac_unit_outlined, color: Colors.blueGrey, size: 48)),
                    const SizedBox(height: 20),
                    Text('CASE GONE COLD', style: GoogleFonts.orbitron(
                        fontSize: 22, color: Colors.blueGrey, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text('NOT ENOUGH EVIDENCE', style: GoogleFonts.shareTechMono(
                        fontSize: 11, color: Colors.blueGrey.withOpacity(0.7), letterSpacing: 3)),
                    const SizedBox(height: 20),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueGrey.withOpacity(0.2))),
                        child: Column(children: [
                          Text('"Without sufficient evidence, no case can be made.', style: GoogleFonts.shareTechMono(
                              fontSize: 11, color: CyberColors.textSecondary,
                              height: 1.7, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text('The file goes into the cold case drawer."', style: GoogleFonts.shareTechMono(
                              fontSize: 11, color: CyberColors.textSecondary,
                              height: 1.7, fontStyle: FontStyle.italic)),
                        ])),
                  ]),
                ),

                const SizedBox(height: 24),

                // Evidence stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF060C18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CyberColors.borderSubtle)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('INVESTIGATION REPORT', style: GoogleFonts.shareTechMono(
                        fontSize: 8, color: CyberColors.textMuted, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    _ColdStatRow('Evidence collected', '${engine.collectedEvidence.length}'),
                    _ColdStatRow('Correct evidence needed',
                        '${engine.caseFile.winCondition.minCorrectEvidence}'),
                    _ColdStatRow('Correct found', '${engine.correctEvidenceCount}',
                        highlight: engine.correctEvidenceCount > 0),
                    _ColdStatRow('Verdict', 'INSUFFICIENT EVIDENCE', isRed: true),
                  ]),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: CyberColors.neonAmber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.25))),
                  child: Row(children: [
                    Icon(Icons.lightbulb_outline, color: CyberColors.neonAmber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                        'Explore all evidence panels before flagging a suspect. '
                            'You need at least ${engine.caseFile.winCondition.minCorrectEvidence} correct evidence items.',
                        style: GoogleFonts.shareTechMono(
                            fontSize: 10, color: CyberColors.neonAmber, height: 1.6))),
                  ]),
                ),

                const SizedBox(height: 24),
                _OutcomeButtons(
                  onAnalyze: () => Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const CaseAnalysisScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 350))),
                  onProfile: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FILE DOSSIER WIDGET — the physical case file that drops
// ════════════════════════════════════════════════════════════

class _FileDossier extends StatelessWidget {
  final Color accentColor;
  final CaseFile caseFile;
  const _FileDossier({required this.accentColor, required this.caseFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3A28), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: accentColor.withOpacity(0.08), blurRadius: 30),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // File header tabs
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(4))),
              child: Text('CLASSIFIED', style: GoogleFonts.shareTechMono(
                  fontSize: 8, color: accentColor, letterSpacing: 2, fontWeight: FontWeight.bold))),
          Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: CyberColors.borderSubtle.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(4))),
              child: Text('CASE #${caseFile.caseNumber}', style: GoogleFonts.shareTechMono(
                  fontSize: 8, color: CyberColors.textMuted, letterSpacing: 1.5))),
        ]),
        const SizedBox(height: 16),
        // File content
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left: lines simulating text (paper texture)
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('INVESTIGATION FILE', style: GoogleFonts.shareTechMono(
                fontSize: 8, color: accentColor.withOpacity(0.6), letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(caseFile.title, style: GoogleFonts.orbitron(
                fontSize: 16, color: CyberColors.textPrimary,
                fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 6),
            Text(caseFile.shortDescription, style: GoogleFonts.shareTechMono(
                fontSize: 9, color: CyberColors.textSecondary, height: 1.6),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            // Paper lines
            ..._buildPaperLines(accentColor),
          ])),
          const SizedBox(width: 16),
          // Right: case badge
          Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.08),
                  border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5)),
              child: Center(child: Icon(Icons.folder_outlined, color: accentColor, size: 28))),
        ]),
      ]),
    );
  }

  List<Widget> _buildPaperLines(Color accent) {
    return [
      Container(height: 1, color: accent.withOpacity(0.08), margin: const EdgeInsets.only(bottom: 5)),
      Container(height: 1, width: 180, color: accent.withOpacity(0.06), margin: const EdgeInsets.only(bottom: 5)),
      Container(height: 1, color: accent.withOpacity(0.08), margin: const EdgeInsets.only(bottom: 5)),
      Container(height: 1, width: 140, color: accent.withOpacity(0.05)),
    ];
  }
}

// ════════════════════════════════════════════════════════════
//  CASE CLOSED STICKER — rubber stamp style
// ════════════════════════════════════════════════════════════

class _CaseClosedSticker extends StatelessWidget {
  final bool isPerfect;
  const _CaseClosedSticker({required this.isPerfect});

  @override
  Widget build(BuildContext context) {
    final Color stamp = isPerfect ? CyberColors.neonGreen : CyberColors.neonAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: stamp.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: stamp, width: 3),
        boxShadow: [
          BoxShadow(color: stamp.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: stamp.withOpacity(0.2), blurRadius: 40, spreadRadius: 6),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          isPerfect ? 'CASE CLOSED' : 'PARTIAL',
          style: GoogleFonts.orbitron(
            fontSize: isPerfect ? 22 : 18,
            fontWeight: FontWeight.w900,
            color: stamp,
            letterSpacing: isPerfect ? 4 : 3,
            shadows: [Shadow(color: stamp, blurRadius: 12)],
          ),
        ),
        if (isPerfect) ...[
          const SizedBox(height: 2),
          Container(height: 1.5, width: 100, color: stamp.withOpacity(0.6)),
          const SizedBox(height: 2),
          Text('RESOLVED', style: GoogleFonts.shareTechMono(
              fontSize: 9, color: stamp.withOpacity(0.7), letterSpacing: 4)),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CULPRIT ESCAPE CARD
// ════════════════════════════════════════════════════════════

class _CulpritEscapeCard extends StatelessWidget {
  final dynamic culprit; // Suspect
  final String quote;
  final double quoteOpacity;

  const _CulpritEscapeCard({
    required this.culprit, required this.quote, required this.quoteOpacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0508),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberColors.neonRed.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: CyberColors.neonRed.withOpacity(0.12), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: Column(children: [
        // Suspect avatar — large circle with initial + smirk icon
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow
            Container(width: 110, height: 110, decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: CyberColors.neonRed.withOpacity(0.3), blurRadius: 40, spreadRadius: 8)])),
            // Avatar circle
            Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      CyberColors.neonRed.withOpacity(0.2),
                      const Color(0xFF0A0508),
                    ]),
                    border: Border.all(color: CyberColors.neonRed.withOpacity(0.6), width: 2)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(culprit.name.isNotEmpty ? culprit.name[0] : '?',
                      style: GoogleFonts.orbitron(
                          fontSize: 36, color: CyberColors.neonRed,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: CyberColors.neonRed, blurRadius: 16)])),
                ])),
            // Smirk badge
            Positioned(bottom: 0, right: 0,
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A0508),
                        border: Border.all(color: CyberColors.neonRed.withOpacity(0.5), width: 1.5)),
                    child: Text('😏', style: const TextStyle(fontSize: 18)))),
          ],
        ),
        const SizedBox(height: 16),
        Text(culprit.name, style: GoogleFonts.orbitron(
            fontSize: 16, color: CyberColors.neonRed, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(culprit.role, style: GoogleFonts.shareTechMono(
            fontSize: 9, color: CyberColors.textMuted, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        // Speech bubble
        Opacity(
          opacity: quoteOpacity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
                color: CyberColors.neonRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberColors.neonRed.withOpacity(0.25))),
            child: Column(children: [
              Text('"$quote"',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 14, color: CyberColors.textPrimary,
                      height: 1.6, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('— ${culprit.name}', style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: CyberColors.neonRed.withOpacity(0.6), letterSpacing: 1)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  WIN STATS PANEL
// ════════════════════════════════════════════════════════════

class _WinStatsPanel extends StatelessWidget {
  final CaseEngine engine;
  final String suspectName;
  final Color accentColor;

  const _WinStatsPanel({
    required this.engine, required this.suspectName, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final correct = engine.correctEvidenceCount;
    final total = engine.caseFile.correctEvidenceIds.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF060D14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CASE REPORT', style: GoogleFonts.shareTechMono(
            fontSize: 8, color: CyberColors.textMuted, letterSpacing: 2)),
        const SizedBox(height: 12),
        _WinStatRow('Culprit Flagged', suspectName, accentColor),
        _WinStatRow('Evidence Correct', '$correct / $total',
            correct >= engine.caseFile.winCondition.minCorrectEvidence
                ? CyberColors.neonGreen : CyberColors.neonAmber),
        _WinStatRow('Irrelevant Evidence', '${engine.irrelevantEvidenceCount}',
            engine.irrelevantEvidenceCount > 0 ? CyberColors.neonRed : CyberColors.neonGreen),
        if (engine.hintsUsed > 0)
          _WinStatRow('Hints Used', '${engine.hintsUsed}', CyberColors.neonAmber),
        if (engine.hasTimer)
          _WinStatRow('Time Used', _formatTime(engine.elapsedSeconds),
              engine.isTimeUp ? CyberColors.neonRed : CyberColors.neonGreen),
      ]),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _WinStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _WinStatRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: GoogleFonts.shareTechMono(
          fontSize: 10, color: CyberColors.textSecondary))),
      Text(value, style: GoogleFonts.orbitron(
          fontSize: 12, color: valueColor, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════
//  XP PANEL
// ════════════════════════════════════════════════════════════

class _XpPanel extends StatelessWidget {
  final int xpAwarded;
  final int baseXp;
  final List<XpBreakdownItem> breakdown;
  final Animation<double> barAnim;
  final String? nextTitle;

  const _XpPanel({
    required this.xpAwarded, required this.baseXp,
    required this.breakdown, required this.barAnim, this.nextTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF060D14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CyberColors.neonCyan.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.stars, color: CyberColors.neonCyan, size: 20),
          const SizedBox(width: 8),
          Text('XP AWARDED', style: GoogleFonts.shareTechMono(
              fontSize: 8, color: CyberColors.textMuted, letterSpacing: 2)),
          const Spacer(),
          xpAwarded > 0
              ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [CyberColors.neonCyan, CyberColors.neonPurple]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.4), blurRadius: 10)]),
              child: Text('+$xpAwarded XP', style: GoogleFonts.orbitron(
                  fontSize: 13, color: Colors.black, fontWeight: FontWeight.w900)))
              : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: CyberColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CyberColors.textMuted.withOpacity(0.3))),
              child: Text('ALREADY EARNED', style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: CyberColors.textMuted))),
        ]),
        if (breakdown.isNotEmpty && xpAwarded > 0) ...[
          const SizedBox(height: 12),
          ...breakdown.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(child: Text(item.label, style: GoogleFonts.shareTechMono(
                    fontSize: 10, color: CyberColors.textSecondary))),
                Text(item.positive ? '+${item.delta}' : '${item.delta}',
                    style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w700,
                        color: item.positive ? CyberColors.neonGreen : CyberColors.neonRed)),
              ]))),
          Divider(color: CyberColors.borderSubtle, height: 16),
          Row(children: [
            Expanded(child: Text('FINAL XP', style: GoogleFonts.shareTechMono(
                fontSize: 10, color: CyberColors.textPrimary, fontWeight: FontWeight.bold))),
            Text('+$xpAwarded', style: GoogleFonts.orbitron(
                fontSize: 14, color: CyberColors.neonCyan, fontWeight: FontWeight.w900)),
          ]),
        ],
        const SizedBox(height: 14),
        // Rank progress bar
        Row(children: [
          Text('${GameProgress.title.toUpperCase()}', style: GoogleFonts.shareTechMono(
              fontSize: 9, color: CyberColors.neonPurple, letterSpacing: 1)),
          const Spacer(),
          Text('${GameProgress.xpToNextRank} → ${GameProgress.nextRankName}',
              style: GoogleFonts.shareTechMono(fontSize: 8, color: CyberColors.textMuted)),
        ]),
        const SizedBox(height: 6),
        AnimatedBuilder(
            animation: barAnim,
            builder: (_, __) => Stack(children: [
              Container(height: 6, decoration: BoxDecoration(
                  color: CyberColors.borderSubtle, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                  widthFactor: barAnim.value.clamp(0.0, 1.0),
                  child: Container(height: 6, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [CyberColors.neonCyan, CyberColors.neonPurple]),
                      boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.5), blurRadius: 6)]))),
            ])),
        if (nextTitle != null) ...[
          const SizedBox(height: 14),
          Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: CyberColors.neonGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.lock_open_outlined, color: CyberColors.neonGreen, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NEXT MISSION UNLOCKED', style: GoogleFonts.shareTechMono(
                      fontSize: 8, color: CyberColors.neonGreen, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(nextTitle!, style: GoogleFonts.orbitron(
                      fontSize: 11, color: CyberColors.textPrimary, fontWeight: FontWeight.w600)),
                ])),
              ])),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _OutcomeTopBar extends StatelessWidget {
  final String title;
  const _OutcomeTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: CyberColors.neonCyan.withOpacity(0.1)))),
      child: Row(children: [
        Text(title, style: GoogleFonts.orbitron(
            fontSize: 16, color: CyberColors.neonCyan,
            fontWeight: FontWeight.w700, letterSpacing: 2)),
        const Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: CyberColors.neonGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3))),
            child: Text('FIELD REPORT', style: GoogleFonts.shareTechMono(
                fontSize: 8, color: CyberColors.neonGreen, letterSpacing: 1.5))),
      ]),
    );
  }
}

class _OutcomeButtons extends StatelessWidget {
  final VoidCallback onAnalyze;
  final VoidCallback onProfile;
  const _OutcomeButtons({required this.onAnalyze, required this.onProfile});

  @override
  Widget build(BuildContext context) => Column(children: [
    GestureDetector(
      onTap: onAnalyze,
      child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(colors: [
                CyberColors.neonAmber.withOpacity(0.15),
                CyberColors.neonAmber.withOpacity(0.06)]),
              border: Border.all(color: CyberColors.neonAmber.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: CyberColors.neonAmber.withOpacity(0.1), blurRadius: 12)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.manage_search_outlined, color: CyberColors.neonAmber, size: 18),
            const SizedBox(width: 10),
            Text('ANALYZE CASE', style: GoogleFonts.orbitron(
                fontSize: 13, color: CyberColors.neonAmber, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ])),
    ),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: onProfile,
      child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(colors: [
                CyberColors.neonCyan.withOpacity(0.15),
                CyberColors.neonCyan.withOpacity(0.06)]),
              border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_outline, color: CyberColors.neonCyan, size: 18),
            const SizedBox(width: 10),
            Text('CHECK PROFILE', style: GoogleFonts.orbitron(
                fontSize: 13, color: CyberColors.neonCyan, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ])),
    ),
  ]);
}

class _ColdStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isRed;
  const _ColdStatRow(this.label, this.value, {this.highlight = false, this.isRed = false});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.shareTechMono(
            fontSize: 10, color: CyberColors.textSecondary))),
        Text(value, style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w700,
            color: isRed ? CyberColors.neonRed : highlight ? CyberColors.neonAmber : CyberColors.textPrimary)),
      ]));
}