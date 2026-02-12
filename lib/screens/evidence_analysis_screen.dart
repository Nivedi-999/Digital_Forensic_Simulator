// lib/screens/evidence_analysis_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../services/evidence_collector.dart';
import 'mini_game.dart'; // your decryption screen

class EvidenceAnalysisScreen extends StatelessWidget {
  final String evidenceType;
  final String? selectedItem;

  const EvidenceAnalysisScreen({
    super.key,
    required this.evidenceType,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Evidence Analysis',
      showBack: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Case #2047 • Operation GhostTrace',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getCategoryTitle(evidenceType),
                    style: const TextStyle(
                      fontFamily: 'DotMatrix',
                      fontSize: 26,
                      color: AppShell.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedItem != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppShell.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppShell.neonCyan.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Selected: $selectedItem',
                        style: const TextStyle(
                          color: AppShell.neonCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _panel(
                    child: SizedBox(
                      height: 480,
                      child: SingleChildScrollView(child: _buildContent(evidenceType, selectedItem)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open, color: Colors.black),
                      label: const Text('Unlock Hidden Clue', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppShell.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DecryptionMiniGameScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Mark Relevant / Irrelevant buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: const Border(
                top: BorderSide(color: AppShell.neonCyan, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                  label: const Text('Add as Evidence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    if (selectedItem != null && selectedItem!.isNotEmpty) {
                      EvidenceCollector().addEvidence(evidenceType, selectedItem!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Evidence added',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.greenAccent,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(String type) {
    switch (type) {
      case 'chat': return 'Chat Logs';
      case 'files': return 'Files';
      case 'meta': return 'Metadata Extract';
      case 'ip': return 'IP Traces';
      default: return 'Evidence';
    }
  }

  Widget _buildContent(String type, String? selected) {
    if (selected == null) {
      return const Text(
        'No item selected.\nGo back and choose an evidence item to analyze.',
        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
      );
    }

    if (type == 'files') {
      if (selected == 'finance_report_q3.pdf') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Finance Report [Q3]', style: TextStyle(
                color: AppShell.neonCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Last modified: 09:31 AM by Ankita E',
                style: TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            const Text(
                'Content: \nAnomalies Detected:\n'
                    '-> ₹2.3 Crore transferred to offshore account: ACC-4482-X\n'
                    '-> Unscheduled vendor payment: “Northstar Solutions”\n'
                    '-> Duplicate reimbursement entries on 14th August',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 12),
            const Text('Quarter 3 Revenue Overview: \n'
                '# Total Revenue: ₹48.6 Crore\n'
                '# Operating Costs: ₹31.2 Crore\n'
                '# Net Profit: ₹17.4 Crore\n',
                style: TextStyle(color: Colors.purpleAccent)),
          ],
        );
      }
      if (selected == 'system_patch.exe') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Patch Executable', style: TextStyle(
                color: AppShell.neonCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Deployed: 09:45 AM', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('Size: 4.2 MB', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Signed by: Internal Admin (Dhruv A)',
                style: TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 12),
            const Text(
                'Note: Patch included unusual outbound connection module.',
                style: TextStyle(color: Colors.white70)),
          ],
        );
      }
      if (selected == 'debug_log.txt') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug Log', style: TextStyle(color: AppShell.neonCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Key entry: "Credentials export initiated from FIN-WS-114 at 10:43 AM"',
                style: TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            const Text(
                '[2026-02-02 01:14:22] PatchService: Starting update...\n'
                    '[2026-02-02 01:14:24] PatchService: Verified signature (status: OK)\n'
                    '[2026-02-02 01:14:31] Network: Outbound connection established \nto 185.193.127.44\n'
                    '[2026-02-02 01:14:32] Warning: Unexpected privilege escalation\n'
                    '[2026-02-02 01:14:35] Error: Hash mismatch in module agent.dll\n'
                    '[2026-02-02 01:14:36] PatchService: Process terminated \nunexpectedly\n'
                    '[2026-02-02 01:14:40] SecurityAgent: No threat detected'),
          ],
        );
      }
      if (selected == 'cache_dump.bin') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cache Dump (Binary)', style: TextStyle(
                color: AppShell.neonCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Contains fragments of employee credential database dump',
                style: TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            const Text('Dump timestamp: 10:44–10:46 AM',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('Exfiltration path: FIN-WS-114 → local IP 172.16.44.21',
                style: TextStyle(color: Colors.white70)),
          ],
        );
      }
      return const Text(
        'File content preview not available yet...\n\nTap "Unlock Hidden Clue" for deeper analysis.',
        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
      );
    }

    if (type == 'meta') {
      if (selected == 'Device') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MetaLine('Workstation ID', 'FIN-WS-114'),
            _MetaLine('Physical Location', 'Finance Dept. Mumbai HQ'),
            _MetaLine('Access Control', 'Biometric + PIN required'),
          ],
        );
      }
      if (selected == 'OS') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MetaLine('Operating System', 'Windows 11 Pro (Build 22621)'),
            _MetaLine('Last Update', '2024-01-15 08:40 AM'),
            _MetaLine('Patch Level', 'KB5034123 applied'),
          ],
        );
      }
      if (selected == 'Last User') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MetaLine('Last Logged In User', 'Ankita E'),
            _MetaLine('Login Time', '09:15 AM – 11:02 AM'),
            _MetaLine('Session Type', 'Active'),
          ],
        );
      }
      return const Text(
        'Metadata detail not available for this selection.',
        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
      );
    }

    if (type == 'ip') {
      if (selected == 'Internal Origin') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MetaLine('Source IP', '172.16.44.21'),
            _MetaLine('MAC Address', '00-25-96-FF-12-34'),
            _MetaLine('Hostname', 'FIN-WS-114.corp.local'),
            _MetaLine('Location', 'Internal LAN – Finance Floor'),
          ],
        );
      }
      if (selected == 'External Hop') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MetaLine('Next Hop IP', '202.56.23.101'),
            _MetaLine('GeoIP Lookup', 'Mumbai, Maharashtra, India'),
            _MetaLine('ISP', 'Public WiFi Hotspot – Cafe near office'),
          ],
        );
      }
    }

    if (type == 'chat') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LogLine('Admin', 'Patch deployed successfully.'),
          _LogLine('Ghost', 'I noticed.'),
          _LogLine('Admin', 'You shouldn’t be here.'),
          _LogLine('Ghost', 'You left a door open.'),
          _LogLine('Admin', 'Who are you?'),
          _LogLine('Ghost', 'Just a shadow.'),
          _LogLine('Ghost', 'Check your finance workstation.'),
          _LogLine('Ankita E', 'Can you send me the Q3 forecast \n again?'),
          _LogLine('Admin', 'Sent to your internal mail.'),
          _LogLine(
              'Ghost', 'For the next phase, transfer \n to offshore account.'),
        ],
      );
    }
    return const Text(
      'Detailed content not available for this selection.\nUse "Unlock Hidden Clue" for deeper insights.',
      style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
    );
  }

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border.all(color: AppShell.neonCyan, width: 2)),
    child: child,
  );
}

class _LogLine extends StatelessWidget {
  final String left;
  final String right;

  const _LogLine(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(color: Colors.white)),
          Text(right, style: TextStyle(color: AppShell.neonCyan.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: AppShell.neonCyan)),
        ],
      ),
    );
  }
}