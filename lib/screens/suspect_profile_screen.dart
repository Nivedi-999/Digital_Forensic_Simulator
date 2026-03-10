// lib/screens/suspect_profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  SUSPECT PROFILE — data-driven via CaseEngine
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/suspect.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/game_progress.dart';
import 'case_outcome_screen.dart';

class SuspectProfileScreen extends StatefulWidget {
  final String suspectId;

  const SuspectProfileScreen({super.key, required this.suspectId});

  @override
  State<SuspectProfileScreen> createState() => _SuspectProfileScreenState();
}

class _SuspectProfileScreenState extends State<SuspectProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _barCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _barAnim =
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _barCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  // Score-based colour: >=70% → red, >=35% → amber, else green
  Color _scoreColor(double score) {
    if (score >= 0.70) return CyberColors.neonRed;
    if (score >= 0.35) return CyberColors.neonAmber;
    return CyberColors.neonGreen;
  }

  // Score-based label: >=70% → Critical, >=35% → Moderate, else Low
  String _scoreText(double score) {
    if (score >= 0.70) return 'Critical';
    if (score >= 0.35) return 'Moderate';
    return 'Low';
  }

  // Fixed display score from riskLevel — never changes during gameplay
  double _fixedScore(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return 0.75;
      case 'medium': return 0.50;
      default:       return 0.20;
    }
  }

  // Kept for reference
  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final suspect = engine.caseFile.suspectById(widget.suspectId);
    if (suspect == null) return const SizedBox();

    // Suspicion display is FIXED — derived entirely from the JSON riskLevel.
    // It never reads from the engine's dynamic score, so collecting evidence
    // cannot change what the player sees on this screen.
    //   high   → 0.75  (Critical)
    //   medium → 0.50  (Moderate)
    //   low    → 0.20  (Low)
    final double suspicionValue = _fixedScore(suspect.riskLevel);
    final riskColor = _scoreColor(suspicionValue);
    final footprint = suspect.digitalFootprint;

    return AppShell(
      title: 'Suspect Profile',
      showBack: true,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar Hero Card ──
              Center(
                child: NeonContainer(
                  borderColor: riskColor,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            riskColor.withOpacity(0.2),
                            CyberColors.bgCard,
                          ]),
                          border: Border.all(color: riskColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: riskColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            suspect.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 42,
                              color: riskColor,
                              fontFamily: 'DotMatrix',
                              shadows: [
                                Shadow(color: riskColor, blurRadius: 12)
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        suspect.name,
                        style: TextStyle(
                          fontFamily: 'DotMatrix',
                          fontSize: 26,
                          color: riskColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(suspect.department, style: CyberText.bodySmall),
                      const SizedBox(height: 4),
                      Text(suspect.role,
                          style: CyberText.bodySmall
                              .copyWith(color: CyberColors.textSecondary)),
                      const SizedBox(height: 12),
                      StatusChip(
                        label: 'THREAT: ${_scoreText(suspicionValue).toUpperCase()}',
                        color: riskColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Suspicion Meter ──
              CyberSectionHeader(
                title: 'Suspicion Level',
                color: riskColor,
              ),
              NeonContainer(
                borderColor: riskColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _barAnim,
                      builder: (_, __) => CyberProgressBar(
                        value: suspicionValue * _barAnim.value,
                        color: riskColor,
                        height: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ${_scoreText(suspicionValue)}',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(suspicionValue * 100).toInt()}% threat score',
                          style: CyberText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Profile Notes ──
              if (suspect.profileNotes != null) ...[
                const SizedBox(height: 28),
                const CyberSectionHeader(
                  title: 'Analyst Notes',
                  subtitle: 'Investigation observations',
                ),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    suspect.profileNotes!,
                    style:
                    CyberText.bodySmall.copyWith(height: 1.6),
                  ),
                ),
              ],

              // ── Digital Footprint ──
              if (footprint != null) ...[
                const SizedBox(height: 28),
                const CyberSectionHeader(
                  title: 'Digital Footprint',
                  subtitle: 'Network & device activity trace',
                ),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FootprintRow(
                        icon: Icons.wifi,
                        label: 'IP Activity',
                        value: footprint.ipActivity,
                      ),
                      _FootprintRow(
                        icon: Icons.computer,
                        label: 'Device Usage',
                        value: footprint.deviceUsage,
                      ),
                      _FootprintRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location Trace',
                        value: footprint.locationTrace,
                      ),
                      _FootprintRow(
                        icon: Icons.vpn_lock_outlined,
                        label: 'VPN Check',
                        value: footprint.vpnCheck,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: CyberButton(
                      label: 'Investigate',
                      icon: Icons.search,
                      isOutlined: true,
                      isSmall: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberButton(
                      label: 'Flag Culprit',
                      icon: Icons.flag,
                      accentColor: CyberColors.neonRed,
                      isSmall: true,
                      onTap: () => _flagAsCulprit(context, engine, suspect),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _flagAsCulprit(
      BuildContext context, CaseEngine engine, Suspect suspect) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmFlagDialog(
        suspectName: suspect.name,
        onConfirm: () {
          final outcome = engine.accuse(suspect.id);
          GameProgress.recordFlag(correct: suspect.isGuilty);
          Navigator.pop(context); // close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CaseOutcomeScreen(
                suspectId: suspect.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Footprint Row ──

class _FootprintRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _FootprintRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CyberColors.neonCyan.withOpacity(0.1),
              borderRadius: CyberRadius.small,
            ),
            child: Icon(icon, color: CyberColors.neonCyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: CyberText.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 1),
                Text(value,
                    style: CyberText.bodySmall.copyWith(
                        color: CyberColors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ]),
        if (!isLast)
          Divider(
            color: CyberColors.borderSubtle,
            height: 20,
            thickness: 1,
          ),
      ],
    );
  }
}

// ── Confirm Flag Dialog ──

class _ConfirmFlagDialog extends StatelessWidget {
  final String suspectName;
  final VoidCallback onConfirm;

  const _ConfirmFlagDialog({
    required this.suspectName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: CyberRadius.large,
        side: BorderSide(
            color: CyberColors.neonRed.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, color: CyberColors.neonRed, size: 48,
                shadows: [Shadow(color: CyberColors.neonRed, blurRadius: 16)]),
            const SizedBox(height: 16),
            Text('Flag as Culprit?',
                style: CyberText.sectionTitle.copyWith(
                    color: CyberColors.neonRed, fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              'You are about to accuse $suspectName.\nThis action will close the case.\n\nAre you confident in your evidence?',
              style: CyberText.bodySmall.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: CyberButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CyberButton(
                  label: 'Confirm',
                  accentColor: CyberColors.neonRed,
                  onTap: onConfirm,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}