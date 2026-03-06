// lib/screens/suspect_profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  REDESIGNED SUSPECT PROFILE
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../case_data/ghosttrace_case_data.dart' hide GameProgress;
import 'case_outcome_screen.dart';
import '../services/game_progress.dart';

/// Suspect profile screen.'

class SuspectProfileScreen extends StatefulWidget {
  final Suspect suspect;

  const SuspectProfileScreen({
    super.key,
    required this.suspect,
  });

  @override
  State<SuspectProfileScreen> createState() => _SuspectProfileScreenState();
}

class _SuspectProfileScreenState extends State<SuspectProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _barCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _barAnim;

  Color get _riskColor {
    switch (widget.suspect.riskLevel.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  double get _suspicionValue {
    switch (widget.suspect.riskLevel.toLowerCase()) {
      case 'high':   return 0.85;
      case 'medium': return 0.55;
      default:       return 0.25;
    }
  }

  String get _suspicionText {
    switch (widget.suspect.riskLevel.toLowerCase()) {
      case 'high':   return 'Critical';
      case 'medium': return 'Moderate';
      default:       return 'Low';
    }
  }

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
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);

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

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor;
    final name = widget.suspect.name;

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
                      // Avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              riskColor.withOpacity(0.2),
                              CyberColors.bgCard,
                            ],
                          ),
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
                            name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 42,
                              color: riskColor,
                              fontFamily: 'DotMatrix',
                              shadows: [
                                Shadow(color: riskColor, blurRadius: 12),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'DotMatrix',
                          fontSize: 26,
                          color: riskColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Finance Department • Mumbai HQ',
                        style: CyberText.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      StatusChip(
                        label: 'THREAT: ${widget.suspect.risk.toUpperCase()}',
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
                        value: _suspicionValue * _barAnim.value,
                        color: riskColor,
                        height: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: $_suspicionText',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(_suspicionValue * 100).toInt()}% threat score',
                          style: CyberText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Digital Footprint ──
              const CyberSectionHeader(
                title: 'Digital Footprint',
                subtitle: 'Network & device activity trace',
              ),
              NeonContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _FootprintRow(
                      icon: Icons.wifi,
                      label: 'IP Activity',
                      value: '202.56.23.101 — 10:45 AM',
                    ),
                    _FootprintRow(
                      icon: Icons.computer,
                      label: 'Device Usage',
                      value: 'FIN-WS-114 — 09:15–10:50 AM',
                    ),
                    _FootprintRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location Trace',
                      value: 'Mumbai Office WiFi',
                    ),
                    _FootprintRow(
                      icon: Icons.vpn_lock_outlined,
                      label: 'VPN Check',
                      value: 'No foreign VPN detected',
                      isLast: true,
                    ),
                  ],
                ),
              ),

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
                      onTap: () => _flagAsCulprit(context),
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

  void _flagAsCulprit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmFlagDialog(
        suspectName: widget.suspect.name,
        onConfirm: () {
          GameProgress.recordFlag(correct: widget.suspect.name == 'Ankita E');
          Navigator.pop(context); // close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CaseOutcomeScreen(
                flaggedSuspectName: widget.suspect.name,
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
        Row(
          children: [
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
                  Text(label, style: CyberText.caption.copyWith(fontSize: 11)),
                  const SizedBox(height: 1),
                  Text(value,
                      style: CyberText.bodySmall.copyWith(
                          color: CyberColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
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
        side: BorderSide(color: CyberColors.neonRed.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag,
              color: CyberColors.neonRed,
              size: 48,
              shadows: const [Shadow(color: CyberColors.neonRed, blurRadius: 16)],
            ),
            const SizedBox(height: 16),
            Text(
              'Flag as Culprit?',
              style: CyberText.sectionTitle.copyWith(
                color: CyberColors.neonRed,
                fontSize: 20,
              ),
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