// lib/screens/case_outcome_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../services/evidence_collector.dart';
import '../services/game_progress.dart';
import '../widgets/main_scaffold.dart';

class CaseOutcomeScreen extends StatefulWidget {
  final String? flaggedSuspectName; // Who the user flagged

  const CaseOutcomeScreen({
    super.key,
    this.flaggedSuspectName,
  });

  @override
  State<CaseOutcomeScreen> createState() => _CaseOutcomeScreenState();
}

class _CaseOutcomeScreenState extends State<CaseOutcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  // Define correct evidences (you can move this to ghosttrace_case_data.dart later)
  final Set<String> _correctEvidences = {
    'files:finance_report_q3.pdf',
    'files:debug_log.txt',
    'meta:Last User',
    'ip:Internal Origin',
    'ip:External Hop',
    // Add any other truly decisive evidences here
  };

  @override
  void initState() {
    super.initState();

    // Count correct evidences
    final collected = EvidenceCollector().collected;
    int correctCount = collected.where((item) {
      final key = '${item['category']}:${item['item']}';
      return _correctEvidences.contains(key);
    }).length;

    // Check if the flagged suspect is correct
    final bool isCorrectSuspect = widget.flaggedSuspectName == 'Ankita E';

    // Only award XP if both suspect and evidence are correct
    if (isCorrectSuspect && correctCount >= 3) {
      GameProgress.addXp(10);
    }

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: GameProgress.xp / 100.0.clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start animation only on actual win
    if (isCorrectSuspect && correctCount >= 3) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collected = EvidenceCollector().collected;
    final correctCount = collected.where((item) {
      final key = '${item['category']}:${item['item']}';
      return _correctEvidences.contains(key);
    }).length;

    final bool isCorrectSuspect = widget.flaggedSuspectName == 'Ankita E';

    String title;
    Color accentColor;
    IconData icon;
    String? subtitle;

    if (!isCorrectSuspect) {
      title = 'WRONG SUSPECT';
      accentColor = Colors.redAccent;
      icon = Icons.error_outline;
      subtitle = 'You flagged ${widget.flaggedSuspectName ?? "unknown"}, but the real culprit was Ankita E.';
    } else if (correctCount >= 3) {
      title = 'CASE SOLVED';
      accentColor = Colors.greenAccent;
      icon = Icons.verified;
      subtitle = 'Correctly identified Ankita E + sufficient evidence chain.';
    } else if (correctCount == 0) {
      title = 'CASE GONE COLD';
      accentColor = Colors.blueGrey;
      icon = Icons.ac_unit;
      subtitle = 'No relevant evidence collected to support the accusation.';
    } else {
      title = 'NOT ENOUGH EVIDENCE';
      accentColor = Colors.orangeAccent;
      icon = Icons.warning_amber_rounded;
      subtitle = 'Evidence collected is insufficient to close the case.';
    }

    final bool isWin = isCorrectSuspect && correctCount >= 3;

    return MainScaffold(
      title: 'Case Outcome',
      showBack: false,
      currentIndex: 0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big icon with scale animation
              AnimatedScale(
                scale: isWin ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  size: 120,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 32),

              // Main title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'DotMatrix',
                  fontSize: 36,
                  color: accentColor,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle / explanation
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),

              // Evidence stats
              Text(
                'Relevant evidences collected: ${collected.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Correct matches: $correctCount / ${_correctEvidences.length}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (isWin) ...[
                const SizedBox(height: 40),
                Text(
                  '+10 XP Awarded',
                  style: TextStyle(
                    color: AppShell.neonCyan,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Animated XP bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey[800],
                          color: AppShell.neonCyan,
                          minHeight: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'XP: ${GameProgress.xp} • ${GameProgress.rankName}',
                          style: TextStyle(
                            color: AppShell.neonCyan,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 60),

              // Return to home
              ElevatedButton.icon(
                icon: const Icon(Icons.home, color: Colors.black),
                label: const Text('Return to Home', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppShell.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Clear evidence for next case (optional – comment out if unwanted)
                  EvidenceCollector().clearAll();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}