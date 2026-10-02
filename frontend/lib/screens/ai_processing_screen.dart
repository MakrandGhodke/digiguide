import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../models/landmark.dart';
import 'landmark_result_screen.dart';
import '../services/recent_history_service.dart';
import '../config.dart';

class AIProcessingScreen extends StatefulWidget {
  static const routeName = '/processing';

  final File imageFile;

  const AIProcessingScreen({super.key, required this.imageFile});

  @override
  State<AIProcessingScreen> createState() => _AIProcessingScreenState();
}

class _AIProcessingScreenState extends State<AIProcessingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Analyzing image...',
    'Identifying landmark...',
    'Synthesizing historical context...',
  ];
  Timer? _stepTimer;

  String? _funFact;
  String? _funFactLandmarkName;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _fetchFunFact(); // Start fetching fact immediately
    _performRecognition();
  }

  void _startAnimation() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchFunFact() async {
    try {
      final position = await _determinePosition();
      if (position == null) return;

      final uri = Uri.parse(Config.nearbyUrl);
      final response = await http.post(
        uri,
        body: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['landmarks'] != null &&
            (data['landmarks'] as List).isNotEmpty) {
          final first = data['landmarks'][0];
          final facts = List<String>.from(first['facts'] ?? []);

          if (facts.isNotEmpty) {
            if (mounted) {
              setState(() {
                _funFactLandmarkName = first['name'];
                _funFact =
                    facts[DateTime.now().millisecond %
                        facts.length]; // Random fact
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching fun fact: $e");
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _performRecognition() async {
    // API Endpoint - use Config for consistent IP
    final uri = Uri.parse(Config.predictUrl);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', widget.imageFile.path),
      );

      // Add Location Data
      try {
        Position? position = await _determinePosition();
        if (position != null) {
          request.fields['latitude'] = position.latitude.toString();
          request.fields['longitude'] = position.longitude.toString();
        }
      } catch (e) {
        debugPrint('Location error: $e');
        // Continue without location
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Expecting {"predictions": [...]}
        if (data != null && data['predictions'] != null) {
          final List<dynamic> predictionsJson = data['predictions'];
          final List<Landmark> landmarks = predictionsJson
              .map((json) => Landmark.fromJson(json))
              .toList();

          // Add to History Logic
          if (landmarks.isNotEmpty) {
            final first = landmarks[0];
            // If visual match, add it.
            // If location match (and not "Unknown" placeholder id -1), add it.
            // We'll trust the first item IS the best guess.
            if (first.id != '-1' && first.id != 'unknown') {
              RecentHistoryService().addLandmark(first);
            }
          }

          // Ensure minimum animation time
          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            LandmarkResultScreen.routeName,
            // Pass the entire list of landmarks
            arguments: {'landmarks': landmarks, 'imageFile': widget.imageFile},
          );
        } else {
          // Backward compatibility check or error
          _showError('Invalid server response: Missing predictions.');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop(); // Go back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview Image
            Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.only(bottom: 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(widget.imageFile, fit: BoxFit.cover),
                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pulse Animation
            Stack(
              alignment: Alignment.center,
              children: [
                // Rings w/ generic Pulse (implementing simple scale animation is better in separate widget, but using static for speed)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.coral500.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppTheme.coral500,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Steps
            SizedBox(
              width: 250,
              child: Column(
                children: List.generate(_steps.length, (index) {
                  final isActive = index <= _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentStep
                                ? AppTheme.coral500
                                : isActive
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _steps[index],
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.slate700
                                : AppTheme.slate400,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // FUN FACT SECTION
            if (_funFact != null) ...[
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.coral500.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: AppTheme.coral500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Fun Fact about $_funFactLandmarkName",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.coral500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _funFact!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.slate700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: const Text(
                'Powered by AI image recognition',
                style: TextStyle(fontSize: 12, color: AppTheme.slate500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('DEBUG: Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    debugPrint('DEBUG: Current permission status: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('DEBUG: Location permission denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('DEBUG: Location permission denied forever.');
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    debugPrint('DEBUG: Fetching current position...');
    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
      debugPrint(
        'DEBUG: Position fetched: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('DEBUG: Error getting position: $e');
      return null;
    }
  }
}
