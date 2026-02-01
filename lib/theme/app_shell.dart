import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final bool showBack;
  final String? title;

  const AppShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.title,
  });

  // ───── THEME COLORS ─────
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color bgBlack = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [ // ───── BACKGROUND IMAGE ─────
          Positioned.fill(
            child: Image.asset(
              'lib/assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // ───── CYBER LINE ─────
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _CyberLinePainter(neonCyan),
          ),
          // ───── CONTENT ─────
          SafeArea(
            child: Column(
              children: [
                // ───── TOP BAR ─────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back Button
                      if (showBack && Navigator.canPop(context))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: neonCyan,
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                      // Title (centered, but slightly nudged left)
                      if (title != null)
                        Transform.translate(
                          offset: const Offset(0, 0),
                          child: Text(
                            title!,
                            style: const TextStyle(
                              color: neonCyan,
                              fontSize: 35,
                              fontFamily: 'DotMatrix',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // SCREEN CONTENT
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ───────────────── CYBER LINE PAINTER ─────────────────
class _CyberLinePainter extends CustomPainter { final Color color; _CyberLinePainter(this.color);
@override void paint(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = color.withOpacity(0.3)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final path = Path(); path.moveTo(20, 0);
  path.lineTo(20, 40); path.lineTo(60, 40);
  canvas.drawPath(path, paint);
  canvas.drawLine( Offset(size.width * 0.7, 0), Offset(size.width, 100), paint, );
  canvas.drawLine( Offset(size.width * 0.7, 0), Offset(size.width * 0.7, 50), paint, );
}
@override
bool shouldRepaint(CustomPainter oldDelegate) => false;
}