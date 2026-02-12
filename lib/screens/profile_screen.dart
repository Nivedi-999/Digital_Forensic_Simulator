// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../widgets/main_scaffold.dart'; // if you're using the MainScaffold we created earlier

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // These values can later come from a real state/provider/game progress class
    const String currentRank = 'Junior Analyst';
    const double xpProgress = 0.45; // 0.0 to 1.0
    const int totalCasesSolved = 3;
    const double overallAccuracy = 78.5;
    const int totalXpEarned = 1420;

    return MainScaffold(
      title: 'Analyst Profile',
      showBack: true,
      currentIndex: 2, // highlights "Profile" in bottom nav
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Avatar + Rank
            CircleAvatar(
              radius: 70,
              backgroundColor: AppShell.neonCyan.withOpacity(0.2),
              child: Text(
                'JA', // initials of Junior Analyst
                style: TextStyle(
                  fontSize: 60,
                  color: AppShell.neonCyan,
                  fontFamily: 'DotMatrix',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentRank,
              style: const TextStyle(
                fontFamily: 'DotMatrix',
                fontSize: 32,
                color: AppShell.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cyber Investigator Division',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // XP Progress
            _statCard(
              title: 'Experience Progress',
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: xpProgress,
                    backgroundColor: Colors.grey[800],
                    color: AppShell.neonCyan,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(xpProgress * 100).toStringAsFixed(0)}% to next rank',
                    style: TextStyle(
                      color: AppShell.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statBox('Cases Solved', '$totalCasesSolved'),
                _statBox('Accuracy', '${overallAccuracy.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            _statBox('Total XP Earned', '$totalXpEarned', fullWidth: true),

            const SizedBox(height: 48),

            // Action buttons
            OutlinedButton.icon(
              icon: const Icon(Icons.settings, color: AppShell.neonCyan),
              label: const Text('Settings', style: TextStyle(color: AppShell.neonCyan)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppShell.neonCyan, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () {
                // TODO: open settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () {
                // TODO: logout logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              },
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppShell.neonCyan.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'DotMatrix',
              fontSize: 18,
              color: AppShell.neonCyan,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppShell.neonCyan.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              color: AppShell.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}