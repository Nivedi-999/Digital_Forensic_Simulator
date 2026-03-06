// lib/screens/evidence_analysis_screen.dart
// ═══════════════════════════════════════════════════════════════
//  REDESIGNED EVIDENCE ANALYSIS SCREEN
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../services/evidence_collector.dart';
import '../services/game_progress.dart';
import '../services/tutorial_service.dart';
import '../widgets/aria_guide.dart';
import '../widgets/aria_controller.dart';
import 'mini_game.dart';

class EvidenceAnalysisScreen extends StatefulWidget {
  final String evidenceType;
  final String? selectedItem;

  const EvidenceAnalysisScreen({
    super.key,
    required this.evidenceType,
    this.selectedItem,
  });

  @override
  State<EvidenceAnalysisScreen> createState() => _EvidenceAnalysisScreenState();
}

class _EvidenceAnalysisScreenState extends State<EvidenceAnalysisScreen>
    with AriaMixin {

  @override
  void initState() {
    super.initState();
    triggerAria(TutorialStep.viewEvidence);
  }

  void _handleAddEvidence() {
    if (widget.selectedItem != null && widget.selectedItem!.isNotEmpty) {
      EvidenceCollector().addEvidence(widget.evidenceType, widget.selectedItem!);
      TutorialService().onEvidenceMarked();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: CyberColors.textOnNeon),
              const SizedBox(width: 10),
              const Text(
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
          shape: RoundedRectangleBorder(
              borderRadius: CyberRadius.medium),
          duration: const Duration(seconds: 2),
        ),
      );

      final service = TutorialService();
      if (service.currentStep == TutorialStep.markEvidence &&
          !service.messageShown) {
        triggerAria(TutorialStep.markEvidence, delayMs: 400);
      }
    }
  }

  String _getCategoryTitle(String type) {
    switch (type) {
      case 'chat': return 'Chat Logs';
      case 'files': return 'File System';
      case 'meta': return 'Metadata Extract';
      case 'ip': return 'IP Traces';
      default: return 'Evidence';
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'chat': return Icons.chat_bubble_outline;
      case 'files': return Icons.folder_outlined;
      case 'meta': return Icons.data_object;
      case 'ip': return Icons.wifi;
      default: return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyUnlocked = GameProgress.isBriefingUnlocked;

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
                  type: widget.evidenceType,
                  title: _getCategoryTitle(widget.evidenceType),
                  icon: _getCategoryIcon(widget.evidenceType),
                  selectedItem: widget.selectedItem,
                ),

                const SizedBox(height: 20),

                // ── Content panel ──
                NeonContainer(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: 200, maxHeight: 440),
                    child: SingleChildScrollView(
                      child: _buildContent(
                        widget.evidenceType,
                        widget.selectedItem,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Unlock Hidden Clue button ──
                SizedBox(
                  width: double.infinity,
                  child: isAlreadyUnlocked
                      ? _AlreadyUnlockedBanner()
                      : CyberButton(
                    label: 'Unlock Hidden Clue',
                    icon: Icons.lock_open_outlined,
                    accentColor: CyberColors.neonPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DecryptionMiniGameScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Add Evidence button (directly below Unlock) ──
                SizedBox(
                  width: double.infinity,
                  child: CyberButton(
                    label: 'Mark as Evidence',
                    icon: Icons.add_circle_outline,
                    accentColor: CyberColors.neonGreen,
                    onTap: _handleAddEvidence,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── ARIA Guide ──
          buildAriaLayer(),
        ],
      ),
    );
  }

  Widget _buildContent(String type, String? selected) {
    if (selected == null) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.inbox_outlined,
                color: CyberColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'No item selected.\nGo back and choose an evidence item.',
              style: CyberText.bodySmall.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (type == 'files') {
      if (selected == 'finance_report_q3.pdf') {
        return _FileReport(
          filename: 'finance_report_q3.pdf',
          modifier: 'Ankita E',
          modTime: '09:31 AM',
          entries: const [
            _DataEntry('Anomaly 1', '₹2.3 Crore → offshore ACC-4482-X',
                color: CyberColors.neonRed),
            _DataEntry('Anomaly 2', 'Unscheduled payment to "Northstar Solutions"',
                color: CyberColors.neonAmber),
            _DataEntry('Anomaly 3', 'Duplicate reimbursements — 14 Aug',
                color: CyberColors.neonAmber),
            _DataEntry('Total Revenue', '₹48.6 Crore'),
            _DataEntry('Operating Costs', '₹31.2 Crore'),
            _DataEntry('Net Profit', '₹17.4 Crore'),
          ],
        );
      }
      if (selected == 'system_patch.exe') {
        return _FileReport(
          filename: 'system_patch.exe',
          modifier: 'Dhruv A (Admin)',
          modTime: '09:45 AM',
          entries: const [
            _DataEntry('Signed by', 'Internal Admin — Dhruv A'),
            _DataEntry('Size', '4.2 MB'),
            _DataEntry('Note', 'Contains unusual outbound connection module',
                color: CyberColors.neonAmber),
          ],
        );
      }
      if (selected == 'debug_log.txt') {
        return _LogContent(lines: const [
          '[2026-02-02 01:14:22] PatchService: Starting update...',
          '[2026-02-02 01:14:24] PatchService: Verified signature (OK)',
          '[2026-02-02 01:14:31] Network: Outbound → 185.193.127.44',
          '[2026-02-02 01:14:32] ⚠ Warning: Unexpected privilege escalation',
          '[2026-02-02 01:14:35] ✗ Error: Hash mismatch in module agent.dll',
          '[2026-02-02 01:14:36] PatchService: Process terminated unexpectedly',
          '[2026-02-02 01:14:40] SecurityAgent: No threat detected',
        ], highlight: 'Credentials export initiated from FIN-WS-114 at 10:43 AM');
      }
      if (selected == 'cache_dump.bin') {
        return _FileReport(
          filename: 'cache_dump.bin',
          modifier: 'System',
          modTime: '10:44–10:46 AM',
          entries: const [
            _DataEntry('Contains', 'Employee credential database fragments',
                color: CyberColors.neonRed),
            _DataEntry('Dump Timestamp', '10:44–10:46 AM'),
            _DataEntry('Exfil Path', 'FIN-WS-114 → 172.16.44.21'),
          ],
        );
      }
      // ── UNLOCKED via decryption mini-game ──
      if (selected == 'credentials.pdf') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unlocked badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CyberColors.neonGreen.withOpacity(0.08),
                borderRadius: CyberRadius.small,
                border: Border.all(
                    color: CyberColors.neonGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open, color: CyberColors.neonGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'DECRYPTED — Hidden Clue Unlocked',
                    style: TextStyle(
                      color: CyberColors.neonGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _FileReport(
              filename: 'credentials.pdf',
              modifier: 'Ankita E',
              modTime: '10:43 AM',
              entries: const [
                _DataEntry('Document Type', 'Internal Credential Export',
                    color: CyberColors.neonRed),
                _DataEntry('Exported By', 'Ankita E — Employee ID AE-4471',
                    color: CyberColors.neonRed),
                _DataEntry('Workstation', 'FIN-WS-114'),
                _DataEntry('Export Time', '10:43:22 AM'),
                _DataEntry('Contents', 'DB admin credentials for FINDB-PROD-01',
                    color: CyberColors.neonAmber),
                _DataEntry('Target Account', 'offshore ACC-4482-X',
                    color: CyberColors.neonAmber),
                _DataEntry('Auth Token', 'ghst_tkn_8f2d91cc4b7a...  [REDACTED]',
                    color: CyberColors.neonRed),
                _DataEntry('Destination IP', '202.56.23.101 (External)',
                    color: CyberColors.neonRed),
                _DataEntry('File Hash', 'SHA256: 3f4a1b9c... [truncated]'),
                _DataEntry('Note',
                    'This file was found in the exfiltration cache. It directly links Ankita E to the data breach.',
                    color: CyberColors.neonAmber),
              ],
            ),
          ],
        );
      }
    }

    if (type == 'meta') {
      final rows = <_DataEntry>[];
      if (selected == 'Device') {
        rows.addAll(const [
          _DataEntry('Workstation ID', 'FIN-WS-114'),
          _DataEntry('Location', 'Finance Dept. Mumbai HQ'),
          _DataEntry('Access Control', 'Biometric + PIN'),
        ]);
      } else if (selected == 'OS') {
        rows.addAll(const [
          _DataEntry('OS', 'Windows 11 Pro (Build 22621)'),
          _DataEntry('Last Update', '2024-01-15 08:40 AM'),
          _DataEntry('Patch Level', 'KB5034123 applied'),
        ]);
      } else if (selected == 'Last User') {
        rows.addAll(const [
          _DataEntry('Last Login User', 'Ankita E',
              color: CyberColors.neonAmber),
          _DataEntry('Login Time', '09:15 AM – 11:02 AM'),
          _DataEntry('Session Type', 'Active'),
        ]);
      }
      return Column(
        children: rows.map((e) => _DataEntryRow(entry: e)).toList(),
      );
    }

    if (type == 'ip') {
      final rows = <_DataEntry>[];
      if (selected == 'Internal Origin') {
        rows.addAll(const [
          _DataEntry('Source IP', '172.16.44.21'),
          _DataEntry('MAC', '00-25-96-FF-12-34'),
          _DataEntry('Hostname', 'FIN-WS-114.corp.local'),
          _DataEntry('Location', 'Internal LAN – Finance Floor'),
        ]);
      } else if (selected == 'External Hop') {
        rows.addAll(const [
          _DataEntry('Next Hop IP', '202.56.23.101',
              color: CyberColors.neonAmber),
          _DataEntry('GeoIP', 'Mumbai, Maharashtra, India'),
          _DataEntry('ISP', 'Public WiFi — Cafe near office',
              color: CyberColors.neonRed),
        ]);
      }
      return Column(
        children: rows.map((e) => _DataEntryRow(entry: e)).toList(),
      );
    }

    if (type == 'chat') {
      return _ChatLog();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No detailed content available for this item.\nUse "Unlock Hidden Clue" for deeper analysis.',
          style: CyberText.bodySmall.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Type Header ──
class _TypeHeader extends StatelessWidget {
  final String type;
  final String title;
  final IconData icon;
  final String? selectedItem;

  const _TypeHeader({
    required this.type,
    required this.title,
    required this.icon,
    this.selectedItem,
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
                    style: CyberText.sectionTitle.copyWith(
                        color: CyberColors.neonPurple, fontSize: 16)),
                if (selectedItem != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedItem!,
                    style: CyberText.bodySmall
                        .copyWith(color: CyberColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text('Case #2047', style: CyberText.caption),
        ],
      ),
    );
  }
}


// ── Already Unlocked Banner ──
class _AlreadyUnlockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: CyberColors.neonGreen.withOpacity(0.08),
        borderRadius: CyberRadius.medium,
        border: Border.all(
          color: CyberColors.neonGreen.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CyberColors.neonGreen.withOpacity(0.12),
              borderRadius: CyberRadius.small,
            ),
            child: const Icon(
              Icons.lock_open,
              color: CyberColors.neonGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hidden Clue Already Unlocked',
                  style: TextStyle(
                    color: CyberColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'credentials.pdf is now available in your file feed.',
                  style: CyberText.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          StatusChip(label: 'UNLOCKED', color: CyberColors.neonGreen),
        ],
      ),
    );
  }
}

// ── Add Evidence Bottom Bar ──
class _AddEvidenceBar extends StatelessWidget {
  final VoidCallback onAdd;
  final String? selectedItem;

  const _AddEvidenceBar({required this.onAdd, this.selectedItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: CyberColors.neonCyan.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (selectedItem != null)
            Expanded(
              child: Text(
                selectedItem!,
                style: CyberText.bodySmall.copyWith(
                    color: CyberColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: CyberButton(
              label: 'Add Evidence',
              icon: Icons.add_circle_outline,
              accentColor: CyberColors.neonGreen,
              isSmall: true,
              onTap: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── File Report Widget ──
class _FileReport extends StatelessWidget {
  final String filename;
  final String modifier;
  final String modTime;
  final List<_DataEntry> entries;

  const _FileReport({
    required this.filename,
    required this.modifier,
    required this.modTime,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(filename,
            style: CyberText.sectionTitle.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text('Modified by $modifier at $modTime',
            style: CyberText.caption.copyWith(
                color: CyberColors.neonAmber.withOpacity(0.8))),
        const SizedBox(height: 16),
        ...entries.map((e) => _DataEntryRow(entry: e)),
      ],
    );
  }
}

// ── Log Content Widget ──
class _LogContent extends StatelessWidget {
  final List<String> lines;
  final String? highlight;

  const _LogContent({required this.lines, this.highlight});

  @override
  Widget build(BuildContext context) {
    if (highlight != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: CyberColors.neonAmber.withOpacity(0.1),
              borderRadius: CyberRadius.small,
              border: Border.all(
                  color: CyberColors.neonAmber.withOpacity(0.4), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: CyberColors.neonAmber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Key entry: "$highlight"',
                    style: TextStyle(
                        color: CyberColors.neonAmber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ...lines.map((l) => _LogLine(line: l)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((l) => _LogLine(line: l)).toList(),
    );
  }
}

class _LogLine extends StatelessWidget {
  final String line;
  const _LogLine({required this.line});

  Color get _color {
    if (line.contains('Error') || line.contains('✗'))
      return CyberColors.neonRed;
    if (line.contains('Warning') || line.contains('⚠'))
      return CyberColors.neonAmber;
    return CyberColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.5,
          color: _color,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── Chat Log Widget ──
class _ChatLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = [
      ('Admin', 'Patch deployed successfully.', false),
      ('Ghost', 'I noticed.', true),
      ('Admin', 'You shouldn\'t be here.', false),
      ('Ghost', 'You left a door open.', true),
      ('Admin', 'Who are you?', false),
      ('Ghost', 'Just a shadow.', true),
      ('Ghost', 'Check your finance workstation.', true),
      ('Ankita E', 'Can you send me the Q3 forecast again?', false),
      ('Admin', 'Sent to your internal mail.', false),
      ('Ghost', 'For the next phase, transfer to offshore account.', true),
    ];

    return Column(
      children: messages.map((m) {
        final isGhost = m.$2;
        return _ChatBubble(sender: m.$1, message: m.$2, isSuspect: m.$3);
      }).toList(),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final bool isSuspect;

  const _ChatBubble({
    required this.sender,
    required this.message,
    required this.isSuspect,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuspect ? CyberColors.neonRed : CyberColors.neonCyan;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Center(
              child: Text(
                sender.substring(0, 1),
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sender,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(
                        color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    message,
                    style: CyberText.bodySmall.copyWith(
                        color: CyberColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Entry types ──
class _DataEntry {
  final String label;
  final String value;
  final Color? color;

  const _DataEntry(this.label, this.value, {this.color});
}

class _DataEntryRow extends StatelessWidget {
  final _DataEntry entry;
  const _DataEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(entry.label, style: CyberText.bodySmall),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.value,
              style: TextStyle(
                color: entry.color ?? CyberColors.textPrimary,
                fontSize: 13,
                fontWeight: entry.color != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}