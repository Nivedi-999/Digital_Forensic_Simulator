// lib/screens/profile_screen.dart
// ═══════════════════════════════════════════════════════════════
//  REDESIGNED PROFILE SCREEN
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
    return AppShell(
      title: 'Analyst Profile',
      showBack: true,
      currentIndex: 2,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: Column(
            children: [
              // ── Profile Hero ──
              NeonContainer(
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
                            CyberColors.neonCyan.withOpacity(0.2),
                            CyberColors.bgCard,
                          ],
                        ),
                        border: Border.all(
                            color: CyberColors.neonCyan, width: 2.5),
                        boxShadow: CyberShadows.neonCyan(),
                      ),
                      child: const Center(
                        child: Text(
                          'JA',
                          style: TextStyle(
                            fontFamily: 'DotMatrix',
                            fontSize: 36,
                            color: CyberColors.neonCyan,
                            shadows: [
                              Shadow(
                                  color: CyberColors.neonCyan, blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      GameProgress.title.toUpperCase(),
                      style: CyberText.displaySmall.copyWith(
                          letterSpacing: 2, fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    StatusChip(
                      label: 'AGENT ONLINE',
                      color: CyberColors.neonGreen,
                      pulsing: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── XP Progress ──
              NeonContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CyberSectionHeader(
                      title: 'Experience Progress',
                      subtitle: 'Progress to next rank',
                    ),
                    CyberProgressBar(
                      value: GameProgress.rankProgress,
                      height: 14,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(GameProgress.rankProgress * 100).toInt()}% complete',
                          style: CyberText.bodySmall.copyWith(
                              color: CyberColors.neonCyan),
                        ),
                        Text(
                          '${GameProgress.xpToNextRank} XP to ${GameProgress.nextRankName}',
                          style: CyberText.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Stats Grid ──
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: 'Cases Solved',
                      value: '${GameProgress.casesSolved}',
                      icon: Icons.cases_outlined,
                      color: CyberColors.neonBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: 'Accuracy',
                      value: '${GameProgress.accuracy.toStringAsFixed(1)}%',
                      icon: Icons.gps_fixed,
                      color: CyberColors.neonPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MetricTile(
                label: 'Total XP Earned',
                value: '${GameProgress.xp}',
                icon: Icons.stars,
                color: CyberColors.neonCyan,
              ),

              const SizedBox(height: 32),

              // ── Action buttons ──
              SizedBox(
                width: double.infinity,
                child: CyberButton(
                  label: 'Home',
                  icon: Icons.home,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
        ),
      ),
    );
  }
}