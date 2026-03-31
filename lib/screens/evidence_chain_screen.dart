// lib/screens/evidence_chain_screen.dart
// ═══════════════════════════════════════════════════════════════
//  EVIDENCE NETWORK — Interactive visual evidence board
//  Modern, clean design with better organization and visuals
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../logic/game_engine.dart';
import '../state/case_engine_provider.dart';

// ── Evidence Node Data ────────────────────────────────────────

class _EvidenceNode {
  final CollectedEvidence evidence;
  Offset position;
  bool isSelected;
  bool isConnected;

  _EvidenceNode({
    required this.evidence,
    required this.position,
    this.isSelected = false,
    this.isConnected = false,
  });
}

// ── Main Screen ───────────────────────────────────────────────

class EvidenceChainScreen extends StatefulWidget {
  const EvidenceChainScreen({super.key});

  @override
  State<EvidenceChainScreen> createState() => _EvidenceChainScreenState();
}

class _EvidenceChainScreenState extends State<EvidenceChainScreen>
    with TickerProviderStateMixin {
  final List<_EvidenceNode> _nodes = [];
  final TransformationController _transformCtrl = TransformationController();
  final List<_Connection> _connections = [];

  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _glowAnim;

  String? _selectedNodeId;
  bool _initialized = false;
  double _zoomLevel = 0.6;

  // Canvas size
  static const double _canvasW = 1600;
  static const double _canvasH = 1200;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
    });
  }

  void _centerView() {
    final size = MediaQuery.of(context).size;
    final tx = (size.width - _canvasW * _zoomLevel) / 2;
    final ty = (size.height - _canvasH * _zoomLevel) / 2;
    _transformCtrl.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(_zoomLevel);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _initNodes(List<CollectedEvidence> collected, CaseEngine engine) {
    if (_initialized || collected.isEmpty) return;
    _initialized = true;

    _nodes.clear();
    _connections.clear();

    // Group evidence by type
    final Map<String, List<CollectedEvidence>> grouped = {};
    for (final evidence in collected) {
      grouped.putIfAbsent(evidence.panelId, () => []).add(evidence);
    }

    // Create clusters for each group
    final groups = grouped.entries.toList();
    final clusterPositions = _calculateClusterPositions(groups.length);

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final clusterCenter = clusterPositions[i];
      final nodesInGroup = group.value;

      // Create nodes in circular arrangement
      for (int j = 0; j < nodesInGroup.length; j++) {
        final angle = (2 * pi * j / nodesInGroup.length);
        final radius = max(80.0, nodesInGroup.length * 15.0);
        final x = clusterCenter.dx + cos(angle) * radius;
        final y = clusterCenter.dy + sin(angle) * radius;

        _nodes.add(_EvidenceNode(
          evidence: nodesInGroup[j],
          position: Offset(x, y),
        ));
      }

      // Create connections within group
      for (int j = 0; j < nodesInGroup.length - 1; j++) {
        for (int k = j + 1; k < nodesInGroup.length; k++) {
          _connections.add(_Connection(
            from: _nodes[_nodes.length - nodesInGroup.length + j].position,
            to: _nodes[_nodes.length - nodesInGroup.length + k].position,
            type: group.key,
          ));
        }
      }
    }

    // Create connections between correct evidence
    _createCrossConnections(engine);
  }

  List<Offset> _calculateClusterPositions(int count) {
    final positions = <Offset>[];
    if (count == 1) {
      positions.add(Offset(_canvasW / 2, _canvasH / 2));
    } else {
      for (int i = 0; i < count; i++) {
        final angle = (2 * pi * i / count) - pi / 2;
        final radius = min(_canvasW, _canvasH) * 0.3;
        positions.add(Offset(
          _canvasW / 2 + cos(angle) * radius,
          _canvasH / 2 + sin(angle) * radius,
        ));
      }
    }
    return positions;
  }

  void _createCrossConnections(CaseEngine engine) {
    final correctNodes = _nodes.where((node) =>
        engine.caseFile.correctEvidenceIds.contains(node.evidence.itemId));

    final correctList = correctNodes.toList();
    if (correctList.length > 1) {
      for (int i = 0; i < correctList.length - 1; i++) {
        for (int j = i + 1; j < correctList.length; j++) {
          _connections.add(_Connection(
            from: correctList[i].position,
            to: correctList[j].position,
            type: 'cross',
            isCorrect: true,
          ));
        }
      }
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'chat':
        return CyberColors.neonBlue;
      case 'files':
        return CyberColors.neonPurple;
      case 'meta':
        return const Color(0xFFFF6B9D);
      case 'ip':
        return CyberColors.neonCyan;
      case 'cross':
        return CyberColors.neonGreen;
      default:
        return CyberColors.neonAmber;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat;
      case 'files':
        return Icons.folder;
      case 'meta':
        return Icons.data_object;
      case 'ip':
        return Icons.network_check;
      default:
        return Icons.description;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'chat':
        return 'CHATS';
      case 'files':
        return 'FILES';
      case 'meta':
        return 'METADATA';
      case 'ip':
        return 'IP TRACES';
      default:
        return type.toUpperCase();
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
      final nodeIndex = _nodes.indexWhere((n) => n.evidence.itemId == itemId);
      if (nodeIndex >= 0) {
        final node = _nodes[nodeIndex];
        node.position = Offset(
          (node.position.dx + details.delta.dx / scale)
              .clamp(60.0, _canvasW - 60),
          (node.position.dy + details.delta.dy / scale)
              .clamp(60.0, _canvasH - 60),
        );
      }
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.2).clamp(0.3, 2.0);
      _centerView();
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.2).clamp(0.3, 2.0);
      _centerView();
    });
  }

  void _resetView() {
    setState(() {
      _zoomLevel = 0.6;
      _centerView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = CaseEngineProvider.of(context);
    final collected = engine.collectedEvidence;

    _initNodes(collected, engine);

    return AppShell(
      title: 'Evidence Network',
      showBack: true,
      currentIndex: 2,
      showBottomNav: true,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // Header with Stats
            _EvidenceHeader(
              totalEvidence: collected.length,
              correctEvidence: _nodes
                  .where((n) => engine.caseFile.correctEvidenceIds
                  .contains(n.evidence.itemId))
                  .length,
              connections: _connections.length,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onReset: _resetView,
            ),

            // Main Board Area
            Expanded(
              child: collected.isEmpty
                  ? _EmptyBoardState()
                  : Stack(
                children: [
                  // Interactive Board
                  InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 0.3,
                    maxScale: 2.0,
                    constrained: false,
                    child: SizedBox(
                      width: _canvasW,
                      height: _canvasH,
                      child: Stack(
                        children: [
                          // Background
                          _BoardBackground(),

                          // Connections
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _ConnectionPainter(
                                  connections: _connections,
                                  selectedNodeId: _selectedNodeId,
                                  glowValue: _glowAnim.value,
                                  getColorForType: _getColorForType,
                                ),
                              );
                            },
                          ),

                          // Evidence Nodes
                          ..._nodes.map((node) {
                            final isCorrect = engine.caseFile
                                .correctEvidenceIds
                                .contains(node.evidence.itemId);
                            final isSelected =
                                _selectedNodeId == node.evidence.itemId;
                            final color =
                            _getColorForType(node.evidence.panelId);

                            return Positioned(
                              left: node.position.dx - 75,
                              top: node.position.dy - 60,
                              child: _EvidenceNodeCard(
                                node: node,
                                color: color,
                                icon: _getIconForType(node.evidence.panelId),
                                isCorrect: isCorrect,
                                isSelected: isSelected,
                                onTap: () => _onNodeTap(node.evidence.itemId),
                                onDrag: (details) =>
                                    _onNodeDrag(node.evidence.itemId, details),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Zoom Controls
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _ZoomControls(
                      onZoomIn: _zoomIn,
                      onZoomOut: _zoomOut,
                      onReset: _resetView,
                    ),
                  ),

                  // Selected Node Details
                  if (_selectedNodeId != null)
                    _buildSelectedNodeDetails(engine),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedNodeDetails(CaseEngine engine) {
    final node = _nodes.firstWhere(
          (n) => n.evidence.itemId == _selectedNodeId,
      orElse: () => _nodes.first,
    );
    final isCorrect = engine.caseFile.correctEvidenceIds
        .contains(node.evidence.itemId);
    final color = _getColorForType(node.evidence.panelId);

    return Positioned(
      right: 20,
      top: 100,
      child: _EvidenceDetailPanel(
        evidence: node.evidence,
        color: color,
        isCorrect: isCorrect,
        panelLabel: _getLabelForType(node.evidence.panelId),
        icon: _getIconForType(node.evidence.panelId),
        onClose: () => setState(() => _selectedNodeId = null),
      ),
    );
  }
}

// ── Connection Model ──────────────────────────────────────────

class _Connection {
  final Offset from;
  final Offset to;
  final String type;
  final bool isCorrect;

  _Connection({
    required this.from,
    required this.to,
    required this.type,
    this.isCorrect = false,
  });
}

// ── Board Background ──────────────────────────────────────────

class _BoardBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0F1C),
            const Color(0xFF111827),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw grid lines
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw subtle glow at center
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(center, 200, glowPaint);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ── Connection Painter ────────────────────────────────────────

class _ConnectionPainter extends CustomPainter {
  final List<_Connection> connections;
  final String? selectedNodeId;
  final double glowValue;
  final Color Function(String) getColorForType;

  _ConnectionPainter({
    required this.connections,
    required this.selectedNodeId,
    required this.glowValue,
    required this.getColorForType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      final color = getColorForType(connection.type);
      final isHighlighted = selectedNodeId != null;

      // Main connection line
      final linePaint = Paint()
        ..color = connection.isCorrect
            ? CyberColors.neonGreen.withOpacity(0.4 + glowValue * 0.2)
            : color.withOpacity(0.2 + glowValue * 0.1)
        ..strokeWidth = connection.isCorrect ? 2.0 : 1.5
        ..strokeCap = StrokeCap.round;

      if (connection.isCorrect) {
        // Draw dashed line for correct connections
        final path = Path()
          ..moveTo(connection.from.dx, connection.from.dy)
          ..lineTo(connection.to.dx, connection.to.dy);

        final dashPaint = Paint()
          ..color = CyberColors.neonGreen.withOpacity(0.6)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final dashPath = Path();
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final distance = (connection.to - connection.from).distance;
        final direction = (connection.to - connection.from) / distance;

        for (double i = 0; i < distance; i += dashWidth + dashSpace) {
          final start = connection.from + direction * i;
          final end = connection.from + direction * (i + dashWidth);
          dashPath.moveTo(start.dx, start.dy);
          dashPath.lineTo(end.dx, end.dy);
        }

        canvas.drawPath(dashPath, dashPaint);
      } else {
        // Draw solid line for regular connections
        canvas.drawLine(connection.from, connection.to, linePaint);
      }

      // Glow effect for highlighted connections
      if (isHighlighted) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.1 * glowValue)
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawLine(connection.from, connection.to, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.connections != connections ||
          oldDelegate.selectedNodeId != selectedNodeId ||
          oldDelegate.glowValue != glowValue;
}

// ── Evidence Node Card ────────────────────────────────────────

class _EvidenceNodeCard extends StatelessWidget {
  final _EvidenceNode node;
  final Color color;
  final IconData icon;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(DragUpdateDetails) onDrag;

  const _EvidenceNodeCard({
    required this.node,
    required this.color,
    required this.icon,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onDrag,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          decoration: BoxDecoration(
            color: CyberColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : isCorrect
                  ? CyberColors.neonGreen
                  : color.withOpacity(0.4),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.5),
                blurRadius: isSelected ? 20 : 10,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.evidence.label.split(' ').first.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCorrect)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CyberColors.neonGreen,
                          boxShadow: [
                            BoxShadow(
                              color: CyberColors.neonGreen.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.evidence.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: color.withOpacity(0.6),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Collected ${node.evidence.collectedAt.hour}:${node.evidence.collectedAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Evidence Detail Panel ─────────────────────────────────────

class _EvidenceDetailPanel extends StatelessWidget {
  final CollectedEvidence evidence;
  final Color color;
  final bool isCorrect;
  final String panelLabel;
  final IconData icon;
  final VoidCallback onClose;

  const _EvidenceDetailPanel({
    required this.evidence,
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
        width: 280,
        decoration: BoxDecoration(
          color: CyberColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          panelLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          evidence.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: CyberColors.textMuted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCorrect)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CyberColors.neonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CyberColors.neonGreen.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: CyberColors.neonGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CRITICAL EVIDENCE',
                            style: TextStyle(
                              color: CyberColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Collection Time',
                    value:
                    '${evidence.collectedAt.hour}:${evidence.collectedAt.minute.toString().padLeft(2, '0')}',
                    color: color,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.category,
                    label: 'Evidence Type',
                    value: panelLabel,
                    color: color,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.source,
                    label: 'Source',
                    value: 'Digital Forensics',
                    color: color,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Evidence Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This piece of evidence was collected during the investigation. '
                        'It contains important information that may help solve the case.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Evidence Header ───────────────────────────────────────────

class _EvidenceHeader extends StatelessWidget {
  final int totalEvidence;
  final int correctEvidence;
  final int connections;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _EvidenceHeader({
    required this.totalEvidence,
    required this.correctEvidence,
    required this.connections,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        border: Border(
          bottom: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Stats
          _HeaderStat(
            icon: Icons.layers,
            value: totalEvidence.toString(),
            label: 'Evidence',
            color: CyberColors.neonCyan,
          ),
          const SizedBox(width: 16),
          _HeaderStat(
            icon: Icons.verified,
            value: correctEvidence.toString(),
            label: 'Critical',
            color: CyberColors.neonGreen,
          ),
          const SizedBox(width: 16),
          _HeaderStat(
            icon: Icons.link,
            value: connections.toString(),
            label: 'Connections',
            color: CyberColors.neonPurple,
          ),

          const Spacer(),

          // Zoom Controls
          Row(
            children: [
              IconButton(
                onPressed: onZoomOut,
                icon: Icon(
                  Icons.remove,
                  color: CyberColors.neonCyan,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: CyberColors.neonCyan.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onReset,
                icon: Icon(
                  Icons.center_focus_strong,
                  color: CyberColors.neonCyan,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: CyberColors.neonCyan.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onZoomIn,
                icon: Icon(
                  Icons.add,
                  color: CyberColors.neonCyan,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: CyberColors.neonCyan.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Zoom Controls ─────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.bgCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomIn,
            icon: Icon(Icons.add, color: CyberColors.neonCyan),
            tooltip: 'Zoom In',
          ),
          Container(
            height: 1,
            color: CyberColors.neonCyan.withOpacity(0.1),
          ),
          IconButton(
            onPressed: onReset,
            icon: Icon(Icons.center_focus_strong, color: CyberColors.neonCyan),
            tooltip: 'Reset View',
          ),
          Container(
            height: 1,
            color: CyberColors.neonCyan.withOpacity(0.1),
          ),
          IconButton(
            onPressed: onZoomOut,
            icon: Icon(Icons.remove, color: CyberColors.neonCyan),
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────

class _EmptyBoardState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CyberColors.neonCyan.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: CyberColors.neonCyan.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.hub,
              color: CyberColors.neonCyan,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Evidence Collected',
            style: CyberText.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Collect evidence in the Investigation Hub\nto build your evidence network.',
            style: CyberText.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CyberButton(
            label: 'Go to Investigation',
            icon: Icons.search,
            onTap: () {
              // Navigate back to investigation hub
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
