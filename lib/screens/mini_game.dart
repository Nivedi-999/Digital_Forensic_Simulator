// lib/screens/mini_game.dart
// ═══════════════════════════════════════════════════════════════
//  DECRYPTION MINI GAME — reads puzzle from CaseEngine / JSON
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/tutorial_service.dart';
import '../widgets/aria_controller.dart';

class DecryptionMiniGameScreen extends StatefulWidget {
  /// The panel that owns this mini-game (e.g. 'files').
  final String panelId;

  const DecryptionMiniGameScreen({super.key, required this.panelId});

  @override
  State<DecryptionMiniGameScreen> createState() =>
      _DecryptionMiniGameScreenState();
}

class _DecryptionMiniGameScreenState
    extends State<DecryptionMiniGameScreen>
    with AriaMixin, TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _feedback = '';
  int _hintsUsed = 0;
  bool _success = false;

  late AnimationController _entryCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _successScale;
  late Animation<double> _successGlow;

  // Resolved from the case JSON in initState / first build
  MinigameConfig? _minigame;

  @override
  void initState() {
    super.initState();
    triggerAria(TutorialStep.decryptionHint);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _entryCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _checkAnswer(CaseEngine engine) {
    if (_minigame == null) return;
    final input = _controller.text.trim().toLowerCase();
    final solution = (_minigame!.solution ?? '').toLowerCase();

    if (input == solution) {
      setState(() {
        _success = true;
        _feedback = '';
      });
      // Notify the engine — this unlocks the hidden evidence item
      engine.solveMinigame(_minigame!.id);
      _successCtrl.forward();
    } else {
      setState(() => _feedback = 'Incorrect decryption. Try again.');
    }
  }

  void _showHint() {
    if (_minigame == null) return;
    if (_hintsUsed < _minigame!.hints.length) {
      setState(() {
        _feedback = _minigame!.hints[_hintsUsed];
        _hintsUsed++;
      });
    } else {
      setState(() => _feedback = 'No more hints available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final panel = engine.caseFile.panelById(widget.panelId);
    _minigame ??= panel?.minigame;

    if (_minigame == null) {
      return AppShell(
        title: 'Hidden Clue',
        showBack: true,
        child: Center(
          child: Text('No mini-game found for this panel.',
              style: CyberText.bodySmall),
        ),
      );
    }

    final mg = _minigame!;
    final maxHints = mg.hints.length;
    final alreadySolved = engine.isMinigameSolved(mg.id);
    if (alreadySolved && !_success) {
      // Reflect existing solved state without animation re-trigger
      _success = true;
    }

    return AppShell(
      title: 'Hidden Clue',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Encrypted String Panel ──
                  const CyberSectionHeader(
                    title: 'Encrypted String',
                    subtitle: 'Decode to reveal the hidden filename',
                  ),
                  NeonContainer(
                    borderColor: CyberColors.neonPurple,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CyberColors.neonPurple.withOpacity(0.12),
                              borderRadius: CyberRadius.small,
                              border: Border.all(
                                color: CyberColors.neonPurple.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: CyberColors.neonPurple, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            mg.cipherText ?? '',
                            style: TextStyle(
                              fontFamily: 'DotMatrix',
                              fontSize: 26,
                              color: CyberColors.neonPurple,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                    color: CyberColors.neonPurple,
                                    blurRadius: 12)
                              ],
                            ),
                          ),
                        ]),
                        if (mg.hint != null) ...[
                          const SizedBox(height: 16),
                          Divider(color: CyberColors.borderSubtle, thickness: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.info_outline,
                                color: CyberColors.neonAmber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mg.hint!,
                                style: CyberText.bodySmall
                                    .copyWith(color: CyberColors.neonAmber),
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Input ──
                  const CyberSectionHeader(title: 'Decryption Input'),
                  NeonContainer(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      TextField(
                        controller: _controller,
                        enabled: !_success,
                        style: const TextStyle(
                          color: CyberColors.textPrimary,
                          fontSize: 16,
                          fontFamily: 'DotMatrix',
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter your decryption',
                          labelStyle: CyberText.bodySmall,
                          prefixIcon: const Icon(Icons.terminal,
                              color: CyberColors.neonCyan, size: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: CyberRadius.medium,
                            borderSide: BorderSide(
                                color: CyberColors.neonCyan.withOpacity(0.4),
                                width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: CyberRadius.medium,
                            borderSide: const BorderSide(
                                color: CyberColors.neonCyan, width: 1.5),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: CyberRadius.medium,
                            borderSide: BorderSide(
                                color: CyberColors.neonGreen.withOpacity(0.4),
                                width: 1.5),
                          ),
                          filled: true,
                          fillColor: CyberColors.bgMid,
                        ),
                        onSubmitted: (_) {
                          if (!_success) _checkAnswer(engine);
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(children: [
                        Expanded(
                          child: CyberButton(
                            label: 'Hint (${maxHints - _hintsUsed})',
                            icon: Icons.lightbulb_outline,
                            accentColor: CyberColors.neonAmber,
                            isOutlined: true,
                            isSmall: true,
                            onTap: _hintsUsed < maxHints && !_success
                                ? _showHint
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CyberButton(
                            label: _success ? 'Solved!' : 'Decrypt',
                            icon: _success
                                ? Icons.check_circle_outline
                                : Icons.lock_open_outlined,
                            accentColor: _success
                                ? CyberColors.neonGreen
                                : CyberColors.neonCyan,
                            isSmall: true,
                            onTap: _success ? null : () => _checkAnswer(engine),
                          ),
                        ),
                      ]),
                    ]),
                  ),

                  // ── Feedback ──
                  if (_feedback.isNotEmpty && !_success) ...[
                    const SizedBox(height: 16),
                    _FeedbackBanner(
                      message: _feedback,
                      isHint: _hintsUsed > 0 &&
                          mg.hints.contains(_feedback),
                    ),
                  ],

                  if (_hintsUsed > 0) ...[
                    const SizedBox(height: 16),
                    _HintProgress(used: _hintsUsed, total: maxHints),
                  ],

                  // ── Success ──
                  if (_success) ...[
                    const SizedBox(height: 28),
                    _SuccessPanel(
                      scaleAnim: _successScale,
                      glowAnim: _successGlow,
                      unlockedFilename:
                      mg.unlocksHiddenItemId ?? 'credentials.pdf',
                      successMessage: mg.successMessage ??
                          'Return to the Evidence Hub to access this file.',
                    ),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),

          buildAriaLayer(),
        ],
      ),
    );
  }
}

// ── Feedback Banner ───────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isHint;
  const _FeedbackBanner({required this.message, required this.isHint});

  @override
  Widget build(BuildContext context) {
    final color = isHint ? CyberColors.neonAmber : CyberColors.neonRed;
    final icon = isHint ? Icons.lightbulb_outline : Icons.error_outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: CyberRadius.medium,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13, height: 1.5))),
      ]),
    );
  }
}

// ── Hint Progress ─────────────────────────────────────────────

class _HintProgress extends StatelessWidget {
  final int used;
  final int total;
  const _HintProgress({required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('Hints used: ', style: CyberText.caption),
      ...List.generate(total, (i) {
        final active = i < used;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? CyberColors.neonAmber
                  : CyberColors.borderSubtle,
              boxShadow: active
                  ? [
                BoxShadow(
                    color: CyberColors.neonAmber.withOpacity(0.5),
                    blurRadius: 6)
              ]
                  : null,
            ),
          ),
        );
      }),
      const Spacer(),
      if (used >= total)
        Text('No hints remaining',
            style: CyberText.caption
                .copyWith(color: CyberColors.neonRed.withOpacity(0.7))),
    ]);
  }
}

// ── Success Panel ─────────────────────────────────────────────

class _SuccessPanel extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> glowAnim;
  final String unlockedFilename;
  final String successMessage;

  const _SuccessPanel({
    required this.scaleAnim,
    required this.glowAnim,
    required this.unlockedFilename,
    required this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (_, __) => Transform.scale(
        scale: scaleAnim.value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CyberColors.neonGreen.withOpacity(0.08),
                CyberColors.bgCard,
              ],
            ),
            borderRadius: CyberRadius.large,
            border: Border.all(
                color: CyberColors.neonGreen.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: CyberColors.neonGreen
                    .withOpacity(0.25 * glowAnim.value),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  CyberColors.neonGreen.withOpacity(0.2),
                  Colors.transparent,
                ]),
                border: Border.all(color: CyberColors.neonGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: CyberColors.neonGreen.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.lock_open,
                  color: CyberColors.neonGreen, size: 34),
            ),
            const SizedBox(height: 18),
            const StatusChip(
              label: 'DECRYPTION SUCCESSFUL',
              color: CyberColors.neonGreen,
              pulsing: true,
            ),
            const SizedBox(height: 14),
            Text(
              'Clue Unlocked',
              style: TextStyle(
                fontFamily: 'DotMatrix',
                fontSize: 22,
                color: CyberColors.neonGreen,
                letterSpacing: 1,
                shadows: const [
                  Shadow(color: CyberColors.neonGreen, blurRadius: 12)
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CyberColors.neonGreen.withOpacity(0.08),
                borderRadius: CyberRadius.medium,
                border: Border.all(
                    color: CyberColors.neonGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.insert_drive_file_outlined,
                    color: CyberColors.neonGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  unlockedFilename,
                  style: const TextStyle(
                    fontFamily: 'DotMatrix',
                    fontSize: 15,
                    color: CyberColors.neonGreen,
                    letterSpacing: 1,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              successMessage,
              style: CyberText.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}