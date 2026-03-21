// lib/screens/evidence_analysis_screen.dart
// ═══════════════════════════════════════════════════════════════
//  EVIDENCE ANALYSIS — fully data-driven via CaseEngine
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';
import '../services/tutorial_service.dart';
import '../widgets/aria_controller.dart';
import 'mini_game.dart';

class EvidenceAnalysisScreen extends StatefulWidget {
  final String panelId;
  final String itemId;

  const EvidenceAnalysisScreen({
    super.key,
    required this.panelId,
    required this.itemId,
  });

  @override
  State<EvidenceAnalysisScreen> createState() =>
      _EvidenceAnalysisScreenState();
}

class _EvidenceAnalysisScreenState extends State<EvidenceAnalysisScreen>
    with AriaMixin {
  @override
  void initState() {
    super.initState();
    triggerAria(TutorialStep.viewEvidence);
  }

  void _handleAddEvidence(BuildContext context) {
    final engine = CaseEngineProvider.read(context);
    engine.collectEvidence(widget.panelId, widget.itemId);
    TutorialService().onEvidenceMarked();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: CyberColors.textOnNeon),
            SizedBox(width: 10),
            Text(
              'Evidence added to collection',
              style: TextStyle(
                color: CyberColors.textOnNeon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: CyberColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
        duration: const Duration(seconds: 2),
      ),
    );

    final service = TutorialService();
    if (service.currentStep == TutorialStep.markEvidence &&
        !service.messageShown) {
      triggerAria(TutorialStep.markEvidence, delayMs: 400);
    }
  }

  String _iconForType(String type) {
    switch (type) {
      case 'chat':
        return 'chat_bubble_outline';
      case 'files':
        return 'folder_outlined';
      case 'meta':
        return 'data_object';
      case 'ip':
        return 'wifi';
      default:
        return 'search';
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'chat':
        return 'Chat Logs';
      case 'files':
        return 'File System';
      case 'meta':
        return 'Metadata Extract';
      case 'ip':
        return 'IP Traces';
      default:
        return 'Evidence';
    }
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      case 'folder_outlined':
        return Icons.folder_outlined;
      case 'data_object':
        return Icons.data_object;
      case 'wifi':
        return Icons.wifi;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final panel = engine.caseFile.panelById(widget.panelId);
    if (panel == null) return const SizedBox();

    // Find the item — check visible items (includes unlocked hidden items)
    final visibleItems = engine.visibleItemsForPanel(widget.panelId);
    EvidenceItem? item;
    try {
      item = visibleItems.firstWhere((i) => i.id == widget.itemId);
    } catch (_) {
      item = null;
    }

    final isAlreadyCollected = engine.isEvidenceCollected(widget.itemId);
    final minigame = panel.minigame;
    final isMinigameSolved =
        minigame != null && engine.isMinigameSolved(minigame.id);

    return AppShell(
      title: 'Evidence Analysis',
      showBack: true,
      showBottomNav: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type header ──
                _TypeHeader(
                  title: _titleForType(panel.evidenceType),
                  icon: _iconData(_iconForType(panel.evidenceType)),
                  selectedLabel: item?.label,
                  caseNumber: engine.caseFile.caseNumber,
                ),

                const SizedBox(height: 20),

                // ── Content panel ──
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: 200, maxHeight: 440),
                    child: SingleChildScrollView(
                      child: item != null
                          ? _EvidenceContent(item: item, panel: panel)
                          : _EmptyContent(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Unlock Hidden Clue button ──
                if (minigame != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: isMinigameSolved
                        ? _AlreadyUnlockedBanner(
                        message: minigame.successMessage ??
                            'Hidden clue unlocked.')
                        : CyberButton(
                      label: minigame.title,
                      icon: Icons.lock_open_outlined,
                      accentColor: CyberColors.neonPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DecryptionMiniGameScreen(
                              panelId: widget.panelId,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Mark as Evidence ──
                SizedBox(
                  width: double.infinity,
                  child: isAlreadyCollected
                      ? _AlreadyMarkedBanner()
                      : CyberButton(
                    label: 'Mark as Evidence',
                    icon: Icons.add_circle_outline,
                    accentColor: CyberColors.neonGreen,
                    onTap: () => _handleAddEvidence(context),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          buildAriaLayer(),
        ],
      ),
    );
  }
}

// ── Type Header ──────────────────────────────────────────────

class _TypeHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? selectedLabel;
  final String caseNumber;

  const _TypeHeader({
    required this.title,
    required this.icon,
    this.selectedLabel,
    required this.caseNumber,
  });

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      borderColor: CyberColors.neonPurple,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CyberColors.neonPurple.withOpacity(0.12),
              borderRadius: CyberRadius.small,
              border: Border.all(
                  color: CyberColors.neonPurple.withOpacity(0.4), width: 1),
            ),
            child: Icon(icon, color: CyberColors.neonPurple, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: CyberText.sectionTitle
                        .copyWith(color: CyberColors.neonPurple, fontSize: 16)),
                if (selectedLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedLabel!,
                    style: CyberText.bodySmall
                        .copyWith(color: CyberColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text('Case #$caseNumber', style: CyberText.caption),
        ],
      ),
    );
  }
}

// ── Evidence Content — renders correctly for each panel type ─

class _EvidenceContent extends StatelessWidget {
  final EvidenceItem item;
  final EvidencePanel panel;

  const _EvidenceContent({required this.item, required this.panel});

  @override
  Widget build(BuildContext context) {
    switch (panel.evidenceType) {
      case 'chat':
        return _ChatDetail(item: item);
      case 'files':
        return _FileDetail(item: item);
      case 'meta':
      case 'ip':
        return _RowDetail(item: item);
      default:
        return _GenericDetail(item: item);
    }
  }
}

// Chat message detail
class _ChatDetail extends StatelessWidget {
  final EvidenceItem item;
  const _ChatDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final color =
    item.isSuspectMessage ? CyberColors.neonRed : CyberColors.neonCyan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Center(
              child: Text(
                (item.sender ?? '?').substring(0, 1),
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(item.sender ?? 'Unknown',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: CyberRadius.medium,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Text(item.label,
              style: CyberText.bodySmall
                  .copyWith(color: CyberColors.textPrimary, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        _DetailBox(text: item.detail, isKey: item.isKeyEvidence),
      ],
    );
  }
}

// File detail
class _FileDetail extends StatelessWidget {
  final EvidenceItem item;
  const _FileDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = item.metadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.isHidden)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: CyberColors.neonGreen.withOpacity(0.08),
              borderRadius: CyberRadius.small,
              border: Border.all(
                  color: CyberColors.neonGreen.withOpacity(0.4), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.lock_open,
                  color: CyberColors.neonGreen, size: 16),
              const SizedBox(width: 8),
              Text('DECRYPTED — Hidden Clue Unlocked',
                  style: TextStyle(
                      color: CyberColors.neonGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        Text(item.label, style: CyberText.sectionTitle.copyWith(fontSize: 16)),
        if (meta != null) ...[
          const SizedBox(height: 4),
          Text(
            'Modified by ${meta.modifier} at ${meta.modifiedAt}',
            style: CyberText.caption
                .copyWith(color: CyberColors.neonAmber.withOpacity(0.8)),
          ),
        ],
        const SizedBox(height: 16),
        _DetailBox(text: item.detail, isKey: item.isKeyEvidence),
      ],
    );
  }
}

// Metadata / IP row-based detail
class _RowDetail extends StatelessWidget {
  final EvidenceItem item;
  const _RowDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...item.rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(row.key, style: CyberText.bodySmall),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.value,
                  style: TextStyle(
                    color: row.highlight
                        ? CyberColors.neonAmber
                        : CyberColors.textPrimary,
                    fontSize: 13,
                    fontWeight: row.highlight
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
        _DetailBox(text: item.detail, isKey: item.isKeyEvidence),
      ],
    );
  }
}

// Fallback
class _GenericDetail extends StatelessWidget {
  final EvidenceItem item;
  const _GenericDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailBox(text: item.detail, isKey: item.isKeyEvidence);
  }
}

// Analyst insight box
class _DetailBox extends StatelessWidget {
  final String text;
  final bool isKey;
  const _DetailBox({required this.text, this.isKey = false});

  /// Returns first 1-2 sentences only for the collapsed preview.
  String _shortText(String full) {
    final sentences = full.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 2) return full;
    return sentences.take(2).join(' ') + '...';
  }

  @override
  Widget build(BuildContext context) {
    final color = isKey ? CyberColors.neonAmber : CyberColors.neonCyan;
    final preview = _shortText(text);
    final hasMore = preview != text;

    return _ExpandableNote(
      text: text,
      preview: preview,
      hasMore: hasMore,
      color: color,
      isKey: isKey,
    );
  }
}

class _ExpandableNote extends StatefulWidget {
  final String text;
  final String preview;
  final bool hasMore;
  final Color color;
  final bool isKey;
  const _ExpandableNote({
    required this.text,
    required this.preview,
    required this.hasMore,
    required this.color,
    required this.isKey,
  });
  @override
  State<_ExpandableNote> createState() => _ExpandableNoteState();
}

class _ExpandableNoteState extends State<_ExpandableNote> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.06),
        borderRadius: CyberRadius.small,
        border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              widget.isKey ? Icons.warning_amber_outlined : Icons.info_outline,
              color: widget.color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text('Analyst Note',
                style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            if (widget.hasMore) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: widget.color.withOpacity(0.7),
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(
            _expanded ? widget.text : widget.preview,
            style: TextStyle(
                color: widget.color, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.inbox_outlined, color: CyberColors.textMuted, size: 48),
        const SizedBox(height: 12),
        Text(
          'No item selected.\nGo back and choose an evidence item.',
          style: CyberText.bodySmall.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _AlreadyUnlockedBanner extends StatelessWidget {
  final String message;
  const _AlreadyUnlockedBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: CyberColors.neonGreen.withOpacity(0.08),
        borderRadius: CyberRadius.medium,
        border: Border.all(
            color: CyberColors.neonGreen.withOpacity(0.5), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CyberColors.neonGreen.withOpacity(0.12),
            borderRadius: CyberRadius.small,
          ),
          child: const Icon(Icons.lock_open,
              color: CyberColors.neonGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Hidden Clue Already Unlocked',
                style: TextStyle(
                    color: CyberColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 3),
            Text(message, style: CyberText.bodySmall.copyWith(fontSize: 12)),
          ]),
        ),
        const StatusChip(label: 'UNLOCKED', color: CyberColors.neonGreen),
      ]),
    );
  }
}

class _AlreadyMarkedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: CyberColors.neonGreen.withOpacity(0.08),
        borderRadius: CyberRadius.medium,
        border: Border.all(
            color: CyberColors.neonGreen.withOpacity(0.5), width: 1.5),
      ),
      child: const Row(children: [
        Icon(Icons.check_circle_outline,
            color: CyberColors.neonGreen, size: 20),
        SizedBox(width: 12),
        Text('Already marked as evidence',
            style: TextStyle(
                color: CyberColors.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ]),
    );
  }
}