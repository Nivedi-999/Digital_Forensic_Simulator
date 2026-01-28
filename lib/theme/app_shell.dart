import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔹 BACKGROUND IMAGE
        Positioned.fill(
          child: Image.asset(
            'lib/assets/background.png',
            fit: BoxFit.cover,
          ),
        ),

        // 🔹 OPTIONAL: subtle vignette (recommended)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(),
                ],
              ),
            ),
          ),
        ),

        // 🔹 SCREEN CONTENT
        child,
      ],
    );
  }
}
