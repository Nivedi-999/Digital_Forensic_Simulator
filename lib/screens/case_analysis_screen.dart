// lib/screens/case_analysis_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CASE ANALYSIS — shows the player exactly which evidence
//  they marked was correct vs incorrect, with explanations.
//  Accessible from the Case Outcome screen for all outcomes.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';

// ── Data class for one row in the analysis list ───────────────

class _EvidenceAnalysisRow {
  final String itemId;
  final String panelId;
  final String label;
  final bool isCorrect;
  /// For correct items: why it mattered.
  /// For incorrect items: why it was irrelevant.
  final String explanation;
  final String panelLabel;

  const _EvidenceAnalysisRow({
    required this.itemId,
    required this.panelId,
    required this.label,
    required this.isCorrect,
    required this.explanation,
    required this.panelLabel,
  });
}

// ── Screen ────────────────────────────────────────────────────

class CaseAnalysisScreen extends StatefulWidget {
  const CaseAnalysisScreen({super.key});

  @override
  State<CaseAnalysisScreen> createState() => _CaseAnalysisScreenState();
}

class _CaseAnalysisScreenState extends State<CaseAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeIn;

  // Filter: 'all' | 'correct' | 'wrong'
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Build the analysis rows from engine state ─────────────

  List<_EvidenceAnalysisRow> _buildRows(CaseEngine engine) {
    final rows = <_EvidenceAnalysisRow>[];

    for (final collected in engine.collectedEvidence) {
      final isCorrect =
      engine.caseFile.correctEvidenceIds.contains(collected.itemId);

      // Find the EvidenceItem object so we can get detail / irrelevantReason
      EvidenceItem? item;
      String panelLabel = collected.panelId;

      for (final panel in engine.caseFile.evidencePanels) {
        if (panel.id == collected.panelId) {
          panelLabel = panel.label;
          // Check regular items
          for (final i in panel.items) {
            if (i.id == collected.itemId) {
              item = i;
              break;
            }
          }
          // Check hidden item
          if (item == null && panel.hiddenItem?.id == collected.itemId) {
            item = panel.hiddenItem;
          }
          break;
        }
      }

      final String explanation;
      if (item == null) {
        explanation = isCorrect
            ? 'This evidence contributed to the case.'
            : 'This evidence was not relevant to solving the case.';
      } else if (isCorrect) {
        // Use the detail field as the "why it matters" explanation
        explanation = item.detail;
      } else {
        explanation = item.irrelevantReason != null
            ? item.irrelevantReason!
            : item.detail.isNotEmpty
            ? item.detail
            : 'This item did not contribute to identifying the culprit.';
      }

      rows.add(_EvidenceAnalysisRow(
        itemId: collected.itemId,
        panelId: collected.panelId,
        label: collected.label,
        isCorrect: isCorrect,
        explanation: explanation,
        panelLabel: panelLabel,
      ));
    }

    // Sort: correct first, then wrong
    rows.sort((a, b) {
      if (a.isCorrect && !b.isCorrect) return -1;
      if (!a.isCorrect && b.isCorrect) return 1;
      return 0;
    });

    return rows;
  }

  List<_EvidenceAnalysisRow> _filtered(List<_EvidenceAnalysisRow> all) {
    if (_filter == 'correct') return all.where((r) => r.isCorrect).toList();
    if (_filter == 'wrong') return all.where((r) => !r.isCorrect).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final allRows = _buildRows(engine);
    final displayed = _filtered(allRows);

    final correctCount = allRows.where((r) => r.isCorrect).length;
    final wrongCount = allRows.where((r) => !r.isCorrect).length;
    final totalMarked = allRows.length;
    final outcomeType = engine.outcomeType ?? OutcomeType.coldCase;
    final isWin = outcomeType == OutcomeType.perfect;

    return AppShell(
      title: 'Case Analysis',
      showBack: true,
      showBottomNav: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Summary banner ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: NeonContainer(
                borderColor:
                isWin ? CyberColors.neonGreen : CyberColors.neonAmber,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        isWin
                            ? Icons.analytics_outlined
                            : Icons.manage_search_outlined,
                        color: isWin
                            ? CyberColors.neonGreen
                            : CyberColors.neonAmber,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Evidence Review',
                        style: CyberText.sectionTitle.copyWith(
                          color: isWin
                              ? CyberColors.neonGreen
                              : CyberColors.neonAmber,
                          fontSize: 16,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    // Score bar
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: CyberRadius.pill,
                          child: LinearProgressIndicator(
                            value: totalMarked == 0
                                ? 0
                                : correctCount / totalMarked,
                            backgroundColor:
                            CyberColors.neonRed.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(
                                CyberColors.neonGreen),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$correctCount / $totalMarked correct',
                        style: CyberText.bodySmall.copyWith(
                          color: CyberColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Stat chips
                    Row(children: [
                      _StatChip(
                        label: '$correctCount Relevant',
                        color: CyberColors.neonGreen,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: '$wrongCount Irrelevant',
                        color: CyberColors.neonRed,
                        icon: Icons.cancel_outlined,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: '$totalMarked Total',
                        color: CyberColors.neonCyan,
                        icon: Icons.folder_outlined,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Filter tabs ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _FilterTab(
                  label: 'All ($totalMarked)',
                  isActive: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Relevant ($correctCount)',
                  isActive: _filter == 'correct',
                  color: CyberColors.neonGreen,
                  onTap: () => setState(() => _filter = 'correct'),
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Irrelevant ($wrongCount)',
                  isActive: _filter == 'wrong',
                  color: CyberColors.neonRed,
                  onTap: () => setState(() => _filter = 'wrong'),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Evidence list ────────────────────────────────
            Expanded(
              child: displayed.isEmpty
                  ? _EmptyFilterState(filter: _filter)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: displayed.length,
                itemBuilder: (context, index) {
                  return _EvidenceCard(
                    row: displayed[index],
                    index: index,
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

// ── Evidence Card ─────────────────────────────────────────────

class _EvidenceCard extends StatefulWidget {
  final _EvidenceAnalysisRow row;
  final int index;

  const _EvidenceCard({required this.row, required this.index});

  @override
  State<_EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<_EvidenceCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  IconData _panelIcon(String panelId) {
    switch (panelId) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'files':
        return Icons.folder_outlined;
      case 'meta':
        return Icons.data_object;
      case 'ip':
        return Icons.wifi;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final accentColor =
    row.isCorrect ? CyberColors.neonGreen : CyberColors.neonRed;
    final statusIcon =
    row.isCorrect ? Icons.check_circle : Icons.cancel;
    final statusLabel = row.isCorrect ? 'RELEVANT' : 'IRRELEVANT';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeonContainer(
        borderColor: accentColor,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────
            InkWell(
              onTap: _toggle,
              borderRadius: CyberRadius.medium,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  // Panel type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                          color: accentColor.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(_panelIcon(row.panelId),
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Label + panel tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: CyberText.bodySmall.copyWith(
                            color: CyberColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: CyberColors.neonCyan.withOpacity(0.08),
                              borderRadius: CyberRadius.pill,
                              border: Border.all(
                                  color:
                                  CyberColors.neonCyan.withOpacity(0.3),
                                  width: 1),
                            ),
                            child: Text(
                              row.panelLabel.toUpperCase(),
                              style: const TextStyle(
                                color: CyberColors.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status badge + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        Icon(statusIcon, color: accentColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: CyberColors.textMuted,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),

            // ── Expandable explanation ───────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: accentColor.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // "Why" header
                    Row(children: [
                      Icon(
                        row.isCorrect
                            ? Icons.lightbulb_outline
                            : Icons.info_outline,
                        color: accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        row.isCorrect
                            ? 'Why this mattered'
                            : 'Why this was irrelevant',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.05),
                        borderRadius: CyberRadius.small,
                        border: Border.all(
                            color: accentColor.withOpacity(0.15), width: 1),
                      ),
                      child: Text(
                        row.explanation,
                        style: TextStyle(
                          color: CyberColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: CyberRadius.pill,
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ]),
    );
  }
}

// ── Filter Tab ────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    this.color = CyberColors.neonCyan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.14) : Colors.transparent,
          borderRadius: CyberRadius.pill,
          border: Border.all(
            color: isActive ? color : CyberColors.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : CyberColors.textMuted,
            fontSize: 12,
            fontWeight:
            isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Empty filter state ────────────────────────────────────────

class _EmptyFilterState extends StatelessWidget {
  final String filter;
  const _EmptyFilterState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = filter == 'correct'
        ? 'None of your marked evidence was correct.'
        : filter == 'wrong'
        ? 'All your marked evidence was correct!'
        : 'No evidence was marked during this investigation.';

    final icon = filter == 'correct'
        ? Icons.search_off
        : filter == 'wrong'
        ? Icons.verified_outlined
        : Icons.folder_open_outlined;

    final color = filter == 'wrong'
        ? CyberColors.neonGreen
        : CyberColors.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 52),
            const SizedBox(height: 16),
            Text(
              message,
              style: CyberText.bodySmall.copyWith(
                height: 1.6,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}