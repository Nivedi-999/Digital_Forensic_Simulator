// lib/screens/suspect_profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  SUSPECT PROFILE — redesigned layout, same colour theme
//  Layout changes:
//    • Full-width banner with avatar LEFT + name/role/chips RIGHT
//    • Suspicion bar moved into the banner (contextual, not a
//      separate section)
//    • Digital Footprint as a 2-column key/value grid (not a
//      vertical list of rows)
//    • Analyst Notes in a bordered terminal-style block
//    • Action buttons pinned to bottom in a row
//  Avatar: loads assets/avatars/<suspectId>.png, falls back to
//  role icon + initial on error (identical to original fallback).
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
    _fadeIn   = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _barAnim  = CurvedAnimation(parent: _barCtrl,   curve: Curves.easeOutCubic);

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

  // ── Helpers (unchanged from original) ──────────────────────

  IconData _avatarIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('engineer') || r.contains('developer') || r.contains('devops')) return Icons.code;
    if (r.contains('finance') || r.contains('analyst') || r.contains('account')) return Icons.account_balance_outlined;
    if (r.contains('admin') || r.contains('manager') || r.contains('director')) return Icons.manage_accounts_outlined;
    if (r.contains('hr') || r.contains('human')) return Icons.people_outline;
    if (r.contains('student') || r.contains('intern')) return Icons.school_outlined;
    if (r.contains('security') || r.contains('forensic')) return Icons.security;
    if (r.contains('vendor') || r.contains('consultant')) return Icons.business_center_outlined;
    if (r.contains('network') || r.contains('telecom')) return Icons.router_outlined;
    return Icons.person_outline;
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  String _suspicionLabel(double value) {
    if (value >= 0.7) return 'CRITICAL';
    if (value >= 0.4) return 'MODERATE';
    return 'LOW';
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine    = CaseEngineProvider.of(context);
    final suspect   = engine.caseFile.suspectById(widget.suspectId);
    if (suspect == null) return const SizedBox();

    final suspicionValue = engine.suspicionFor(suspect.id);
    final riskColor      = _riskColor(suspect.riskLevel);
    final footprint      = suspect.digitalFootprint;

    return AppShell(
      title: 'Suspect Profile',
      showBack: true,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ════════════════════════════════════════════
              //  HERO BANNER — horizontal layout
              //  [ avatar ]  [ name / role / chips / bar ]
              // ════════════════════════════════════════════
              NeonContainer(
                borderColor: riskColor,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar (loads from assets first) ──
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          riskColor.withOpacity(0.22),
                          CyberColors.bgCard,
                        ]),
                        border: Border.all(color: riskColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: riskColor.withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/avatars/${suspect.id}.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _avatarIcon(suspect.role),
                                color: riskColor.withOpacity(0.2),
                                size: 52,
                              ),
                              Text(
                                suspect.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 40,
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: riskColor, blurRadius: 16)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // ── Identity + suspicion column ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suspect.name,
                            style: TextStyle(
                              fontFamily: 'DotMatrix',
                              fontSize: 20,
                              color: riskColor,
                              letterSpacing: 1,
                              shadows: [Shadow(color: riskColor, blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            suspect.role,
                            style: CyberText.bodySmall.copyWith(fontSize: 12),
                          ),
                          Text(
                            suspect.department,
                            style: CyberText.bodySmall.copyWith(
                                color: CyberColors.textSecondary,
                                fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          // Threat chip + suspicion label inline
                          Row(
                            children: [
                              StatusChip(
                                label: 'THREAT: ${suspect.risk.toUpperCase()}',
                                color: riskColor,
                              ),
                              const SizedBox(width: 8),
                              AnimatedBuilder(
                                animation: _barAnim,
                                builder: (_, __) => Text(
                                  '${(suspicionValue * _barAnim.value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontFamily: 'DotMatrix',
                                    fontSize: 13,
                                    color: riskColor,
                                    shadows: [Shadow(color: riskColor, blurRadius: 6)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Suspicion bar inside the banner
                          AnimatedBuilder(
                            animation: _barAnim,
                            builder: (_, __) => CyberProgressBar(
                              value: suspicionValue * _barAnim.value,
                              color: riskColor,
                              height: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SUSPICION: ${_suspicionLabel(suspicionValue)}',
                            style: CyberText.caption.copyWith(
                                color: riskColor, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ════════════════════════════════════════════
              //  DIGITAL FOOTPRINT — 2-column key/value grid
              // ════════════════════════════════════════════
              if (footprint != null) ...[
                const CyberSectionHeader(
                  title: 'Digital Footprint',
                  subtitle: 'Network & device activity trace',
                ),
                const SizedBox(height: 10),
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FootprintGrid(footprint: footprint),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ════════════════════════════════════════════
              //  ANALYST NOTES — terminal block style
              // ════════════════════════════════════════════
              if (suspect.profileNotes != null) ...[
                const CyberSectionHeader(
                  title: 'Analyst Notes',
                  subtitle: 'Investigation observations',
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CyberColors.bgCard,
                    borderRadius: CyberRadius.medium,
                    border: Border(
                      left: BorderSide(color: riskColor, width: 3),
                      top: BorderSide(
                          color: CyberColors.borderSubtle, width: 1),
                      right: BorderSide(
                          color: CyberColors.borderSubtle, width: 1),
                      bottom: BorderSide(
                          color: CyberColors.borderSubtle, width: 1),
                    ),
                  ),
                  child: Text(
                    suspect.profileNotes!,
                    style: CyberText.bodySmall.copyWith(height: 1.7),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // ════════════════════════════════════════════
              //  ACTION BUTTONS — side by side row
              // ════════════════════════════════════════════
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
          engine.accuse(suspect.id);
          GameProgress.recordFlag(correct: suspect.isGuilty);
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CaseOutcomeScreen(suspectId: suspect.id),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FOOTPRINT GRID — 2-column layout replacing the vertical list
// ══════════════════════════════════════════════════════════════

class _FootprintGrid extends StatelessWidget {
  final dynamic footprint; // DigitalFootprint model

  const _FootprintGrid({required this.footprint});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _FootprintEntry(Icons.wifi,               'IP Activity',    footprint.ipActivity),
      _FootprintEntry(Icons.computer,            'Device',         footprint.deviceUsage),
      _FootprintEntry(Icons.location_on_outlined,'Location',       footprint.locationTrace),
      _FootprintEntry(Icons.vpn_lock_outlined,   'VPN Check',      footprint.vpnCheck),
    ];

    return Column(
      children: List.generate(rows.length, (i) {
        final entry = rows[i];
        final isLast = i == rows.length - 1;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tag
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CyberColors.neonCyan.withOpacity(0.08),
                    borderRadius: CyberRadius.small,
                  ),
                  child: Icon(entry.icon, color: CyberColors.neonCyan, size: 16),
                ),
                const SizedBox(width: 10),
                // Key
                SizedBox(
                  width: 74,
                  child: Text(
                    entry.label,
                    style: CyberText.caption.copyWith(fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                // Value (flexible)
                Expanded(
                  child: Text(
                    entry.value,
                    style: CyberText.bodySmall.copyWith(
                        color: CyberColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (!isLast)
              Divider(
                color: CyberColors.borderSubtle,
                height: 18,
                thickness: 1,
              ),
          ],
        );
      }),
    );
  }
}

class _FootprintEntry {
  final IconData icon;
  final String label;
  final String value;
  const _FootprintEntry(this.icon, this.label, this.value);
}

// ══════════════════════════════════════════════════════════════
//  CONFIRM FLAG DIALOG — unchanged from original
// ══════════════════════════════════════════════════════════════

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
            const Icon(
              Icons.flag,
              color: CyberColors.neonRed,
              size: 48,
              shadows: [Shadow(color: CyberColors.neonRed, blurRadius: 16)],
            ),
            const SizedBox(height: 16),
            Text(
              'Flag as Culprit?',
              style: CyberText.sectionTitle
                  .copyWith(color: CyberColors.neonRed, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'You are about to accuse $suspectName.\nThis action will close the case.\n\nAre you confident in your evidence?',
              style: CyberText.bodySmall.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
