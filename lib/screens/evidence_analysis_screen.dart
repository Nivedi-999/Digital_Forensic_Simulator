// lib/screens/evidence_analysis_screen.dart
// ═══════════════════════════════════════════════════════════════
//  EVIDENCE ANALYSIS
//  Chat: full conversation thread, selected message highlighted
//  Files: rich document viewer rendering item.detail (no Analyst Note)
//  Meta/IP: key-value rows
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: CyberColors.textOnNeon),
        const SizedBox(width: 10),
        Text('Evidence added to collection',
            style: GoogleFonts.shareTechMono(
                color: CyberColors.textOnNeon, fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: CyberColors.neonGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: CyberRadius.medium),
      duration: const Duration(seconds: 2),
    ));

    final service = TutorialService();
    if (service.currentStep == TutorialStep.markEvidence && !service.messageShown) {
      triggerAria(TutorialStep.markEvidence, delayMs: 400);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat':  return Icons.chat_bubble_outline;
      case 'files': return Icons.folder_outlined;
      case 'meta':  return Icons.data_object;
      case 'ip':    return Icons.wifi;
      default:      return Icons.search;
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'chat':  return 'Chat Logs';
      case 'files': return 'File System';
      case 'meta':  return 'Metadata Extract';
      case 'ip':    return 'IP Traces';
      default:      return 'Evidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final panel  = engine.caseFile.panelById(widget.panelId);
    if (panel == null) return const SizedBox();

    final visibleItems = engine.visibleItemsForPanel(widget.panelId);
    EvidenceItem? item;
    try {
      item = visibleItems.firstWhere((i) => i.id == widget.itemId);
    } catch (_) { item = null; }

    final isAlreadyCollected = engine.isEvidenceCollected(widget.itemId);
    final minigame = panel.minigame;
    final isMinigameSolved = minigame != null && engine.isMinigameSolved(minigame.id);

    return AppShell(
      title: 'Evidence Analysis',
      showBack: true,
      showBottomNav: false,
      child: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Type header ──
            _TypeHeader(
              title: _titleForType(panel.evidenceType),
              icon: _iconForType(panel.evidenceType),
              selectedLabel: item?.label,
              caseNumber: engine.caseFile.caseNumber,
            ),

            const SizedBox(height: 20),

            // ── Content ──
            NeonContainer(
              padding: const EdgeInsets.all(0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 200),
                child: item != null
                    ? _EvidenceContent(
                  item: item,
                  panel: panel,
                  allItems: visibleItems,
                )
                    : const _EmptyContent(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Unlock Hidden Clue ──
            if (minigame != null) ...[
              SizedBox(
                width: double.infinity,
                child: isMinigameSolved
                    ? _AlreadyUnlockedBanner(
                    message: minigame.successMessage ?? 'Hidden clue unlocked.')
                    : CyberButton(
                  label: minigame.title,
                  icon: Icons.lock_open_outlined,
                  accentColor: CyberColors.neonPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DecryptionMiniGameScreen(panelId: widget.panelId),
                    ),
                  ).then((_) => setState(() {})),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Mark as Evidence ──
            SizedBox(
              width: double.infinity,
              child: isAlreadyCollected
                  ? const _AlreadyMarkedBanner()
                  : CyberButton(
                label: 'Mark as Evidence',
                icon: Icons.add_circle_outline,
                accentColor: CyberColors.neonGreen,
                onTap: () => _handleAddEvidence(context),
              ),
            ),

            const SizedBox(height: 32),
          ]),
        ),

        buildAriaLayer(),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TYPE HEADER
// ═══════════════════════════════════════════════════════════════

class _TypeHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? selectedLabel;
  final String caseNumber;

  const _TypeHeader({
    required this.title, required this.icon,
    this.selectedLabel, required this.caseNumber,
  });

  @override
  Widget build(BuildContext context) {
    return NeonContainer(
      borderColor: CyberColors.neonPurple,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: CyberColors.neonPurple.withOpacity(0.12),
            borderRadius: CyberRadius.small,
            border: Border.all(color: CyberColors.neonPurple.withOpacity(0.4), width: 1),
          ),
          child: Icon(icon, color: CyberColors.neonPurple, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: CyberText.sectionTitle.copyWith(color: CyberColors.neonPurple, fontSize: 16)),
          if (selectedLabel != null) ...[
            const SizedBox(height: 4),
            Text(selectedLabel!, style: CyberText.bodySmall.copyWith(color: CyberColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ],
        ])),
        Text('Case #$caseNumber', style: CyberText.caption),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EVIDENCE CONTENT ROUTER
// ═══════════════════════════════════════════════════════════════

class _EvidenceContent extends StatelessWidget {
  final EvidenceItem item;
  final EvidencePanel panel;
  final List<EvidenceItem> allItems;

  const _EvidenceContent({
    required this.item, required this.panel, required this.allItems,
  });

  @override
  Widget build(BuildContext context) {
    switch (panel.evidenceType) {
      case 'chat':   return _ChatThread(item: item, allItems: allItems);
      case 'files':  return _FileDocument(item: item);
      case 'meta':
      case 'ip':     return _RowDetail(item: item);
      default:       return _GenericDetail(item: item);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  CHAT — full conversation thread
// ═══════════════════════════════════════════════════════════════

class _ChatThread extends StatelessWidget {
  final EvidenceItem item;
  final List<EvidenceItem> allItems;

  const _ChatThread({required this.item, required this.allItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Thread header
        Row(children: [
          const Icon(Icons.chat_bubble_outline, color: CyberColors.neonCyan, size: 14),
          const SizedBox(width: 8),
          Text('FULL CONVERSATION LOG',
              style: GoogleFonts.shareTechMono(
                  color: CyberColors.neonCyan, fontSize: 10,
                  letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${allItems.length} MESSAGES',
              style: GoogleFonts.shareTechMono(
                  color: CyberColors.textMuted, fontSize: 9, letterSpacing: 1)),
        ]),

        const SizedBox(height: 4),
        Container(height: 1, color: CyberColors.neonCyan.withOpacity(0.12)),
        const SizedBox(height: 12),

        // All messages in order
        ...allItems.map((msg) {
          final isSelected = msg.id == item.id;
          final isSuspect = msg.isSuspectMessage;
          final color = isSuspect ? CyberColors.neonRed : CyberColors.neonCyan;
          final sender = msg.sender ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChatBubble(
              sender: sender,
              message: msg.label,
              color: color,
              isSelected: isSelected,
              isSuspect: isSuspect,
            ),
          );
        }),

        // Selected message detail
        const SizedBox(height: 4),
        Container(height: 1, color: CyberColors.borderSubtle),
        const SizedBox(height: 14),
        _SelectedMessageDetail(item: item),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final Color color;
  final bool isSelected;
  final bool isSuspect;

  const _ChatBubble({
    required this.sender, required this.message, required this.color,
    required this.isSelected, required this.isSuspect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: isSelected
          ? const EdgeInsets.all(12)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: CyberRadius.medium,
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
      )
          : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar circle
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(isSelected ? 0.6 : 0.3), width: 1),
          ),
          child: Center(
            child: Text(
              sender.isNotEmpty ? sender.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(sender,
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            if (isSuspect) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: CyberColors.neonRed.withOpacity(0.12),
                  borderRadius: CyberRadius.pill,
                  border: Border.all(color: CyberColors.neonRed.withOpacity(0.3), width: 1),
                ),
                child: Text('SUSPECT', style: GoogleFonts.shareTechMono(
                    color: CyberColors.neonRed, fontSize: 8, letterSpacing: 0.8)),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: CyberRadius.pill,
                ),
                child: Text('SELECTED', style: GoogleFonts.shareTechMono(
                    color: color, fontSize: 8, letterSpacing: 0.8)),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.shareTechMono(
              color: isSelected ? CyberColors.textPrimary : CyberColors.textSecondary,
              fontSize: 13, height: 1.5,
            ),
          ),
        ])),
      ]),
    );
  }
}

class _SelectedMessageDetail extends StatelessWidget {
  final EvidenceItem item;
  const _SelectedMessageDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.manage_search, color: CyberColors.neonCyan, size: 14),
        const SizedBox(width: 7),
        Text('FORENSIC ANALYSIS',
            style: GoogleFonts.shareTechMono(
                color: CyberColors.neonCyan, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 10),
      // Parse detail into paragraphs and render them
      ..._parseDetail(item.detail),
    ]);
  }

  List<Widget> _parseDetail(String detail) {
    final paragraphs = detail.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return paragraphs.map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(p.trim(),
          style: GoogleFonts.shareTechMono(
              color: CyberColors.textSecondary, fontSize: 12.5, height: 1.6)),
    )).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
//  FILE DOCUMENT — rich viewer, no Analyst Note
// ═══════════════════════════════════════════════════════════════

class _FileDocument extends StatelessWidget {
  final EvidenceItem item;
  const _FileDocument({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = item.metadata;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── File header bar ──
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: CyberColors.bgMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(bottom: BorderSide(color: CyberColors.borderSubtle, width: 1)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: CyberColors.neonPurple.withOpacity(0.1),
              borderRadius: CyberRadius.small,
              border: Border.all(color: CyberColors.neonPurple.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.description_outlined,
                color: CyberColors.neonPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.label,
                style: GoogleFonts.orbitron(
                    color: CyberColors.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            if (meta != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.edit_outlined, color: CyberColors.neonAmber.withOpacity(0.7), size: 11),
                const SizedBox(width: 4),
                Text('${meta.modifier}  ·  ${meta.modifiedAt}  ·  ${meta.size}',
                    style: GoogleFonts.shareTechMono(
                        color: CyberColors.neonAmber.withOpacity(0.75), fontSize: 10)),
              ]),
            ],
          ])),
          if (item.isHidden)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CyberColors.neonGreen.withOpacity(0.1),
                borderRadius: CyberRadius.pill,
                border: Border.all(color: CyberColors.neonGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_open, color: CyberColors.neonGreen, size: 11),
                const SizedBox(width: 4),
                Text('DECRYPTED', style: GoogleFonts.shareTechMono(
                    color: CyberColors.neonGreen, fontSize: 8,
                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ]),
            ),
        ]),
      ),

      // ── Document body ──
      Padding(
        padding: const EdgeInsets.all(16),
        child: _DocumentBody(detail: item.detail, itemId: item.id),
      ),
    ]);
  }
}

class _DocumentBody extends StatelessWidget {
  final String detail;
  final String itemId;
  const _DocumentBody({required this.detail, required this.itemId});

  @override
  Widget build(BuildContext context) {
    // Split into paragraphs, detect key lines containing numbers / flags / keywords
    final paragraphs = detail.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...paragraphs.asMap().entries.map((entry) {
        final i   = entry.key;
        final raw = entry.value.trim();
        return _DocParagraph(text: raw, index: i);
      }),
    ]);
  }
}

class _DocParagraph extends StatelessWidget {
  final String text;
  final int index;
  const _DocParagraph({required this.text, required this.index});

  // Detect lines that look like key findings — contain specific forensic keywords
  bool get _isKeyLine {
    final lower = text.toLowerCase();
    return lower.contains('₹') ||
        lower.contains('\$') ||
        lower.contains('crore') ||
        lower.contains('lakh') ||
        lower.contains('warning') ||
        lower.contains('error') ||
        lower.contains('critical') ||
        lower.contains('mismatch') ||
        lower.contains('anomal') ||
        lower.contains('suspicious') ||
        lower.contains('flagged') ||
        lower.contains('unauthorized') ||
        lower.contains('breach') ||
        lower.contains('exfil') ||
        lower.contains('injected') ||
        lower.contains('malicious') ||
        lower.contains('stolen') ||
        (lower.contains('[') && lower.contains(']') && lower.contains('am')) ||
        (lower.contains('[') && lower.contains(']') && lower.contains('pm'));
  }

  // Detect lines that look like log entries
  bool get _isLogLine =>
      text.startsWith('[') ||
          RegExp(r'^\d{2}:\d{2}').hasMatch(text) ||
          text.startsWith('>') ||
          text.startsWith('#');

  @override
  Widget build(BuildContext context) {
    if (_isLogLine) {
      return _LogEntry(text: text, isAlert: _isKeyLine);
    }

    if (_isKeyLine) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CyberColors.neonAmber.withOpacity(0.05),
          borderRadius: CyberRadius.small,
          border: Border(left: BorderSide(color: CyberColors.neonAmber.withOpacity(0.5), width: 2.5)),
        ),
        child: Text(text, style: GoogleFonts.shareTechMono(
            color: CyberColors.neonAmber, fontSize: 12.5, height: 1.55)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: GoogleFonts.shareTechMono(
          color: CyberColors.textSecondary, fontSize: 12.5, height: 1.6)),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final String text;
  final bool isAlert;
  const _LogEntry({required this.text, required this.isAlert});

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? CyberColors.neonRed : CyberColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAlert
            ? CyberColors.neonRed.withOpacity(0.04)
            : CyberColors.neonCyan.withOpacity(0.02),
        borderRadius: CyberRadius.small,
      ),
      child: Text(text,
          style: GoogleFonts.robotoMono(color: color, fontSize: 11, height: 1.5)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ROW DETAIL — meta / IP
// ═══════════════════════════════════════════════════════════════

class _RowDetail extends StatelessWidget {
  final EvidenceItem item;
  const _RowDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section label
        Row(children: [
          const Icon(Icons.table_rows_outlined, color: CyberColors.neonCyan, size: 13),
          const SizedBox(width: 7),
          Text('EXTRACTED DATA',
              style: GoogleFonts.shareTechMono(
                  color: CyberColors.neonCyan, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 12),

        // Key-value table
        Container(
          decoration: BoxDecoration(
            borderRadius: CyberRadius.medium,
            border: Border.all(color: CyberColors.borderSubtle, width: 1),
          ),
          child: Column(children: item.rows.asMap().entries.map((entry) {
            final i   = entry.key;
            final row = entry.value;
            final isLast = i == item.rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: row.highlight
                    ? CyberColors.neonAmber.withOpacity(0.05)
                    : (i.isOdd ? CyberColors.neonCyan.withOpacity(0.02) : Colors.transparent),
                border: isLast ? null : Border(
                  bottom: BorderSide(color: CyberColors.borderSubtle, width: 1),
                ),
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(10))
                    : BorderRadius.zero,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 110,
                  child: Text(row.key,
                      style: GoogleFonts.shareTechMono(
                          color: CyberColors.textMuted, fontSize: 11)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(row.value,
                    style: GoogleFonts.shareTechMono(
                      color: row.highlight ? CyberColors.neonAmber : CyberColors.textPrimary,
                      fontSize: 12,
                      fontWeight: row.highlight ? FontWeight.w600 : FontWeight.normal,
                    ))),
                if (row.highlight)
                  const Icon(Icons.flag, color: CyberColors.neonAmber, size: 13),
              ]),
            );
          }).toList()),
        ),

        const SizedBox(height: 16),

        // Detail text — parsed paragraphs
        ..._parseDetail(item.detail),
      ]),
    );
  }

  List<Widget> _parseDetail(String detail) {
    if (detail.isEmpty) return [];
    return [
      Row(children: [
        const Icon(Icons.manage_search, color: CyberColors.neonCyan, size: 13),
        const SizedBox(width: 7),
        Text('INVESTIGATOR NOTES',
            style: GoogleFonts.shareTechMono(
                color: CyberColors.neonCyan, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 8),
      ...detail.split('\n').where((s) => s.trim().isNotEmpty).map((p) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(p.trim(),
                style: GoogleFonts.shareTechMono(
                    color: CyberColors.textSecondary, fontSize: 12, height: 1.6)),
          ),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════
//  GENERIC FALLBACK
// ═══════════════════════════════════════════════════════════════

class _GenericDetail extends StatelessWidget {
  final EvidenceItem item;
  const _GenericDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(item.detail,
          style: GoogleFonts.shareTechMono(
              color: CyberColors.textSecondary, fontSize: 12.5, height: 1.6)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY CONTENT
// ═══════════════════════════════════════════════════════════════

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.inbox_outlined, color: CyberColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No item selected.\nGo back and choose an evidence item.',
              style: CyberText.bodySmall.copyWith(height: 1.6),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BANNERS
// ═══════════════════════════════════════════════════════════════

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
        border: Border.all(color: CyberColors.neonGreen.withOpacity(0.5), width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CyberColors.neonGreen.withOpacity(0.12),
            borderRadius: CyberRadius.small,
          ),
          child: const Icon(Icons.lock_open, color: CyberColors.neonGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hidden Clue Already Unlocked',
              style: GoogleFonts.orbitron(
                  color: CyberColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 3),
          Text(message, style: CyberText.bodySmall.copyWith(fontSize: 12)),
        ])),
        const StatusChip(label: 'UNLOCKED', color: CyberColors.neonGreen),
      ]),
    );
  }
}

class _AlreadyMarkedBanner extends StatelessWidget {
  const _AlreadyMarkedBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: CyberColors.neonGreen.withOpacity(0.08),
        borderRadius: CyberRadius.medium,
        border: Border.all(color: CyberColors.neonGreen.withOpacity(0.5), width: 1.5),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: CyberColors.neonGreen, size: 20),
        const SizedBox(width: 12),
        Text('Already marked as evidence',
            style: GoogleFonts.shareTechMono(
                color: CyberColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}