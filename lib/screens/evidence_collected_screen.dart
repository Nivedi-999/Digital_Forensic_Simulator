// lib/screens/evidences_collected_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../widgets/main_scaffold.dart';
import '../services/evidence_collector.dart';

class EvidencesCollectedScreen extends StatefulWidget {
  const EvidencesCollectedScreen({super.key});

  @override
  State<EvidencesCollectedScreen> createState() => _EvidencesCollectedScreenState();
}

class _EvidencesCollectedScreenState extends State<EvidencesCollectedScreen> {
  @override
  Widget build(BuildContext context) {
    final collected = EvidenceCollector().collected;

    return MainScaffold(
      title: 'Collected Evidence',
      showBack: true,
      currentIndex: 1,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relevant Evidence (${collected.length})',
              style: TextStyle(
                fontFamily: 'DotMatrix',
                fontSize: 24,
                color: AppShell.neonCyan,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: collected.isEmpty
                  ? Center(
                child: Text(
                  'No evidence marked as relevant yet.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: collected.length,
                itemBuilder: (context, index) {
                  final item = collected[index];
                  return Card(
                    color: Colors.black.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppShell.neonCyan.withOpacity(0.4)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        '${item['category']?.toUpperCase()}: ${item['item']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Added: ${item['addedAt']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Remove this evidence',
                        onPressed: () {
                          // Remove this specific item
                          EvidenceCollector().removeEvidence(
                            item['category']!,
                            item['item']!,
                          );

                          // Rebuild the screen to show updated list
                          setState(() {});

                          // Optional feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Evidence removed'),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}