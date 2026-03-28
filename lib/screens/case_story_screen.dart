// lib/screens/case_story_screen.dart
// ═══════════════════════════════════════════════════════════════
//  ANIMATED CASE BRIEFING — DOSSIER DROP
//  Visual briefing with page-turning animations like opening a case file
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/case_repository.dart';
import 'investigation_hub_screen.dart';

class StorylineScreen extends StatefulWidget {
  final String? caseId;
  const StorylineScreen({super.key, this.caseId});

  @override
  State<StorylineScreen> createState() => _StorylineScreenState();
}

class _StorylineScreenState extends State<StorylineScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  List<Widget> _briefingPages = [];
  int _currentPage = 0;
  bool _loading = false;
  CaseFile? _caseFile;
  bool _caseLoading = true;

  // Animation controllers for page transitions
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Animation controllers for page-specific animations
  late AnimationController _pageFlipCtrl;
  late Animation<double> _pageFlipAnim;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    // Page flip animation
    _pageFlipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pageFlipAnim = CurvedAnimation(
      parent: _pageFlipCtrl,
      curve: Curves.easeInOut,
    );

    _loadCase();
  }

  Future<void> _loadCase() async {
    await CaseRepository.instance.loadAll();
    final caseFile = widget.caseId != null
        ? CaseRepository.instance.byId(widget.caseId!)
        : CaseRepository.instance.first;

    if (mounted) {
      setState(() {
        _caseFile = caseFile;
        _caseLoading = false;
      });
      _createBriefingPages();
      // Start page flip animation after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _pageFlipCtrl.forward();
      });
    }
  }

  void _createBriefingPages() {
    if (_caseFile == null) return;

    final briefing = _caseFile!.briefing;
    final suspects = _caseFile!.suspects;
    final evidence = _caseFile!.evidencePanels
        .expand((p) => p.items)
        .toList();

    _briefingPages = [
      // Page 1: Case Header
      _CaseFilePage(
        title: 'CASE FILE: ${_caseFile!.id.toUpperCase()}',
        subtitle: 'CLASSIFIED // EYES ONLY',
        icon: Icons.folder_open,
        color: CyberColors.neonCyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'INCIDENT REPORT',
              style: CyberText.bodySmall.copyWith(
                color: CyberColors.neonCyan,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _caseFile!.title,
              style: CyberText.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CyberColors.neonCyan.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              briefing.incidentSummary,
              style: CyberText.bodyLarge.copyWith(
                height: 1.6,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 32),
            _CaseFileStamp(
              label: 'PRIORITY LEVEL',
              value: '${_caseFile!.difficulty.toUpperCase()}',
              color: CyberColors.neonCyan,
            ),
          ],
        ),
      ),

      // Page 2: Timeline
      _CaseFilePage(
        title: 'TIMELINE ANALYSIS',
        subtitle: 'EVENT CHRONOLOGY',
        icon: Icons.timeline,
        color: CyberColors.neonPurple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _TimelineEvent(
              time: '${_caseFile!.timeline.first.time} - 22:47',
              title: 'INITIAL INCIDENT',
              description: briefing.incidentSummary.split('.')[0] + '.',
              isFirst: true,
            ),
            _TimelineEvent(
              time: '${_caseFile!.timeline.first.time} - 23:15',
              title: 'SECURITY BREACH DETECTED',
              description: 'Unauthorized access to secure systems logged.',
            ),
            _TimelineEvent(
              time: '${_caseFile!.timeline.first.time} - 23:42',
              title: 'DATA EXFILTRATION',
              description: 'Sensitive files transferred to external server.',
            ),
            _TimelineEvent(
              time: '${_caseFile!.timeline.first.time} - 00:05',
              title: 'INVESTIGATION INITIATED',
              description: 'Case assigned to your unit.',
              isLast: true,
            ),
            const SizedBox(height: 32),
            _CaseFileStamp(
              label: 'TIMEFRAME',
              value: '${_caseFile!.estimatedDuration} MIN',
              color: CyberColors.neonPurple,
            ),
          ],
        ),
      ),

      // Page 3: Suspects
      _CaseFilePage(
        title: 'PERSON OF INTEREST',
        subtitle: 'SUSPECT DOSSIER',
        icon: Icons.person_search,
        color: CyberColors.neonRed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (suspects.isNotEmpty) ...[
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CyberColors.neonRed.withOpacity(0.3),
                    width: 1,
                  ),
                  image: DecorationImage(
                    image: AssetImage(suspects.first.imagePath ?? 'assets/avatars/${suspects.first.id}.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.2),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suspects.first.name.toUpperCase(),
                              style: CyberText.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suspects.first.role,
                              style: CyberText.bodySmall.copyWith(
                                color: CyberColors.neonRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Redacted overlay
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          border: Border.all(color: CyberColors.neonRed),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CLASSIFIED',
                          style: CyberText.caption.copyWith(
                            color: CyberColors.neonRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _RedactedText(
                text: suspects.first.description ?? suspects.first.profileNotes ?? 'No description available.',
                lines: 3,
                color: CyberColors.neonRed,
              ),
            ],
            const SizedBox(height: 32),
            _CaseFileStamp(
              label: 'SUSPECTS IDENTIFIED',
              value: '${suspects.length}',
              color: CyberColors.neonRed,
            ),
          ],
        ),
      ),

      // Page 4: Mission Briefing
      _CaseFilePage(
        title: 'MISSION PARAMETERS',
        subtitle: 'OPERATIONAL DIRECTIVES',
        icon: Icons.assignment,
        color: CyberColors.neonGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _MissionObjective(
              icon: Icons.search,
              title: 'PRIMARY OBJECTIVE',
              description: briefing.missionText.split('.')[0] + '.',
            ),
            _MissionObjective(
              icon: Icons.fingerprint,
              title: 'SECONDARY TASKS',
              description: 'Gather digital evidence and trace data pathways.',
            ),
            _MissionObjective(
              icon: Icons.security,
              title: 'SECURITY PROTOCOL',
              description: 'Maintain operational security at all times.',
            ),
            const SizedBox(height: 24),
            _RedactedText(
              text: 'Additional classified directives omitted for security.',
              lines: 2,
              color: CyberColors.neonGreen,
            ),
            const SizedBox(height: 32),
            _CaseFileStamp(
              label: 'CLEARANCE LEVEL',
              value: 'LEVEL ${_caseFile!.difficulty == 'easy' ? '3' : _caseFile!.difficulty == 'medium' ? '5' : '7'}',
              color: CyberColors.neonGreen,
            ),
          ],
        ),
      ),

      // Page 5: Evidence Preview
      if (evidence.isNotEmpty)
        _CaseFilePage(
          title: 'EVIDENCE CATALOG',
          subtitle: 'DIGITAL ARTIFACTS',
          icon: Icons.analytics,
          color: CyberColors.neonAmber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: evidence.length > 4 ? 4 : evidence.length,
                itemBuilder: (context, index) {
                  final item = evidence[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CyberColors.neonAmber.withOpacity(0.3),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getEvidenceIcon(item.label),
                          color: CyberColors.neonAmber,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: CyberText.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          item.label.toUpperCase(),
                          style: CyberText.caption.copyWith(
                            color: CyberColors.neonAmber.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                '${evidence.length} pieces of evidence collected. Analyze each carefully for clues.',
                style: CyberText.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              _CaseFileStamp(
                label: 'EVIDENCE COUNT',
                value: '${evidence.length}',
                color: CyberColors.neonAmber,
              ),
            ],
          ),
        ),
    ];
  }

  IconData _getEvidenceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return Icons.description;
      case 'email':
        return Icons.email;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'log':
        return Icons.analytics;
      default:
        return Icons.find_in_page;
    }
  }

  void _launchInvestigation() async {
    if (_caseFile == null) return;
    setState(() => _loading = true);

    // Play page flip animation before transition
    await _pageFlipCtrl.reverse();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final engine = CaseEngine(_caseFile!);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CaseEngineProvider(
          engine: engine,
          child: const InvestigationHubScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCtrl.dispose();
    _pageFlipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_caseLoading) {
      return AppShell(
        title: 'Loading...',
        showBack: true,
        showBottomNav: false,
        child: const Center(
          child: CircularProgressIndicator(color: CyberColors.neonCyan),
        ),
      );
    }

    if (_caseFile == null) {
      return AppShell(
        title: 'Error',
        showBack: true,
        showBottomNav: false,
        child: Center(
          child: Text(
            'Case not found.',
            style: CyberText.bodyMedium,
          ),
        ),
      );
    }

    return AppShell(
      title: 'CASE BRIEFING',
      showBack: true,
      showBottomNav: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                // Page indicator
                _PageIndicator(
                  currentPage: _currentPage,
                  totalPages: _briefingPages.length,
                ),
                const SizedBox(height: 16),

                // Animated PageView
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pageFlipCtrl,
                    builder: (context, child) {
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_pageFlipAnim.value * 0.05)
                          ..rotateY(_pageFlipAnim.value * 0.02),
                        alignment: Alignment.center,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _briefingPages.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                            // Animate page flip on change
                            _pageFlipCtrl.reset();
                            _pageFlipCtrl.forward();
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: _AnimatedPage(
                                index: index,
                                currentIndex: _currentPage,
                                child: _briefingPages[index],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      CyberButton(
                        label: 'Previous',
                        icon: Icons.arrow_back,
                        isOutlined: true,
                        isSmall: true,
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                      )
                    else
                      const SizedBox(width: 100),

                    _PageCounter(
                      current: _currentPage + 1,
                      total: _briefingPages.length,
                    ),

                    if (_currentPage < _briefingPages.length - 1)
                      CyberButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        isSmall: true,
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                      )
                    else
                      CyberButton(
                        label: _loading ? 'Loading...' : 'Begin',
                        icon: _loading ? null : Icons.play_arrow,
                        isSmall: true,
                        onTap: _launchInvestigation,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page Components ──────────────────────────────────────────

class _CaseFilePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _CaseFilePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DotMatrix',
                        fontSize: 12,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: CyberText.caption.copyWith(
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPage extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Widget child;

  const _AnimatedPage({
    required this.index,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final offset = index - currentIndex;
    final isCurrent = offset == 0;
    final isNext = offset == 1;
    final isPrevious = offset == -1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..translate(
          isCurrent ? 0.0 : isNext ? 20.0 : isPrevious ? -20.0 : 0.0,
          0.0,
        )
        ..scale(isCurrent ? 1.0 : 0.95),
      child: Opacity(
        opacity: isCurrent ? 1.0 : isNext || isPrevious ? 0.7 : 0.4,
        child: child,
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          width: index == currentPage ? 24 : 8,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index == currentPage
                ? CyberColors.neonCyan
                : CyberColors.neonCyan.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
            boxShadow: index == currentPage
                ? CyberShadows.neonCyan(intensity: 0.5)
                : null,
          ),
        );
      }),
    );
  }
}

class _PageCounter extends StatelessWidget {
  final int current;
  final int total;

  const _PageCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2)),
      ),
      child: Text(
        '$current / $total',
        style: CyberText.bodySmall.copyWith(
          color: CyberColors.neonCyan,
          fontFamily: 'DotMatrix',
        ),
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final bool isFirst;
  final bool isLast;

  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 1,
                  height: 20,
                  color: CyberColors.neonPurple.withOpacity(0.5),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CyberColors.neonPurple,
                  boxShadow: CyberShadows.neonPurple(intensity: 0.5),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 20,
                  color: CyberColors.neonPurple.withOpacity(0.5),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Event content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: CyberText.caption.copyWith(
                    color: CyberColors.neonPurple.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: CyberText.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: CyberText.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
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

class _MissionObjective extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _MissionObjective({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CyberColors.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3)),
            ),
            child: Icon(icon, color: CyberColors.neonGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CyberText.bodyMedium.copyWith(
                    color: CyberColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: CyberText.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
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

class _RedactedText extends StatelessWidget {
  final String text;
  final int lines;
  final Color color;

  const _RedactedText({
    required this.text,
    this.lines = 1,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines; i++) ...[
          Container(
            width: double.infinity,
            height: 20,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                for (int j = 0; j < 10; j++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2,
                      color: color.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
        Text(
          '[REDACTED]',
          style: CyberText.caption.copyWith(
            color: color.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _CaseFileStamp extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CaseFileStamp({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CyberText.caption.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: CyberText.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'DotMatrix',
            ),
          ),
        ],
      ),
    );
  }
}
