// lib/screens/detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/landmark.dart';
import '../providers/favorites_provider.dart';

class DetailScreen extends StatelessWidget {
  static const routeName = '/detail';
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Landmark lm = args['landmark'] as Landmark;
    final String? imagePath = args['imagePath'] as String?;
    final favProv = Provider.of<FavoritesProvider>(context);
    final theme = Theme.of(context);

    final heroTag = imagePath?.isNotEmpty == true ? imagePath! : lm.id;

    Widget headerImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      headerImage = Image.file(File(imagePath), width: double.infinity, height: 240, fit: BoxFit.cover);
    } else {
      headerImage = Image.asset(lm.imageAsset, width: double.infinity, height: 240, fit: BoxFit.cover);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lm.name),
        actions: [
          Semantics(
            button: true,
            label: favProv.isFavorite(lm.id) ? 'Unfavorite' : 'Add to favorites',
            child: IconButton(
              icon: Icon(favProv.isFavorite(lm.id) ? Icons.favorite : Icons.favorite_border),
              onPressed: () => favProv.toggleFavorite(lm),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero wraps the header for shared element transition
            Hero(
              tag: heroTag,
              child: Semantics(
                label: 'Image of ${lm.name}',
                child: headerImage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lm.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(lm.shortDescription, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 6),
                      Text('${lm.lat.toStringAsFixed(4)}, ${lm.lng.toStringAsFixed(4)}'),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Get directions to ${lm.name}',
                        child: ElevatedButton.icon(
                          onPressed: () {}, // TODO: open directions
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('About', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(lm.longDescription),
                  const SizedBox(height: 20),
                  Semantics(
                    button: true,
                    label: 'Share ${lm.name}',
                    child: ElevatedButton.icon(
                      onPressed: () {}, // TODO: share functionality
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
