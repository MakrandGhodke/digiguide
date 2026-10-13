import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/landmark.dart';
import '../services/recent_history_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/tactile_bounce.dart';
import 'landmark_result_screen.dart';

class AIProcessingScreen extends StatefulWidget {
  static const routeName = '/processing';

  final File imageFile;

  const AIProcessingScreen({super.key, required this.imageFile});

  @override
  State<AIProcessingScreen> createState() => _AIProcessingScreenState();
}

class _AIProcessingScreenState extends State<AIProcessingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final List<String> _steps = [
    'Analyzing visual features & architecture...',
    'Matching neural vectors against Darmstadt index...',
    'Synthesizing historical context & audio tour...',
  ];
  Timer? _stepTimer;

  String? _funFact;
  String? _funFactLandmarkName;

  late AnimationController _scanLaserController;
  late Animation<double> _scanLaserAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();
    _fetchFunFact();
    _performRecognition();
  }

  void _initAnimations() {
    // Holographic Laser Scan Line Animation
    _scanLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanLaserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanLaserController,
        curve: Curves.easeInOut,
      ),
    );

    // Radar Concentric Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  void _startAnimation() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (_currentStep < _steps.length - 1) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
        }
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

          if (facts.isNotEmpty && mounted) {
            setState(() {
              _funFactLandmarkName = first['name'];
              _funFact = facts[DateTime.now().millisecond % facts.length];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching trivia: $e");
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _scanLaserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _performRecognition() async {
    final uri = Uri.parse(Config.predictUrl);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', widget.imageFile.path),
      );

      try {
        Position? position = await _determinePosition();
        if (position != null) {
          request.fields['latitude'] = position.latitude.toString();
          request.fields['longitude'] = position.longitude.toString();
        }
      } catch (e) {
        debugPrint('Location attachment error: $e');
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['predictions'] != null) {
          final List<dynamic> predictionsJson = data['predictions'];
          final List<Landmark> landmarks = predictionsJson
              .map((json) => Landmark.fromJson(json))
              .toList();

          if (landmarks.isNotEmpty) {
            final first = landmarks[0];
            if (first.id != '-1' && first.id != 'unknown') {
              RecentHistoryService().addLandmark(first);
            }
          }

          // Ensure cinematic minimum time so the user experiences the vision analysis
          await Future.delayed(const Duration(milliseconds: 1800));

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            LandmarkResultScreen.routeName,
            arguments: {'landmarks': landmarks, 'imageFile': widget.imageFile},
          );
        } else {
          _showError('Missing prediction data from vision server.');
        }
      } else {
        _showError('Server error: HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      _showError('Server took too long to respond. Please snap again.');
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.obsidian950,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Top App Bar / Dismiss
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TactileBounce(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.coral500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.coral500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.coral500,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Vision AI Active',
                            style: TextStyle(
                              color: AppTheme.coral500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // -------------------------------------------------------------
                // HOLOGRAPHIC SCANNER VIEWPORT WITH LASER LINE
                // -------------------------------------------------------------
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Pulse Rings
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 250 * _pulseAnimation.value,
                            height: 250 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.coral500.withValues(
                                  alpha: (1.4 - _pulseAnimation.value).clamp(
                                    0.0,
                                    0.35,
                                  ),
                                ),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),

                      // Image Viewport
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.coral500.withValues(alpha: 0.25),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                            ),

                            // Ambient Tint
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),

                            // Holographic Laser Scanner Beam
                            AnimatedBuilder(
                              animation: _scanLaserAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanLaserAnimation.value * 190,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.coral500,
                                          Colors.white,
                                          AppTheme.coral500,
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.coral500,
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Reticle Corner Brackets
                            const Positioned(
                              top: 10,
                              left: 10,
                              child: Icon(
                                Icons.crop_free_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // -------------------------------------------------------------
                // PROGRESSIVE NEURAL STEPS
                // -------------------------------------------------------------
                SizedBox(
                  width: 300,
                  child: Column(
                    children: List.generate(_steps.length, (index) {
                      final isCompleted = index < _currentStep;
                      final isCurrent = index == _currentStep;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? AppTheme.emeraldLive
                                    : (isCurrent
                                        ? AppTheme.coral500
                                        : Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : (isCurrent
                                        ? Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _steps[index],
                                style: TextStyle(
                                  color: isCurrent
                                      ? Colors.white
                                      : (isCompleted
                                          ? AppTheme.emeraldLive
                                          : Colors.white38),
                                  fontSize: 13,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(flex: 1),

                // -------------------------------------------------------------
                // FLOATING TRIVIA / FUN FACT CARD
                // -------------------------------------------------------------
                if (_funFact != null)
                  AppGlass.container(
                    context: context,
                    blur: AppGlass.blurThin,
                    opacity: 0.15,
                    borderOpacity: 0.12,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              color: AppTheme.amber400,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _funFactLandmarkName != null
                                  ? "Did you know about $_funFactLandmarkName?"
                                  : "While we identify this: Did you know?",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.amber400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _funFact!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 60),

                const SizedBox(height: 16),

                // Security & Privacy Caption
                Text(
                  'Processed with on-device GPS & DigiGuide Vision Embeddings',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
