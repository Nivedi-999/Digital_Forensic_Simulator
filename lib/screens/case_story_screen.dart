import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import 'investigation_hub_screen.dart';

class StorylineScreen extends StatefulWidget {
  const StorylineScreen({super.key});

  @override
  State<StorylineScreen> createState() => _StorylineScreenState();
}

class _StorylineScreenState extends State<StorylineScreen>
    with TickerProviderStateMixin {
  int step = 0;
  int visibleChars = 0;
  Timer? _timer;
  bool loading = false;

  final String shortStory =
      'A classified internal database was accessed illegally.\n\n'
      'Suspicions say the database was infiltrated internally';

  final String missionText =
      'Your mission is:\n\n'
      '• Find the Culprit\n'
      '• Use evidence wisely — some data may be misleading\n'
      '• Find at least 5 correct evidences to\n '
      ' catch the culprit';

  String get currentText => step == 0 ? shortStory : missionText;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer?.cancel();
    visibleChars = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Operation \nGhostTrace',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const SizedBox(height: 24),

            /// ───── STORY CARD ─────
            AnimatedSlide(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              offset: Offset(0, step == 0 ? 0.12 : 0),
              child: _storyBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyBox() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppShell.neonCyan, width: 2),
          color: Colors.black,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔥 KEY LINE
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ───── TYPEWRITER TEXT ─────
            GestureDetector(
              onTap: _skipTyping,
              child: Text(
                currentText.substring(0, visibleChars),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ───── ACTION BUTTONS ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (step == 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppShell.neonCyan,
                    onPressed: () {
                      setState(() => step = 0);
                      _startTyping();
                    },
                  ),

                loading
                    ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    color: AppShell.neonCyan,
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  icon: Icon(
                    step == 0
                        ? Icons.arrow_forward
                        : Icons.play_arrow,
                    size: 30,
                    color: AppShell.neonCyan,
                  ),
                  onPressed: () async {
                    if (visibleChars < currentText.length) {
                      _skipTyping();
                      return;
                    }

                    if (step == 0) {
                      setState(() => step = 1);
                      _startTyping();
                    } else {
                      setState(() => loading = true);
                      await Future.delayed(
                          const Duration(seconds: 4));

                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const InvestigationHubScreen(),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}