// lib/screens/evidence_chain_screen.dart
// ═══════════════════════════════════════════════════════════════
//  EVIDENCE CHAIN — Interactive node-and-line corkboard
//  Shows all collected evidence as draggable nodes connected
//  by glowing thread lines, grouped by panel type.
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';

// ── Data model for a node on the board ───────────────────────

class _EvidenceNode {
  final CollectedEvidence evidence;
  Offset position;
  bool isSelected;

  _EvidenceNode({
    required this.evidence,
    required this.position,
    this.isSelected = false,
  });
}

// ── Screen ────────────────────────────────────────────────────

class EvidenceChainScreen extends StatefulWidget {
  const EvidenceChainScreen({super.key});

  @override
  State<EvidenceChainScreen> createState() => _EvidenceChainScreenState();
}

class _EvidenceChainScreenState extends State<EvidenceChainScreen>
    with TickerProviderStateMixin {
  final List<_EvidenceNode> _nodes = [];
  final TransformationController _transformCtrl = TransformationController();

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;

  String? _selectedNodeId;
  bool _initialized = false;

  // Board canvas size
  static const double _canvasW = 1400;
  static const double _canvasH = 1000;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _initNodes(List<CollectedEvidence> collected, CaseEngine engine) {
    if (_initialized) return;
    _initialized = true;

    // Group by panel and lay out in clusters
    final Map<String, List<CollectedEvidence>> byPanel = {};
    for (final e in collected) {
      byPanel.putIfAbsent(e.panelId, ()=>[]).add(e);
    }

    final panelList = byPanel.entries.toList();
    final rng = Random(42); // stable layout

    // Place each panel cluster at a different region of the canvas
    final clusterCenters = _computeClusterCenters(panelList.length);

    for (int pi = 0; pi < panelList.length; pi++) {
      final items = panelList[pi].value;
      final center = clusterCenters[pi];

      for (int i = 0; i < items.length; i++) {
        // Spread nodes around the cluster center
        final angle = (2 * pi * i / items.length) + rng.nextDouble() * 0.4;
        final radius = items.length == 1 ? 0.0 : 90.0 + rng.nextDouble() * 40;
        final x = (center.dx + cos(angle) * radius).clamp(80.0, _canvasW - 80);
        final y = (center.dy + sin(angle) * radius).clamp(80.0, _canvasH - 80);

        _nodes.add(_EvidenceNode(
          evidence: items[i],
          position: Offset(x, y),
        ));
      }
    }

    // Center the view initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final tx = (size.width - _canvasW * 0.55) / 2;
      final ty = (size.height - _canvasH * 0.55) / 2;
      _transformCtrl.value = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(0.55);
    });
  }

  List<Offset> _computeClusterCenters(int count) {
    // Spread clusters across the canvas
    final positions = <Offset>[];
    if (count == 0) return positions;
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i / count) - pi / 2;
      final rx = _canvasW * 0.28;
      final ry = _canvasH * 0.28;
      positions.add(Offset(
        _canvasW / 2 + cos(angle) * rx,
        _canvasH / 2 + sin(angle) * ry,
      ));
    }
    return positions;
  }

  Color _colorForPanel(String panelId) {
    switch (panelId) {
      case 'chat':
        return CyberColors.neonBlue;
      case 'files':
        return CyberColors.neonPurple;
      case 'meta':
        return CyberColors.neonAmber;
      case 'ip':
        return CyberColors.neonCyan;
      default:
        return CyberColors.neonGreen;
    }
  }

  IconData _iconForPanel(String panelId) {
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

  String _labelForPanel(String panelId) {
    switch (panelId) {
      case 'chat':
        return 'CHAT';
      case 'files':
        return 'FILES';
      case 'meta':
        return 'META';
      case 'ip':
        return 'IP';
      default:
        return panelId.toUpperCase();
    }
  }

  void _onNodeTap(String itemId) {
    setState(() {
      _selectedNodeId = _selectedNodeId == itemId ? null : itemId;
    });
  }

  void _onNodeDrag(String itemId, DragUpdateDetails details) {
    setState(() {
      final scale = _transformCtrl.value.getMaxScaleOnAxis();
      final idx = _nodes.indexWhere((n) => n.evidence.itemId == itemId);
      if (idx < 0) return;
      final node = _nodes[idx];
      node.position = Offset(
        (node.position.dx + details.delta.dx / scale).clamp(60.0, _canvasW - 60),
        (node.position.dy + details.delta.dy / scale).clamp(60.0, _canvasH - 60),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final collected = engine.collectedEvidence;

    _initNodes(collected, engine);

    return AppShell(
      title: 'Evidence Chain',
      showBack: true,
      showBottomNav: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Legend + stats bar ──
            _LegendBar(
              nodes: _nodes,
              engine: engine,
              colorForPanel: _colorForPanel,
              labelForPanel: _labelForPanel,
              iconForPanel: _iconForPanel,
            ),

            // ── Board ──
            Expanded(
              child: collected.isEmpty
                  ? _EmptyBoard()
                  : InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.25,
                maxScale: 2.0,
                constrained: false,
                child: SizedBox(
                  width: _canvasW,
                  height: _canvasH,
                  child: Stack(
                    children: [
                      // ── Corkboard background ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CorkboardPainter(),
                        ),
                      ),

                      // ── Thread lines ──
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => CustomPaint(
                            painter: _ThreadPainter(
                              nodes: _nodes,
                              colorForPanel: _colorForPanel,
                              selectedId: _selectedNodeId,
                              pulseValue: _pulse.value,
                              correctIds: engine.caseFile.correctEvidenceIds,
                            ),
                          ),
                        ),
                      ),

                      // ── Nodes ──
                      ..._nodes.map((node) {
                        final isCorrect = engine.caseFile.correctEvidenceIds
                            .contains(node.evidence.itemId);
                        final isSelected =
                            _selectedNodeId == node.evidence.itemId;
                        final color = _colorForPanel(node.evidence.panelId);

                        return Positioned(
                          left: node.position.dx - 70,
                          top: node.position.dy - 56,
                          child: GestureDetector(
                            onTap: () => _onNodeTap(node.evidence.itemId),
                            onPanUpdate: (d) =>
                                _onNodeDrag(node.evidence.itemId, d),
                            child: _EvidenceNodeWidget(
                              node: node,
                              color: color,
                              icon: _iconForPanel(node.evidence.panelId),
                              panelLabel: _labelForPanel(node.evidence.panelId),
                              isCorrect: isCorrect,
                              isSelected: isSelected,
                              pulseCtrl: _pulseCtrl,
                            ),
                          ),
                        );
                      }),

                      // ── Selected node detail card ──
                      if (_selectedNodeId != null)
                        _buildDetailCard(engine),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(CaseEngine engine) {
    final node = _nodes.firstWhere(
          (n) => n.evidence.itemId == _selectedNodeId,
      orElse: () => _nodes.first,
    );
    final isCorrect =
    engine.caseFile.correctEvidenceIds.contains(node.evidence.itemId);
    final color = _colorForPanel(node.evidence.panelId);

    return Positioned(
      left: (node.position.dx + 80).clamp(0, _canvasW - 260),
      top: (node.position.dy - 60).clamp(0, _canvasH - 200),
      child: _DetailPopup(
        node: node,
        color: color,
        isCorrect: isCorrect,
        panelLabel: _labelForPanel(node.evidence.panelId),
        icon: _iconForPanel(node.evidence.panelId),
        onClose: () => setState(() => _selectedNodeId = null),
      ),
    );
  }
}

// ── Corkboard background painter ─────────────────────────────

class _CorkboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark base
    final bgPaint = Paint()..color = const Color(0xFF050C16);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle grid dots
    final dotPaint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Corner scan-line accents
    final linePaint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.06)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_CorkboardPainter _) => false;
}

// ── Thread lines painter ──────────────────────────────────────

class _ThreadPainter extends CustomPainter {
  final List<_EvidenceNode> nodes;
  final Color Function(String) colorForPanel;
  final String? selectedId;
  final double pulseValue;
  final List<String> correctIds;

  const _ThreadPainter({
    required this.nodes,
    required this.colorForPanel,
    required this.selectedId,
    required this.pulseValue,
    required this.correctIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;

    // Group by panel
    final Map<String, List<_EvidenceNode>> byPanel = {};
    for (final n in nodes) {
      byPanel.putIfAbsent(n.evidence.panelId, ()=>[]).add(n);
    }

    for (final entry in byPanel.entries) {
      final panelNodes = entry.value;
      final color = colorForPanel(entry.key);
      if (panelNodes.length < 2) continue;

      // Connect nodes in same panel with thread lines
      for (int i = 0; i < panelNodes.length - 1; i++) {
        final a = panelNodes[i].position;
        final b = panelNodes[i + 1].position;

        final isHighlighted = selectedId != null &&
            (panelNodes[i].evidence.itemId == selectedId ||
                panelNodes[i + 1].evidence.itemId == selectedId);

        final opacity = isHighlighted
            ? 0.5 + pulseValue * 0.4
            : 0.15 + pulseValue * 0.1;

        final threadPaint = Paint()
          ..color = color.withOpacity(opacity)
          ..strokeWidth = isHighlighted ? 2.0 : 1.2
          ..style = PaintingStyle.stroke;

        // Draw slightly curved line (string effect)
        final midX = (a.dx + b.dx) / 2;
        final midY = (a.dy + b.dy) / 2 + 18;
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(midX, midY, b.dx, b.dy);

        canvas.drawPath(path, threadPaint);

        // Glow pass
        if (isHighlighted) {
          final glowPaint = Paint()
            ..color = color.withOpacity(0.08 * pulseValue)
            ..strokeWidth = 10
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawPath(path, glowPaint);
        }
      }
    }

    // Cross-panel connection line between correct evidence nodes
    final correctNodes =
    nodes.where((n) => correctIds.contains(n.evidence.itemId)).toList();
    if (correctNodes.length >= 2) {
      for (int i = 0; i < correctNodes.length - 1; i++) {
        final a = correctNodes[i].position;
        final b = correctNodes[i + 1].position;

        final linePaint = Paint()
          ..color = CyberColors.neonGreen.withOpacity(0.08 + pulseValue * 0.06)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        canvas.drawLine(a, b, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter old) =>
      old.pulseValue != pulseValue ||
          old.selectedId != selectedId ||
          old.nodes.length != nodes.length;
}

// ── Individual evidence node widget ──────────────────────────

class _EvidenceNodeWidget extends StatelessWidget {
  final _EvidenceNode node;
  final Color color;
  final IconData icon;
  final String panelLabel;
  final bool isCorrect;
  final bool isSelected;
  final AnimationController pulseCtrl;

  const _EvidenceNodeWidget({
    required this.node,
    required this.color,
    required this.icon,
    required this.panelLabel,
    required this.isCorrect,
    required this.isSelected,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? color
        : isCorrect
        ? CyberColors.neonGreen.withOpacity(0.6)
        : color.withOpacity(0.4);
    final borderWidth = isSelected ? 2.0 : 1.2;

    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final pulse = Tween<double>(begin: 0.4, end: 1.0)
            .animate(CurvedAnimation(
          parent: pulseCtrl,
          curve: Curves.easeInOut,
        ))
            .value;

        return Container(
          width: 140,
          constraints: const BoxConstraints(minHeight: 90),
          decoration: BoxDecoration(
            color: CyberColors.bgCard,
            borderRadius: CyberRadius.medium,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.35 * pulse),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header bar ──
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    topRight: Radius.circular(13),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: color.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      panelLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    // Correct / incorrect dot
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect
                            ? CyberColors.neonGreen.withOpacity(0.8)
                            : CyberColors.textMuted.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.evidence.label,
                      style: const TextStyle(
                        color: CyberColors.textPrimary,
                        fontSize: 10,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      node.evidence.collectedAt
                          .toString()
                          .substring(11, 19),
                      style: TextStyle(
                        color: color.withOpacity(0.6),
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Detail popup on node tap ──────────────────────────────────

class _DetailPopup extends StatelessWidget {
  final _EvidenceNode node;
  final Color color;
  final bool isCorrect;
  final String panelLabel;
  final IconData icon;
  final VoidCallback onClose;

  const _DetailPopup({
    required this.node,
    required this.color,
    required this.isCorrect,
    required this.panelLabel,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: CyberColors.bgCard,
          borderRadius: CyberRadius.medium,
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 6),
                Text(
                  panelLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? CyberColors.neonGreen.withOpacity(0.15)
                        : CyberColors.textMuted.withOpacity(0.1),
                    borderRadius: CyberRadius.pill,
                    border: Border.all(
                      color: isCorrect
                          ? CyberColors.neonGreen.withOpacity(0.5)
                          : CyberColors.textMuted.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isCorrect ? 'RELEVANT' : 'MARKED',
                    style: TextStyle(
                      color: isCorrect
                          ? CyberColors.neonGreen
                          : CyberColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close,
                      color: CyberColors.textMuted, size: 14),
                ),
              ]),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.evidence.label,
                    style: const TextStyle(
                      color: CyberColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.access_time,
                        color: color.withOpacity(0.6), size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Collected ${node.evidence.collectedAt.toString().substring(11, 19)}',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend bar ────────────────────────────────────────────────

class _LegendBar extends StatelessWidget {
  final List<_EvidenceNode> nodes;
  final CaseEngine engine;
  final Color Function(String) colorForPanel;
  final String Function(String) labelForPanel;
  final IconData Function(String) iconForPanel;

  const _LegendBar({
    required this.nodes,
    required this.engine,
    required this.colorForPanel,
    required this.labelForPanel,
    required this.iconForPanel,
  });

  @override
  Widget build(BuildContext context) {
    final totalNodes = nodes.length;
    final correctCount = nodes
        .where((n) =>
        engine.caseFile.correctEvidenceIds.contains(n.evidence.itemId))
        .length;

    // Unique panels
    final panels = nodes.map((n) => n.evidence.panelId).toSet().toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: CyberColors.bgCard.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Stats
          _StatPill(
            label: '$totalNodes Nodes',
            color: CyberColors.neonCyan,
            icon: Icons.hub_outlined,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: '$correctCount Relevant',
            color: CyberColors.neonGreen,
            icon: Icons.check_circle_outline,
          ),

          const SizedBox(width: 16),

          // Panel legend dots
          ...panels.map((p) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorForPanel(p),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                labelForPanel(p),
                style: TextStyle(
                  color: colorForPanel(p),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ]),
          )),

          const Spacer(),

          // Hint
          Text(
            'Drag nodes · Pinch to zoom · Tap to inspect',
            style: CyberText.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: CyberRadius.pill,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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

// ── Empty state ───────────────────────────────────────────────

class _EmptyBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined,
              color: CyberColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No evidence collected yet',
            style: CyberText.bodyMedium
                .copyWith(color: CyberColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Mark evidence in the Investigation Hub\nto build your chain.',
            style: CyberText.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}