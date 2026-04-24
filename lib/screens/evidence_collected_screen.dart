// lib/screens/evidence_collected_screen.dart
// ═══════════════════════════════════════════════════════════════
//  EVIDENCE LOCKER — reads from CaseEngine (not old EvidenceCollector)
//  This fixes the "evidence not showing" bug: the old screen was
//  reading from the EvidenceCollector singleton which is no longer
//  written to. All evidence is now stored in CaseEngine.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';

class EvidencesCollectedScreen extends StatefulWidget {
  const EvidencesCollectedScreen({super.key});

  @override
  State<EvidencesCollectedScreen> createState() =>
      _EvidencesCollectedScreenState();
}

class _EvidencesCollectedScreenState
    extends State<EvidencesCollectedScreen> {

  IconData _iconForPanel(String panelId) {
    switch (panelId) {
      case 'chat':  return Icons.chat_bubble_outline;
      case 'files': return Icons.folder_outlined;
      case 'meta':  return Icons.data_object;
      case 'ip':    return Icons.wifi;
      default:      return Icons.description_outlined;
    }
  }

  Color _colorForPanel(String panelId) {
    switch (panelId) {
      case 'chat':  return CyberColors.neonBlue;
      case 'files': return CyberColors.neonPurple;
      case 'meta':  return CyberColors.neonAmber;
      case 'ip':    return CyberColors.neonCyan;
      default:      return CyberColors.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read engine from the inherited provider — same engine that
    // InvestigationHubScreen and EvidenceAnalysisScreen write to.
    final engine = CaseEngineProvider.of(context);
    final collected = engine.collectedEvidence;

    return AppShell(
      title: 'Evidence Locker',
      showBack: true,
      currentIndex: 1,
      child: Column(
        children: [
          // ── Header stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: NeonContainer(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(children: [
                const Icon(Icons.folder_outlined,
                    color: CyberColors.neonCyan, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${collected.length} Items Collected',
                      style:
                      CyberText.sectionTitle.copyWith(fontSize: 16),
                    ),
                    Text(engine.caseFile.title,
                        style: CyberText.caption),
                  ],
                ),
                const Spacer(),
                if (collected.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      engine.clearEvidence();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CyberColors.neonRed.withOpacity(0.1),
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                            color: CyberColors.neonRed.withOpacity(0.4),
                            width: 1),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: CyberColors.neonRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: collected.isEmpty
                ? _EmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: collected.length,
              itemBuilder: (context, index) {
                final item = collected[index];
                final color = _colorForPanel(item.panelId);
                final isCorrect = engine.caseFile.correctEvidenceIds
                    .contains(item.itemId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NeonContainer(
                    borderColor: color,
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      // Panel icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                              color: color.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(_iconForPanel(item.panelId),
                            color: color, size: 20),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: CyberText.bodySmall.copyWith(
                                color: CyberColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              Flexible(
                                child: StatusChip(
                                  label: item.panelId.toUpperCase(),
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isCorrect
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                color: isCorrect
                                    ? CyberColors.neonGreen
                                    : CyberColors.textMuted,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.collectedAt.toString().substring(11, 19),
                                  style: CyberText.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),

                      // Remove button
                      GestureDetector(
                        onTap: () {
                          engine.removeEvidence(item.itemId);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Evidence removed'),
                              backgroundColor: CyberColors.neonRed,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CyberColors.neonRed.withOpacity(0.08),
                            borderRadius: CyberRadius.small,
                            border: Border.all(
                              color: CyberColors.neonRed.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: CyberColors.neonRed, size: 18),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
              color: CyberColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No evidence collected yet',
            style:
            CyberText.bodyMedium.copyWith(color: CyberColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Open the Investigation Hub to start marking evidence.',
            style: CyberText.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}