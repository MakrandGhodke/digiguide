import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import 'landmark_result_screen.dart';
import '../config.dart';

class FavoritesScreen extends StatelessWidget {
  static const routeName = '/favorites';
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favProv = Provider.of<FavoritesProvider>(context);
    final favs = favProv.favorites;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: favs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              itemBuilder: (ctx, i) {
                final lm = favs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  color: theme.cardTheme.color,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        LandmarkResultScreen.routeName,
                        arguments: {'landmark': lm},
                      );
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: lm.imageAsset.isNotEmpty
                              ? Image.network(
                                  '${Config.imagesUrl}/${lm.imageAsset}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lm.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lm.shortDescription,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () {
                            favProv.toggleFavorite(lm);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
