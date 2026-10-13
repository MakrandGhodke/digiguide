import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/floating_nav_bar.dart';
import 'camera_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Unified Application Navigation Shell
/// Keeps the FloatingGlassNavBar persistent across Home, Explore, and Profile tabs,
/// smoothly maintaining state with zero page reloads or broken back stacks.
class MainScreen extends StatefulWidget {
  static const routeName = '/home';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0 = Home, 1 = Explore, 2 = Profile

  final List<Widget> _pages = const [
    HomeScreen(isEmbeddedInShell: true),
    ExploreScreen(isEmbeddedInShell: true),
    ProfileScreen(isEmbeddedInShell: true),
  ];

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onScanPressed() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushNamed(CameraScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Content flows behind the floating glass dock
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: FloatingGlassNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onScanPressed: _onScanPressed,
      ),
    );
  }
}
