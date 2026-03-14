// lib/screens/investigation_hub_screen.dart
// ═══════════════════════════════════════════════════════════════
//  INVESTIGATION HUB — data-driven via CaseEngine
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
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
          FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Case Header ──
                  _CaseHeader(caseFile: caseFile),
                  const SizedBox(height: 24),

                  // ── Feed Tabs ──
                  const CyberSectionHeader(
                    title: 'Evidence Feed',
                    subtitle: 'Tap a category to explore',
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

                  // ── Evidence Viewer ──
                  NeonContainer(
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          minHeight: 80, maxHeight: 260),
                      child: SingleChildScrollView(
                        child: _activeFeed == 'suspects'
                            ? _buildSuspectFeed(context, engine)
                            : _buildEvidenceFeed(context, engine),
                      ),
                    ),
                  ),

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

  // ── Evidence feed for the active panel ──────────────────

  Widget _buildEvidenceFeed(BuildContext context, CaseEngine engine) {
    final panel = engine.caseFile.panelById(_activeFeed);
    if (panel == null) return const SizedBox();

    final visibleItems = engine.visibleItemsForPanel(_activeFeed);

    return Column(
      children: List.generate(visibleItems.length, (index) {
        final item = visibleItems[index];
        return LogRow(
          left: item.sender ?? item.label,
          right: item.metadata?.size ?? item.label,
          highlighted: index.isEven, // alternating rows — even=amber, odd=default
          onTap: () => _openAnalysis(context, panel.id, item.id),
        );
      }),
    );
  }

  // ── Suspect feed ─────────────────────────────────────────

  Widget _buildSuspectFeed(BuildContext context, CaseEngine engine) {
    return Column(
      children: engine.suspectsByThreat.map((suspect) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SuspectCard(
            name: suspect.name,
            role: suspect.role,
            riskLevel: suspect.riskLevel,
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
                  style: const TextStyle(
                    fontFamily: 'DotMatrix',
                    fontSize: 13,
                    color: CyberColors.neonCyan,
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
                  style: const TextStyle(
                    fontFamily: 'DotMatrix',
                    fontSize: 15,
                    color: CyberColors.neonCyan,
                    letterSpacing: 0.5,
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