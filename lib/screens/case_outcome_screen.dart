// lib/screens/case_outcome_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CASE OUTCOME — data-driven via CaseEngine
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/game_progress.dart';
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
  late AnimationController _entryCtrl;
  late AnimationController _iconCtrl;
  late AnimationController _barCtrl;

  late Animation<double> _fadeIn;
  late Animation<double> _iconScale;
  late Animation<double> _iconGlow;
  late Animation<double> _barProgress;

  late OutcomeConfig _config;
  late bool _isWin;

  // True if XP was freshly awarded; false when replaying an already-completed case
  bool _xpAwarded = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();

    // Entry
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Icon pop
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));

    // XP bar — end value is set after XP award in _bootstrapFromEngine
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Placeholder; real tween is built in _bootstrapFromEngine after XP applied
    _barProgress = const AlwaysStoppedAnimation(0.0);

    Future.delayed(const Duration(milliseconds: 400),
            () => mounted ? _iconCtrl.forward() : null);
  }

  /// Called exactly once in the first build when the engine is available.
  void _bootstrapFromEngine(CaseEngine engine) {
    final outcomeType = engine.outcomeType;
    if (outcomeType == null) return;

    _config = engine.resolvedOutcomeConfig!;
    _isWin = outcomeType == OutcomeType.perfect;

    if (_isWin) {
      // completeCaseWithXp guards against double-XP on replay
      _xpAwarded = GameProgress.completeCaseWithXp(
          engine.caseFile.id, _config.xp);
    }

    // Build bar animation using the post-award rankProgress value
    _barProgress =
        Tween<double>(begin: 0.0, end: GameProgress.rankProgress).animate(
            CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));

    if (_isWin) {
      Future.delayed(const Duration(milliseconds: 800),
              () => mounted ? _barCtrl.forward() : null);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _iconCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  _IconConfig _iconConfig(OutcomeType type) {
    switch (type) {
      case OutcomeType.perfect:
        return _IconConfig(Icons.verified_outlined, CyberColors.neonGreen);
      case OutcomeType.partial:
        return _IconConfig(
            Icons.warning_amber_outlined, CyberColors.neonAmber);
      case OutcomeType.wrongAccusation:
        return _IconConfig(Icons.cancel_outlined, CyberColors.neonRed);
      case OutcomeType.coldCase:
        return _IconConfig(Icons.ac_unit_outlined, Colors.blueGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);

    if (!_bootstrapped) {
      _bootstrapFromEngine(engine);
      _bootstrapped = true;
    }

    final outcomeType = engine.outcomeType ?? OutcomeType.coldCase;
    final iconCfg = _iconConfig(outcomeType);
    final collected = engine.collectedEvidence;
    final correctCount = engine.correctEvidenceCount;
    final accusedSuspect =
    engine.caseFile.suspectById(widget.suspectId);

    return AppShell(
      title: 'Case Outcome',
      showBack: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(children: [
            // ── Outcome Hero ──
            NeonContainer(
              borderColor: iconCfg.color,
              padding: const EdgeInsets.symmetric(
                  vertical: 40, horizontal: 24),
              child: Column(children: [
                AnimatedBuilder(
                  animation: _iconCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _iconScale.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          iconCfg.color
                              .withOpacity(0.15 * _iconGlow.value),
                          Colors.transparent,
                        ]),
                        border: Border.all(
                            color: iconCfg.color.withOpacity(0.6),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: iconCfg.color
                                .withOpacity(0.4 * _iconGlow.value),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(iconCfg.icon,
                          color: iconCfg.color, size: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StatusChip(
                    label: _config.label, color: iconCfg.color),
                const SizedBox(height: 12),
                Text(
                  _config.title,
                  style: TextStyle(
                    fontFamily: 'DotMatrix',
                    fontSize: 28,
                    color: iconCfg.color,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: iconCfg.color, blurRadius: 16)
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _config.subtitle,
                  style: CyberText.bodySmall.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Stats Panel ──
            NeonContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CyberSectionHeader(title: 'Case Report'),
                    _StatRow(
                      label: 'Suspect Flagged',
                      value: accusedSuspect?.name ?? '—',
                      valueColor: (accusedSuspect?.isGuilty ?? false)
                          ? CyberColors.neonGreen
                          : CyberColors.neonRed,
                    ),
                    _StatRow(
                      label: 'Evidences Collected',
                      value: '${collected.length}',
                    ),
                    _StatRow(
                      label: 'Correct Evidence Matches',
                      value:
                      '$correctCount / ${engine.caseFile.correctEvidenceIds.length}',
                      valueColor: correctCount >= 3
                          ? CyberColors.neonGreen
                          : CyberColors.neonAmber,
                    ),
                    _StatRow(
                      label: 'Outcome',
                      value: _config.label,
                      valueColor: iconCfg.color,
                      isLast: true,
                    ),
                  ]),
            ),

            // ── XP Panel (win only) ──
            if (_isWin) ...[
              const SizedBox(height: 24),
              NeonContainer(
                borderColor: CyberColors.neonCyan,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.stars,
                            color: CyberColors.neonCyan, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('XP Awarded',
                              style: CyberText.sectionTitle),
                        ),
                        // Show glowing "+N XP" on first win; muted badge on replay
                        _xpAwarded
                            ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: CyberColors.neonCyanGradient,
                            borderRadius: CyberRadius.pill,
                            boxShadow:
                            CyberShadows.neonCyan(intensity: 0.6),
                          ),
                          child: Text(
                            '+ ${_config.xp} XP',
                            style: const TextStyle(
                              fontFamily: 'DotMatrix',
                              fontSize: 14,
                              color: CyberColors.textOnNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                            CyberColors.textMuted.withOpacity(0.1),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(
                                color: CyberColors.textMuted
                                    .withOpacity(0.35),
                                width: 1),
                          ),
                          child: const Text(
                            'ALREADY EARNED',
                            style: TextStyle(
                              fontFamily: 'DotMatrix',
                              fontSize: 11,
                              color: CyberColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Text('Title: ', style: CyberText.bodySmall),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CyberColors.neonPurple.withOpacity(0.12),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(
                              color:
                              CyberColors.neonPurple.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            GameProgress.title.toUpperCase(),
                            style: const TextStyle(
                              color: CyberColors.neonPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _barProgress,
                        builder: (_, __) => CyberProgressBar(
                          value: _barProgress.value,
                          height: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total XP: ${GameProgress.xp}',
                              style: CyberText.bodySmall.copyWith(
                                  color: CyberColors.neonCyan)),
                          Text(
                              '${GameProgress.xpToNextRank} XP → ${GameProgress.nextRankName}',
                              style: CyberText.caption),
                        ],
                      ),
                    ]),
              ),
            ],

            const SizedBox(height: 36),

            // ── Analyze Case ──
            SizedBox(
              width: double.infinity,
              child: CyberButton(
                label: 'Analyze Case',
                icon: Icons.manage_search_outlined,
                accentColor: CyberColors.neonAmber,
                isOutlined: true,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                      const CaseAnalysisScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                      transitionDuration:
                      const Duration(milliseconds: 350),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Check Profile ──
            SizedBox(
              width: double.infinity,
              child: CyberButton(
                label: 'Check Profile',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _IconConfig {
  final IconData icon;
  final Color color;
  const _IconConfig(this.icon, this.color);
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: CyberText.bodySmall),
            Text(value,
                style: TextStyle(
                  color: valueColor ?? CyberColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
          ],
        ),
      ),
      if (!isLast)
        Divider(
            color: CyberColors.borderSubtle, height: 1, thickness: 1),
    ]);
  }
}