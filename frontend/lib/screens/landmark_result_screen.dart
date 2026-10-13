import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/landmark.dart';
import '../providers/favorites_provider.dart';
import '../services/audio_tour_service.dart';
import '../services/auth_service.dart';
import '../services/weather_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tactile_bounce.dart';
import 'home_screen.dart';

class LandmarkResultScreen extends StatefulWidget {
  static const routeName = '/result';

  const LandmarkResultScreen({super.key});

  @override
  State<LandmarkResultScreen> createState() => _LandmarkResultScreenState();
}

class _LandmarkResultScreenState extends State<LandmarkResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Landmark> _landmarks = [];
  File? _capturedImage;
  bool _showListView = false;
  WeatherData? _weather;
  bool _feedbackSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['landmarks'] != null) {
        _landmarks = (args['landmarks'] as List).cast<Landmark>();
      } else if (args['landmark'] != null) {
        _landmarks = [args['landmark'] as Landmark];
      }

      _capturedImage = args['imageFile'] as File?;

      if (_landmarks.isNotEmpty) {
        final first = _landmarks[0];
        bool showDetails =
            first.matchType == 'visual' || first.matchType == 'proximity';

        if (showDetails) {
          _showListView = false;
        } else {
          _showListView = _landmarks.length > 1;
        }
      }

      if (_landmarks.isNotEmpty && _weather == null) {
        _fetchWeather(_landmarks[0]);
      }
    }
  }

  Future<void> _submitFeedback(bool isGood, Landmark landmark) async {
    if (_feedbackSubmitted) return;
    if (landmark.imageId == null) return;

    setState(() => _feedbackSubmitted = true);
    HapticFeedback.mediumImpact();

    try {
      final token = AuthService.token;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please log in to submit AI training feedback'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image_id': landmark.imageId,
          'landmark_slug': landmark.id,
          'is_good': isGood,
          'comments': isGood ? 'Accurate match' : 'Inaccurate match',
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isGood
                    ? 'Thanks! Your feedback helps refine our vision model.'
                    : 'Thanks! We will recalibrate the landmark embeddings.',
              ),
              backgroundColor: isGood ? AppTheme.emeraldLive : AppTheme.amber500,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to record feedback at this time'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Feedback error: $e');
    }
  }

  Future<void> _fetchWeather(Landmark landmark) async {
    final weather = await WeatherService.fetchWeather(
      landmark.lat,
      landmark.lng,
    );
    if (mounted && weather != null) {
      setState(() => _weather = weather);
    }
  }

  void _onLandmarkSelected(Landmark landmark) {
    setState(() {
      _landmarks = [landmark];
      _showListView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_landmarks.isEmpty) {
      return Scaffold(
        body: Center(
          child: ShimmerLoader.box(
            context: context,
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
    }

    return _showListView
        ? _buildNearbyListView()
        : _buildDetailParallaxView(_landmarks[0]);
  }

  // ---------------------------------------------------------------------------
  // 1. DETAIL VIEW: STRETCHY PARALLAX HERO & SEGMENTED TABS
  // ---------------------------------------------------------------------------
  Widget _buildDetailParallaxView(Landmark landmark) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imageUrl = landmark.imageAsset.isNotEmpty
        ? '${Config.imagesUrl}/${landmark.imageAsset}'
        : 'https://images.unsplash.com/photo-1564507592333-c60657eea523?fit=crop&w=1200&h=800';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveContainer(
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppTheme.obsidian900 : Colors.white,
                elevation: 0,
                scrolledUnderElevation: 2,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: TactileBounce(
                      onTap: () {
                        Navigator.of(context).popUntil(
                          (route) => route.settings.name == HomeScreen.routeName,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: AppShadows.subtle(context),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: isDark ? Colors.white : AppTheme.slate800,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Weather Badge
                  if (_weather != null)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _weather!.icon,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_weather!.temperature}°C',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.slate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Favorite Action
                  Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFav = favProvider.isFavorite(landmark.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: TactileBounce(
                            onTap: () {
                              favProvider.toggleFavorite(landmark);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: AppShadows.subtle(context),
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: isFav
                                    ? AppTheme.coral500
                                    : (isDark
                                        ? Colors.white
                                        : AppTheme.slate800),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo
                      _capturedImage != null
                          ? Image.file(_capturedImage!, fit: BoxFit.cover)
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return ShimmerLoader.box(
                                  context: context,
                                  borderRadius: BorderRadius.zero,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark
                                      ? AppTheme.slate800
                                      : Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),

                      // Cinematic Vignette Gradient Overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),

                      // Floating Meta Badges & Title (Bottom Left of Header)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Recognition Match Pill
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (landmark.matchType == 'visual')
                                        ? AppTheme.emeraldLive
                                        : AppTheme.coral500,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        landmark.matchType == 'visual'
                                            ? Icons.verified_rounded
                                            : Icons.near_me_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        landmark.matchType == 'visual'
                                            ? 'Visual AI Match'
                                            : 'Proximity GPS Match',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Landmark Name
                            Text(
                              landmark.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Location Distance / Coordinates
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  landmark.distance > 0
                                      ? '${landmark.distance.toStringAsFixed(1)} km away • Darmstadt'
                                      : 'Lat: ${landmark.lat.toStringAsFixed(2)}, Lng: ${landmark.lng.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // PINNED SEGMENTED TABS (APPLE HIG PILL BAR)
              // -------------------------------------------------------------
              SliverPersistentHeader(
                pinned: true,
                delegate: _SegmentedTabHeaderDelegate(
                  tabController: _tabController,
                  isDark: isDark,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryTab(landmark),
              _buildCultureTab(landmark),
              _buildFactsTab(landmark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(landmark),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: HISTORY & EDITORIAL CONTEXT
  // ---------------------------------------------------------------------------
  Widget _buildHistoryTab(Landmark landmark) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Audio Guide Play Banner
          Consumer<AudioTourService>(
            builder: (context, tourService, child) {
              final isCurrentPlaying = tourService.isSpeaking &&
                  tourService.currentSpeakingLandmarkId == landmark.id;

              return TactileBounce(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isCurrentPlaying) {
                    tourService.stop();
                  } else {
                    tourService.playSpecificLandmark(landmark);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentPlaying
                        ? (isDark
                            ? AppTheme.emeraldLive.withValues(alpha: 0.18)
                            : const Color(0xFFE8FDF4))
                        : (isDark
                            ? AppTheme.coral500.withValues(alpha: 0.15)
                            : AppTheme.coral50),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCurrentPlaying
                          ? AppTheme.emeraldLive.withValues(alpha: 0.4)
                          : AppTheme.coral500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentPlaying
                              ? AppTheme.emeraldLive
                              : AppTheme.coral500,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentPlaying
                              ? Icons.pause_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCurrentPlaying
                                  ? 'Audio Guide Playing...'
                                  : 'Listen to Audio Narration',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isCurrentPlaying
                                    ? AppTheme.emeraldLive
                                    : AppTheme.coral600,
                              ),
                            ),
                            Text(
                              isCurrentPlaying
                                  ? 'Tap to pause narration'
                                  : 'Narrated by DigiGuide AI Tour Voice',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isCurrentPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.play_arrow_rounded,
                        color: isCurrentPlaying
                            ? AppTheme.emeraldLive
                            : AppTheme.coral500,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Editorial Body
          Text(
            'Historical Chronology',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            landmark.history.isNotEmpty
                ? landmark.history
                : landmark.longDescription,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              color: isDark ? AppTheme.slate300 : AppTheme.slate700,
              letterSpacing: -0.1,
            ),
          ),

          // Alternative Landmarks Fallback (if proximity)
          if (landmark.matchType == 'proximity' && _landmarks.length > 1) ...[
            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Not quite what you snapped?",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Here are other monuments detected near your coordinates:",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
            ),
            const SizedBox(height: 14),
            ..._landmarks.skip(1).map(
                  (alt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TactileBounce(
                      onTap: () => _onLandmarkSelected(alt),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.slate850 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: AppShadows.subtle(context),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.coral500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: AppTheme.coral500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alt.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${alt.distance.toStringAsFixed(1)} km away',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppTheme.slate400
                                          : AppTheme.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.slate400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ARCHITECTURE & CULTURE
  // ---------------------------------------------------------------------------
  Widget _buildCultureTab(Landmark landmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.slate850 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: AppShadows.subtle(context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.architecture_rounded,
                  color: AppTheme.coral500,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cultural Significance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        landmark.longDescription.isNotEmpty
                            ? landmark.longDescription
                            : "Cultural background and heritage documentation for this site is curated by Darmstadt heritage archives.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: TRIVIA & QUICK FACTS CARDS
  // ---------------------------------------------------------------------------
  Widget _buildFactsTab(Landmark landmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final facts = landmark.facts.isNotEmpty
        ? landmark.facts
        : [
            "Located in the historic center of Darmstadt, Germany.",
            "Recognized by regional cultural heritage initiatives.",
          ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: facts.length,
      itemBuilder: (context, index) {
        final fact = facts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.slate850 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: AppShadows.subtle(context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.amber400.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: AppTheme.amber500,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fact #${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.amber500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fact,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.slate200 : AppTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING BOTTOM ACTION DOCK: FEEDBACK & AUDIO
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(Landmark landmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: AppGlass.container(
          context: context,
          blur: AppGlass.blurRegular,
          opacity: isDark ? 0.88 : 0.92,
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shadows: AppShadows.floating(context),
          child: Row(
            children: [
              // AI Accuracy Feedback Pills (Thumbs Up / Down)
              if (landmark.imageId != null) ...[
                Text(
                  _feedbackSubmitted ? 'Feedback logged' : 'Accurate match?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                  ),
                ),
                const SizedBox(width: 8),
                TactileBounce(
                  onTap: _feedbackSubmitted
                      ? null
                      : () => _submitFeedback(true, landmark),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldLive.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up_rounded,
                      size: 15,
                      color: AppTheme.emeraldLive,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TactileBounce(
                  onTap: _feedbackSubmitted
                      ? null
                      : () => _submitFeedback(false, landmark),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.coral500.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_down_rounded,
                      size: 15,
                      color: AppTheme.coral500,
                    ),
                  ),
                ),
                const Spacer(),
              ],

              // Home Return Button
              TactileBounce(
                onTap: () {
                  Navigator.of(context).popUntil(
                    (route) => route.settings.name == HomeScreen.routeName,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.sunsetCoral,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.coralGlow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEARBY LIST VIEW (FOR AMBIGUOUS / FALLBACK DETECTIONS)
  // ---------------------------------------------------------------------------
  Widget _buildNearbyListView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Nearby Landmarks",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).popUntil(
              (route) => route.settings.name == HomeScreen.routeName,
            );
          },
        ),
      ),
      body: ResponsiveContainer(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _landmarks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final landmark = _landmarks[index];
            if (landmark.id == '-1' || landmark.id == 'unknown') {
              return const SizedBox.shrink();
            }

            return TactileBounce(
              onTap: () => _onLandmarkSelected(landmark),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate850 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: AppShadows.subtle(context),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.coral500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: AppTheme.coral500,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            landmark.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            landmark.shortDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.slate400
                                  : AppTheme.slate500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${landmark.distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.coral500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.slate400,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// SEGMENTED TAB HEADER DELEGATE (APPLE HIG PILL SELECTOR)
// =============================================================================
class _SegmentedTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;

  _SegmentedTabHeaderDelegate({
    required this.tabController,
    required this.isDark,
  });

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppTheme.obsidian900 : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate850 : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: TabBar(
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: isDark ? AppTheme.coral500 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: isDark ? Colors.white : AppTheme.slate900,
          unselectedLabelColor: isDark ? AppTheme.slate400 : AppTheme.slate600,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Culture'),
            Tab(text: 'Quick Facts'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SegmentedTabHeaderDelegate oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.tabController != tabController;
}
