import 'package:flutter/material.dart';

void main() {
  runApp(const CyberInvestigatorApp());
}

class CyberInvestigatorApp extends StatelessWidget {
  const CyberInvestigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  final Color neonCyan = const Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Image (Based on your file structure: assets/img.png)
          Positioned.fill(
            child: Image.asset(
              'assets/img.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Background Decorative Lines (Painter remains as an overlay)
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
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

                  // Title Section - Split into two lines as requested
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
                      letterSpacing: 4.0,
                    ),
                  ),

                  const SizedBox(height: 100),

                  // Buttons - Increased height for "Start New" using verticalPadding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                    child: _buildCyberButton(
                      " New investigation",
                      verticalPadding: 25,

                    ),
                  ),

                  const SizedBox(height: 80),
                  _buildCyberButton(
                    "Continue investigation",
                    verticalPadding: 25, // Standard height
                  ),

                  const Spacer(),

                  // Rank & XP Section
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

  // Neon Border Button Widget
  Widget _buildCyberButton(String label, {double verticalPadding = 20}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        border: Border.all(color: neonCyan.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: neonCyan.withOpacity(0.1),
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
    );
  }

  // Rank and XP Progress Bar
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

class LinePainter extends CustomPainter {
  final Color color;
  LinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.moveTo(20, 0);
    path.lineTo(20, 40);
    path.lineTo(60, 40);
    canvas.drawPath(path, paint);

    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width, 100), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, 50), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}