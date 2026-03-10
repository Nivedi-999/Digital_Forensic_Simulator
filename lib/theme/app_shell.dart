// lib/theme/app_shell.dart
// ═══════════════════════════════════════════════════════════════
//  APP SHELL — Bottom nav navigates correctly through the engine tree
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';
import '../screens/evidence_collected_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/investigation_hub_screen.dart';
import '../state/active_case.dart';
import '../state/case_engine_provider.dart';
import '../widgets/cyber_widgets.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final bool showBack;
  final String? title;
  final int currentIndex;
  final bool showBottomNav;

  const AppShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.title,
    this.showBottomNav = true,
    this.currentIndex = 0,
  });

  static const Color neonCyan = CyberColors.neonCyan;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _onItemTapped(int index) {
    if (index == 0) {
      // Push a fresh hub wrapped in CaseEngineProvider.
      // ActiveCase.engine is always available once a case has been started.
      if (ActiveCase.isActive) {
        Navigator.push(
          context,
          _route(
            CaseEngineProvider(
              engine: ActiveCase.engine,
              child: const InvestigationHubScreen(),
            ),
          ),
        );
      }
    } else if (index == 1) {
      Navigator.push(context, _route(const EvidencesCollectedScreen()));
    } else if (index == 2) {
      Navigator.push(context, _route(const ProfileScreen()));
    }
  }

  PageRouteBuilder _route(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.bgDeep,
      extendBody: true,

      bottomNavigationBar: widget.showBottomNav
          ? _CyberBottomNav(
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      )
          : null,

      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: CyberColors.backgroundGradient,
              ),
            ),
          ),

          // Corner accent blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CyberColors.neonCyan.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CyberColors.neonPurple.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          const ScanlineOverlay(),
          const Positioned.fill(child: _CornerDecorations()),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(title: widget.title, showBack: widget.showBack),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? title;
  final bool showBack;

  const _TopBar({this.title, required this.showBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CyberColors.neonCyan.withOpacity(0.15),
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CyberColors.bgDeep.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack && Navigator.canPop(context))
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: CyberRadius.small,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: CyberColors.neonCyan.withOpacity(0.3),
                          width: 1),
                      borderRadius: CyberRadius.small,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: CyberColors.neonCyan,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DotMatrix',
                fontSize: 22,
                color: CyberColors.neonCyan,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: CyberColors.neonCyan, blurRadius: 12),
                ],
              ),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: StatusChip(
              label: 'ONLINE',
              color: CyberColors.neonGreen,
              pulsing: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────

class _CyberBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CyberBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.large,
        border: Border.all(
          color: CyberColors.neonCyan.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CyberColors.neonCyan.withOpacity(0.08),
            blurRadius: 24,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.manage_search_outlined,
            label: 'Hub',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.folder_outlined,
            label: 'Evidence',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? CyberColors.neonCyan.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: CyberRadius.medium,
          border: isActive
              ? Border.all(
              color: CyberColors.neonCyan.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? CyberColors.neonCyan : CyberColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color:
                isActive ? CyberColors.neonCyan : CyberColors.textMuted,
                fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Corner Decorations ────────────────────────────────────────

class _CornerDecorations extends StatelessWidget {
  const _CornerDecorations();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CornerPainter());
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const len = 28.0;

    canvas.drawPath(
      Path()
        ..moveTo(16, 16 + len)
        ..lineTo(16, 16)
        ..lineTo(16 + len, 16),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 16 - len, 16)
        ..lineTo(size.width - 16, 16)
        ..lineTo(size.width - 16, 16 + len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(16, size.height - 16 - len)
        ..lineTo(16, size.height - 16)
        ..lineTo(16 + len, size.height - 16),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter _) => false;
}