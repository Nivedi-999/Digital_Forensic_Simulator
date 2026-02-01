import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../screens/case_list_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const Color neonCyan = AppShell.neonCyan;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showBack: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ───── Title ─────
              const Text(
                'Cyber Investigator',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neonCyan,
                  fontSize: 35,
                  fontFamily: 'DotMatrix',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Simulation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neonCyan,
                  fontSize: 35,
                  fontFamily: 'DotMatrix',
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 80),

              // ───── New Investigation ─────
              _buildCyberButton(
                label: 'New Investigation',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaseListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // ───── Continue Investigation ─────
              _buildCyberButton(
                label: 'Continue Investigation',
                onTap: () {
                  // TODO: Navigate to saved progress
                },
              ),

              const SizedBox(height: 80),

              // ───── Rank & XP ─────
              _buildRankBox(),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── BUTTON ─────────────────
  static Widget _buildCyberButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: neonCyan.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: neonCyan,
              fontSize: 28,
              fontFamily: 'DotMatrix',
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── RANK BOX ─────────────────
  static Widget _buildRankBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Rank: Junior Analyst',
            style: TextStyle(
              color: neonCyan,
              fontSize: 28,
              fontFamily: 'DotMatrix',
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Text(
                'XP:',
                style: TextStyle(
                  color: neonCyan,
                  fontSize: 28,
                  fontFamily: 'DotMatrix',
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: _XPBar()),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────── XP BAR ─────────────────
class _XPBar extends StatelessWidget {
  const _XPBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: AppShell.neonCyan.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: AppShell.neonCyan,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: AppShell.neonCyan, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
