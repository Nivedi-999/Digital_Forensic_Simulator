import 'package:flutter/material.dart';
import '../theme/app_shell.dart';
import '../screens/case_list_screen.dart';          // for "Cases"
import '../screens/evidence_collected_screen.dart'; // we'll create this next
import '../screens/profile_screen.dart';            // placeholder for now

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final bool showBack;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.showBack = true,
    this.currentIndex = 0,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate based on index
    if (index == 0) {
      // Cases → go to case list or home
      Navigator.pushReplacementNamed(context, '/cases');
    } else if (index == 1) {
      // Evidences Collected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EvidencesCollectedScreen()),
      );
    } else if (index == 2) {
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppShell.bgBlack,
      body: Stack(
        children: [
          // Background (if you have one)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar (like your AppShell)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      if (widget.showBack && Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppShell.neonCyan),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppShell.neonCyan,
                              fontSize: 28,
                              fontFamily: 'DotMatrix',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        selectedItemColor: AppShell.neonCyan,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_outlined),
            label: 'Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Evidences',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}