import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  final Color neonCyan = const Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Decorative Cyber Lines
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: LinePainter(neonCyan),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // Title
                  Text(
                    'Cyber Investigator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonCyan,
                      fontSize: 35,
                      fontFamily: 'DotMatrix',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Simulation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonCyan,
                      fontSize: 35,
                      fontFamily: 'DotMatrix',
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 100),

                  // Start Investigation
                  _buildCyberButton(
                    context,
                    "New Investigation",
                  ),

                  const SizedBox(height: 50),

                  // Continue Investigation
                  _buildCyberButton(
                    context,
                    "Continue Investigation",
                  ),

                  const Spacer(),

                  // Rank & XP
                  _buildRankBox(),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cyber Button
  Widget _buildCyberButton(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigator.push to Case List screen
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: neonCyan.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: neonCyan,
              fontSize: 28,
              fontFamily: 'DotMatrix',
            ),
          ),
        ),
      ),
    );
  }

  // Rank & XP Box
  Widget _buildRankBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rank: Junior Analyst",
            style: TextStyle(
              color: neonCyan,
              fontSize: 28,
              fontFamily: 'DotMatrix',
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                "XP: ",
                style: TextStyle(
                  color: neonCyan,
                  fontSize: 28,
                  fontFamily: 'DotMatrix',
                ),
              ),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: neonCyan.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: neonCyan,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: neonCyan, blurRadius: 8),
                        ],
                      ),
                    ),
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

// Cyber Decorative Lines Painter
class LinePainter extends CustomPainter {
  final Color color;
  LinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(20, 0);
    path.lineTo(20, 40);
    path.lineTo(60, 40);
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width, 100),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, 50),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
