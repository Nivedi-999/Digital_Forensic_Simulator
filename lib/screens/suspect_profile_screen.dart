// lib/screens/suspect_profile_screen.dart
// Dossier-style suspect profile — Orbitron/ShareTechMono, no DotMatrix
// Full layout: hero card, suspicion meter, notes, footprint table, sticky buttons

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _barCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeIn    = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _barAnim   = CurvedAnimation(parent: _barCtrl,   curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 450), () { if (mounted) _barCtrl.forward(); });
  }

  @override
  void dispose() { _entryCtrl.dispose(); _barCtrl.dispose(); super.dispose(); }

  IconData _roleIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('engineer') || r.contains('developer') || r.contains('devops')) return Icons.code;
    if (r.contains('finance')  || r.contains('analyst')   || r.contains('account')) return Icons.account_balance_outlined;
    if (r.contains('admin')    || r.contains('manager')   || r.contains('director')) return Icons.manage_accounts_outlined;
    if (r.contains('hr')       || r.contains('human'))   return Icons.people_outline;
    if (r.contains('student')  || r.contains('intern'))  return Icons.school_outlined;
    if (r.contains('security') || r.contains('forensic')) return Icons.security;
    if (r.contains('vendor')   || r.contains('consult'))  return Icons.business_center_outlined;
    if (r.contains('network')  || r.contains('telecom'))  return Icons.router_outlined;
    return Icons.person_outline;
  }

  Color _riskColor(String lvl) {
    switch (lvl.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  String _susLabel(double v) {
    if (v >= 0.7)  return 'CRITICAL';
    if (v >= 0.4)  return 'MODERATE';
    if (v >= 0.15) return 'ELEVATED';
    return 'LOW';
  }

  Color _susColor(double v) {
    if (v >= 0.65) return CyberColors.neonRed;
    if (v >= 0.35) return CyberColors.neonAmber;
    return CyberColors.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    final engine  = CaseEngineProvider.of(context);
    final suspect = engine.caseFile.suspectById(widget.suspectId);
    if (suspect == null) return const SizedBox();

    final sus       = engine.suspicionFor(suspect.id);
    final riskColor = _riskColor(suspect.riskLevel);
    final susColor  = _susColor(sus);
    final fp        = suspect.digitalFootprint;

    return AppShell(
      title: 'Suspect Profile',
      showBack: true,
      showBottomNav: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            child: Column(children: [

              // ── HERO ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: CyberColors.bgCard,
                  border: Border(bottom: BorderSide(color: riskColor.withOpacity(0.2), width: 1)),
                ),
                child: Column(children: [
                  // Avatar with risk badge
                  Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [riskColor.withOpacity(0.18), CyberColors.bgDeep]),
                        border: Border.all(color: riskColor.withOpacity(0.6), width: 2.5),
                        boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/avatars/${suspect.id}.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Stack(alignment: Alignment.center, children: [
                            Icon(_roleIcon(suspect.role), color: riskColor.withOpacity(0.15), size: 52),
                            Text(suspect.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(fontSize: 40, color: riskColor, fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: riskColor, blurRadius: 12)])),
                          ]),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: riskColor, borderRadius: CyberRadius.pill),
                      child: Text(suspect.risk.toUpperCase(), style: GoogleFonts.shareTechMono(
                          color: CyberColors.textOnNeon, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  // Name
                  Text(suspect.name, textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w700, color: riskColor,
                          letterSpacing: 1, shadows: [Shadow(color: riskColor, blurRadius: 10)])),
                  const SizedBox(height: 5),
                  Text(suspect.role, style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(suspect.department, style: CyberText.caption),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: CyberColors.bgMid,
                      borderRadius: CyberRadius.pill,
                      border: Border.all(color: CyberColors.borderSubtle, width: 1),
                    ),
                    child: Text('SUBJECT OF INVESTIGATION',
                        style: GoogleFonts.shareTechMono(
                            color: CyberColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
                  ),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── SUSPICION ──
                  _SecLabel('THREAT ASSESSMENT'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CyberColors.bgCard,
                      borderRadius: CyberRadius.medium,
                      border: Border.all(color: susColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Suspicion Index', style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: susColor.withOpacity(0.12),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(color: susColor.withOpacity(0.4), width: 1),
                          ),
                          child: Text(_susLabel(sus), style: GoogleFonts.shareTechMono(
                              color: susColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _barAnim,
                        builder: (_, __) => ClipRRect(
                          borderRadius: CyberRadius.pill,
                          child: LinearProgressIndicator(
                            value: sus * _barAnim.value,
                            backgroundColor: CyberColors.borderSubtle,
                            valueColor: AlwaysStoppedAnimation(susColor),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('0%', style: CyberText.caption),
                        Text('${(sus * 100).toInt()}% confidence',
                            style: GoogleFonts.shareTechMono(color: susColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('100%', style: CyberText.caption),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 22),

                  // ── NOTES ──
                  if (suspect.profileNotes != null) ...[
                    _SecLabel('INVESTIGATOR NOTES'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CyberColors.bgCard,
                        borderRadius: CyberRadius.medium,
                        border: Border.all(color: CyberColors.borderSubtle, width: 1),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 3,
                          height: 70,
                          decoration: BoxDecoration(
                            color: CyberColors.neonCyan.withOpacity(0.45),
                            borderRadius: CyberRadius.pill,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(suspect.profileNotes!,
                            style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary, height: 1.65))),
                      ]),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // ── FOOTPRINT ──
                  if (fp != null) ...[
                    _SecLabel('DIGITAL FOOTPRINT'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: CyberColors.bgCard,
                        borderRadius: CyberRadius.medium,
                        border: Border.all(color: CyberColors.borderSubtle, width: 1),
                      ),
                      child: Column(children: [
                        _FpRow(icon: Icons.wifi_outlined, label: 'IP ACTIVITY', value: fp.ipActivity, first: true),
                        _FpRow(icon: Icons.computer_outlined, label: 'DEVICE', value: fp.deviceUsage),
                        _FpRow(icon: Icons.location_on_outlined, label: 'LOCATION', value: fp.locationTrace),
                        _FpRow(icon: Icons.vpn_lock_outlined, label: 'VPN CHECK', value: fp.vpnCheck, last: true),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),
                ]),
              ),
            ]),
          ),

          // ── STICKY BUTTONS ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: CyberColors.bgDeep.withOpacity(0.96),
                border: Border(top: BorderSide(color: CyberColors.borderSubtle, width: 1)),
              ),
              child: Row(children: [
                Expanded(child: CyberButton(
                  label: 'Investigate',
                  icon: Icons.arrow_back,
                  isOutlined: true,
                  onTap: () => Navigator.pop(context),
                )),
                const SizedBox(width: 12),
                Expanded(child: CyberButton(
                  label: 'Flag Culprit',
                  icon: Icons.flag_outlined,
                  accentColor: CyberColors.neonRed,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _showFlag(context, engine, suspect);
                  },
                )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showFlag(BuildContext ctx, CaseEngine engine, Suspect suspect) {
    showDialog(context: ctx, builder: (_) => _FlagDialog(
      suspectName: suspect.name,
      onConfirm: () {
        engine.accuse(suspect.id);
        GameProgress.recordFlag(correct: suspect.isGuilty);
        Navigator.pop(ctx);
        Navigator.pushReplacement(ctx, MaterialPageRoute(
          builder: (_) => CaseOutcomeScreen(suspectId: suspect.id),
        ));
      },
    ));
  }
}

// helpers ─────────────────────────────────────────────────────

class _SecLabel extends StatelessWidget {
  final String label;
  const _SecLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 13,
          decoration: BoxDecoration(color: CyberColors.neonCyan, borderRadius: CyberRadius.pill,
              boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.5), blurRadius: 5)])),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.shareTechMono(
          color: CyberColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
    ]);
  }
}

class _FpRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool first, last;
  const _FpRow({required this.icon, required this.label, required this.value,
    this.first = false, this.last = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : BorderSide(color: CyberColors.borderSubtle, width: 1)),
        borderRadius: last ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : first ? const BorderRadius.vertical(top: Radius.circular(10)) : BorderRadius.zero,
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.07), borderRadius: CyberRadius.small),
          child: Icon(icon, color: CyberColors.neonCyan.withOpacity(0.65), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.shareTechMono(
              color: CyberColors.textMuted, fontSize: 9, letterSpacing: 1.2)),
          const SizedBox(height: 2),
          Text(value, style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary, fontSize: 12.5)),
        ])),
      ]),
    );
  }
}

class _FlagDialog extends StatelessWidget {
  final String suspectName;
  final VoidCallback onConfirm;
  const _FlagDialog({required this.suspectName, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: CyberRadius.large,
        side: BorderSide(color: CyberColors.neonRed.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberColors.neonRed.withOpacity(0.1),
              border: Border.all(color: CyberColors.neonRed.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.flag_outlined, color: CyberColors.neonRed, size: 28),
          ),
          const SizedBox(height: 16),
          Text('FLAG AS CULPRIT?', style: GoogleFonts.orbitron(
              color: CyberColors.neonRed, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Accuse $suspectName?\n\nThis closes the case.',
              style: CyberText.bodySmall.copyWith(height: 1.6), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: CyberButton(label: 'Cancel', isOutlined: true, onTap: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: CyberButton(label: 'Confirm', accentColor: CyberColors.neonRed, onTap: onConfirm)),
          ]),
        ]),
      ),
    );
  }
}