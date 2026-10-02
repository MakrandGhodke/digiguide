import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/landmark.dart';

class RecentHistoryService {
  static final RecentHistoryService _instance =
      RecentHistoryService._internal();

  factory RecentHistoryService() {
    return _instance;
  }

  RecentHistoryService._internal();

  static const String _storageKey = 'recent_landmarks';

  final ValueNotifier<List<Landmark>> recentLandmarksNotifier =
      ValueNotifier<List<Landmark>>([]);

  /// Load history from SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final landmarks = jsonList
            .map((json) => Landmark.fromJson(json))
            .toList();
        recentLandmarksNotifier.value = landmarks;
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  /// Save history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recentLandmarksNotifier.value
          .map((l) => l.toJson())
          .toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addLandmark(Landmark landmark) {
    // Avoid duplicates based on ID or Name
    final currentList = List<Landmark>.from(recentLandmarksNotifier.value);

    // Remove if exists (to move to top)
    currentList.removeWhere(
      (item) => item.id == landmark.id || item.name == landmark.name,
    );

    // Add to front
    currentList.insert(0, landmark);

    // Keep max 10
    if (currentList.length > 10) {
      currentList.removeLast();
    }

    recentLandmarksNotifier.value = currentList;

    // Persist to storage
    _saveHistory();
  }

  // Statistics Getters
  int get uniqueLandmarksCount => recentLandmarksNotifier.value.length;

  int get uniqueCitiesCount {
    final cities = recentLandmarksNotifier.value
        .map((l) => l.city)
        .where((c) => c != 'Unknown City')
        .toSet();
    return cities.length;
  }

  int get uniqueCountriesCount {
    final countries = recentLandmarksNotifier.value
        .map((l) => l.country)
        .where((c) => c != 'Unknown Country')
        .toSet();
    return countries.length;
  }
}
