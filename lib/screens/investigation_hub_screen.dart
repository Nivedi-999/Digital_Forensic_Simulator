// lib/screens/investigation_hub_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../case_data/ghosttrace_case_data.dart';
import 'evidence_analysis_screen.dart';
import 'suspect_profile_screen.dart';
import '../widgets/main_scaffold.dart';

class InvestigationHubScreen extends StatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  State<InvestigationHubScreen> createState() => _InvestigationHubScreenState();
}

class _InvestigationHubScreenState extends State<InvestigationHubScreen> {
  String _activeFeed = 'chat';

  void _openAnalysis(String category, String selectedItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceAnalysisScreen(
          evidenceType: category,
          selectedItem: selectedItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Widget _timelineEvent(TimelineEvent event) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppShell.neonCyan.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(6),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 80,
              child: Text(
                event.time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppShell.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }


    final caseData = ghostTraceCase;

    return MainScaffold(
        title: 'Investigation Hub',
        showBack: true,
        currentIndex: 0, // or 1 if you want Evidences highlighted
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Case #${caseData.caseId} • Status: ${caseData.status} • Time: ${caseData.duration}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 35),
                _sectionTitle('Evidence Feed'),
                _panel(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      _feedButton('Chat Logs', 'chat'),
                      _feedButton('Files', 'files'),
                      _feedButton('Metadata', 'meta'),
                      _feedButton('IP Traces', 'ip'),
                      _feedButton('Suspects', 'suspects'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Evidence Viewer'),
                _panel(
                  child: SizedBox(
                    height: 100,
                    child: SingleChildScrollView(child: _buildEvidenceContent()),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionTitle('Timeline View'),
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: caseData.timeline.map((event) {
                      return _timelineEvent(event);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        )
    );
  }

  Widget _feedButton(String label, String key) {
    return OutlinedButton(
      onPressed: () => setState(() => _activeFeed = key),
      style: OutlinedButton.styleFrom(
        foregroundColor: _activeFeed == key ? Colors.black : AppShell.neonCyan,
        backgroundColor: _activeFeed == key ? AppShell.neonCyan : Colors.transparent,
        side: const BorderSide(color: AppShell.neonCyan),
      ),
      child: Text(label),
    );
  }

  Widget _buildEvidenceContent() {
    switch (_activeFeed) {
      case 'chat':
        return Column(
          children: [
            _ClickableLogLine(left: 'Admin', right: 'Patch deployed successfully.', onTap: () {
              _openAnalysis('chat', 'Patch deployed successfully.');
            }),
            _ClickableLogLine(left: 'Ghost', right: 'I noticed.', onTap: () => _openAnalysis('chat', 'I noticed.')),
            _ClickableLogLine(left: 'Ghost', right: 'Check your finance account.', onTap: () => _openAnalysis('chat', 'Check your finance workstation.')),
          ],
        );

      case 'files':
        return Column(
          children: [
            _ClickableLogLine(left: 'finance_report_q3.pdf', right: '12 MB', onTap: () => _openAnalysis('files', 'finance_report_q3.pdf')),
            _ClickableLogLine(left: 'system_patch.exe', right: '4.2 MB', onTap: () => _openAnalysis('files', 'system_patch.exe')),
            _ClickableLogLine(left: 'debug_log.txt', right: '1.1 MB', onTap: () => _openAnalysis('files', 'debug_log.txt')),
            _ClickableLogLine(left: 'cache_dump.bin', right: '88 MB', onTap: () => _openAnalysis('files', 'cache_dump.bin')),
            if (GameProgress.isBriefingUnlocked)
              _ClickableLogLine(
                left: 'ghosttrace_briefing.pdf',
                right: 'Unlocked Briefing',
                onTap: () => _openAnalysis('files', 'ghosttrace_briefing.pdf'),
              ),
          ],
        );

      case 'meta':
        return Column(
          children: [
            _ClickableLogLine(left: 'Device', right: 'FIN-WS-114', onTap: () => _openAnalysis('meta', 'Device')),
            _ClickableLogLine(left: 'OS', right: 'Windows 11 Pro', onTap: () => _openAnalysis('meta', 'OS')),
            _ClickableLogLine(left: 'Last User', right: 'Ankita E @ 09:15 AM', onTap: () => _openAnalysis('meta', 'Last User')),
          ],
        );

      case 'ip':
        return Column(
          children: [
            _ClickableLogLine(left: 'Internal Origin', right: '172.16.44.21', onTap: () => _openAnalysis('ip', 'Internal Origin')),
            _ClickableLogLine(left: 'External Hop', right: '202.56.23.101', onTap: () => _openAnalysis('ip', 'External Hop')),
          ],
        );

      case 'suspects':
        return Column(
          children: ghostTraceCase.suspects.map((suspect) {
            Color color;
            switch (suspect.riskLevel.toLowerCase()) {
              case 'high':
                color = Colors.redAccent;
                break;
              case 'medium':
                color = Colors.orangeAccent;
                break;
              default:
                color = Colors.greenAccent;
            }
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuspectProfileScreen(suspect: suspect),
                  ),
                );
              },
              child: _SuspectRow(suspect.name, suspect.risk, color),
            );
          }).toList(),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontFamily: 'DotMatrix', fontSize: 22, color: AppShell.neonCyan),
  );

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border.all(color: AppShell.neonCyan, width: 2)),
    child: child,
  );
}

class _ClickableLogLine extends StatelessWidget {
  final String left;
  final String right;
  final VoidCallback onTap;

  const _ClickableLogLine({required this.left, required this.right, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left, style: const TextStyle(color: Colors.white)),
            Text(right, style: TextStyle(color: AppShell.neonCyan.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
class _SuspectRow extends StatelessWidget {
  final String name;
  final String risk;
  final Color color;

  const _SuspectRow(this.name, this.risk, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white))),
          Text(
            risk,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}