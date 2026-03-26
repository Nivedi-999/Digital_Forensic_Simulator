// lib/screens/profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  PROFILE SCREEN
//  Fonts: Orbitron for headings/titles, Inter for body/labels
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../services/game_progress.dart';
import 'case_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _barAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials    = GameProgress.avatarInitials;
    final titleText   = GameProgress.title;
    final rankProgress = GameProgress.rankProgress;
    final xp          = GameProgress.xp;
    final casesSolved = GameProgress.casesSolved;
    final nextRank    = GameProgress.nextRankName;
    final xpToNext    = GameProgress.xpToNextRank;

    return AppShell(
      title: 'Analyst Profile',
      showBack: true,
      currentIndex: 3,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(children: [

            // ── HERO CARD ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: CyberColors.bgCard,
                borderRadius: CyberRadius.large,
                border: Border.all(
                    color: CyberColors.neonCyan.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: CyberColors.neonCyan.withOpacity(0.05),
                    blurRadius: 24, spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(children: [
                // Avatar circle
                Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        CyberColors.neonCyan.withOpacity(0.18),
                        CyberColors.bgDeep,
                      ]),
                      border: Border.all(color: CyberColors.neonCyan, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: CyberColors.neonCyan.withOpacity(0.3),
                            blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: Center(
                      child: Text(initials,
                        style: GoogleFonts.orbitron(
                          fontSize: 34, fontWeight: FontWeight.w700,
                          color: CyberColors.neonCyan,
                          shadows: [Shadow(color: CyberColors.neonCyan, blurRadius: 14)],
                        ),
                      ),
                    ),
                  ),
                  // Online dot
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CyberColors.neonGreen,
                      border: Border.all(color: CyberColors.bgCard, width: 2),
                      boxShadow: [BoxShadow(
                          color: CyberColors.neonGreen.withOpacity(0.7), blurRadius: 6)],
                    ),
                  ),
                ]),

                const SizedBox(height: 18),

                // Rank title
                Text(titleText.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: CyberColors.neonCyan,
                    letterSpacing: 2,
                    shadows: [Shadow(color: CyberColors.neonCyan.withOpacity(0.4), blurRadius: 10)],
                  ),
                ),

                const SizedBox(height: 6),

                Text('Cyber Investigator Unit',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: CyberColors.textMuted, letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 14),

                const StatusChip(
                  label: 'AGENT ONLINE',
                  color: CyberColors.neonGreen,
                  pulsing: true,
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── XP PROGRESS ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CyberColors.bgCard,
                borderRadius: CyberRadius.medium,
                border: Border.all(color: CyberColors.borderSubtle, width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  Container(
                    width: 3, height: 16,
                    decoration: BoxDecoration(
                      color: CyberColors.neonCyan,
                      borderRadius: CyberRadius.pill,
                      boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.5), blurRadius: 5)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('RANK PROGRESS',
                    style: GoogleFonts.orbitron(
                      color: CyberColors.neonCyan, fontSize: 12,
                      fontWeight: FontWeight.w600, letterSpacing: 1.2,
                    ),
                  ),
                ]),

                const SizedBox(height: 14),

                // XP numbers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: '$xp ',
                          style: GoogleFonts.orbitron(
                            color: CyberColors.neonCyan, fontSize: 28,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: CyberColors.neonCyan.withOpacity(0.4), blurRadius: 8)],
                          )),
                      TextSpan(text: 'XP',
                          style: GoogleFonts.inter(
                            color: CyberColors.textSecondary, fontSize: 14,
                          )),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('NEXT RANK', style: GoogleFonts.inter(
                          color: CyberColors.textMuted, fontSize: 10, letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(nextRank, style: GoogleFonts.orbitron(
                        color: CyberColors.neonPurple, fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                    ]),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                AnimatedBuilder(
                  animation: _barAnim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: CyberRadius.pill,
                    child: LinearProgressIndicator(
                      value: rankProgress * _barAnim.value,
                      backgroundColor: CyberColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation(CyberColors.neonCyan),
                      minHeight: 8,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(rankProgress * 100).toInt()}% complete',
                      style: GoogleFonts.inter(
                          color: CyberColors.neonCyan, fontSize: 12)),
                  Text('$xpToNext XP to $nextRank',
                      style: GoogleFonts.inter(
                          color: CyberColors.textMuted, fontSize: 11)),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // ── STATS ROW ──────────────────────────────────
            Row(children: [
              Expanded(child: _StatCard(
                label: 'Cases Solved',
                value: '$casesSolved',
                icon: Icons.cases_outlined,
                color: CyberColors.neonBlue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Total XP Earned',
                value: '$xp',
                icon: Icons.stars_outlined,
                color: CyberColors.neonCyan,
              )),
            ]),

            const SizedBox(height: 32),

            // ── ACTION BUTTONS ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                label: 'Browse Cases',
                icon: Icons.folder_outlined,
                outlined: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CaseListScreen())),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                label: 'Log Out',
                icon: Icons.logout_outlined,
                color: CyberColors.neonRed,
                outlined: true,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged out',
                        style: GoogleFonts.inter(color: CyberColors.textPrimary)),
                    backgroundColor: CyberColors.bgCardLight,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.medium,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: CyberRadius.small,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value,
          style: GoogleFonts.orbitron(
            color: color, fontSize: 24, fontWeight: FontWeight.w700,
            shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
          style: GoogleFonts.inter(
            color: CyberColors.textMuted, fontSize: 11, letterSpacing: 0.3,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ACTION BUTTON
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon,
    this.color = CyberColors.neonCyan,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.12),
          borderRadius: CyberRadius.medium,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label,
            style: GoogleFonts.inter(
              color: color, fontSize: 14,
              fontWeight: FontWeight.w600, letterSpacing: 0.3,
            ),
          ),
        ]),
      ),
    );
  }
}