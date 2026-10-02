import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 72, color: cs.onPrimary),
            const SizedBox(height: 12),
            Text('DigiGuide', style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Photo-powered landmark info', style: TextStyle(color: cs.onPrimary.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
}
