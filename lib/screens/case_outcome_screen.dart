// lib/screens/case_outcome_screen.dart
// ═══════════════════════════════════════════════════════════════
//  REDESIGNED CASE OUTCOME SCREEN
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../services/evidence_collector.dart';
import '../services/game_progress.dart';

class CaseOutcomeScreen extends StatefulWidget {
  final String? flaggedSuspectName;

  const CaseOutcomeScreen({
    super.key,
    this.flaggedSuspectName,
  });

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

  final Set<String> _correctEvidences = {
    'files:finance_report_q3.pdf',
    'files:debug_log.txt',
    'meta:Last User',
    'ip:Internal Origin',
    'ip:External Hop',
  };

  late bool _isCorrectSuspect;
  late int _correctCount;
  late bool _isWin;

  @override
  void initState() {
    super.initState();

    final collected = EvidenceCollector().collected;
    _correctCount = collected.where((item) {
      final key = '${item['category']}:${item['item']}';
      return _correctEvidences.contains(key);
    }).length;
    _isCorrectSuspect = widget.flaggedSuspectName == 'Ankita E';
    _isWin = _isCorrectSuspect && _correctCount >= 3;

    if (_isWin) {
      GameProgress.addXp(10);
      GameProgress.incrementCasesSolved();
    }

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Icon scale
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut),
    );
    _iconGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut),
    );

    // XP bar
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _barProgress = Tween<double>(
      begin: 0.0,
      end: GameProgress.rankProgress,
    ).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _iconCtrl.forward();
    });
    if (_isWin) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _barCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _iconCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // Outcome configuration
  _OutcomeConfig get _config {
    if (!_isCorrectSuspect) {
      return _OutcomeConfig(
        title: 'Wrong Suspect',
        subtitle:
        'You flagged ${widget.flaggedSuspectName ?? "unknown"}, but the real culprit was Ankita E.',
        label: 'CASE FAILED',
        icon: Icons.cancel_outlined,
        color: CyberColors.neonRed,
        gradient: CyberColors.dangerGradient,
      );
    } else if (_correctCount >= 3) {
      return _OutcomeConfig(
        title: 'Case Solved!',
        subtitle:
        'Correct suspect identified with sufficient evidence chain.',
        label: 'CASE CLOSED',
        icon: Icons.verified_outlined,
        color: CyberColors.neonGreen,
        gradient: CyberColors.successGradient,
      );
    } else if (_correctCount == 0) {
      return _OutcomeConfig(
        title: 'Case Gone Cold',
        subtitle: 'No relevant evidence was collected to support the accusation.',
        label: 'COLD CASE',
        icon: Icons.ac_unit_outlined,
        color: Colors.blueGrey,
        gradient: const LinearGradient(colors: [Colors.blueGrey, Colors.grey]),
      );
    } else {
      return _OutcomeConfig(
        title: 'Insufficient Evidence',
        subtitle:
        'Correct suspect, but not enough evidence to close the case.',
        label: 'PARTIAL',
        icon: Icons.warning_amber_outlined,
        color: CyberColors.neonAmber,
        gradient: LinearGradient(
          colors: [CyberColors.neonAmber, Colors.orange.shade800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final collected = EvidenceCollector().collected;

    return AppShell(
      title: 'Case Outcome',
      showBack: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            children: [
              // ── Outcome Hero ──
              NeonContainer(
                borderColor: cfg.color,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    // Icon with glow
                    AnimatedBuilder(
                      animation: _iconCtrl,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _iconScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  cfg.color.withOpacity(0.15 * _iconGlow.value),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: cfg.color.withOpacity(0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cfg.color
                                      .withOpacity(0.4 * _iconGlow.value),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(cfg.icon, color: cfg.color, size: 56),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Status label
                    StatusChip(label: cfg.label, color: cfg.color),
                    const SizedBox(height: 12),

                    Text(
                      cfg.title,
                      style: TextStyle(
                        fontFamily: 'DotMatrix',
                        fontSize: 28,
                        color: cfg.color,
                        letterSpacing: 1,
                        shadows: [Shadow(color: cfg.color, blurRadius: 16)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cfg.subtitle,
                      style: CyberText.bodySmall.copyWith(height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                      value: widget.flaggedSuspectName ?? '—',
                      valueColor: _isCorrectSuspect
                          ? CyberColors.neonGreen
                          : CyberColors.neonRed,
                    ),
                    _StatRow(
                      label: 'Evidences Collected',
                      value: '${collected.length}',
                    ),
                    _StatRow(
                      label: 'Correct Evidence Matches',
                      value: '$_correctCount / ${_correctEvidences.length}',
                      valueColor: _correctCount >= 3
                          ? CyberColors.neonGreen
                          : CyberColors.neonAmber,
                    ),
                    _StatRow(
                      label: 'Outcome',
                      value: cfg.label,
                      valueColor: cfg.color,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // ── XP Panel (win only) ──
              if (_isWin) ...[
                const SizedBox(height: 24),
                NeonContainer(
                  borderColor: CyberColors.neonCyan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with +10 XP badge
                      Row(
                        children: [
                          const Icon(Icons.stars, color: CyberColors.neonCyan, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('XP Awarded', style: CyberText.sectionTitle),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: CyberColors.neonCyanGradient,
                              borderRadius: CyberRadius.pill,
                              boxShadow: CyberShadows.neonCyan(intensity: 0.6),
                            ),
                            child: const Text(
                              '+ 10 XP',
                              style: TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 14,
                                color: CyberColors.textOnNeon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Title badge
                      Row(
                        children: [
                          Text('Title: ', style: CyberText.bodySmall),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: CyberColors.neonPurple.withOpacity(0.12),
                              borderRadius: CyberRadius.pill,
                              border: Border.all(
                                color: CyberColors.neonPurple.withOpacity(0.4),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar within current rank band
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
                          Text(
                            'Total XP: ${GameProgress.xp}',
                            style: CyberText.bodySmall.copyWith(color: CyberColors.neonCyan),
                          ),
                          Text(
                            '${GameProgress.xpToNextRank} XP → ${GameProgress.nextRankName}',
                            style: CyberText.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),

              // ── Return Home ──
              SizedBox(
                width: double.infinity,
                child: CyberButton(
                  label: 'Return to Home',
                  icon: Icons.home_outlined,
                  onTap: () {
                    EvidenceCollector().clearAll();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Row ──
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: CyberText.bodySmall),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? CyberColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              color: CyberColors.borderSubtle, height: 1, thickness: 1),
      ],
    );
  }
}

// ── Config data class ──
class _OutcomeConfig {
  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const _OutcomeConfig({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}