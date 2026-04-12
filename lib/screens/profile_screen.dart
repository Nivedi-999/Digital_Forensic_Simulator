import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/game_progress.dart';
import '../theme/cyber_theme.dart';
import 'case_list_screen.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulse = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankProgress = GameProgress.rankProgress.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ScreenGridPainter())),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.25,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF040A0F).withOpacity(0.58),
                    ],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _ProfileTopBar(onBack: () => Navigator.pop(context)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AgentIdPanel(pulse: _pulse, rankProgress: rankProgress),
                          const SizedBox(height: 16),
                          const _SectionLabel(
                            title: 'PERFORMANCE MATRIX',
                            subtitle: 'Mission analytics stream',
                          ),
                          const SizedBox(height: 8),
                          _StatsGrid(),
                          const SizedBox(height: 16),
                          _ActionRow(
                            onOpenCases: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CaseListScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CyberColors.neonCyan.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: CyberColors.neonCyan,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AGENT PROFILE',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CyberColors.neonCyan,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          const _MiniSignal(color: CyberColors.neonGreen, label: 'ONLINE'),
          const SizedBox(width: 10),
          const _MiniSignal(color: CyberColors.neonBlue, label: 'SYNCED'),
        ],
      ),
    );
  }
}

class _AgentIdPanel extends StatelessWidget {
  final Animation<double> pulse;
  final double rankProgress;

  const _AgentIdPanel({required this.pulse, required this.rankProgress});

  @override
  Widget build(BuildContext context) {
    final user      = FirebaseAuth.instance.currentUser;
    final codename  = (user?.displayName ?? '').isNotEmpty
        ? user!.displayName!.toUpperCase()
        : 'UNKNOWN AGENT';
    final email     = user?.email ?? '—';
    final initials  = codename.isNotEmpty ? codename[0] : '?';

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: CyberColors.neonCyan.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CyberColors.neonCyan.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: CyberColors.neonCyan.withOpacity(0.12 * pulse.value),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [

              // ── Top row: photo + identity ──────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Avatar photo
                    Container(
                      width: 88,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CyberColors.neonCyan.withOpacity(0.35),
                          width: 1.5,
                        ),
                        color: const Color(0xFF08131E),
                        boxShadow: [
                          BoxShadow(
                            color: CyberColors.neonCyan.withOpacity(0.18 * pulse.value),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          'assets/avatars/agent_default.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.orbitron(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: CyberColors.neonCyan,
                                shadows: [Shadow(
                                  color: CyberColors.neonCyan.withOpacity(0.9),
                                  blurRadius: 12,
                                )],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Identity block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CyberColors.neonGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: CyberColors.neonGreen.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'RANK  ${GameProgress.title.toUpperCase()}',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 9,
                                color: CyberColors.neonGreen,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Codename
                          Text(
                            codename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CyberColors.neonCyan,
                              letterSpacing: 1.2,
                              shadows: [Shadow(
                                color: CyberColors.neonCyan.withOpacity(0.6),
                                blurRadius: 10,
                              )],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Email
                          Row(children: [
                            Icon(Icons.alternate_email,
                                size: 10,
                                color: CyberColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 9,
                                  color: CyberColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // XP + cases inline
                          Row(children: [
                            _StatPill(
                              icon: Icons.bolt,
                              label: '${GameProgress.xp} XP',
                              color: CyberColors.neonCyan,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              icon: Icons.task_alt,
                              label: '${GameProgress.casesSolved} CASES',
                              color: CyberColors.neonPurple,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Rank progress bar (full width strip) ───────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RANK PROGRESS',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 8,
                            color: CyberColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '${(rankProgress * 100).toInt()}%  →  ${GameProgress.nextRankName.toUpperCase()}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 8,
                            color: CyberColors.neonGreen.withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bar
                    Stack(children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: CyberColors.neonGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: rankProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: CyberColors.neonGreen,
                            boxShadow: [BoxShadow(
                              color: CyberColors.neonGreen.withOpacity(0.5),
                              blurRadius: 6,
                            )],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(
                      '${GameProgress.xpToNextRank} XP REMAINING TO NEXT RANK',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 8,
                        color: CyberColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

// Small pill badge used inside the agent panel
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.shareTechMono(
          fontSize: 9,
          color: color,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _stats = const [
    _StatData('CASES SOLVED',  Icons.task_alt,                  CyberColors.neonBlue),
    _StatData('ACCURACY',      Icons.gps_fixed,                 CyberColors.neonPurple),
    _StatData('TOTAL XP',      Icons.bolt,                      CyberColors.neonCyan),
    _StatData('FLAGS CORRECT', Icons.flag_outlined,             CyberColors.neonAmber),
  ];

  _StatsGrid();

  String _valueFor(String label) {
    switch (label) {
      case 'CASES SOLVED':  return '${GameProgress.casesSolved}';
      case 'ACCURACY':      return '${GameProgress.accuracy.toStringAsFixed(1)}%';
      case 'TOTAL XP':      return '${GameProgress.xp}';
      case 'FLAGS CORRECT': return '${GameProgress.correctFlags}/${GameProgress.totalFlags}';
      default:              return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: _stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) {
        final stat = _stats[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stat.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: stat.color.withOpacity(0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(stat.icon, color: stat.color, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stat.label,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9,
                        color: stat.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _valueFor(stat.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'DotMatrix',
                  fontSize: 20,
                  color: stat.color,
                  shadows: [Shadow(color: stat.color.withOpacity(0.9), blurRadius: 8)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onOpenCases;
  const _ActionRow({required this.onOpenCases});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FrameButton(
            icon: Icons.grid_view_rounded,
            label: 'MISSION MAP',
            color: CyberColors.neonCyan,
            onTap: onOpenCases,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FrameButton(
            icon: Icons.logout,
            label: 'LOG OUT',
            color: CyberColors.neonRed,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              GameProgress.resetAll();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SignupScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                    (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FrameButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FrameButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
            color: color.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: CyberColors.neonPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CyberColors.neonPurple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: CyberColors.neonPurple,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: CyberColors.neonPurple.withOpacity(0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: CyberColors.neonPurple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 9,
                    color: CyberColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSignal extends StatelessWidget {
  final Color color;
  final String label;

  const _MiniSignal({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 8,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.icon, this.color);
}

class _ScreenGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CyberColors.neonCyan.withOpacity(0.06);

    const gap = 28.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}