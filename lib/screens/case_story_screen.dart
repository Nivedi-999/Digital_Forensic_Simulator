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
import '../models/suspect.dart';
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

  // ── FIX: total pages is a constant, not derived from a stale list ──
  static const int _totalPages = 4;

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
      // Start page flip animation after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _pageFlipCtrl.forward();
      });
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

  // ── FIX: Build each page inline inside itemBuilder so they always
  //         receive the live _currentPage value, not a stale captured one. ──
  Widget _buildPage(int index) {
    final caseFile = _caseFile!;
    final briefing = caseFile.briefing;
    final suspects = caseFile.suspects;

    switch (index) {
    // ── Page 1: Case Header ──────────────────────────────────
      case 0:
        return _CaseFilePage(
          title: 'CASE FILE: ${caseFile.id.toUpperCase()}',
          subtitle: 'CLASSIFIED // EYES ONLY',
          icon: Icons.folder_open,
          color: CyberColors.neonCyan,
          showNavigation: true,
          currentPage: _currentPage, // live value
          totalPages: _totalPages,
          onPrevious: null, // first page — no previous
          onNext: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Visual Header with Icons
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: CyberColors.neonCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CyberColors.neonCyan.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: CyberColors.neonCyan,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INCIDENT REPORT',
                          style: CyberText.bodySmall.copyWith(
                            color: CyberColors.neonCyan,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          caseFile.title,
                          style: CyberText.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _VisualInfoCard(
                      icon: Icons.calendar_today,
                      title: 'DATE',
                      value: caseFile.caseNumber,
                      color: CyberColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisualInfoCard(
                      icon: Icons.schedule,
                      title: 'TIME ESTIMATE',
                      value: '${caseFile.estimatedDuration} min',
                      color: CyberColors.neonCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _VisualInfoCard(
                      icon: Icons.bar_chart,
                      title: 'DIFFICULTY',
                      value: caseFile.difficulty.toUpperCase(),
                      color: CyberColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisualInfoCard(
                      icon: Icons.attach_money,
                      title: 'REWARD',
                      value: 'CLASSIFIED',
                      color: CyberColors.neonCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Incident Summary
              Text(
                'SUMMARY',
                style: CyberText.bodySmall.copyWith(
                  color: CyberColors.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                briefing.incidentSummary,
                style: CyberText.bodyLarge.copyWith(
                  height: 1.6,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );

    // ── Page 2: Timeline ─────────────────────────────────────
      case 1:
      // FIX: Use actual timeline entries from the case model.
      // Fall back gracefully if the timeline has fewer than 4 items.
        final tl = caseFile.timeline;
        final timelineEntries = [
          _TimelineEntryData(
            time: tl.length > 0 ? tl[0].time : '22:31',
            title: tl.length > 0 ? tl[0].title : 'INITIAL INCIDENT',
            description: tl.length > 0
                ? tl[0].description
                : briefing.incidentSummary.split('.').first + '.',
            isFirst: true,
          ),
          _TimelineEntryData(
            time: tl.length > 1 ? tl[1].time : '23:15',
            title: tl.length > 1 ? tl[1].title : 'SECURITY BREACH DETECTED',
            description: tl.length > 1
                ? tl[1].description
                : 'Unauthorized access to secure systems logged.',
          ),
          _TimelineEntryData(
            time: tl.length > 2 ? tl[2].time : '23:42',
            title: tl.length > 2 ? tl[2].title : 'DATA EXFILTRATION',
            description: tl.length > 2
                ? tl[2].description
                : 'Sensitive files transferred to external server.',
          ),
          _TimelineEntryData(
            time: tl.length > 3 ? tl[3].time : '00:05',
            title: tl.length > 3 ? tl[3].title : 'INVESTIGATION INITIATED',
            description: tl.length > 3
                ? tl[3].description
                : 'Case assigned to your unit.',
            isLast: true,
          ),
        ];

        return _CaseFilePage(
          title: 'TIMELINE ANALYSIS',
          subtitle: 'EVENT CHRONOLOGY',
          icon: Icons.timeline,
          color: CyberColors.neonPurple,
          showNavigation: true,
          currentPage: _currentPage,
          totalPages: _totalPages,
          onPrevious: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          onNext: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              ...timelineEntries.map((e) => _TimelineEvent(
                time: e.time,
                title: e.title,
                description: e.description,
                isFirst: e.isFirst,
                isLast: e.isLast,
              )),
            ],
          ),
        );

    // ── Page 3: Suspects ─────────────────────────────────────
      case 2:
        return _CaseFilePage(
          title: 'PERSONS OF INTEREST',
          subtitle: 'SUSPECT DOSSIERS',
          icon: Icons.people,
          color: CyberColors.neonRed,
          showNavigation: true,
          currentPage: _currentPage,
          totalPages: _totalPages,
          onPrevious: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          onNext: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                '${suspects.length} SUSPECTS IDENTIFIED',
                style: CyberText.caption.copyWith(
                  color: CyberColors.neonRed.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: suspects.length,
                itemBuilder: (context, index) {
                  return _SuspectCard(suspect: suspects[index], index: index);
                },
              ),
            ],
          ),
        );

    // ── Page 4: Evidence Catalog ─────────────────────────────
      case 3:
      default:
        return _CaseFilePage(
          title: 'EVIDENCE CATALOG',
          subtitle: 'DIGITAL ARTIFACTS',
          icon: Icons.analytics,
          color: CyberColors.neonAmber,
          showNavigation: true,
          currentPage: _currentPage,
          totalPages: _totalPages,
          onPrevious: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          onNext: null, // Last page — no next, shows Begin Investigation button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                '4 KEY EVIDENCE TYPES TO ANALYZE',
                style: CyberText.caption.copyWith(
                  color: CyberColors.neonAmber.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              // FIX: Use a fixed-height layout instead of GridView with
              // tight childAspectRatio that caused pixel overflow on last card.
              // Two rows of two cards with explicit height.
              _EvidenceGrid(),
              const SizedBox(height: 24),
              Text(
                'Analyze each evidence type carefully for clues and connections.',
                style: CyberText.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
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
                  totalPages: _totalPages,
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
                          itemCount: _totalPages,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
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
                                // FIX: Build page here so it always reads
                                // the current _currentPage from setState.
                                child: _buildPage(index),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom button — only on last page
                if (_currentPage == _totalPages - 1)
                  CyberButton(
                    label: _loading ? 'Loading...' : 'Begin Investigation',
                    icon: _loading ? null : Icons.play_arrow,
                    isSmall: false,
                    onTap: _launchInvestigation,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small data class for timeline entries ─────────────────────
class _TimelineEntryData {
  final String time;
  final String title;
  final String description;
  final bool isFirst;
  final bool isLast;
  const _TimelineEntryData({
    required this.time,
    required this.title,
    required this.description,
    this.isFirst = false,
    this.isLast = false,
  });
}

// ── Page Components ──────────────────────────────────────────

class _CaseFilePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final bool showNavigation;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _CaseFilePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.showNavigation = false,
    this.currentPage = 0,
    this.totalPages = 1,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with page counter
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

              // FIX: Page counter now always shows the correct page number
              // because currentPage is passed as a live value from _buildPage.
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  '${currentPage + 1}/$totalPages',
                  style: CyberText.caption.copyWith(
                    color: color,
                    fontFamily: 'DotMatrix',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),

          // Navigation buttons
          if (showNavigation) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // FIX: Show Previous on any page > 0 (page 1 has null onPrevious,
                // so the button never renders there). No stale guard needed.
                if (onPrevious != null)
                  _NavigationButton(
                    label: 'PREVIOUS',
                    icon: Icons.arrow_back,
                    color: color,
                    onTap: onPrevious!,
                  )
                else
                  const SizedBox(width: 100),

                if (onNext != null)
                  _NavigationButton(
                    label: 'NEXT',
                    icon: Icons.arrow_forward,
                    color: color,
                    onTap: onNext!,
                  )
                else
                  const SizedBox(width: 100),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Scrollable content
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

class _NavigationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBack = icon == Icons.arrow_back;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: Icon and spacing placed correctly for both directions.
            if (isBack) ...[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: CyberText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isBack) ...[
              const SizedBox(width: 6),
              Icon(icon, color: color, size: 16),
            ],
          ],
        ),
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

class _VisualInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _VisualInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: CyberText.caption.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CyberText.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

class _SuspectCard extends StatelessWidget {
  final Suspect suspect;
  final int index;

  const _SuspectCard({
    required this.suspect,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberColors.neonRed.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suspect Image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: AssetImage(
                    suspect.imagePath ?? 'assets/avatars/${suspect.id}.png',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Suspect number badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: CyberColors.neonRed,
                        shape: BoxShape.circle,
                        boxShadow: CyberShadows.danger(intensity: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: CyberText.caption.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Suspect Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suspect.name.toUpperCase(),
                  style: CyberText.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  suspect.role,
                  style: CyberText.caption.copyWith(
                    color: CyberColors.neonRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suspect.description ?? 'No description available',
                  style: CyberText.caption.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  maxLines: 2,
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

// FIX: Replace the overflowing GridView with an explicit two-row layout.
// Each card is a fixed square (icon container is now also square 48×48),
// preventing the RenderFlex pixel overflow on the last evidence card.
class _EvidenceGrid extends StatelessWidget {
  static const _types = [
    {'icon': Icons.chat, 'title': 'CHATS', 'color': CyberColors.neonCyan},
    {
      'icon': Icons.description,
      'title': 'FILES',
      'color': CyberColors.neonPurple
    },
    {
      'icon': Icons.location_on,
      'title': 'IP TRACES',
      'color': CyberColors.neonRed
    },
    {
      'icon': Icons.info,
      'title': 'METADATA',
      'color': CyberColors.neonAmber
    },
  ];

  const _EvidenceGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _EvidenceCard(index: 0)),
              const SizedBox(width: 16),
              Expanded(child: _EvidenceCard(index: 1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _EvidenceCard(index: 2)),
              const SizedBox(width: 16),
              Expanded(child: _EvidenceCard(index: 3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final int index;

  const _EvidenceCard({required this.index});

  static const _evidenceTypes = [
    {'icon': Icons.chat, 'title': 'CHATS', 'color': CyberColors.neonCyan},
    {
      'icon': Icons.description,
      'title': 'FILES',
      'color': CyberColors.neonPurple
    },
    {
      'icon': Icons.location_on,
      'title': 'IP TRACES',
      'color': CyberColors.neonRed
    },
    {
      'icon': Icons.info,
      'title': 'METADATA',
      'color': CyberColors.neonAmber
    },
  ];

  @override
  Widget build(BuildContext context) {
    final type = _evidenceTypes[index % _evidenceTypes.length];
    final color = type['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX: Icon container is now square (48×48) to avoid overflow.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
            ),
            child: Icon(type['icon'] as IconData, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            type['title'] as String,
            style: CyberText.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}