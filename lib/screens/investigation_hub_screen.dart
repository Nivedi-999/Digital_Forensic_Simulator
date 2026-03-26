// lib/screens/investigation_hub_screen.dart
// ═══════════════════════════════════════════════════════════════
//  INVESTIGATION HUB — data-driven via CaseEngine
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
import '../services/tutorial_service.dart';
import '../widgets/aria_guide.dart';
import '../widgets/aria_controller.dart';
import 'evidence_analysis_screen.dart';
import 'suspect_profile_screen.dart';
import '../widgets/crime_board.dart';

class InvestigationHubScreen extends StatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  State<InvestigationHubScreen> createState() => _InvestigationHubScreenState();
}

class _InvestigationHubScreenState extends State<InvestigationHubScreen>
    with AriaMixin, TickerProviderStateMixin {
  String _activeFeed = 'chat';
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    TutorialService().onHubOpened();
    triggerAria(TutorialStep.welcomeToHub);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onAriaWelcomeDismissed() {
    final service = TutorialService();
    service.advance(TutorialStep.exploreFeeds);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) triggerAria(TutorialStep.exploreFeeds, delayMs: 0);
    });
  }

  void _openAnalysis(BuildContext context, String panelId, String itemId) {
    TutorialService().onFeedTapped();
    Navigator.push(
      context,
      _slideRoute(EvidenceAnalysisScreen(
        panelId: panelId,
        itemId: itemId,
      )),
    ).then((_) {
      final engine = CaseEngineProvider.read(context);
      final service = TutorialService();
      final count = engine.collectedEvidence.length;
      service.onReadyForDecryption();
      service.onReadyToFlag(count);
      setState(() {});
      if (service.currentStep == TutorialStep.markEvidence &&
          !service.messageShown) {
        triggerAria(TutorialStep.markEvidence, delayMs: 300);
      } else if (service.currentStep == TutorialStep.decryptionHint &&
          !service.messageShown) {
        triggerAria(TutorialStep.decryptionHint, delayMs: 300);
      } else if (service.currentStep == TutorialStep.flagSuspect &&
          !service.messageShown) {
        triggerAria(TutorialStep.flagSuspect, delayMs: 300);
      }
    });
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

    return AppShell(
      title: 'Investigation Hub',
      showBack: true,
      child: Stack(
        children: [
          // ── Vertical scan line in background ──
          const Positioned.fill(
            child: IgnorePointer(child: _VerticalScanLine()),
          ),

          FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Case Header ──
                  _CaseHeader(caseFile: caseFile),
                  const SizedBox(height: 14),

                  // ── Evidence Progress Bar ──
                  _EvidenceProgressBar(engine: engine),
                  const SizedBox(height: 24),

                  // ── Feed Tabs ──
                  const CyberSectionHeader(
                    title: 'Crime Board',
                    subtitle: 'Tap a card to analyse evidence',
                  ),
                  _FeedTabBar(
                    panels: caseFile.evidencePanels,
                    activeFeed: _activeFeed,
                    onTabChanged: (key) {
                      setState(() => _activeFeed = key);
                      if (key != 'suspects') TutorialService().onFeedTapped();
                    },
                    showSuspects: true,
                  ),
                  const SizedBox(height: 14),

                  // ── Evidence Viewer — Crime Board or Suspect Feed ──
                  _activeFeed == 'suspects'
                      ? NeonContainer(
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          minHeight: 80, maxHeight: 300),
                      child: SingleChildScrollView(
                        child: _buildSuspectFeed(context, engine),
                      ),
                    ),
                  )
                      : (() {
                    final panel = engine.caseFile.panelById(_activeFeed);
                    if (panel == null) return const SizedBox();
                    return CrimeBoard(
                      panel: panel,
                      engine: engine,
                      onItemTap: (panelId, itemId) =>
                          _openAnalysis(context, panelId, itemId),
                    );
                  })(),

                  const SizedBox(height: 28),

                  // ── Timeline ──
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

          // ── ARIA Guide ──
          buildAriaLayer(
            onDismiss: () {
              if (ariaStep == TutorialStep.welcomeToHub) {
                _onAriaWelcomeDismissed();
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Suspect feed ─────────────────────────────────────────

  Widget _buildSuspectFeed(BuildContext context, CaseEngine engine) {
    return Column(
      children: engine.suspectsByThreat.map((suspect) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SuspectCard(
            suspectId: suspect.id,
            name: suspect.name,
            role: suspect.role,
            riskLevel: suspect.riskLevel,
            suspicionValue: engine.suspicionFor(suspect.id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuspectProfileScreen(
                    suspectId: suspect.id,
                  ),
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

// ── Case Header ─────────────────────────────────────────────

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
                  color: CyberColors.neonCyan.withOpacity(0.4), width: 1.5),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: caseFile.status,
                color: CyberColors.neonGreen,
                pulsing: true,
              ),
              const SizedBox(height: 6),
              Text(caseFile.estimatedDuration, style: CyberText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feed Tab Bar ─────────────────────────────────────────────

class _FeedTabBar extends StatelessWidget {
  final List<EvidencePanel> panels;
  final String activeFeed;
  final ValueChanged<String> onTabChanged;
  final bool showSuspects;

  const _FeedTabBar({
    required this.panels,
    required this.activeFeed,
    required this.onTabChanged,
    this.showSuspects = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Evidence panel tabs — driven by the case JSON
          ...panels.map((panel) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FeedTabButton(
              label: panel.label,
              isActive: activeFeed == panel.id,
              onTap: () => onTabChanged(panel.id),
            ),
          )),
          // Suspects tab is always present
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
// ─────────────────────────────────────────────────────────────
//  VERTICAL SCAN LINE — animated moving line across the screen
// ─────────────────────────────────────────────────────────────

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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _ScanLinePainter(progress: _anim.value),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  const _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;

    // Main line
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

    // Glow band
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

// ── Evidence Progress Bar ────────────────────────────────────

class _EvidenceProgressBar extends StatelessWidget {
  final CaseEngine engine;
  const _EvidenceProgressBar({required this.engine});

  @override
  Widget build(BuildContext context) {
    final collected = engine.collectedEvidence.length;
    final needed    = engine.caseFile.winCondition.minCorrectEvidence;
    final correct   = engine.correctEvidenceCount;
    final total     = engine.caseFile.correctEvidenceIds.length;

    // Progress fraction toward win condition
    final double fraction = total == 0 ? 0.0 : (correct / needed).clamp(0.0, 1.0);
    final bool canAccuse  = engine.canAccuse;

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Label row
        Row(children: [
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
          RichText(text: TextSpan(children: [
            TextSpan(
              text: '$correct',
              style: GoogleFonts.orbitron(
                color: barColor, fontSize: 12, fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' / $needed correct',
              style: GoogleFonts.shareTechMono(
                color: CyberColors.textMuted, fontSize: 10,
              ),
            ),
            if (collected > correct) TextSpan(
              text: '  ($collected collected)',
              style: GoogleFonts.shareTechMono(
                color: CyberColors.textMuted.withOpacity(0.6), fontSize: 9,
              ),
            ),
          ])),
        ]),

        const SizedBox(height: 8),

        // Bar
        ClipRRect(
          borderRadius: CyberRadius.pill,
          child: Stack(children: [
            // Background track
            Container(
              height: 6,
              color: CyberColors.borderSubtle,
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canAccuse
                        ? [CyberColors.neonGreen, CyberColors.neonGreen]
                        : [CyberColors.neonCyan.withOpacity(0.5), CyberColors.neonCyan],
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
            // Milestone tick marks
            ...List.generate(needed, (i) {
              final pos = (i + 1) / needed;
              return Positioned(
                left: null,
                right: null,
                child: FractionallySizedBox(
                  widthFactor: pos,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1.5, height: 6,
                    color: CyberColors.bgDeep.withOpacity(0.5),
                  ),
                ),
              );
            }),
          ]),
        ),
      ]),
    );
  }
}