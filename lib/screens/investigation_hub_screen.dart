// lib/screens/investigation_hub_screen.dart
// ═══════════════════════════════════════════════════════════════
//  INVESTIGATION HUB — data-driven via CaseEngine
//  v2: live case timer displayed in AppShell title area
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/case_timer.dart';
import 'evidence_analysis_screen.dart';
import 'suspect_profile_screen.dart';
import '../widgets/crime_board.dart';

class InvestigationHubScreen extends StatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  State<InvestigationHubScreen> createState() => _InvestigationHubScreenState();
}

class _InvestigationHubScreenState extends State<InvestigationHubScreen>
    with TickerProviderStateMixin {
  String _activeFeed = 'chat';
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;

  // ── Timer ──────────────────────────────────────────────────
  late final CaseTimer _caseTimer;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Start timing immediately when investigation opens
    _caseTimer = CaseTimer();
    _caseTimer.start();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    // Do NOT call _caseTimer.dispose() here — the timer is passed to the
    // outcome screen via CaseEngineProvider so it can read the final time.
    // The outcome screen is responsible for stopping it.
    super.dispose();
  }

  void _openAnalysis(BuildContext context, String panelId, String itemId) {
    Navigator.push(
      context,
      _slideRoute(EvidenceAnalysisScreen(panelId: panelId, itemId: itemId)),
    );
  }

  PageRouteBuilder _slideRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final caseFile = engine.caseFile;
    final unlockedPanels = caseFile.evidencePanels
        .where((panel) => engine.isPanelUnlocked(panel.id))
        .toList();

    // Attach timer to engine so the outcome screen can read it
    engine.attachTimer(_caseTimer);

    String effectiveFeed = _activeFeed;
    final activePanel = caseFile.panelById(effectiveFeed);
    final activeLocked =
        effectiveFeed != 'suspects' &&
        (activePanel == null || !engine.isPanelUnlocked(effectiveFeed));
    if (activeLocked) {
      effectiveFeed = unlockedPanels.isNotEmpty
          ? unlockedPanels.first.id
          : (caseFile.evidencePanels.isNotEmpty
                ? caseFile.evidencePanels.first.id
                : 'suspects');
      if (effectiveFeed != _activeFeed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _activeFeed = effectiveFeed);
          }
        });
      }
    }

    return AppShell(
      title: 'Investigation Hub', // Back to a simple String
      showBack: true,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _VerticalScanLine()),
          ),

          // ── NEW: Manually position the timer at the top ──
          Positioned(top: 10, right: 20, child: _TimerBadge(timer: _caseTimer)),

          FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              // Increased top padding (from 12 to 60) to make room for the timer
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CaseHeader(caseFile: caseFile),
                  const SizedBox(height: 14),
                  _EvidenceProgressBar(engine: engine),
                  // ... rest of your Column code stays exactly the same
                  const SizedBox(height: 24),
                  const CyberSectionHeader(
                    title: 'Crime Board',
                    subtitle: 'Tap a card to analyse evidence',
                  ),
                  _FeedTabBar(
                    panels: caseFile.evidencePanels,
                    activeFeed: effectiveFeed,
                    onTabChanged: (key) => setState(() => _activeFeed = key),
                    isPanelUnlocked: engine.isPanelUnlocked,
                    showSuspects: true,
                  ),
                  const SizedBox(height: 14),

                  effectiveFeed == 'suspects'
                      ? NeonContainer(
                          padding: const EdgeInsets.all(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 80,
                              maxHeight: 300,
                            ),
                            child: SingleChildScrollView(
                              child: _buildSuspectFeed(context, engine),
                            ),
                          ),
                        )
                      : (() {
                          final panel = engine.caseFile.panelById(
                            effectiveFeed,
                          );
                          if (panel == null) return const SizedBox();
                          if (!engine.isPanelUnlocked(panel.id)) {
                            return NeonContainer(
                              padding: const EdgeInsets.all(16),
                              borderColor: CyberColors.neonAmber,
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: CyberColors.neonAmber,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'This panel unlocks after completing the linked mini-game.',
                                      style: TextStyle(
                                        color: CyberColors.neonAmber,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return CrimeBoard(
                            panel: panel,
                            engine: engine,
                            onItemTap: (panelId, itemId) =>
                                _openAnalysis(context, panelId, itemId),
                          );
                        })(),

                  const SizedBox(height: 28),

                  const CyberSectionHeader(
                    title: 'Event Timeline',
                    subtitle: 'Chronological breach activity',
                  ),
                  NeonContainer(
                    borderColor: CyberColors.neonPurple,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Column(
                      children: caseFile.timeline.asMap().entries.map((entry) {
                        final i = entry.key;
                        final event = entry.value;
                        return TimelineItem(
                          time: event.time,
                          title: event.title,
                          description: event.description,
                          isLast: i == caseFile.timeline.length - 1,
                          accentColor: _severityColor(event.severity),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspectFeed(BuildContext context, CaseEngine engine) {
    final suspectsByThreat = engine.suspectsByThreat;

    return Column(
      children: suspectsByThreat.map((suspect) {
        final isUnlocked = engine.isSuspectUnlocked(suspect.id);

        if (!isUnlocked) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CyberColors.borderSubtle.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CyberColors.textMuted.withOpacity(0.06),
                      border: Border.all(
                        color: CyberColors.textMuted.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: CyberColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUSPECT IDENTITY LOCKED',
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: CyberColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete a mini-game to reveal this suspect.',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 9,
                            color: CyberColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: CyberColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SuspectCard(
            suspectId: suspect.id,
            name: suspect.name,
            role: suspect.role,
            riskLevel: suspect.riskLevel,
            suspicionValue: engine.normalizedSuspicionFor(suspect.id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuspectProfileScreen(suspectId: suspect.id),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return CyberColors.neonRed;
      case 'high':
        return CyberColors.neonAmber;
      case 'medium':
        return CyberColors.neonPurple;
      default:
        return CyberColors.neonCyan;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  TIMER BADGE — live MM:SS counter shown in the AppBar
// ─────────────────────────────────────────────────────────────

class _TimerBadge extends StatefulWidget {
  final CaseTimer timer;
  const _TimerBadge({required this.timer});

  @override
  State<_TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<_TimerBadge> {
  late String _display;

  @override
  void initState() {
    super.initState();
    _display = widget.timer.formattedTime;
    widget.timer.secondStream.listen((_) {
      if (mounted) setState(() => _display = widget.timer.formattedTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CyberColors.neonAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CyberColors.neonAmber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: CyberColors.neonAmber, size: 12),
          const SizedBox(width: 5),
          Text(
            _display,
            style: GoogleFonts.shareTechMono(
              fontSize: 12,
              color: CyberColors.neonAmber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  The rest of the file is unchanged from v1
// ─────────────────────────────────────────────────────────────

class _CaseHeader extends StatelessWidget {
  final CaseFile caseFile;
  const _CaseHeader({required this.caseFile});

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      borderColor: CyberColors.neonCyan,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CyberColors.neonCyan.withOpacity(0.1),
              borderRadius: CyberRadius.small,
              border: Border.all(
                color: CyberColors.neonCyan.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${caseFile.caseNumber}',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    color: CyberColors.neonCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseFile.title,
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    color: CyberColors.neonCyan,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(caseFile.shortDescription, style: CyberText.bodySmall),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                  label: caseFile.status,
                  color: CyberColors.neonGreen,
                  pulsing: true,
                ),
                const SizedBox(height: 6),
                Text(
                  caseFile.estimatedDuration,
                  style: CyberText.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTabBar extends StatelessWidget {
  final List<EvidencePanel> panels;
  final String activeFeed;
  final ValueChanged<String> onTabChanged;
  final bool Function(String panelId) isPanelUnlocked;
  final bool showSuspects;

  const _FeedTabBar({
    required this.panels,
    required this.activeFeed,
    required this.onTabChanged,
    required this.isPanelUnlocked,
    this.showSuspects = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...panels.map((panel) {
            final unlocked = isPanelUnlocked(panel.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeedTabButton(
                label: panel.label,
                isActive: activeFeed == panel.id,
                isLocked: !unlocked,
                onTap: unlocked ? () => onTabChanged(panel.id) : null,
              ),
            );
          }),
          if (showSuspects)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FeedTabButton(
                label: 'Suspects',
                isActive: activeFeed == 'suspects',
                onTap: () => onTabChanged('suspects'),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerticalScanLine extends StatefulWidget {
  const _VerticalScanLine();
  @override
  State<_VerticalScanLine> createState() => _VerticalScanLineState();
}

class _VerticalScanLineState extends State<_VerticalScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) =>
          CustomPaint(painter: _ScanLinePainter(progress: _anim.value)),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  const _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          CyberColors.neonCyan.withOpacity(0.12),
          CyberColors.neonCyan.withOpacity(0.18),
          CyberColors.neonCyan.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(x - 1, 0, 2, size.height))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          CyberColors.neonCyan.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x - 12, 0, 24, size.height));
    canvas.drawRect(Rect.fromLTWH(x - 12, 0, 24, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _EvidenceProgressBar extends StatelessWidget {
  final CaseEngine engine;
  const _EvidenceProgressBar({required this.engine});

  @override
  Widget build(BuildContext context) {
    final collected = engine.collectedEvidence.length;
    final needed = engine.caseFile.winCondition.minCorrectEvidence;
    final correct = engine.correctEvidenceCount;
    final total = engine.caseFile.correctEvidenceIds.length;
    final double fraction = total == 0
        ? 0.0
        : (correct / needed).clamp(0.0, 1.0);
    final bool canAccuse = engine.canAccuse;
    final barColor = canAccuse ? CyberColors.neonGreen : CyberColors.neonCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.medium,
        border: Border.all(
          color: canAccuse
              ? CyberColors.neonGreen.withOpacity(0.3)
              : CyberColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canAccuse ? Icons.verified_outlined : Icons.folder_outlined,
                color: barColor,
                size: 13,
              ),
              const SizedBox(width: 7),
              Text(
                canAccuse ? 'READY TO ACCUSE' : 'EVIDENCE CHAIN',
                style: GoogleFonts.shareTechMono(
                  color: barColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$correct',
                      style: GoogleFonts.orbitron(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' / $needed correct',
                      style: GoogleFonts.shareTechMono(
                        color: CyberColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (collected > correct)
                      TextSpan(
                        text: '  ($collected collected)',
                        style: GoogleFonts.shareTechMono(
                          color: CyberColors.textMuted.withOpacity(0.6),
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: CyberRadius.pill,
            child: Stack(
              children: [
                Container(height: 6, color: CyberColors.borderSubtle),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: canAccuse
                            ? [CyberColors.neonGreen, CyberColors.neonGreen]
                            : [
                                CyberColors.neonCyan.withOpacity(0.5),
                                CyberColors.neonCyan,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                ...List.generate(needed, (i) {
                  final pos = (i + 1) / needed;
                  return Positioned(
                    left: null,
                    right: null,
                    child: FractionallySizedBox(
                      widthFactor: pos,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 1.5,
                        height: 6,
                        color: CyberColors.bgDeep.withOpacity(0.5),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
