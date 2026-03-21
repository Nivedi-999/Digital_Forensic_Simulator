// lib/screens/mini_game.dart
// Routes: caesar_cipher | ip_trace | code_crack | phishing_analysis | metadata_correlation | alibi_verify

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/tutorial_service.dart';
import '../widgets/aria_controller.dart';

// ── Entry point ──────────────────────────────────────────────

class DecryptionMiniGameScreen extends StatefulWidget {
  final String panelId;
  const DecryptionMiniGameScreen({super.key, required this.panelId});
  @override
  State<DecryptionMiniGameScreen> createState() => _DecryptionMiniGameScreenState();
}

class _DecryptionMiniGameScreenState extends State<DecryptionMiniGameScreen> with AriaMixin {
  MinigameConfig? _minigame;
  @override
  void initState() {
    super.initState();
    triggerAria(TutorialStep.decryptionHint);
  }
  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final panel = engine.caseFile.panelById(widget.panelId);
    _minigame ??= panel?.minigame;
    final mg = _minigame;
    if (mg == null) {
      return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
          child: const Center(child: Text('No mini-game found.')));
    }
    switch (mg.type) {
      case 'ip_trace': return _IpTraceGame(panelId: widget.panelId, minigame: mg);
      case 'code_crack': return _CodeCrackGame(panelId: widget.panelId, minigame: mg);
      case 'phishing_analysis': return _PhishingGame(panelId: widget.panelId, minigame: mg);
      case 'metadata_correlation': return _MetadataCorrelationGame(panelId: widget.panelId, minigame: mg);
      case 'alibi_verify': return _AlibiVerifyGame(panelId: widget.panelId, minigame: mg);
      case 'caesar_cipher':
      default: return _CaesarCipherGame(panelId: widget.panelId, minigame: mg);
    }
  }
  @override
  Widget buildAriaLayer({void Function()? onDismiss}) => const SizedBox.shrink();
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SUCCESS OVERLAY
// ═══════════════════════════════════════════════════════════════

class _SuccessOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onContinue;
  const _SuccessOverlay({required this.message, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberColors.neonGreen.withOpacity(0.15),
                border: Border.all(color: CyberColors.neonGreen, width: 2),
                boxShadow: [BoxShadow(color: CyberColors.neonGreen.withOpacity(0.4), blurRadius: 32, spreadRadius: 4)],
              ),
              child: const Icon(Icons.check_rounded, color: CyberColors.neonGreen, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('SUCCESS', style: TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonGreen,
                fontSize: 28, letterSpacing: 3, shadows: [Shadow(color: CyberColors.neonGreen, blurRadius: 16)])),
            const SizedBox(height: 12),
            Text(message, style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            CyberButton(label: 'Continue Investigation', icon: Icons.arrow_forward_outlined, onTap: onContinue),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  1. CAESAR CIPHER — Easy
// ═══════════════════════════════════════════════════════════════

class _CaesarCipherGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CaesarCipherGame({required this.panelId, required this.minigame});
  @override
  State<_CaesarCipherGame> createState() => _CaesarCipherGameState();
}

class _CaesarCipherGameState extends State<_CaesarCipherGame> with TickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  String _feedback = '';
  int _hintsUsed = 0;
  bool _success = false;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); _entryCtrl.dispose(); super.dispose(); }

  void _check(CaseEngine engine) {
    final input = _ctrl.text.trim().toLowerCase();
    final solution = (widget.minigame.solution ?? '').toLowerCase();
    if (input == solution) { engine.solveMinigame(widget.minigame.id); setState(() => _success = true); }
    else setState(() => _feedback = 'Incorrect. Try again.');
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          FadeTransition(opacity: _fadeIn, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NeonContainer(borderColor: CyberColors.neonPurple, padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 48, height: 48,
                        decoration: BoxDecoration(color: CyberColors.neonPurple.withOpacity(0.12),
                            borderRadius: CyberRadius.small, border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4))),
                        child: const Icon(Icons.lock_open_outlined, color: CyberColors.neonPurple, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonPurple)),
                      if (mg.hint != null) ...[const SizedBox(height: 4),
                        Text(mg.hint!, style: CyberText.bodySmall.copyWith(fontSize: 12))],
                    ])),
                  ])),
              const SizedBox(height: 20),
              NeonContainer(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ENCODED TEXT', style: CyberText.caption.copyWith(letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(mg.cipherText ?? '', style: const TextStyle(fontFamily: 'DotMatrix', fontSize: 28,
                    color: CyberColors.neonAmber, letterSpacing: 4,
                    shadows: [Shadow(color: CyberColors.neonAmber, blurRadius: 12)])),
              ])),
              const SizedBox(height: 20),
              NeonContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DECODED TEXT', style: CyberText.caption.copyWith(letterSpacing: 2)),
                const SizedBox(height: 10),
                TextField(controller: _ctrl,
                    style: const TextStyle(color: CyberColors.neonCyan, fontSize: 20, fontFamily: 'DotMatrix'),
                    decoration: InputDecoration(hintText: 'Type decoded text...',
                        hintStyle: TextStyle(color: CyberColors.textMuted.withOpacity(0.5)), border: InputBorder.none),
                    onSubmitted: (_) => _check(engine)),
              ])),
              if (_feedback.isNotEmpty) ...[const SizedBox(height: 12),
                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08),
                        borderRadius: CyberRadius.small, border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                    child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: CyberButton(label: 'Submit', icon: Icons.check_outlined, onTap: () => _check(engine))),
                const SizedBox(width: 12),
                CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                    isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
              ]),
            ]),
          )),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Hidden evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. IP TRACE — Medium
// ═══════════════════════════════════════════════════════════════

class _IpTraceGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _IpTraceGame({required this.panelId, required this.minigame});
  @override
  State<_IpTraceGame> createState() => _IpTraceGameState();
}

class _IpTraceGameState extends State<_IpTraceGame> with TickerProviderStateMixin {
  String _typed = '';
  bool _success = false;
  bool _failed = false;
  int _hintsUsed = 0;
  String _feedback = '';
  int _highlightedIndex = -1;
  static const int _totalSeconds = 45;
  int _remaining = _totalSeconds;
  Timer? _timer;
  late List<String> _ipList;
  late int _correctIndex;
  late AnimationController _flashCtrl;
  late Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    final mg = widget.minigame;
    _ipList = List<String>.from(mg.decoys);
    if (!_ipList.contains(mg.solution)) _ipList.add(mg.solution ?? '');
    _ipList.shuffle();
    _correctIndex = _ipList.indexWhere((ip) => ip == mg.solution);
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _flash = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeInOut);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remaining--);
      if (_remaining <= 0) { t.cancel(); setState(() => _failed = true); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _flashCtrl.dispose(); super.dispose(); }

  void _tap(String char) {
    if (_success || _failed) return;
    setState(() {
      if (char == '⌫') { if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1); }
      else if (char == '✓') { _submit(); }
      else if (_typed.length < 15) { _typed += char; }
    });
  }

  void _submit() {
    final solution = widget.minigame.solution ?? '';
    if (_typed.trim() == solution) {
      _timer?.cancel();
      final engine = CaseEngineProvider.read(context);
      engine.solveMinigame(widget.minigame.id);
      setState(() => _success = true);
    } else { setState(() => _feedback = 'Wrong IP. Try again.'); HapticFeedback.heavyImpact(); }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; _highlightedIndex = _correctIndex; });
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _highlightedIndex = -1); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final progress = _remaining / _totalSeconds;
    final timerColor = _remaining > 20 ? CyberColors.neonGreen : _remaining > 10 ? CyberColors.neonAmber : CyberColors.neonRed;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          Column(children: [
            LinearProgressIndicator(value: progress, backgroundColor: CyberColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(timerColor), minHeight: 6),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Column(children: [
              Container(width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF0A1628), borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4), width: 2),
                      boxShadow: CyberShadows.neonCyan(intensity: 0.3)),
                  child: Column(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                            border: Border(bottom: BorderSide(color: CyberColors.neonCyan.withOpacity(0.2)))),
                        child: Row(children: [
                          const Icon(Icons.wifi_find, color: CyberColors.neonCyan, size: 20),
                          const SizedBox(width: 10),
                          Text(mg.title, style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonCyan, fontSize: 14, letterSpacing: 1)),
                          const Spacer(),
                          Text('$_remaining s', style: TextStyle(color: timerColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ])),
                    Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('POSSIBLE IP ADDRESSES', style: CyberText.caption.copyWith(letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ..._ipList.asMap().entries.map((entry) {
                        final i = entry.key; final ip = entry.value; final isH = i == _highlightedIndex;
                        return AnimatedBuilder(animation: _flash, builder: (_, __) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                                color: isH ? CyberColors.neonAmber.withOpacity(0.1 + _flash.value * 0.1) : CyberColors.neonCyan.withOpacity(0.04),
                                borderRadius: CyberRadius.small,
                                border: Border.all(color: isH ? CyberColors.neonAmber.withOpacity(0.6) : CyberColors.borderSubtle)),
                            child: Text(ip, style: TextStyle(fontFamily: 'DotMatrix',
                                color: isH ? CyberColors.neonAmber : CyberColors.textPrimary, fontSize: 15, letterSpacing: 1.5))));
                      }),
                    ])),
                    Container(margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: CyberRadius.small,
                            border: Border.all(color: CyberColors.neonCyan.withOpacity(0.5))),
                        child: Row(children: [
                          Expanded(child: Text(_typed.isEmpty ? 'Enter IP address...' : _typed,
                              style: TextStyle(fontFamily: 'DotMatrix',
                                  color: _typed.isEmpty ? CyberColors.textMuted : CyberColors.neonCyan, fontSize: 18, letterSpacing: 2))),
                          if (_feedback.isNotEmpty) const Icon(Icons.error_outline, color: CyberColors.neonRed, size: 18),
                        ])),
                    if (_feedback.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 12))),
                    const SizedBox(height: 16),
                    _NumericKeypad(onTap: _tap),
                    const SizedBox(height: 12),
                    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                            isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                            onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null)),
                  ])),
            ]))),
          ]),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Hacker IP found. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
          if (_failed && !_success) Container(color: Colors.black.withOpacity(0.85), child: Center(child: Padding(
              padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_off_outlined, color: CyberColors.neonRed, size: 64),
            const SizedBox(height: 16),
            const Text('TIME OUT', style: TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonRed, fontSize: 28, letterSpacing: 3)),
            const SizedBox(height: 12),
            Text('The trace window expired.', style: CyberText.bodySmall),
            const SizedBox(height: 24),
            CyberButton(label: 'Try Again', icon: Icons.replay, accentColor: CyberColors.neonRed,
                onTap: () { setState(() { _typed = ''; _feedback = ''; _failed = false; _remaining = _totalSeconds; }); _startTimer(); }),
            const SizedBox(height: 12),
            CyberButton(label: 'Go Back', icon: Icons.arrow_back, isOutlined: true, onTap: () => Navigator.pop(context)),
          ])))),
        ]));
  }
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onTap;
  const _NumericKeypad({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final keys = [['1','2','3'],['4','5','6'],['7','8','9'],['.','0','⌫'],['✓']];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(
        children: keys.map((row) => Row(children: row.map((key) {
          final isSubmit = key == '✓'; final isDelete = key == '⌫';
          return Expanded(child: Padding(padding: const EdgeInsets.all(4),
              child: Material(color: isSubmit ? CyberColors.neonCyan.withOpacity(0.15) : CyberColors.neonCyan.withOpacity(0.05),
                  borderRadius: CyberRadius.small,
                  child: InkWell(borderRadius: CyberRadius.small, onTap: () => onTap(key),
                      child: Container(height: 48,
                          decoration: BoxDecoration(borderRadius: CyberRadius.small,
                              border: Border.all(color: isSubmit ? CyberColors.neonCyan.withOpacity(0.5) : CyberColors.borderSubtle)),
                          child: Center(child: isDelete
                              ? const Icon(Icons.backspace_outlined, color: CyberColors.neonRed, size: 20)
                              : isSubmit ? const Icon(Icons.check_rounded, color: CyberColors.neonCyan, size: 22)
                              : Text(key, style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.textPrimary, fontSize: 18))))))));
        }).toList())).toList()));
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. CODE CRACK — Hard
// ═══════════════════════════════════════════════════════════════

class _CodeCrackGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _CodeCrackGame({required this.panelId, required this.minigame});
  @override
  State<_CodeCrackGame> createState() => _CodeCrackGameState();
}

class _CodeCrackGameState extends State<_CodeCrackGame> with TickerProviderStateMixin {
  static const List<String> _chars = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'];
  late List<int> _currentIndices;
  bool _success = false;
  int _hintsUsed = 0;
  String _feedback = '';
  late AnimationController _glitchCtrl;

  @override
  void initState() {
    super.initState();
    _currentIndices = [0, 0, 0];
    _glitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80))..repeat(reverse: true);
  }
  @override
  void dispose() { _glitchCtrl.dispose(); super.dispose(); }

  void _scroll(int reel, int dir) {
    if (_success) return;
    setState(() {
      _currentIndices[reel] = (_currentIndices[reel] + dir) % _chars.length;
      if (_currentIndices[reel] < 0) _currentIndices[reel] = _chars.length - 1;
    });
  }

  void _submit(CaseEngine engine) {
    final solution = widget.minigame.solution ?? '';
    final current = _currentIndices.map((i) => _chars[i]).join();
    if (current == solution) { engine.solveMinigame(widget.minigame.id); setState(() => _success = true); }
    else { setState(() => _feedback = 'Code mismatch. Keep trying.'); HapticFeedback.heavyImpact(); }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      final solution = mg.solution ?? '';
      if (_hintsUsed < solution.length) {
        final idx = _chars.indexOf(solution[_hintsUsed].toUpperCase());
        if (idx >= 0) setState(() => _currentIndices[_hintsUsed] = idx);
      }
      setState(() { _feedback = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final solution = mg.solution ?? '???';
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), child: Column(children: [
            NeonContainer(borderColor: CyberColors.neonRed, padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.terminal, color: CyberColors.neonRed, size: 20), const SizedBox(width: 10),
                    Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonRed))]),
                  const SizedBox(height: 10),
                  _TerminalLine('> Accessing Hacker System...', CyberColors.neonRed),
                  _TerminalLine('> Bypassing Firewall...', CyberColors.neonAmber),
                  _TerminalLine('> Enter 3-character unlock code to proceed.', CyberColors.neonCyan),
                ])),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('TARGET CODE:  ', style: TextStyle(color: CyberColors.textSecondary, fontSize: 13)),
              ...solution.split('').map((c) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4), width: 44, height: 44,
                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.1), borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.5))),
                  child: Center(child: Text(c, style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonAmber,
                      fontSize: 22, shadows: [Shadow(color: CyberColors.neonAmber, blurRadius: 8)]))))),
            ]),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (reel) {
              final cur = _chars[_currentIndices[reel]];
              final prv = _chars[(_currentIndices[reel] - 1 + _chars.length) % _chars.length];
              final nxt = _chars[(_currentIndices[reel] + 1) % _chars.length];
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Column(children: [
                GestureDetector(onTap: () => _scroll(reel, -1), child: Container(width: 64, height: 44,
                    decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.keyboard_arrow_up, color: CyberColors.neonCyan, size: 22),
                      Text(prv, style: const TextStyle(color: CyberColors.textMuted, fontSize: 16, fontFamily: 'DotMatrix'))]))),
                Container(width: 64, height: 72,
                    decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.12),
                        border: Border.all(color: CyberColors.neonCyan, width: 2), boxShadow: CyberShadows.neonCyan(intensity: 0.4)),
                    child: Center(child: Text(cur, style: const TextStyle(fontFamily: 'DotMatrix', fontSize: 36,
                        color: CyberColors.neonCyan, shadows: [Shadow(color: CyberColors.neonCyan, blurRadius: 16)])))),
                GestureDetector(onTap: () => _scroll(reel, 1), child: Container(width: 64, height: 44,
                    decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(nxt, style: const TextStyle(color: CyberColors.textMuted, fontSize: 16, fontFamily: 'DotMatrix')),
                      const Icon(Icons.keyboard_arrow_down, color: CyberColors.neonCyan, size: 22)]))),
              ]));
            })),
            const SizedBox(height: 8),
            Text('Tap arrows to match the target code', style: CyberText.caption.copyWith(color: CyberColors.textMuted)),
            if (_feedback.isNotEmpty) ...[const SizedBox(height: 14),
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08), borderRadius: CyberRadius.small,
                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                  child: Text(_feedback, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: CyberButton(label: 'CRACK CODE', icon: Icons.lock_open_outlined,
                  accentColor: CyberColors.neonRed, onTap: () => _submit(engine))),
              const SizedBox(width: 12),
              CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                  isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                  onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
            ]),
          ])),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'System breached. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}

class _TerminalLine extends StatelessWidget {
  final String text;
  final Color color;
  const _TerminalLine(this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontFamily: 'DotMatrix', color: color, fontSize: 12, letterSpacing: 0.5)));
}

// ═══════════════════════════════════════════════════════════════
//  4. PHISHING ANALYSIS — Advanced
// ═══════════════════════════════════════════════════════════════

class _PhishingGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _PhishingGame({required this.panelId, required this.minigame});
  @override
  State<_PhishingGame> createState() => _PhishingGameState();
}

class _PhishingGameState extends State<_PhishingGame> {
  bool _success = false;
  bool _wrongChoice = false;
  final Set<int> _flagged = {};
  int _hintsUsed = 0;
  String _hintText = '';

  void _choose(String action, CaseEngine engine) {
    final correct = widget.minigame.correctAction ?? 'report';
    if (action == correct) { engine.solveMinigame(widget.minigame.id); setState(() => _success = true); }
    else { setState(() => _wrongChoice = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _wrongChoice = false); }); }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NeonContainer(borderColor: CyberColors.neonAmber, padding: const EdgeInsets.all(14),
                    child: Row(children: [const Icon(Icons.security, color: CyberColors.neonAmber, size: 20),
                      const SizedBox(width: 10),
                      Text('Email Security Analysis', style: CyberText.sectionTitle.copyWith(color: CyberColors.neonAmber))])),
                const SizedBox(height: 16),
                Container(decoration: BoxDecoration(color: const Color(0xFF0D1B2A), borderRadius: CyberRadius.medium,
                    border: Border.all(color: CyberColors.neonRed.withOpacity(0.4), width: 1.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.06),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              border: Border(bottom: BorderSide(color: CyberColors.neonRed.withOpacity(0.2)))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: CyberColors.neonRed.withOpacity(0.15), border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                                  child: const Icon(Icons.mail_outlined, color: CyberColors.neonRed, size: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(mg.emailFrom ?? '', style: const TextStyle(color: CyberColors.neonRed, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('To: investigator@cybercell.in', style: CyberText.caption)])),
                            ]),
                            const SizedBox(height: 10),
                            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.08), borderRadius: CyberRadius.small),
                                child: Text(mg.emailSubject ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: CyberColors.textPrimary, fontSize: 14))),
                          ])),
                      Padding(padding: const EdgeInsets.all(16),
                          child: Text(mg.emailBody ?? '', style: CyberText.bodySmall.copyWith(height: 1.7, fontSize: 13))),
                    ])),
                const SizedBox(height: 20),
                NeonContainer(borderColor: CyberColors.neonRed, padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.flag_outlined, color: CyberColors.neonRed, size: 16), const SizedBox(width: 8),
                        Text('IDENTIFY RED FLAGS', style: CyberText.caption.copyWith(color: CyberColors.neonRed, letterSpacing: 1.5))]),
                      const SizedBox(height: 10),
                      ...mg.redFlags.asMap().entries.map((entry) {
                        final i = entry.key; final flag = entry.value; final fl = _flagged.contains(i);
                        return GestureDetector(onTap: () => setState(() => fl ? _flagged.remove(i) : _flagged.add(i)),
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: fl ? CyberColors.neonRed.withOpacity(0.12) : Colors.transparent,
                                    borderRadius: CyberRadius.small, border: Border.all(color: fl ? CyberColors.neonRed.withOpacity(0.5) : CyberColors.borderSubtle)),
                                child: Row(children: [Icon(fl ? Icons.flag : Icons.flag_outlined, color: fl ? CyberColors.neonRed : CyberColors.textMuted, size: 16),
                                  const SizedBox(width: 10), Expanded(child: Text(flag, style: TextStyle(color: fl ? CyberColors.textPrimary : CyberColors.textSecondary, fontSize: 13)))])));
                      }),
                    ])),
                if (_hintText.isNotEmpty) ...[const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08), borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: Text(_hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                if (_wrongChoice) ...[const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.08), borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                      child: const Text('Wrong decision. Analyse the email more carefully.',
                          style: TextStyle(color: CyberColors.neonRed, fontSize: 13)))],
                const SizedBox(height: 16),
                CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                    isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
              ])),
          Positioned(left: 0, right: 0, bottom: 0, child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(color: const Color(0xFF060E1A),
                  border: Border(top: BorderSide(color: CyberColors.borderSubtle, width: 1))),
              child: Row(children: [
                Expanded(child: _ActionButton(label: 'Report Phishing', icon: Icons.report_outlined,
                    color: CyberColors.neonCyan, onTap: () => _choose('report', engine))),
                const SizedBox(width: 12),
                Expanded(child: _ActionButton(label: 'Delete', icon: Icons.delete_outline,
                    color: CyberColors.neonRed, onTap: () => _choose('delete', engine))),
              ]))),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Phishing email flagged. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: color.withOpacity(0.12), borderRadius: CyberRadius.medium,
      child: InkWell(borderRadius: CyberRadius.medium, onTap: onTap,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(borderRadius: CyberRadius.medium, border: Border.all(color: color.withOpacity(0.5), width: 1.5)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: color, size: 20), const SizedBox(width: 8),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))]))));
}

// ═══════════════════════════════════════════════════════════════
//  5. METADATA CORRELATION — Hard
//  Uses MetadataFragment fields: id, label, value, hint, correctSuspectId, explanation
// ═══════════════════════════════════════════════════════════════

class _MetadataCorrelationGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _MetadataCorrelationGame({required this.panelId, required this.minigame});
  @override
  State<_MetadataCorrelationGame> createState() => _MetadataCorrelationGameState();
}

class _MetadataCorrelationGameState extends State<_MetadataCorrelationGame> {
  final Map<String, String?> _selections = {};
  final Map<String, bool> _revealed = {};
  bool _submitted = false;
  bool _success = false;
  int _hintsUsed = 0;
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    for (final f in widget.minigame.fragments) { _selections[f.id] = null; _revealed[f.id] = false; }
  }

  void _submit(CaseEngine engine) {
    final mg = widget.minigame;
    bool allCorrect = true;
    for (final f in mg.fragments) {
      if (_selections[f.id] != f.correctSuspectId) allCorrect = false;
      _revealed[f.id] = true;
    }
    setState(() => _submitted = true);
    if (allCorrect) { engine.solveMinigame(mg.id); setState(() => _success = true); }
    else HapticFeedback.heavyImpact();
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  void _reset() {
    setState(() {
      for (final f in widget.minigame.fragments) { _selections[f.id] = null; _revealed[f.id] = false; }
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NeonContainer(borderColor: CyberColors.neonAmber, padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.data_object, color: CyberColors.neonAmber, size: 20), const SizedBox(width: 10),
                        Expanded(child: Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonAmber)))]),
                      const SizedBox(height: 8),
                      Text(mg.instruction ?? mg.hint ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 20),
                ...mg.fragments.map((frag) {
                  final sel = _selections[frag.id];
                  final revealed = _revealed[frag.id] ?? false;
                  final isCorrect = revealed && sel == frag.correctSuspectId;
                  final isWrong = revealed && sel != frag.correctSuspectId;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isCorrect) borderCol = CyberColors.neonGreen;
                  if (isWrong) borderCol = CyberColors.neonRed;
                  return Padding(padding: const EdgeInsets.only(bottom: 16),
                      child: NeonContainer(borderColor: borderCol, padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.1), borderRadius: CyberRadius.pill,
                                      border: Border.all(color: CyberColors.neonAmber.withOpacity(0.4))),
                                  child: Text(frag.label, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 11, fontWeight: FontWeight.bold))),
                              if (isCorrect) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: CyberColors.neonGreen, size: 16)],
                              if (isWrong) ...[const SizedBox(width: 8), const Icon(Icons.cancel, color: CyberColors.neonRed, size: 16)],
                            ]),
                            const SizedBox(height: 8),
                            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: CyberRadius.small,
                                    border: Border.all(color: CyberColors.borderSubtle)),
                                child: Text(frag.value, style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.textPrimary, fontSize: 13, letterSpacing: 0.3))),
                            const SizedBox(height: 10),
                            Text('POINTS TO:', style: CyberText.caption.copyWith(letterSpacing: 1.2)),
                            const SizedBox(height: 6),
                            Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(color: CyberColors.bgCard, borderRadius: CyberRadius.small,
                                    border: Border.all(color: isCorrect ? CyberColors.neonGreen.withOpacity(0.5) : isWrong ? CyberColors.neonRed.withOpacity(0.5) : CyberColors.neonCyan.withOpacity(0.3))),
                                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                                    value: sel, hint: Text('Select suspect...', style: TextStyle(color: CyberColors.textMuted, fontSize: 13)),
                                    dropdownColor: CyberColors.bgCard, style: const TextStyle(color: CyberColors.textPrimary, fontSize: 13),
                                    isExpanded: true, onChanged: _submitted ? null : (val) => setState(() => _selections[frag.id] = val),
                                    items: mg.metaSuspects.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['label'] ?? ''))).toList()))),
                            if (revealed) ...[const SizedBox(height: 10),
                              Container(width: double.infinity, padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: isCorrect ? CyberColors.neonGreen.withOpacity(0.08) : CyberColors.neonRed.withOpacity(0.08),
                                      borderRadius: CyberRadius.small,
                                      border: Border.all(color: isCorrect ? CyberColors.neonGreen.withOpacity(0.3) : CyberColors.neonRed.withOpacity(0.3))),
                                  child: Text(isCorrect ? frag.explanation : 'Incorrect. ${frag.explanation}',
                                      style: TextStyle(color: isCorrect ? CyberColors.neonGreen : CyberColors.neonRed, fontSize: 12, height: 1.5)))],
                          ])));
                }),
                if (_hintText.isNotEmpty) ...[const SizedBox(height: 4),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08), borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: Text(_hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: CyberButton(label: _submitted ? 'Try Again' : 'Submit',
                      icon: _submitted ? Icons.replay : Icons.check_outlined, accentColor: CyberColors.neonAmber,
                      onTap: _submitted ? _reset : () => _submit(engine))),
                  const SizedBox(width: 12),
                  CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                      isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                      onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
                ]),
              ])),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Metadata correlated. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}

// ═══════════════════════════════════════════════════════════════
//  6. ALIBI VERIFICATION — Hard
//  Uses AlibiEntry fields: id, suspectName, alibi, isContradicted, contradiction
// ═══════════════════════════════════════════════════════════════

class _AlibiVerifyGame extends StatefulWidget {
  final String panelId;
  final MinigameConfig minigame;
  const _AlibiVerifyGame({required this.panelId, required this.minigame});
  @override
  State<_AlibiVerifyGame> createState() => _AlibiVerifyGameState();
}

class _AlibiVerifyGameState extends State<_AlibiVerifyGame> {
  String? _selectedAlibiId;
  bool _submitted = false;
  bool _success = false;
  bool _wrong = false;
  int _hintsUsed = 0;
  String _hintText = '';

  // Uses alibi.id to look up the entry
  void _select(String alibiId, CaseEngine engine) {
    if (_submitted) return;
    final alibi = widget.minigame.alibis.firstWhere((a) => a.id == alibiId);
    setState(() { _selectedAlibiId = alibiId; _submitted = true; });
    if (alibi.isContradicted) { engine.solveMinigame(widget.minigame.id); setState(() => _success = true); }
    else {
      HapticFeedback.heavyImpact();
      setState(() => _wrong = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _submitted = false; _wrong = false; _selectedAlibiId = null; });
      });
    }
  }

  void _hint(CaseEngine engine) {
    final mg = widget.minigame;
    if (_hintsUsed < mg.hints.length) {
      engine.recordHintUsed();
      setState(() { _hintText = mg.hints[_hintsUsed]; _hintsUsed++; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final mg = widget.minigame;
    final timeline = mg.timelineEvent;
    return AppShell(title: 'Mini-Game', showBack: true, showBottomNav: false,
        child: Stack(children: [
          SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NeonContainer(borderColor: CyberColors.neonRed, padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.gavel_outlined, color: CyberColors.neonRed, size: 20), const SizedBox(width: 10),
                        Expanded(child: Text(mg.title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonRed)))]),
                      const SizedBox(height: 8),
                      Text(mg.instruction ?? mg.hint ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 16),
                if (timeline != null) Container(width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: CyberColors.neonCyan.withOpacity(0.06), borderRadius: CyberRadius.small,
                        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.access_time, color: CyberColors.neonCyan, size: 14), const SizedBox(width: 6),
                        Text('CONFIRMED EVENT', style: CyberText.caption.copyWith(color: CyberColors.neonCyan, letterSpacing: 1.2))]),
                      const SizedBox(height: 6),
                      Text(timeline['time'] ?? '', style: const TextStyle(fontFamily: 'DotMatrix', color: CyberColors.neonCyan, fontSize: 14, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(timeline['event'] ?? '', style: CyberText.bodySmall.copyWith(height: 1.6)),
                    ])),
                const SizedBox(height: 20),
                Text('WHICH ALIBI IS CONTRADICTED BY THIS EVIDENCE?', style: CyberText.caption.copyWith(letterSpacing: 1.2)),
                const SizedBox(height: 12),
                // alibi.id, alibi.suspectName, alibi.alibi, alibi.isContradicted, alibi.contradiction
                ...mg.alibis.map((alibi) {
                  final isSel = _selectedAlibiId == alibi.id;
                  final isContra = isSel && _submitted && alibi.isContradicted;
                  final isWrongPick = isSel && _wrong && !alibi.isContradicted;
                  Color borderCol = CyberColors.borderSubtle;
                  if (isContra) borderCol = CyberColors.neonRed;
                  if (isWrongPick) borderCol = CyberColors.neonAmber;
                  return Padding(padding: const EdgeInsets.only(bottom: 14),
                      child: Material(color: Colors.transparent, child: InkWell(borderRadius: CyberRadius.medium,
                          onTap: _submitted ? null : () => _select(alibi.id, engine),
                          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: isContra ? CyberColors.neonRed.withOpacity(0.08) : isWrongPick ? CyberColors.neonAmber.withOpacity(0.06) : CyberColors.bgCard,
                                  borderRadius: CyberRadius.medium, border: Border.all(color: borderCol, width: 1.5)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: CyberColors.neonCyan.withOpacity(0.1), border: Border.all(color: CyberColors.neonCyan.withOpacity(0.4))),
                                      child: Center(child: Text(alibi.suspectName.isNotEmpty ? alibi.suspectName[0] : '?',
                                          style: const TextStyle(color: CyberColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14)))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(alibi.suspectName, style: const TextStyle(color: CyberColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
                                  if (isContra) const Icon(Icons.flag, color: CyberColors.neonRed, size: 18),
                                ]),
                                const SizedBox(height: 10),
                                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: CyberRadius.small,
                                        border: Border.all(color: CyberColors.borderSubtle)),
                                    child: Text('"${alibi.alibi}"', style: CyberText.bodySmall.copyWith(fontStyle: FontStyle.italic, height: 1.6))),
                                if (isContra && alibi.contradiction.isNotEmpty) ...[const SizedBox(height: 10),
                                  Container(width: double.infinity, padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: CyberColors.neonRed.withOpacity(0.08), borderRadius: CyberRadius.small,
                                          border: Border.all(color: CyberColors.neonRed.withOpacity(0.4))),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Icon(Icons.warning_amber, color: CyberColors.neonRed, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(alibi.contradiction, style: const TextStyle(color: CyberColors.neonRed, fontSize: 12, height: 1.5))),
                                      ]))],
                              ])))));
                }),
                if (_wrong) ...[const SizedBox(height: 4),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08), borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: const Text('That alibi holds up. Look more carefully at the timeline.',
                          style: TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                if (_hintText.isNotEmpty) ...[const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: CyberColors.neonAmber.withOpacity(0.08), borderRadius: CyberRadius.small,
                          border: Border.all(color: CyberColors.neonAmber.withOpacity(0.3))),
                      child: Text(_hintText, style: const TextStyle(color: CyberColors.neonAmber, fontSize: 13)))],
                const SizedBox(height: 16),
                CyberButton(label: 'Hint (${mg.hints.length - _hintsUsed} left)', icon: Icons.lightbulb_outline,
                    isOutlined: true, isSmall: true, accentColor: CyberColors.neonAmber,
                    onTap: _hintsUsed < mg.hints.length ? () => _hint(engine) : null),
              ])),
          if (_success) _SuccessOverlay(message: mg.successMessage ?? 'Alibi contradicted. Evidence unlocked.',
              onContinue: () => Navigator.pop(context)),
        ]));
  }
}