// lib/screens/suspect_profile_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../case_data/ghosttrace_case_data.dart';
import 'case_outcome_screen.dart';

class SuspectProfileScreen extends StatelessWidget {
  final Suspect suspect;

  const SuspectProfileScreen({
    super.key,
    required this.suspect,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Suspect Profile',
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Avatar placeholder + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    child: Text(
                      suspect.name.substring(0, 1),
                      style: const TextStyle(fontSize: 60, color: AppShell.neonCyan),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    suspect.name,
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppShell.neonCyan,
                      fontFamily: 'DotMatrix',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRiskColor(suspect.riskLevel).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRiskColor(suspect.riskLevel)),
                    ),
                    child: Text(
                      'Threat Level: ${suspect.risk.toUpperCase()}',
                      style: TextStyle(
                        color: _getRiskColor(suspect.riskLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Digital Footprint Timeline (placeholder for now)
            _sectionTitle('Digital Footprint Timeline'),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• IP Activity: 202.56.23.101 – 10:45 AM', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 12),
                  Text('• Device Usage: FIN-WS-114 – 09:15–10:50 AM', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 12),
                  Text('• Location Traces: Mumbai office WiFi', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 12),
                  Text('• No foreign VPN detected after deep trace', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Suspicion meter placeholder
            _sectionTitle('Suspicion Level'),
            _panel(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _getSuspicionValue(suspect.riskLevel),
                    backgroundColor: Colors.grey[800],
                    color: _getRiskColor(suspect.riskLevel),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current Suspicion: ${_getSuspicionText(suspect.riskLevel)}',
                    style: TextStyle(color: _getRiskColor(suspect.riskLevel)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.search, color: AppShell.neonCyan),
                  label: const Text('Investigate Further'),
                  onPressed: () {
                    Navigator.pop(context); // goes back to Investigation Hub
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppShell.neonCyan,
                    side: const BorderSide(color: AppShell.neonCyan),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flag, color: Colors.black),
                  label: const Text('Flag as Culprit'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Flagging ${suspect.name} as primary suspect... Analyzing evidence...'),
                        backgroundColor: Colors.redAccent,
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Navigate to outcome screen and pass the flagged suspect's name
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseOutcomeScreen(
                          flaggedSuspectName: suspect.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  double _getSuspicionValue(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 0.85;
      case 'medium':
        return 0.55;
      default:
        return 0.25;
    }
  }

  String _getSuspicionText(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'Critical';
      case 'medium':
        return 'Moderate';
      default:
        return 'Low';
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'DotMatrix',
          fontSize: 22,
          color: AppShell.neonCyan,
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppShell.neonCyan, width: 2),
      ),
      child: child,
    );
  }
}