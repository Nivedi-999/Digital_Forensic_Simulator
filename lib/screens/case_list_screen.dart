// lib/screens/case_list_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CASE LIST SCREEN
//  Dynamically loads all 20 cases from CaseRepository.
//  Preserves all existing widget usage from the original screen.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../services/case_repository.dart';
import 'case_story_screen.dart';

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  bool _loading = true;
  List<CaseFile> _cases = [];
  String _activeFilter = 'all'; // 'all' | 'easy' | 'medium' | 'hard' | 'advanced'

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    await CaseRepository.instance.loadAll();
    if (mounted) {
      setState(() {
        _cases = CaseRepository.instance.all;
        _loading = false;
      });
    }
  }

  List<CaseFile> get _filtered {
    if (_activeFilter == 'all') return _cases;
    return _cases
        .where((c) => c.difficulty.toLowerCase() == _activeFilter)
        .toList();
  }

  // Count how many cases exist per difficulty (for filter tab badges)
  int _countFor(String diff) => diff == 'all'
      ? _cases.length
      : _cases.where((c) => c.difficulty.toLowerCase() == diff).length;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Case Files',
      showBack: true,
      child: _loading
          ? const Center(
        child: CircularProgressIndicator(color: CyberColors.neonCyan),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: CyberSectionHeader(
              title: 'Case Files',
              subtitle: 'Select a case to begin investigation',
            ),
          ),

          // ── Difficulty filter tabs ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: 'All',
                    count: _countFor('all'),
                    value: 'all',
                    active: _activeFilter,
                    color: CyberColors.neonCyan,
                    onTap: (v) => setState(() => _activeFilter = v),
                  ),
                  _FilterTab(
                    label: 'Easy',
                    count: _countFor('easy'),
                    value: 'easy',
                    active: _activeFilter,
                    color: CyberColors.neonGreen,
                    onTap: (v) => setState(() => _activeFilter = v),
                  ),
                  _FilterTab(
                    label: 'Medium',
                    count: _countFor('medium'),
                    value: 'medium',
                    active: _activeFilter,
                    color: CyberColors.neonAmber,
                    onTap: (v) => setState(() => _activeFilter = v),
                  ),
                  _FilterTab(
                    label: 'Hard',
                    count: _countFor('hard'),
                    value: 'hard',
                    active: _activeFilter,
                    color: CyberColors.neonRed,
                    onTap: (v) => setState(() => _activeFilter = v),
                  ),
                  _FilterTab(
                    label: 'Advanced',
                    count: _countFor('advanced'),
                    value: 'advanced',
                    active: _activeFilter,
                    color: CyberColors.neonPurple,
                    onTap: (v) => setState(() => _activeFilter = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Case list ───────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                final isAvailable =
                    c.status.toLowerCase() == 'active';
                return _CaseCard(
                  caseFile: c,
                  isAvailable: isAvailable,
                  onTap: isAvailable
                      ? () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          StorylineScreen(caseId: c.id),
                      transitionsBuilder:
                          (_, anim, __, child) =>
                          FadeTransition(
                              opacity: anim, child: child),
                      transitionDuration:
                      const Duration(milliseconds: 350),
                    ),
                  )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Filter Tab
// ═══════════════════════════════════════════════════════════════

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final String value;
  final String active;
  final Color color;
  final ValueChanged<String> onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.value,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color:
            isActive ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: CyberRadius.pill,
            border: Border.all(
              color: isActive ? color : CyberColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : CyberColors.textMuted,
                  fontSize: 12,
                  fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withOpacity(0.25)
                      : CyberColors.borderSubtle.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? color : CyberColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Case Card  (matches original _CaseCard structure exactly)
// ═══════════════════════════════════════════════════════════════

class _CaseCard extends StatefulWidget {
  final CaseFile caseFile;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _CaseCard({
    required this.caseFile,
    required this.isAvailable,
    this.onTap,
  });

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _expanded = false;

  Color get _diffColor {
    switch (widget.caseFile.difficulty.toLowerCase()) {
      case 'easy':     return CyberColors.neonGreen;
      case 'medium':   return CyberColors.neonAmber;
      case 'hard':     return CyberColors.neonRed;
      case 'advanced': return CyberColors.neonPurple;
      default:         return CyberColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseFile;
    final borderColor = widget.isAvailable
        ? CyberColors.neonCyan
        : CyberColors.borderSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeonContainer(
        borderColor: borderColor,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // ── Header row ──────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: CyberRadius.medium,
                onTap: widget.isAvailable
                    ? () => widget.onTap?.call()
                    : () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Case icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: CyberRadius.small,
                          border: Border.all(
                              color: borderColor.withOpacity(0.4),
                              width: 1),
                        ),
                        child: Icon(
                          widget.isAvailable
                              ? Icons.folder_open_outlined
                              : Icons.lock_outline,
                          color: borderColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title + theme
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              style: TextStyle(
                                fontFamily: 'DotMatrix',
                                fontSize: 15,
                                color: widget.isAvailable
                                    ? CyberColors.neonCyan
                                    : CyberColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.theme,
                              style: CyberText.bodySmall
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Status chip + chevron
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusChip(
                            label: c.status.toUpperCase(),
                            color: widget.isAvailable
                                ? CyberColors.neonGreen
                                : CyberColors.textMuted,
                            pulsing: widget.isAvailable,
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: CyberColors.textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Expanded detail ──────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Container(
                width: double.infinity,
                padding:
                const EdgeInsets.fromLTRB(18, 0, 18, 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: borderColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Difficulty badge
                    Row(
                      children: [
                        const Text(
                          'Difficulty:  ',
                          style: TextStyle(
                            color: CyberColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                            _diffColor.withOpacity(0.12),
                            borderRadius: CyberRadius.pill,
                            border: Border.all(
                              color: _diffColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            c.difficulty.toUpperCase(),
                            style: TextStyle(
                              color: _diffColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Case number + duration
                    Text(
                      'Case #${c.caseNumber}  •  ${c.estimatedDuration}',
                      style: CyberText.bodySmall
                          .copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 6),

                    // Short description
                    Text(
                      c.shortDescription,
                      style: CyberText.bodySmall
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 6),

                    // Suspect + panel count
                    Text(
                      '${c.suspects.length} suspects  •  ${c.evidencePanels.length} evidence panels',
                      style: CyberText.bodySmall
                          .copyWith(fontSize: 11),
                    ),

                    // Theme line
                    const SizedBox(height: 4),
                    Text(
                      'Theme: ${c.theme}',
                      style: CyberText.bodySmall
                          .copyWith(fontSize: 12),
                    ),

                    if (widget.isAvailable) ...[
                      const SizedBox(height: 14),
                      CyberButton(
                        label: 'Begin Investigation',
                        icon: Icons.play_arrow_outlined,
                        isSmall: true,
                        onTap: () => widget.onTap?.call(),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'Complete earlier cases to unlock.',
                        style: CyberText.bodySmall.copyWith(
                            fontSize: 11,
                            color: CyberColors.textMuted),
                      ),
                    ],
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}