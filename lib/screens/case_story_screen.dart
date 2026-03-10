// lib/screens/case_story_screen.dart
// ═══════════════════════════════════════════════════════════════
//  STORYLINE / BRIEFING SCREEN
//  Loads the case from CaseRepository, creates the CaseEngine,
//  and wraps InvestigationHubScreen with CaseEngineProvider.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/case_repository.dart';
import 'investigation_hub_screen.dart';

class StorylineScreen extends StatefulWidget {
  /// Pass a specific case id, or null to load the first available case.
  final String? caseId;

  const StorylineScreen({super.key, this.caseId});

  @override
  State<StorylineScreen> createState() => _StorylineScreenState();
}

class _StorylineScreenState extends State<StorylineScreen>
    with TickerProviderStateMixin {
  int step = 0;
  int visibleChars = 0;
  Timer? _timer;
  bool _loading = false;

  CaseFile? _caseFile;
  bool _caseLoading = true;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  String get currentText {
    if (_caseFile == null) return '';
    return step == 0
        ? _caseFile!.briefing.incidentSummary
        : _caseFile!.briefing.missionText;
  }

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

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
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    visibleChars = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (visibleChars < currentText.length) {
        setState(() => visibleChars++);
      } else {
        timer.cancel();
      }
    });
  }

  void _skipTyping() {
    _timer?.cancel();
    setState(() => visibleChars = currentText.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _launchInvestigation() async {
    if (_caseFile == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final engine = CaseEngine(_caseFile!);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CaseEngineProvider(
          engine: engine,
          child: const InvestigationHubScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
          child: Text('Case not found.',
              style: CyberText.bodyMedium),
        ),
      );
    }

    return AppShell(
      title: '${_caseFile!.title}',
      showBack: true,
      showBottomNav: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIndicator(currentStep: step),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _skipTyping,
                  child: NeonContainer(
                    borderColor: step == 0
                        ? CyberColors.neonCyan
                        : CyberColors.neonPurple,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            step == 0
                                ? Icons.info_outline
                                : Icons.assignment_outlined,
                            color: step == 0
                                ? CyberColors.neonCyan
                                : CyberColors.neonPurple,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            step == 0
                                ? 'INCIDENT BRIEFING'
                                : 'MISSION PARAMETERS',
                            style: TextStyle(
                              fontFamily: 'DotMatrix',
                              fontSize: 12,
                              color: step == 0
                                  ? CyberColors.neonCyan
                                  : CyberColors.neonPurple,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (visibleChars < currentText.length) ...[
                            const Spacer(),
                            Text('TAP TO SKIP',
                                style: CyberText.caption.copyWith(
                                    color: CyberColors.neonCyan
                                        .withOpacity(0.5))),
                          ],
                        ]),

                        const SizedBox(height: 20),

                        Text(
                          currentText.substring(0, visibleChars),
                          style: CyberText.bodyLarge.copyWith(height: 1.7),
                        ),

                        if (visibleChars < currentText.length)
                          const _BlinkingCursorInline(),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (step == 1) ...[
                              CyberButton(
                                label: 'Back',
                                icon: Icons.arrow_back,
                                isOutlined: true,
                                isSmall: true,
                                onTap: () {
                                  setState(() => step = 0);
                                  _startTyping();
                                },
                              ),
                              const SizedBox(width: 12),
                            ],
                            _loading
                                ? Container(
                              padding: const EdgeInsets.all(12),
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: CyberColors.neonCyan,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                                : CyberButton(
                              label: step == 0 ? 'Continue' : 'Begin',
                              icon: step == 0
                                  ? Icons.arrow_forward
                                  : Icons.play_arrow,
                              isSmall: true,
                              onTap: () async {
                                if (visibleChars < currentText.length) {
                                  _skipTyping();
                                  return;
                                }
                                if (step == 0) {
                                  setState(() => step = 1);
                                  _startTyping();
                                } else {
                                  _launchInvestigation();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ──────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Dot(label: '01', isActive: currentStep == 0, title: 'Briefing'),
      Expanded(
        child: Container(
          height: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              CyberColors.neonCyan.withOpacity(0.5),
              CyberColors.neonPurple.withOpacity(0.5),
            ]),
          ),
        ),
      ),
      _Dot(label: '02', isActive: currentStep == 1, title: 'Mission'),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final bool isActive;
  final String title;
  const _Dot(
      {required this.label, required this.isActive, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? CyberColors.neonCyan : CyberColors.textMuted;
    return Column(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? CyberColors.neonCyan.withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
              color: color, width: isActive ? 2 : 1),
          boxShadow:
          isActive ? CyberShadows.neonCyan(intensity: 0.6) : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 4),
      Text(title,
          style: CyberText.caption.copyWith(color: color)),
    ]);
  }
}

class _BlinkingCursorInline extends StatefulWidget {
  const _BlinkingCursorInline();
  @override
  State<_BlinkingCursorInline> createState() =>
      _BlinkingCursorInlineState();
}

class _BlinkingCursorInlineState extends State<_BlinkingCursorInline>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 18,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: CyberColors.neonCyan,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          boxShadow: [
            BoxShadow(
                color: CyberColors.neonCyan.withOpacity(0.6),
                blurRadius: 6)
          ],
        ),
      ),
    );
  }
}