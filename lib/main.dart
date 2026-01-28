import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CyberInvestigatorApp());
}

class CyberInvestigatorApp extends StatelessWidget {
  const CyberInvestigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyber Investigator',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainMenuScreen(),
    );
  }
}
