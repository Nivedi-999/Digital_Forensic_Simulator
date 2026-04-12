// lib/screens/suspect_profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  SUSPECT DOSSIER — redesigned to match Mission Select aesthetic
//  Grid background · Hex avatar · Orbitron/ShareTechMono fonts
//  Left-accent section headers · Suspicion bar · Glow borders
//  Risk-colour theming throughout (red/amber/green per suspect)
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
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
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _barAnim;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    _fadeIn  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _barAnim = CurvedAnimation(parent: _barCtrl,   curve: Curves.easeOutCubic);
    _pulse   = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) _barCtrl.forward(); });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _barCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────

  // Colour driven by static riskLevel — kept for fallback use only
  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  // Colour driven by live suspicion — used for all UI theming
  Color _suspicionColor(double v) {
    if (v >= 0.6) return CyberColors.neonRed;
    if (v >= 0.3) return CyberColors.neonAmber;
    return CyberColors.neonGreen;
  }

  // Threat label derived from live suspicion
  String _suspicionThreatLabel(double v) {
    if (v >= 0.6) return 'HIGH';
    if (v >= 0.3) return 'MEDIUM';
    return 'LOW';
  }

  String _suspicionLabel(double v) {
    if (v >= 0.7) return 'CRITICAL';
    if (v >= 0.4) return 'MODERATE';
    return 'LOW';
  }

  IconData _avatarIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('engineer') || r.contains('developer')) return Icons.code;
    if (r.contains('finance') || r.contains('analyst') || r.contains('account'))
      return Icons.account_balance_outlined;
    if (r.contains('admin') || r.contains('manager') || r.contains('director'))
      return Icons.manage_accounts_outlined;
    if (r.contains('hr') || r.contains('human')) return Icons.people_outline;
    if (r.contains('student') || r.contains('intern')) return Icons.school_outlined;
    if (r.contains('security')) return Icons.security;
    if (r.contains('vendor') || r.contains('consultant'))
      return Icons.business_center_outlined;
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context) {
    final engine  = CaseEngineProvider.of(context);
    final suspect = engine.caseFile.suspectById(widget.suspectId);
    if (suspect == null) return const SizedBox();

    final suspicion  = engine.suspicionFor(suspect.id);
    final riskColor  = _suspicionColor(suspicion);
    final footprint  = suspect.digitalFootprint;

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment.center, radius: 1.3,
                  colors: [Colors.transparent, const Color(0xFF040A0F).withOpacity(0.55)],
                  stops: const [0.5, 1.0])))),
          SafeArea(child: Column(children: [
            _SuspectTopBar(
                onBack: () => Navigator.pop(context),
                riskColor: riskColor,
                riskLabel: _suspicionThreatLabel(suspicion)),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── SECTION: SUSPECT DOSSIER ─────────────────
                _SectionLabel(label: 'SUSPECT DOSSIER',
                    icon: Icons.manage_search_outlined, color: riskColor),
                const SizedBox(height: 12),

                // Hero card
                _GlowCard(accentColor: riskColor, child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, children: [

                  // Rect avatar
                  AnimatedBuilder(animation: _pulse, builder: (_, __) =>
                      _RectAvatar(suspect: suspect, pulse: _pulse.value,
                          color: riskColor, avatarIcon: _avatarIcon(suspect.role))),

                  const SizedBox(width: 18),

                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Case number / ID tag
                    _InlineTag('#${engine.caseFile.caseNumber}', riskColor),
                    const SizedBox(height: 6),
                    Text(suspect.name, style: GoogleFonts.orbitron(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: riskColor, letterSpacing: 0.8,
                        shadows: [Shadow(color: riskColor, blurRadius: 8)])),
                    const SizedBox(height: 3),
                    Text(suspect.role, style: GoogleFonts.shareTechMono(
                        fontSize: 10, color: CyberColors.textSecondary)),
                    Text(suspect.department, style: GoogleFonts.shareTechMono(
                        fontSize: 9, color: CyberColors.textMuted)),
                    const SizedBox(height: 10),

                    // Threat + suspicion % inline
                    Row(children: [
                      _InlineTag('THREAT: ${_suspicionThreatLabel(suspicion)}', riskColor),
                      const SizedBox(width: 8),
                      AnimatedBuilder(animation: _barAnim, builder: (_, __) =>
                          Text('${(suspicion * _barAnim.value * 100).toInt()}%',
                              style: GoogleFonts.orbitron(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: riskColor,
                                  shadows: [Shadow(color: riskColor, blurRadius: 6)]))),
                    ]),
                    const SizedBox(height: 10),

                    // Suspicion bar
                    AnimatedBuilder(animation: _barAnim, builder: (_, __) {
                      final v = (suspicion * _barAnim.value).clamp(0.0, 1.0);
                      return Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(children: [
                              Container(height: 6, decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3))),
                              FractionallySizedBox(widthFactor: v, child: Container(
                                  height: 6, decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: riskColor,
                                  boxShadow: [BoxShadow(
                                      color: riskColor.withOpacity(0.5), blurRadius: 6)]))),
                            ]),
                            const SizedBox(height: 5),
                            Text('SUSPICION: ${_suspicionLabel(suspicion)}',
                                style: GoogleFonts.shareTechMono(fontSize: 9,
                                    color: riskColor, letterSpacing: 1)),
                          ]);
                    }),
                  ])),
                ])),

                const SizedBox(height: 24),

                // ── SECTION: DIGITAL FOOTPRINT ───────────────
                if (footprint != null) ...[
                  _SectionLabel(label: 'DIGITAL FOOTPRINT',
                      icon: Icons.wifi_outlined, color: CyberColors.neonCyan),
                  const SizedBox(height: 12),
                  _GlowCard(accentColor: CyberColors.neonCyan, padding: EdgeInsets.zero,
                      child: Column(children: [
                        _FootprintRow(icon: Icons.wifi, label: 'IP ACTIVITY',
                            value: footprint.ipActivity, isLast: false),
                        _FootprintRow(icon: Icons.computer, label: 'DEVICE',
                            value: footprint.deviceUsage, isLast: false),
                        _FootprintRow(icon: Icons.location_on_outlined, label: 'LOCATION',
                            value: footprint.locationTrace, isLast: false),
                        _FootprintRow(icon: Icons.vpn_lock_outlined, label: 'VPN CHECK',
                            value: footprint.vpnCheck, isLast: true),
                      ])),
                  const SizedBox(height: 24),
                ],

                // ── SECTION: ANALYST NOTES ───────────────────
                if (suspect.profileNotes != null) ...[
                  _SectionLabel(label: 'ANALYST NOTES',
                      icon: Icons.notes_outlined, color: CyberColors.neonPurple),
                  const SizedBox(height: 12),
                  _GlowCard(accentColor: CyberColors.neonPurple,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 3, margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                                color: CyberColors.neonPurple,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [BoxShadow(
                                    color: CyberColors.neonPurple.withOpacity(0.6),
                                    blurRadius: 6)])),
                        Expanded(child: Text(suspect.profileNotes!,
                            style: GoogleFonts.shareTechMono(
                                fontSize: 11, color: CyberColors.textPrimary,
                                height: 1.7, letterSpacing: 0.2))),
                      ])),
                  const SizedBox(height: 24),
                ],

                // ── ACTION BUTTONS ────────────────────────────
                Row(children: [
                  Expanded(child: _ActionButton(
                      label: 'GO BACK', icon: Icons.arrow_back_outlined,
                      color: CyberColors.neonCyan, isOutlined: true,
                      onTap: () => Navigator.pop(context))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                      label: 'FLAG CULPRIT', icon: Icons.flag,
                      color: CyberColors.neonRed,
                      onTap: () => _flagAsCulprit(context, engine, suspect))),
                ]),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }

  void _flagAsCulprit(BuildContext ctx, CaseEngine engine, Suspect suspect) {
    showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ConfirmFlagSheet(
            suspectName: suspect.name,
            riskColor: _suspicionColor(engine.suspicionFor(suspect.id)),
            onConfirm: () {
              engine.accuse(suspect.id);
              GameProgress.recordFlag(correct: suspect.isGuilty);
              Navigator.pop(ctx);
              Navigator.pushReplacement(ctx, MaterialPageRoute(
                  builder: (_) => CaseOutcomeScreen(suspectId: suspect.id)));
            }));
  }
}

// ─────────────────────────────────────────────────────────────
//  FOOTPRINT ROW
// ─────────────────────────────────────────────────────────────

class _FootprintRow extends StatelessWidget {
  final IconData icon; final String label, value; final bool isLast;
  const _FootprintRow({required this.icon, required this.label,
    required this.value, required this.isLast});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(
                  color: CyberColors.neonCyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: CyberColors.neonCyan, size: 15)),
          const SizedBox(width: 10),
          SizedBox(width: 78, child: Text(label, style: GoogleFonts.shareTechMono(
              fontSize: 8, color: CyberColors.textMuted, letterSpacing: 1))),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: GoogleFonts.shareTechMono(
              fontSize: 10, color: CyberColors.textPrimary, height: 1.4))),
        ])),
    if (!isLast) Divider(
        color: CyberColors.neonCyan.withOpacity(0.08), height: 1, indent: 14, endIndent: 14),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────

class _SuspectTopBar extends StatelessWidget {
  final VoidCallback onBack; final Color riskColor; final String riskLabel;
  const _SuspectTopBar({required this.onBack, required this.riskColor,
    required this.riskLabel});
  @override
  Widget build(BuildContext context) => Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(
          color: riskColor.withOpacity(0.15), width: 1))),
      child: Row(children: [
        GestureDetector(onTap: onBack, child: Container(width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
                border: Border.all(color: riskColor.withOpacity(0.35))),
            child: Icon(Icons.arrow_back_ios_new, color: riskColor, size: 16))),
        const SizedBox(width: 14),
        Text('SUSPECT FILE', style: GoogleFonts.orbitron(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: riskColor, letterSpacing: 2)),
        const Spacer(),
        _InlineTag(riskLabel, riskColor),
      ]));
}

// ─────────────────────────────────────────────────────────────
//  RECT AVATAR — loads image asset, falls back to icon+initial
//
//  To resize: change avatarWidth and avatarHeight below.
//  To change corner rounding: change borderRadius below.
//  To change border thickness: change borderWidth below.
// ─────────────────────────────────────────────────────────────

class _RectAvatar extends StatelessWidget {
  final Suspect suspect;
  final double pulse;
  final Color color;
  final IconData avatarIcon;

  const _RectAvatar({
    required this.suspect,
    required this.pulse,
    required this.color,
    required this.avatarIcon,
  });

  // ── SIZE CONTROLS ─────────────────────────────────────────
  static const double avatarWidth  = 100.0; // ← change width here
  static const double avatarHeight = 120.0; // ← change height here
  static const double borderRadius = 10.0;  // ← change corner rounding here
  static const double borderWidth  = 1.5;   // ← change border thickness here
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  avatarWidth,
      height: avatarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Transparent border that subtly glows with the suspect's risk colour
        border: Border.all(
          color: color.withOpacity(0.0), // fully transparent — change to e.g. 0.4 to make it visible
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15 + pulse * 0.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: suspect.imagePath != null
            ? Image.asset(
          suspect.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: color.withOpacity(0.08),
    child: Stack(alignment: Alignment.center, children: [
      Icon(avatarIcon, color: color.withOpacity(0.18), size: 38),
      Text(
        suspect.name.substring(0, 1).toUpperCase(),
        style: GoogleFonts.orbitron(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: color,
          shadows: [Shadow(color: color, blurRadius: 10)],
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  const _SectionLabel({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.22), width: 1)),
      child: Row(children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 5)])),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.orbitron(fontSize: 10,
            fontWeight: FontWeight.w700, color: color, letterSpacing: 2)),
        const Spacer(),
        Text('ZONE', style: GoogleFonts.shareTechMono(
            fontSize: 9, color: color.withOpacity(0.45), letterSpacing: 2)),
      ]));
}

class _GlowCard extends StatelessWidget {
  final Widget child; final Color accentColor; final EdgeInsets padding;
  const _GlowCard({required this.child, required this.accentColor,
    this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: const Color(0xFF060D14), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 16)]),
      child: child);
}

class _ActionButton extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  final VoidCallback onTap; final bool isOutlined;
  const _ActionButton({required this.label, required this.icon,
    required this.color, required this.onTap, this.isOutlined = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(height: 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isOutlined ? null : LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [color.withOpacity(0.22), color.withOpacity(0.10)]),
              border: Border.all(color: color.withOpacity(0.55), width: 1.5),
              boxShadow: isOutlined ? null
                  : [BoxShadow(color: color.withOpacity(0.12), blurRadius: 14)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.orbitron(fontSize: 10,
                fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
          ])));
}

class _InlineTag extends StatelessWidget {
  final String text; final Color color;
  const _InlineTag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.35))),
      child: Text(text, style: GoogleFonts.shareTechMono(
          fontSize: 8, color: color, letterSpacing: 1)));
}

// ─────────────────────────────────────────────────────────────
//  CONFIRM FLAG BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _ConfirmFlagSheet extends StatelessWidget {
  final String suspectName;
  final Color riskColor;
  final VoidCallback onConfirm;
  const _ConfirmFlagSheet({required this.suspectName,
    required this.riskColor, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: const Color(0xFF060D14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: CyberColors.neonRed.withOpacity(0.35))),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: CyberColors.neonRed.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          // Icon
          Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: CyberColors.neonRed.withOpacity(0.1),
                  border: Border.all(color: CyberColors.neonRed.withOpacity(0.5), width: 1.5)),
              child: const Icon(Icons.flag, color: CyberColors.neonRed, size: 28,
                  shadows: [Shadow(color: CyberColors.neonRed, blurRadius: 12)])),
          const SizedBox(height: 14),
          Text('CONFIRM ACCUSATION', style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: CyberColors.neonRed, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _InlineTag('IRREVERSIBLE ACTION', CyberColors.neonRed),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: CyberColors.neonRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CyberColors.neonRed.withOpacity(0.15))),
              child: Text('You are about to flag $suspectName as the culprit.\n'
                  'This will close the case permanently.\n\n'
                  'Are you confident in your evidence chain?',
                  style: GoogleFonts.shareTechMono(
                      fontSize: 10, color: CyberColors.textSecondary,
                      height: 1.65),
                  textAlign: TextAlign.center)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.close, color: CyberColors.neonCyan, size: 16),
                      const SizedBox(width: 8),
                      Text('ABORT', style: GoogleFonts.orbitron(fontSize: 11,
                          fontWeight: FontWeight.w700, color: CyberColors.neonCyan,
                          letterSpacing: 1.2)),
                    ])))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
                onTap: onConfirm,
                child: Container(height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                            begin: Alignment.centerLeft, end: Alignment.centerRight,
                            colors: [CyberColors.neonRed.withOpacity(0.3),
                              CyberColors.neonRed.withOpacity(0.15)]),
                        border: Border.all(color: CyberColors.neonRed.withOpacity(0.6),
                            width: 1.5),
                        boxShadow: [BoxShadow(
                            color: CyberColors.neonRed.withOpacity(0.15),
                            blurRadius: 14)]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.flag, color: CyberColors.neonRed, size: 16),
                      const SizedBox(width: 8),
                      Text('CONFIRM', style: GoogleFonts.orbitron(fontSize: 11,
                          fontWeight: FontWeight.w800, color: CyberColors.neonRed,
                          letterSpacing: 1.2)),
                    ])))),
          ]),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = CyberColors.neonCyan.withOpacity(0.035)..strokeWidth = 0.5;
    const s = 30.0;
    for (double x = 0; x < size.width;  x += s) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += s) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_GridPainter _) => false;
}