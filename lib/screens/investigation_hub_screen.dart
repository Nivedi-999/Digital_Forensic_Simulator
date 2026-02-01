import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../case_data/ghosttrace_case_data.dart';

class InvestigationHubScreen extends StatelessWidget {
  const InvestigationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caseData = ghostTraceCase;

    return AppShell(
      title: 'Investigation Hub',
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

            const SizedBox(height: 30),

            _sectionTitle('Evidence Feed'),
            _panel(
              child: Column(
                children: caseData.evidenceFeed
                    .map((e) => _feedItem(e.label, e.count))
                    .toList(),
              ),
            ),

            const SizedBox(height: 30),

            _sectionTitle('Actual Evidence Preview'),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseData.preview.message,
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'IP: ${caseData.preview.ip}\n${caseData.preview.time}',
                    style: const TextStyle(color: Colors.yellowAccent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _sectionTitle('Suspects'),
            _panel(
              child: Column(
                children: caseData.suspects
                    .map((s) => _suspectTile(
                  s.name,
                  s.risk,
                  _riskColor(s.riskLevel),
                ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 30),

            _sectionTitle('Digital Footprint Timeline'),
            _panel(
              child: Column(
                children: caseData.timeline
                    .map((t) =>
                    _timelineItem(t.time, t.title, t.description))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case "high":
        return Colors.redAccent;
      case "medium":
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
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
    decoration: BoxDecoration(
      border: Border.all(color: AppShell.neonCyan, width: 2),
    ),
    child: child,
  );
}

Widget _feedItem(String label, int count) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white)),
      Text(count.toString(),
          style: TextStyle(color: AppShell.neonCyan.withOpacity(0.8))),
    ],
  ),
);

Widget _suspectTile(String name, String risk, Color color) => ListTile(
  title: Text(name, style: const TextStyle(color: Colors.white)),
  trailing: Text(risk, style: TextStyle(color: color)),
);

Widget _timelineItem(String time, String title, String description) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$time • $title',
          style: const TextStyle(color: Colors.white)),
      Text(description,
          style: TextStyle(color: Colors.white.withOpacity(0.6))),
    ],
  ),
);
