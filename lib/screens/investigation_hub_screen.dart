import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../case_data/ghosttrace_case_data.dart';

class InvestigationHubScreen extends StatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  State<InvestigationHubScreen> createState() => _InvestigationHubScreenState();
}

class _InvestigationHubScreenState extends State<InvestigationHubScreen> {
  final TextEditingController _solutionController = TextEditingController();
  bool _unlocked = false;
  String? _feedback;

  String _activeFeed = 'chat';

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseData = ghostTraceCase;

    return AppShell(
      title: 'Investigation Hub',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 40),

          Text(
            'Case #${caseData.caseId} • Status: ${caseData.status} • Time: ${caseData.duration}',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),

          const SizedBox(height: 30),

          _sectionTitle('Evidence Feed'),
          _panel(
            child: Wrap(
              spacing: 12,
              children: [
                _feedButton('Chat Logs', 'chat'),
                _feedButton('Files', 'files'),
                _feedButton('Metadata', 'meta'),
                _feedButton('IP Traces', 'ip'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle('Evidence Viewer'),
          _panel(child: _buildEvidenceContent()),

          const SizedBox(height: 30),

          _sectionTitle('Encrypted Attachment'),
          _panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cipher: ${caseData.attachmentPuzzle.cipherText}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(caseData.attachmentPuzzle.hint,
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 16),
              TextField(
                controller: _solutionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter decrypted phrase',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppShell.neonCyan),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _unlocked ? null : () => _checkSolution(caseData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppShell.neonCyan,
                  foregroundColor: Colors.black,
                ),
                child: Text(_unlocked ? 'Unlocked' : 'Decrypt'),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                Text(_feedback!,
                    style: TextStyle(
                        color:
                        _unlocked ? Colors.greenAccent : Colors.redAccent)),
              ]
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _feedButton(String label, String key) {
    return OutlinedButton(
      onPressed: () => setState(() => _activeFeed = key),
      style: OutlinedButton.styleFrom(
        foregroundColor: _activeFeed == key ? Colors.black : AppShell.neonCyan,
        backgroundColor:
        _activeFeed == key ? AppShell.neonCyan : Colors.transparent,
        side: const BorderSide(color: AppShell.neonCyan),
      ),
      child: Text(label),
    );
  }

  Widget _buildEvidenceContent() {
    switch (_activeFeed) {
      case 'chat':
        return Column(children: const [
          _LogLine('Admin', 'Patch deployed successfully.'),
          _LogLine('Ghost', 'I noticed.'),
          _LogLine('Admin', 'You shouldn’t be here.'),
          _LogLine('Ghost', 'You left a door open.'),
          _LogLine('Admin', 'Who are you?'),
          _LogLine('Ghost', 'Just a shadow.'),
          _LogLine('Ghost', 'Check your finance workstation.'),
        ]);

      case 'files':
        return Column(children: const [
          _LogLine('finance_report_q3.pdf', '12 MB'),
          _LogLine('system_patch.exe', '4.2 MB'),
          _LogLine('debug_log.txt', '1.1 MB'),
          _LogLine('cache_dump.bin', '88 MB'),
          _LogLine('Attachment.pdf', 'encrypted'),
        ]);

      case 'meta':
        return Column(children: const [
          _LogLine('Device', 'FIN-WS-114'),
          _LogLine('OS', 'Windows 11 Pro'),
          _LogLine('Hash', 'd41d8cd98f00b204e9800998ecf8427e'),
          _LogLine('Timestamp', '02:14 AM'),
          _LogLine('Session', 'Signed Update Package'),
        ]);

      case 'ip':
        return Column(children: const [
          _LogLine('Origin', '172.16.44.21'),
          _LogLine('VPN Hop', '185.193.127.44'),
          _LogLine('Proxy', 'TOR Exit Node'),
          _LogLine('Geo', 'Romania → Iceland'),
          _LogLine('ISP Mask', 'Yes'),
        ]);

      default:
        return const SizedBox();
    }
  }

  void _checkSolution(CaseData caseData) {
    final attempt = _solutionController.text.trim().toLowerCase();
    final expected = caseData.attachmentPuzzle.solution.toLowerCase();
    setState(() {
      if (attempt == expected) {
        _unlocked = true;
        _feedback = 'Decryption successful. Filename revealed.';
      } else {
        _feedback = 'Decryption failed. Try shifting each letter by -3.';
      }
    });
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontFamily: 'DotMatrix',
      fontSize: 22,
      color: AppShell.neonCyan,
    ),
  );

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration:
    BoxDecoration(border: Border.all(color: AppShell.neonCyan, width: 2)),
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
          Text(right,
              style:
              TextStyle(color: AppShell.neonCyan.withOpacity(0.8))),
        ],
      ),
    );
  }
}
