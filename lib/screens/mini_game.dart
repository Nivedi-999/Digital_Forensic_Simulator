// lib/screens/decryption_mini_game_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import  '../case_data/ghosttrace_case_data.dart';


class DecryptionMiniGameScreen extends StatefulWidget {
  const DecryptionMiniGameScreen({super.key});

  @override
  State<DecryptionMiniGameScreen> createState() => _DecryptionMiniGameScreenState();
}

class _DecryptionMiniGameScreenState extends State<DecryptionMiniGameScreen> {
  final TextEditingController _controller = TextEditingController();
  String _feedback = '';
  int _hintsUsed = 0;
  final List<String> _hints = [
    'It\'s a simple shift cipher. Try moving letters backward.',
    'The shift is exactly 3 positions back in the alphabet.',
    'Dwwdfkphqw → subtract 3 → becomes A...',
  ];
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final input = _controller.text.trim().toLowerCase();
    if (input == 'Attachment') {
      setState(() {
        _success = true;
        _feedback = 'Success! Hidden clue unlocked: ghosttrace_briefing.pdf';
        GameProgress.unlockBriefing();
      });
    } else {
      setState(() {
        _feedback = 'Incorrect. Try again.';
      });
    }
  }

  void _showHint() {
    if (_hintsUsed < 3) {
      setState(() {
        _feedback = _hints[_hintsUsed];
        _hintsUsed++;
      });
    } else {
      setState(() {
        _feedback = 'No more hints available.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Hidden Clue',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            const Text(
              'Encrypted string:',
              style: TextStyle(color: AppShell.neonCyan, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppShell.neonCyan),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Dwwdfkphqw',
                style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Clue #1:',
              style: TextStyle(color: Colors.white70),
            ),
            const Text(
              'Common filename related to documents...',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 32),

            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Your decryption',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppShell.neonCyan)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: _hintsUsed < 3 ? _showHint : null,
                  style: OutlinedButton.styleFrom(foregroundColor: AppShell.neonCyan),
                  child: Text('Hint (${3 - _hintsUsed} left)'),
                ),
                ElevatedButton(
                  onPressed: _success ? null : _checkAnswer,
                  style: ElevatedButton.styleFrom(backgroundColor: AppShell.neonCyan),
                  child: const Text('Decrypt'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_feedback.isNotEmpty)
              Center(
                child: Text(
                  _feedback,
                  style: TextStyle(
                    color: _success ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_success) ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Clue unlocked!\nFile: ghosttrace_briefing.pdf',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
                ),
              ),
            ],

            const Spacer(),
          ],
        ),
      ),
    );
  }
}