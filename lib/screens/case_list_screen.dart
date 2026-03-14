// lib/screens/case_list_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/case.dart';
import '../services/case_repository.dart';
import '../services/game_progress.dart';
import 'case_story_screen.dart';

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  bool _loading = true;
  List<CaseFile> _cases = [];
  String _activeFilter = 'all';

  // Ordered IDs per tier — used by GameProgress.isCaseUnlocked()
  final Map<String, List<String>> _tierOrder = {};

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    await CaseRepository.instance.loadAll();
    if (mounted) {
      final all = CaseRepository.instance.all;
      // Build tier order maps
      for (final diff in ['easy', 'medium', 'hard', 'advanced']) {
        _tierOrder[diff] = all
            .where((c) => c.difficulty.toLowerCase() == diff)
            .map((c) => c.id)
            .toList();
      }
      setState(() {
        _cases = all;
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

  bool _isUnlocked(CaseFile c) {
    final tier = _tierOrder[c.difficulty.toLowerCase()] ?? [];
    return GameProgress.isCaseUnlocked(c.id, tier);
  }

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
          child: CircularProgressIndicator(color: CyberColors.neonCyan))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: CyberSectionHeader(
              title: 'Case Files',
              subtitle: 'Select a case to begin investigation',
            ),
          ),

          // ── Filter tabs ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterTab(label: 'All',      count: _countFor('all'),      value: 'all',      active: _activeFilter, color: CyberColors.neonCyan,   onTap: (v) => setState(() => _activeFilter = v)),
                _FilterTab(label: 'Easy',     count: _countFor('easy'),     value: 'easy',     active: _activeFilter, color: CyberColors.neonGreen,  onTap: (v) => setState(() => _activeFilter = v)),
                _FilterTab(label: 'Medium',   count: _countFor('medium'),   value: 'medium',   active: _activeFilter, color: CyberColors.neonAmber,  onTap: (v) => setState(() => _activeFilter = v)),
                _FilterTab(label: 'Hard',     count: _countFor('hard'),     value: 'hard',     active: _activeFilter, color: CyberColors.neonRed,    onTap: (v) => setState(() => _activeFilter = v)),
                _FilterTab(label: 'Advanced', count: _countFor('advanced'), value: 'advanced', active: _activeFilter, color: CyberColors.neonPurple, onTap: (v) => setState(() => _activeFilter = v)),
              ]),
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
                final unlocked = _isUnlocked(c);
                final completed = GameProgress.isCaseCompleted(c.id);
                return _CaseCard(
                  caseFile: c,
                  isUnlocked: unlocked,
                  isCompleted: completed,
                  onTap: unlocked
                      ? () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          StorylineScreen(caseId: c.id),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(
                              opacity: anim, child: child),
                      transitionDuration:
                      const Duration(milliseconds: 350),
                    ),
                  ).then((_) => setState(() {})) // refresh on return
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

// ── Filter Tab ────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: CyberRadius.pill,
            border: Border.all(
              color: isActive ? color : CyberColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                    color: isActive ? color : CyberColors.textMuted,
                    fontSize: 12,
                    fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.4,
                  )),
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
                child: Text('$count',
                    style: TextStyle(
                      color: isActive ? color : CyberColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Case Card ─────────────────────────────────────────────────

class _CaseCard extends StatefulWidget {
  final CaseFile caseFile;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _CaseCard({
    required this.caseFile,
    required this.isUnlocked,
    required this.isCompleted,
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

  Color get _borderColor {
    if (widget.isCompleted) return CyberColors.neonGreen;
    if (widget.isUnlocked)  return CyberColors.neonCyan;
    return CyberColors.borderSubtle;
  }

  String get _statusLabel {
    if (widget.isCompleted) return 'SOLVED';
    if (widget.isUnlocked)  return 'ACTIVE';
    return 'LOCKED';
  }

  Color get _statusColor {
    if (widget.isCompleted) return CyberColors.neonGreen;
    if (widget.isUnlocked)  return CyberColors.neonCyan;
    return CyberColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseFile;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeonContainer(
        borderColor: _borderColor,
        padding: EdgeInsets.zero,
        child: Column(children: [

          // ── Header ──────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: CyberRadius.medium,
              onTap: widget.isUnlocked
                  ? () => widget.onTap?.call()
                  : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [

                  // Icon box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _borderColor.withOpacity(0.1),
                      borderRadius: CyberRadius.small,
                      border: Border.all(
                          color: _borderColor.withOpacity(0.4), width: 1),
                    ),
                    child: Icon(
                      widget.isCompleted
                          ? Icons.check_circle_outline
                          : widget.isUnlocked
                          ? Icons.folder_open_outlined
                          : Icons.lock_outline,
                      color: _borderColor,
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
                            color: widget.isUnlocked
                                ? (widget.isCompleted
                                ? CyberColors.neonGreen
                                : CyberColors.neonCyan)
                                : CyberColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(c.theme,
                            style: CyberText.bodySmall.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),

                  // Status + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(
                        label: _statusLabel,
                        color: _statusColor,
                        pulsing: widget.isUnlocked && !widget.isCompleted,
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
                ]),
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: _borderColor.withOpacity(0.3), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // Difficulty badge
                  Row(children: [
                    const Text('Difficulty:  ',
                        style: TextStyle(
                            color: CyberColors.textSecondary,
                            fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _diffColor.withOpacity(0.12),
                        borderRadius: CyberRadius.pill,
                        border: Border.all(
                            color: _diffColor.withOpacity(0.4),
                            width: 1),
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
                  ]),
                  const SizedBox(height: 8),

                  Text('Case #${c.caseNumber}  •  ${c.estimatedDuration}',
                      style: CyberText.bodySmall.copyWith(fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(c.shortDescription,
                      style: CyberText.bodySmall.copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '${c.suspects.length} suspects  •  ${c.evidencePanels.length} evidence panels',
                    style: CyberText.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text('Theme: ${c.theme}',
                      style: CyberText.bodySmall.copyWith(fontSize: 12)),

                  if (c.timeLimitSeconds != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.timer_outlined,
                          color: CyberColors.neonRed, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Timed: ${_formatLimit(c.timeLimitSeconds!)}',
                        style: const TextStyle(
                          color: CyberColors.neonRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ],

                  if (widget.isUnlocked) ...[
                    const SizedBox(height: 14),
                    CyberButton(
                      label: widget.isCompleted
                          ? 'Replay Case'
                          : 'Begin Investigation',
                      icon: widget.isCompleted
                          ? Icons.replay_outlined
                          : Icons.play_arrow_outlined,
                      isSmall: true,
                      onTap: () => widget.onTap?.call(),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      'Complete the previous case to unlock.',
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
        ]),
      ),
    );
  }

  String _formatLimit(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }
}