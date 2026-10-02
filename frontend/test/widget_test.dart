// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('DigiGuide loads HomeScreen', (WidgetTester tester) async {
    // Build the DigiGuide app
    await tester.pumpWidget(const DigiGuideApp());

    // Check app title in the AppBar
    expect(find.text('DigiGuide'), findsOneWidget);

    // Check important UI elements
    expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Take Photo button
    expect(find.text('Scan'), findsOneWidget);             // Scan button
  });
}
