// lib/widgets/crime_board.dart
// ═══════════════════════════════════════════════════════════════
//  CRIME BOARD — Visual pinboard replacing the evidence feed list
//
//  Layout: dark corkboard with evidence cards pinned at slight
//  random angles. Each card shows type icon + short label + pin.
//  Tap a card → slides in from right to EvidenceAnalysisScreen.
//  Collected evidence cards get a green "MARKED" stamp overlay.
//  Hidden/locked items show a padlock until mini-game solved.
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import '../models/evidence.dart';
import '../logic/game_engine.dart';

class CrimeBoard extends StatefulWidget {
  final EvidencePanel panel;
  final CaseEngine engine;
  final void Function(String panelId, String itemId) onItemTap;

  const CrimeBoard({
    super.key,
    required this.panel,
    required this.engine,
    required this.onItemTap,
  });

  @override
  State<CrimeBoard> createState() => _CrimeBoardState();
}

class _CrimeBoardState extends State<CrimeBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  // Per-card entry animations
  final List<Animation<double>> _cardFades = [];
  final List<Animation<Offset>> _cardSlides = [];

  // Stable random angles & positions seeded by panel id so they
  // never change between rebuilds.
  late final List<double> _angles= [];
  late final List<Offset> _offsets= [];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _buildCardAnimations();
  }

  void _buildCardAnimations() {
    final items = widget.engine.visibleItemsForPanel(widget.panel.id);
    final total = items.length;
    final rng = Random(widget.panel.id.hashCode);

    _angles.clear();
    _offsets.clear();

    for (int i = 0; i < total; i++) {
      // Stagger per card
      final start = (i / total) * 0.6;
      final end   = start + 0.4;

      _cardFades.add(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
      _cardSlides.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        )),
      );

      // Random tilt: −7° to +7°
      _angles.add((rng.nextDouble() - 0.5) * 14 * pi / 180);
      // Slight random positional nudge (painted inside each card's Transform)
      _offsets.add(Offset(
        (rng.nextDouble() - 0.5) * 6,
        (rng.nextDouble() - 0.5) * 6,
      ));
    }
  }

  // Keep these as fields so initState can call clear()
  @override
  void didUpdateWidget(CrimeBoard old) {
    super.didUpdateWidget(old);
    if (old.panel.id != widget.panel.id) {
      _cardFades.clear();
      _cardSlides.clear();
      _buildCardAnimations();
      _entryCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.engine.visibleItemsForPanel(widget.panel.id);

    // Board: dark panel with subtle grid texture via CustomPaint
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: items.isEmpty ? 120 : 0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1220),
        borderRadius: CyberRadius.medium,
        border: Border.all(color: CyberColors.borderSubtle, width: 1),
      ),
      child: Stack(children: [
        // Subtle grid lines
        Positioned.fill(
          child: ClipRRect(
            borderRadius: CyberRadius.medium,
            child: CustomPaint(painter: _BoardGridPainter()),
          ),
        ),

        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No evidence items in this panel.',
                style: GoogleFonts.inter(
                    color: CyberColors.textMuted, fontSize: 12)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              children: List.generate(items.length, (i) {
                final item  = items[i];
                final angle = i < _angles.length ? _angles[i] : 0.0;
                final fade  = i < _cardFades.length
                    ? _cardFades[i]
                    : const AlwaysStoppedAnimation(1.0);
                final slide = i < _cardSlides.length
                    ? _cardSlides[i]
                    : const AlwaysStoppedAnimation(Offset.zero);

                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: _EvidenceCard(
                      item: item,
                      panel: widget.panel,
                      engine: widget.engine,
                      angle: angle,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onItemTap(widget.panel.id, item.id);
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EVIDENCE CARD
// ─────────────────────────────────────────────────────────────

class _EvidenceCard extends StatefulWidget {
  final EvidenceItem item;
  final EvidencePanel panel;
  final CaseEngine engine;
  final double angle;
  final VoidCallback onTap;

  const _EvidenceCard({
    required this.item,
    required this.panel,
    required this.engine,
    required this.angle,
    required this.onTap,
  });

  @override
  State<_EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<_EvidenceCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // Colours per evidence type
  Color _typeColor() {
    switch (widget.panel.evidenceType) {
      case 'chat':  return CyberColors.neonBlue;
      case 'files': return CyberColors.neonPurple;
      case 'meta':  return CyberColors.neonAmber;
      case 'ip':    return CyberColors.neonCyan;
      default:      return CyberColors.neonGreen;
    }
  }

  IconData _typeIcon() {
    switch (widget.panel.evidenceType) {
      case 'chat':  return Icons.chat_bubble_outline_rounded;
      case 'files': return Icons.description_outlined;
      case 'meta':  return Icons.data_object_rounded;
      case 'ip':    return Icons.wifi_rounded;
      default:      return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCollected = widget.engine.isEvidenceCollected(widget.item.id);
    final isLocked    = widget.item.isHidden &&
        !widget.engine.isHiddenItemUnlocked(widget.item.id);
    final isSuspect   = widget.item.isSuspectMessage;
    final color       = isSuspect ? CyberColors.neonRed : _typeColor();

    // Short label — max 2 lines worth
    final label = widget.item.sender ?? widget.item.label;
    final shortLabel = label.length > 36 ? '${label.substring(0, 34)}…' : label;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _pressCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _pressCtrl.reverse();
        if (!isLocked) widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _pressCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(widget.angle)
            ..scale(_pressAnim.value),
          child: child,
        ),
        child: SizedBox(
          width: 130,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Card body ──
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1A2B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCollected
                        ? CyberColors.neonGreen.withOpacity(0.5)
                        : color.withOpacity(0.25),
                    width: isCollected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isCollected ? 0.15 : 0.08),
                      blurRadius: isCollected ? 14 : 6,
                      offset: const Offset(2, 3),
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: icon row
                    Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isLocked
                            ? Icon(Icons.lock_outline,
                                color: CyberColors.textMuted, size: 15)
                            : Icon(_typeIcon(), color: color, size: 15),
                      ),
                      const Spacer(),
                      if (widget.item.isKeyEvidence && !isLocked)
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CyberColors.neonAmber,
                            boxShadow: [BoxShadow(
                                color: CyberColors.neonAmber.withOpacity(0.7),
                                blurRadius: 5)],
                          ),
                        ),
                    ]),

                    const SizedBox(height: 10),

                    // Label
                    Text(
                      isLocked ? 'ENCRYPTED' : shortLabel,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isLocked
                            ? CyberColors.textMuted
                            : CyberColors.textPrimary,
                        fontSize: 10,
                        height: 1.4,
                        fontStyle: isLocked ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom type tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isLocked
                            ? 'LOCKED'
                            : widget.panel.evidenceType.toUpperCase(),
                        style: GoogleFonts.shareTechMono(
                          color: isLocked ? CyberColors.textMuted : color,
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pin ──
              Positioned(
                top: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: _Pin(color: isCollected ? CyberColors.neonGreen : color),
                ),
              ),

              // ── MARKED stamp (collected) ──
              if (isCollected)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _MarkedStamp(),
                  ),
                ),

              // ── Suspect warning ribbon ──
              if (isSuspect && !isLocked)
                Positioned(
                  top: 4,
                  right: -2,
                  child: Container(
                    width: 6, height: 36,
                    decoration: BoxDecoration(
                      color: CyberColors.neonRed.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
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

// ─────────────────────────────────────────────────────────────
//  PIN WIDGET
// ─────────────────────────────────────────────────────────────

class _Pin extends StatelessWidget {
  final Color color;
  const _Pin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Pin head
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.7), blurRadius: 6),
          ],
        ),
      ),
      // Pin shaft
      Container(
        width: 1.5, height: 6,
        color: color.withOpacity(0.5),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  MARKED STAMP
// ─────────────────────────────────────────────────────────────

class _MarkedStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Transform.rotate(
          angle: -0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                  color: CyberColors.neonGreen.withOpacity(0.7), width: 1.5),
              borderRadius: BorderRadius.circular(3),
              color: CyberColors.neonGreen.withOpacity(0.06),
            ),
            child: Text(
              'MARKED',
              style: GoogleFonts.orbitron(
                color: CyberColors.neonGreen.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOARD GRID PAINTER
// ─────────────────────────────────────────────────────────────

class _BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.025)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BoardGridPainter _) => false;
}
