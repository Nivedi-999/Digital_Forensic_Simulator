// lib/screens/profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  PROFILE SCREEN — redesigned layout, same colour theme
//  Layout changes:
//    • Horizontal banner hero (avatar left, rank + status right)
//    • Inline XP bar inside the hero banner
//    • Stats in a 2×2 symmetric grid with dividers
//    • Action buttons at bottom in a compact row
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials        = GameProgress.avatarInitials;
    final titleText       = GameProgress.title;
    final rankProgress    = GameProgress.rankProgress;

    return AppShell(
      title: 'Analyst Profile',
      showBack: true,
      currentIndex: 3,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ══════════════════════════════════════════════
              //  HERO BANNER — horizontal: avatar | rank info
              // ══════════════════════════════════════════════
              NeonContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Avatar circle ──
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            CyberColors.neonCyan.withOpacity(0.22),
                            CyberColors.bgCard,
                          ],
                        ),
                        border: Border.all(
                            color: CyberColors.neonCyan, width: 2.5),
                        boxShadow: CyberShadows.neonCyan(),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/avatars/agent_default.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 30,
                                color: CyberColors.neonCyan,
                                shadows: [
                                  Shadow(
                                      color: CyberColors.neonCyan,
                                      blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // ── Rank + XP column ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText.toUpperCase(),
                            style: CyberText.displaySmall.copyWith(
                                letterSpacing: 2, fontSize: 17),
                          ),
                          const SizedBox(height: 6),
                          const StatusChip(
                            label: 'AGENT ONLINE',
                            color: CyberColors.neonGreen,
                            pulsing: true,
                          ),
                          const SizedBox(height: 14),
                          // XP bar inline
                          CyberProgressBar(
                            value: rankProgress,
                            height: 10,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(rankProgress * 100).toInt()}%',
                                style: CyberText.bodySmall.copyWith(
                                    color: CyberColors.neonCyan,
                                    fontSize: 11),
                              ),
                              Text(
                                '${GameProgress.xpToNextRank} XP → ${GameProgress.nextRankName}',
                                style: CyberText.caption
                                    .copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ══════════════════════════════════════════════
              //  STATS — 2 × 2 grid with inner dividers
              // ══════════════════════════════════════════════
              const CyberSectionHeader(
                title: 'Operative Stats',
                subtitle: 'Live performance metrics',
              ),
              const SizedBox(height: 10),
              NeonContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Row 1
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCell(
                              label: 'Cases Solved',
                              value: '${GameProgress.casesSolved}',
                              icon: Icons.cases_outlined,
                              color: CyberColors.neonBlue,
                            ),
                          ),
                          VerticalDivider(
                            color: CyberColors.borderSubtle,
                            width: 1,
                            thickness: 1,
                          ),
                          Expanded(
                            child: _StatCell(
                              label: 'Accuracy',
                              value:
                              '${GameProgress.accuracy.toStringAsFixed(1)}%',
                              icon: Icons.gps_fixed,
                              color: CyberColors.neonPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: CyberColors.borderSubtle,
                        height: 1,
                        thickness: 1),
                    // Row 2
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCell(
                              label: 'Total XP',
                              value: '${GameProgress.xp}',
                              icon: Icons.stars,
                              color: CyberColors.neonCyan,
                            ),
                          ),
                          VerticalDivider(
                            color: CyberColors.borderSubtle,
                            width: 1,
                            thickness: 1,
                          ),
                          Expanded(
                            child: _StatCell(
                              label: 'Next Rank',
                              value: GameProgress.nextRankName,
                              icon: Icons.military_tech_outlined,
                              color: CyberColors.neonAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ══════════════════════════════════════════════
              //  ACTION ROW — two equal buttons side by side
              // ══════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: CyberButton(
                      label: 'Cases',
                      icon: Icons.folder_outlined,
                      isOutlined: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaseListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberButton(
                      label: 'Log Out',
                      icon: Icons.logout,
                      accentColor: CyberColors.neonRed,
                      isOutlined: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAT CELL — used inside the 2×2 grid
// ══════════════════════════════════════════════════════════════

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: CyberText.caption.copyWith(
                  color: CyberColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DotMatrix',
              fontSize: 22,
              color: color,
              shadows: [Shadow(color: color, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}
