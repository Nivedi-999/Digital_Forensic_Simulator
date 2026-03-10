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
                          ? _EvidenceContent(item: item, panel: panel, allItems: engine.visibleItemsForPanel(widget.panelId))
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
  final List<EvidenceItem> allItems;

  const _EvidenceContent({required this.item, required this.panel, required this.allItems});

  @override
  Widget build(BuildContext context) {
    switch (panel.evidenceType) {
      case 'chat':
        return _ChatDetail(item: item, allItems: allItems);
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

// Chat — full conversation log, selected message highlighted
class _ChatDetail extends StatelessWidget {
  final EvidenceItem item;
  final List<EvidenceItem> allItems;
  const _ChatDetail({required this.item, required this.allItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.chat_bubble_outline, color: CyberColors.neonCyan, size: 13),
          const SizedBox(width: 6),
          Text('FULL CONVERSATION LOG',
              style: TextStyle(color: CyberColors.neonCyan, fontSize: 10,
                  letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        ...allItems.map((msg) {
          final isSelected = msg.id == item.id;
          final color = msg.isSuspectMessage ? CyberColors.neonRed : CyberColors.neonCyan;
          return _ChatBubble(
            sender: msg.sender ?? 'Unknown',
            message: msg.label,
            color: color,
            isHighlighted: isSelected,
          );
        }),
        const SizedBox(height: 16),
        _DetailBox(text: item.detail, isKey: item.isKeyEvidence),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final Color color;
  final bool isHighlighted;
  const _ChatBubble({required this.sender, required this.message,
    required this.color, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: isHighlighted ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: isHighlighted
          ? BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: CyberRadius.medium,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Center(
              child: Text(sender.substring(0, 1),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(sender,
                      style: TextStyle(color: color, fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  if (isHighlighted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: CyberRadius.pill,
                      ),
                      child: Text('SELECTED',
                          style: TextStyle(color: color, fontSize: 9, letterSpacing: 1)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(message,
                    style: CyberText.bodySmall.copyWith(
                      color: isHighlighted ? CyberColors.textPrimary : CyberColors.textSecondary,
                      fontSize: 13, height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// File detail — structured content per file id
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: CyberColors.neonGreen.withOpacity(0.08),
              borderRadius: CyberRadius.small,
              border: Border.all(color: CyberColors.neonGreen.withOpacity(0.4), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.lock_open, color: CyberColors.neonGreen, size: 16),
              const SizedBox(width: 8),
              Text('DECRYPTED \u2014 Hidden Clue Unlocked',
                  style: TextStyle(color: CyberColors.neonGreen,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        Text(item.label, style: CyberText.sectionTitle.copyWith(fontSize: 16)),
        if (meta != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.edit_outlined, color: CyberColors.neonAmber, size: 13),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'By ${meta.modifier}  \u2022  ${meta.modifiedAt}  \u2022  ${meta.size}',
                style: CyberText.caption.copyWith(color: CyberColors.neonAmber.withOpacity(0.9)),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        _fileBody(),
        const SizedBox(height: 16),
        _DetailBox(text: item.detail, isKey: item.isKeyEvidence),
      ],
    );
  }

  Widget _fileBody() {
    switch (item.id) {
      case 'file_finance':    return const _FinanceReport();
      case 'file_patch':      return const _PatchReport();
      case 'file_debug':      return const _DebugLog();
      case 'file_cache':      return const _CacheReport();
      case 'file_credentials':return const _CredentialsReport();
      default:                return const SizedBox.shrink();
    }
  }
}

class _FinanceReport extends StatelessWidget {
  const _FinanceReport();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTag(label: '\u26a0 ANOMALIES DETECTED', color: CyberColors.neonRed),
      const SizedBox(height: 8),
      const _DataRow('\u20b92.3 Cr transferred', 'Offshore ACC-4482-X', highlight: true),
      const _DataRow('Unscheduled payment', '"Northstar Solutions"', highlight: true),
      const _DataRow('Duplicate entries', '14 reimbursements on 14 Aug', highlight: true),
      const SizedBox(height: 14),
      const _SectionTag(label: 'FINANCIAL SUMMARY', color: CyberColors.neonCyan),
      const SizedBox(height: 8),
      const _DataRow('Total Revenue', '\u20b948.6 Crore'),
      const _DataRow('Operating Costs', '\u20b931.2 Crore'),
      const _DataRow('Net Profit', '\u20b917.4 Crore'),
      const _DataRow('Flagged Transfers', '\u20b92.3 Crore (unverified)', highlight: true),
    ]);
  }
}

class _PatchReport extends StatelessWidget {
  const _PatchReport();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTag(label: 'FILE ANALYSIS', color: CyberColors.neonCyan),
      const SizedBox(height: 8),
      const _DataRow('Signed By', 'Dhruv A (Admin)'),
      const _DataRow('File Size', '4.2 MB'),
      const _DataRow('SHA-256', 'a3f9b1c8...d44e [truncated]'),
      const SizedBox(height: 14),
      const _SectionTag(label: '\u26a0 SUSPICIOUS MODULE', color: CyberColors.neonAmber),
      const SizedBox(height: 8),
      const _DataRow('Module', 'agent.dll', highlight: true),
      const _DataRow('Behaviour', 'Outbound \u2192 185.193.127.44', highlight: true),
      const _DataRow('Expected?', 'No \u2014 not in patch spec', highlight: true),
      const _DataRow('Verdict', 'No direct link to finance data'),
    ]);
  }
}

class _DebugLog extends StatelessWidget {
  const _DebugLog();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTag(label: 'SYSTEM LOG', color: CyberColors.neonCyan),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: CyberRadius.small,
          border: Border.all(color: CyberColors.borderSubtle, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _LogLine('[01:14:22] PatchService: Starting update...'),
          _LogLine('[01:14:24] PatchService: Verified signature (OK)'),
          _LogLine('[01:14:31] Network: Outbound \u2192 185.193.127.44', warn: true),
          _LogLine('[01:14:32] \u26a0 Warning: Unexpected privilege escalation', warn: true),
          _LogLine('[01:14:35] \u2717 Error: Hash mismatch in agent.dll', error: true),
          _LogLine('[01:14:36] PatchService: Terminated unexpectedly', error: true),
          _LogLine('[01:14:40] SecurityAgent: No threat detected'),
          _LogLine('[10:43:01] FIN-WS-114: Session active \u2014 Ankita E', warn: true),
          _LogLine('[10:43:22] CredentialExport: credentials.pdf written', error: true),
          _LogLine('[10:44:10] CacheDump: DB fragments \u2192 172.16.44.21', error: true),
        ]),
      ),
    ]);
  }
}

class _LogLine extends StatelessWidget {
  final String text;
  final bool warn;
  final bool error;
  const _LogLine(this.text, {this.warn = false, this.error = false});
  @override
  Widget build(BuildContext context) {
    final color = error ? CyberColors.neonRed
        : warn ? CyberColors.neonAmber
        : CyberColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(text, style: TextStyle(
          fontFamily: 'monospace', fontSize: 11, color: color, height: 1.5)),
    );
  }
}

class _CacheReport extends StatelessWidget {
  const _CacheReport();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTag(label: '\u26a0 DUMP CONTENTS', color: CyberColors.neonRed),
      const SizedBox(height: 8),
      const _DataRow('Contains', 'Employee credential DB fragments', highlight: true),
      const _DataRow('Dump Window', '10:44 AM \u2013 10:46 AM'),
      const _DataRow('Size', '88 MB'),
      const SizedBox(height: 14),
      const _SectionTag(label: 'EXFILTRATION PATH', color: CyberColors.neonAmber),
      const SizedBox(height: 8),
      const _DataRow('Source', 'FIN-WS-114 (172.16.44.21)', highlight: true),
      const _DataRow('Destination', '202.56.23.101 (External)', highlight: true),
      const _DataRow('Protocol', 'HTTPS \u2014 port 443'),
      const _DataRow('Encrypted?', 'Yes \u2014 TLS 1.2'),
    ]);
  }
}

class _CredentialsReport extends StatelessWidget {
  const _CredentialsReport();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTag(label: 'EXPORT DETAILS', color: CyberColors.neonRed),
      const SizedBox(height: 8),
      const _DataRow('Exported By', 'Ankita E \u2014 AE-4471', highlight: true),
      const _DataRow('Workstation', 'FIN-WS-114'),
      const _DataRow('Export Time', '10:43:22 AM'),
      const SizedBox(height: 14),
      const _SectionTag(label: 'TARGET INFORMATION', color: CyberColors.neonAmber),
      const SizedBox(height: 8),
      const _DataRow('DB Credentials', 'FINDB-PROD-01', highlight: true),
      const _DataRow('Offshore Account', 'ACC-4482-X', highlight: true),
      const _DataRow('Auth Token', 'ghst_tkn_8f2d91cc... [REDACTED]', highlight: true),
      const _DataRow('Destination IP', '202.56.23.101', highlight: true),
      const _DataRow('File Hash', 'SHA256: 3f4a1b9c... [truncated]'),
    ]);
  }
}

class _SectionTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, color: color, margin: const EdgeInsets.only(right: 8)),
      Text(label, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.bold, letterSpacing: 1)),
    ]);
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DataRow(this.label, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130,
            child: Text(label, style: CyberText.bodySmall.copyWith(fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(
          color: highlight ? CyberColors.neonAmber : CyberColors.textPrimary,
          fontSize: 12,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
        ))),
      ]),
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

  @override
  Widget build(BuildContext context) {
    final color = isKey ? CyberColors.neonAmber : CyberColors.neonCyan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: CyberRadius.small,
        border:
        Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isKey ? Icons.warning_amber_outlined : Icons.info_outline,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text('Analyst Note',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(color: color, fontSize: 13, height: 1.55)),
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