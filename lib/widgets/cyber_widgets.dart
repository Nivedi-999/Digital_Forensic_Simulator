// lib/widgets/cyber_widgets.dart
// ═══════════════════════════════════════════════════════════════
//  Shared UI Widgets — CyberInvestigator
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

// ─────────────────────────────────────────────────────────────
//  NeonContainer
// ─────────────────────────────────────────────────────────────
class NeonContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const NeonContainer({
    super.key,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? CyberColors.neonCyan;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.medium,
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CyberButton
// ─────────────────────────────────────────────────────────────
class CyberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool isOutlined;
  final bool isSmall;
  final double? fontSize;

  const CyberButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.accentColor,
    this.isOutlined = false,
    this.isSmall = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? CyberColors.neonCyan;
    final fSize = fontSize ?? (isSmall ? 13.0 : 15.0);
    final vPad = isSmall ? 10.0 : 14.0;
    final hPad = isSmall ? 16.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.15),
          borderRadius: CyberRadius.medium,
          border: Border.all(
            color: onTap != null ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: onTap != null && !isOutlined
              ? [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: onTap != null ? color : color.withOpacity(0.4),
                size: isSmall ? 18 : 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? color : color.withOpacity(0.4),
                fontSize: fSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  StatusChip
// ─────────────────────────────────────────────────────────────
class StatusChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.pulsing = false,
  });

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(
              widget.pulsing ? 0.08 * _anim.value + 0.06 : 0.1),
          borderRadius: CyberRadius.pill,
          border: Border.all(
            color: widget.color.withOpacity(
                widget.pulsing ? 0.5 * _anim.value + 0.2 : 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.pulsing) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color
                      .withOpacity(0.6 * _anim.value + 0.4),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CyberSectionHeader
// ─────────────────────────────────────────────────────────────
class CyberSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? color;

  const CyberSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CyberColors.neonCyan;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: subtitle != null ? 36 : 20,
            decoration: BoxDecoration(
              color: c,
              borderRadius: CyberRadius.pill,
              boxShadow: [
                BoxShadow(color: c.withOpacity(0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CyberText.sectionTitle.copyWith(color: c),
              ),
              if (subtitle != null)
                Text(subtitle!, style: CyberText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LogRow  ← FIXED: left is constrained width, right is Expanded
//  This prevents the left column from going narrow and stacking
//  text characters vertically.
// ─────────────────────────────────────────────────────────────
class LogRow extends StatelessWidget {
  final String left;
  final String right;
  final bool highlighted;
  final VoidCallback? onTap;

  const LogRow({
    super.key,
    required this.left,
    required this.right,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
    highlighted ? CyberColors.neonAmber : CyberColors.neonCyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CyberRadius.small,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: highlighted
                ? CyberColors.neonAmber.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: CyberRadius.small,
            border: highlighted
                ? Border.all(
                color: CyberColors.neonAmber.withOpacity(0.25), width: 1)
                : null,
          ),
          child: Row(
            children: [
              // ── Left: sender / filename — fixed max width, never shrinks
              //    to zero which was causing vertical character stacking
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60, maxWidth: 90),
                child: Text(
                  left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Right: message / value — takes all remaining space
              Expanded(
                child: Text(
                  right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlighted
                        ? CyberColors.neonAmber
                        : CyberColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),

              // ── Chevron
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: accentColor.withOpacity(0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FeedTabButton
// ─────────────────────────────────────────────────────────────
class FeedTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const FeedTabButton({
    super.key,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? CyberColors.neonCyan.withOpacity(0.15)
              : CyberColors.bgCard,
          borderRadius: CyberRadius.pill,
          border: Border.all(
            color: isActive
                ? CyberColors.neonCyan
                : CyberColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: CyberColors.neonCyan.withOpacity(0.2),
              blurRadius: 8,
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? CyberColors.neonCyan : CyberColors.textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SuspectCard
// ─────────────────────────────────────────────────────────────
class SuspectCard extends StatelessWidget {
  final String suspectId; // used to load assets/avatars/<suspectId>.png
  final String name;
  final String role;
  final String riskLevel; // 'high' | 'medium' | 'low'
  /// Live suspicion value from CaseEngine (0.0–1.0).
  /// Drives the mini suspicion bar shown on the card.
  final double suspicionValue;
  final VoidCallback? onTap;

  const SuspectCard({
    super.key,
    required this.suspectId,
    required this.name,
    required this.role,
    required this.riskLevel,
    this.suspicionValue = 0.05,
    this.onTap,
  });

  Color get _riskColor {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return CyberColors.neonRed;
      case 'medium': return CyberColors.neonAmber;
      default:       return CyberColors.neonGreen;
    }
  }

  /// Suspicion bar colour shifts from cyan → amber → red as value rises.
  Color _suspicionColor(double v) {
    if (v >= 0.65) return CyberColors.neonRed;
    if (v >= 0.35) return CyberColors.neonAmber;
    return CyberColors.neonCyan;
  }

  String _suspicionLabel(double v) {
    if (v >= 0.65) return 'HIGH';
    if (v >= 0.35) return 'MED';
    return 'LOW';
  }

  /// Returns an icon that represents the suspect's role visually.
  IconData _avatarIcon() {
    final r = role.toLowerCase();
    if (r.contains('engineer') || r.contains('developer') || r.contains('devops')) {
      return Icons.code;
    } else if (r.contains('finance') || r.contains('analyst') || r.contains('account')) {
      return Icons.account_balance_outlined;
    } else if (r.contains('admin') || r.contains('manager') || r.contains('director')) {
      return Icons.manage_accounts_outlined;
    } else if (r.contains('hr') || r.contains('human')) {
      return Icons.people_outline;
    } else if (r.contains('student') || r.contains('intern')) {
      return Icons.school_outlined;
    } else if (r.contains('security') || r.contains('forensic')) {
      return Icons.security;
    } else if (r.contains('vendor') || r.contains('consultant')) {
      return Icons.business_center_outlined;
    } else if (r.contains('network') || r.contains('telecom')) {
      return Icons.router_outlined;
    } else {
      return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor;
    final susColor = _suspicionColor(suspicionValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CyberRadius.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CyberColors.bgCard,
            borderRadius: CyberRadius.medium,
            border: Border.all(
              // Border glows with suspicion colour once elevated
              color: suspicionValue >= 0.35
                  ? susColor.withOpacity(0.5)
                  : riskColor.withOpacity(0.25),
              width: suspicionValue >= 0.35 ? 1.8 : 1.2,
            ),
            boxShadow: suspicionValue >= 0.65
                ? [BoxShadow(
              color: susColor.withOpacity(0.18),
              blurRadius: 12,
              spreadRadius: 1,
            )]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Photo-realistic avatar placeholder ──
                  // Uses a layered design: background gradient + role icon + initials
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          riskColor.withOpacity(0.25),
                          riskColor.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                        color: suspicionValue >= 0.35
                            ? susColor.withOpacity(0.7)
                            : riskColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/avatars/$suspectId.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Stack(
                          alignment: Alignment.center,
                          children: [
                            // Role-based background icon (large, faded)
                            Icon(
                              _avatarIcon(),
                              color: riskColor.withOpacity(0.25),
                              size: 28,
                            ),
                            // Initials overlay
                            Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Name + role ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: CyberColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(role, style: CyberText.caption),
                      ],
                    ),
                  ),

                  // ── Suspicion badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: susColor.withOpacity(0.12),
                      borderRadius: CyberRadius.pill,
                      border: Border.all(
                          color: susColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      _suspicionLabel(suspicionValue),
                      style: TextStyle(
                        color: susColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right,
                      color: riskColor.withOpacity(0.4), size: 18),
                ],
              ),

              // ── Live suspicion bar ──
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 62), // align under name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SUSPICION',
                              style: TextStyle(
                                color: CyberColors.textMuted,
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${(suspicionValue * 100).toInt()}%',
                              style: TextStyle(
                                color: susColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: suspicionValue,
                            minHeight: 5,
                            backgroundColor:
                            CyberColors.borderSubtle.withOpacity(0.5),
                            valueColor:
                            AlwaysStoppedAnimation(susColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TimelineItem
// ─────────────────────────────────────────────────────────────
class TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final bool isLast;
  final Color? accentColor;

  const TimelineItem({
    super.key,
    required this.time,
    required this.title,
    required this.description,
    this.isLast = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? CyberColors.neonCyan;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dot + line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.6), blurRadius: 8)
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: color.withOpacity(0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: CyberText.caption),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: TextStyle(
                      color: CyberColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: CyberText.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CyberProgressBar
// ─────────────────────────────────────────────────────────────
class CyberProgressBar extends StatelessWidget {
  final double value; // 0.0 → 1.0
  final double height;
  final Color? color;

  const CyberProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CyberColors.neonCyan;
    return LayoutBuilder(builder: (_, constraints) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: CyberRadius.pill,
          border:
          Border.all(color: c.withOpacity(0.25), width: 1),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: CyberRadius.pill,
                gradient: LinearGradient(
                  colors: [c.withOpacity(0.7), c],
                ),
                boxShadow: [
                  BoxShadow(
                      color: c.withOpacity(0.5), blurRadius: 6)
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  MetricTile
// ─────────────────────────────────────────────────────────────
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CyberColors.neonCyan;
    return NeonContainer(
      borderColor: c,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: CyberRadius.small,
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CyberText.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: c,
                    fontSize: 22,
                    fontFamily: 'DotMatrix',
                    shadows: [Shadow(color: c, blurRadius: 10)],
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

// ─────────────────────────────────────────────────────────────
//  ScanlineOverlay  (subtle scanline texture over backgrounds)
// ─────────────────────────────────────────────────────────────
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _ScanlinePainter()),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}