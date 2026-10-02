import 'package:flutter/foundation.dart';
import '../models/landmark.dart';

class FavoritesProvider with ChangeNotifier {
  final List<Landmark> _favorites = [];

  List<Landmark> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favorites.any((lm) => lm.id == id);

  void toggleFavorite(Landmark lm) {
    if (isFavorite(lm.id)) {
      _favorites.removeWhere((item) => item.id == lm.id);
    } else {
      _favorites.add(lm);
    }
    notifyListeners();
  }
}
