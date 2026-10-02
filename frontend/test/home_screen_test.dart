// test/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/detail_screen.dart';
import 'package:frontend/providers/favorites_provider.dart';

void main() {
  testWidgets('HomeScreen shows buttons and navigates to detail', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesProvider(),
        child: MaterialApp(
          home: const HomeScreen(),

          // FIXED: removed const
          routes: {
            DetailScreen.routeName: (ctx) => DetailScreen(),
          },
        ),
      ),
    );

    // Expect buttons
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);

    // Tap scan
    await tester.tap(find.text('Scan'));
    await tester.pump(); // begin async
    await tester.pump(const Duration(seconds: 1)); // finish mockRecognize

    // Check navigation to DetailScreen
    expect(find.byType(DetailScreen), findsOneWidget);
  });
}
