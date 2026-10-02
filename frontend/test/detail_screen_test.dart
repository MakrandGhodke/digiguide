// test/detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/screens/detail_screen.dart';
import 'package:frontend/models/landmark.dart';
import 'package:frontend/providers/favorites_provider.dart';

void main() {
  final Landmark sample = Landmark(
    id: 't1',
    name: 'Test Monument',
    shortDescription: 'Short',
    longDescription: 'Long description here',
    lat: 0.0,
    lng: 0.0,
    imageAsset: 'assets/images/old_town_gate.jpg',
  );

  testWidgets('DetailScreen shows landmark info and toggles favorite', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FavoritesProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(DetailScreen.routeName, arguments: {'landmark': sample, 'imagePath': null});
                },
                child: const Text('Go'),
              );
            },
          ),
          routes: {
            DetailScreen.routeName: (ctx) => const DetailScreen(),
          },
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    // Check landmark name and description
    expect(find.text('Test Monument'), findsOneWidget);
    expect(find.text('Short'), findsOneWidget);
    expect(find.text('Long description here'), findsOneWidget);

    // Favorite button should appear, tap toggles icon
    final favButton = find.byIcon(Icons.favorite_border);
    expect(favButton, findsOneWidget);
    await tester.tap(favButton);
    await tester.pumpAndSettle();

    // Now should be filled heart
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
