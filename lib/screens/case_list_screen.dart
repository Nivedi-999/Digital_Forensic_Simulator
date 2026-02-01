import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import 'case_story_screen.dart';


class CaseListScreen extends StatelessWidget {
  const CaseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Available Cases',
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              _case(
                title: 'Operation GhostTrace',
                difficulty: 'Medium',
                theme: 'Insider Data Leak',
                isGhostTrace: true,
              ),
              _case(
                title: 'Phantom Transaction',
                difficulty: 'Easy',
                theme: 'Unauthorized Bank Transfer',
              ),
              _case(
                title: 'Silent Attendance Hack',
                difficulty: 'Easy–Medium',
                theme: 'College Attendance Manipulation',
              ),
              _case(
                title: 'Dark Proxy Attack',
                difficulty: 'Hard',
                theme: 'Masked DDoS via Proxies',
              ),
              _case(
                title: 'The Vanishing Vault',
                difficulty: 'Insane',
                theme: 'Encrypted File Destruction',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _case({
    required String title,
    required String difficulty,
    required String theme,
    bool isGhostTrace = false,
  }) {
    return _ExpandableCaseTile(
      title: title,
      difficulty: difficulty,
      theme: theme,
      isGhostTrace: isGhostTrace,
    );
  }
}

// ───────────────── EXPANDABLE TILE ─────────────────
class _ExpandableCaseTile extends StatefulWidget {
  final String title;
  final String difficulty;
  final String theme;
  final bool isGhostTrace;

  const _ExpandableCaseTile({
    required this.title,
    required this.difficulty,
    required this.theme,
    required this.isGhostTrace,
  });

  @override
  State<_ExpandableCaseTile> createState() => _ExpandableCaseTileState();
}

class _ExpandableCaseTileState extends State<_ExpandableCaseTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppShell.neonCyan.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───── TITLE ROW ─────
          InkWell(
            onTap: () {
              if (widget.isGhostTrace) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StorylineScreen(),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'DotMatrix',
                        fontSize: 26,
                        color: AppShell.neonCyan,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppShell.neonCyan,
                    ),
                    onPressed: () {
                      setState(() => expanded = !expanded);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ───── DROPDOWN INFO ─────
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Difficulty: ${widget.difficulty}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Theme: ${widget.theme}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
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
