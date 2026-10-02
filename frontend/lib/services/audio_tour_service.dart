import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/landmark.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show asin, cos, sqrt, pi, sin, pow;

class AudioTourService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String _currentSpeakingLandmarkId = '';
  // Keep track of landmarks we've already narrated in this session to avoid repetition
  final Set<String> _narratedLandmarkIds = {};

  // Settings
  static const double activationRadiusKm = 0.10; // 100 meters
  bool _isEnabled = false;

  bool get isSpeaking => _isSpeaking;
  bool get isEnabled => _isEnabled;
  String get currentSpeakingLandmarkId => _currentSpeakingLandmarkId;

  AudioTourService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower, more natural
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentSpeakingLandmarkId = ''; // Reset ID on completion
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _currentSpeakingLandmarkId = '';
      notifyListeners();
      if (kDebugMode) {
        print("TTS Error: $msg");
      }
    });
  }

  void toggleTour(bool value) {
    _isEnabled = value;
    if (!_isEnabled) {
      stop();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _currentSpeakingLandmarkId = '';
    notifyListeners();
  }

  Future<void> playSpecificLandmark(Landmark landmark) async {
    // 1. Stop current speech if any
    await _flutterTts.stop();

    // 2. Set State
    _currentSpeakingLandmarkId = landmark.id;
    _isSpeaking = true;
    notifyListeners();

    // 3. Speak
    String text = landmark.speechText;
    if (text.isEmpty) {
      text = "${landmark.name}. ${landmark.shortDescription}";
    }

    await _flutterTts.speak(text);
  }

  // Called periodically or on location update
  void checkProximity(Position position, List<Landmark> nearbyLandmarks) {
    if (!_isEnabled || _isSpeaking) return;

    for (var landmark in nearbyLandmarks) {
      double distKm = _calculateDistance(
        position.latitude,
        position.longitude,
        landmark.lat,
        landmark.lng,
      );

      // DEBUG LOG
      debugPrint(
        "Checking Proximity: ${landmark.name} is ${distKm.toStringAsFixed(3)} km away",
      );

      if (distKm <= activationRadiusKm) {
        debugPrint("WITHIN RANGE! triggers speak for ${landmark.id}");
        if (!_narratedLandmarkIds.contains(landmark.id) &&
            landmark.speechText.isNotEmpty) {
          _speak(landmark);
          break; // Only narrate one at a time
        }
      }
    }
  }

  Future<void> _speak(Landmark landmark) async {
    if (_isSpeaking) return;

    _narratedLandmarkIds.add(landmark.id);
    _currentSpeakingLandmarkId = landmark.id;

    // Play a chime or just start speaking?
    // Just speak for MVP.
    String text = landmark.speechText;
    if (text.isEmpty) {
      // Fallback
      text = "You are near ${landmark.name}. ${landmark.shortDescription}";
    }

    await _flutterTts.speak(text);
  }

  // Haversine formula for local distance calculation
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
