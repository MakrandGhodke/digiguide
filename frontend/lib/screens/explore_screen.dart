import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/landmark.dart';
import '../services/audio_tour_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tactile_bounce.dart';
import 'camera_screen.dart';
import 'home_screen.dart';
import 'landmark_result_screen.dart';
import 'profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  static const routeName = '/explore';
  final bool isEmbeddedInShell;

  const ExploreScreen({super.key, this.isEmbeddedInShell = false});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Landmark> _nearbyLandmarks = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<Position>? _positionStream;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Sites'},
    {'id': 'nature', 'label': 'Nature 🌿'},
    {'id': 'history', 'label': 'Historic 🏛️'},
    {'id': 'urban', 'label': 'Urban 🏙️'},
  ];

  List<Landmark> get _filteredLandmarks {
    if (_selectedCategory == 'all') {
      return _nearbyLandmarks;
    }
    return _nearbyLandmarks
        .where((l) => l.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchNearbyLandmarks();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null && _nearbyLandmarks.isNotEmpty && mounted) {
          final tourService = Provider.of<AudioTourService>(
            context,
            listen: false,
          );
          tourService.checkProximity(position, _nearbyLandmarks);
        }
      },
      onError: (e) {
        debugPrint("Location Stream Error: $e");
      },
    );
  }

  Future<void> _fetchNearbyLandmarks() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _error = 'Location access is required to discover nearby landmarks';
            _isLoading = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 6),
      );

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
        if (data['landmarks'] != null && mounted) {
          final List<dynamic> list = data['landmarks'];
          setState(() {
            _nearbyLandmarks = list
                .map((json) => Landmark.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Unable to fetch landmarks (HTTP ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to discovery server: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tourService = Provider.of<AudioTourService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isEmbeddedInShell
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Row(
          children: [
            Text(
              'Explore Darmstadt',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.coral500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_nearbyLandmarks.length} Sites',
                style: const TextStyle(
                  color: AppTheme.coral500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Audio Tour Toggle Pill in App Bar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TactileBounce(
              onTap: () {
                tourService.toggleTour(!tourService.isEnabled);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tourService.isEnabled
                      ? AppTheme.emeraldLive.withValues(alpha: 0.15)
                      : (isDark ? AppTheme.slate800 : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: tourService.isEnabled
                        ? AppTheme.emeraldLive.withValues(alpha: 0.4)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tourService.isEnabled
                          ? Icons.headphones_rounded
                          : Icons.headphones_outlined,
                      size: 15,
                      color: tourService.isEnabled
                          ? AppTheme.emeraldLive
                          : (isDark ? Colors.white70 : AppTheme.slate600),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tourService.isEnabled ? 'Tour ON' : 'Audio Tour',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tourService.isEnabled
                            ? AppTheme.emeraldLive
                            : (isDark ? Colors.white70 : AppTheme.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];

                return TactileBounce(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = cat['id']!;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppTheme.coral500 : AppTheme.slate900)
                          : (isDark ? AppTheme.slate850 : Colors.white),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0)),
                      ),
                      boxShadow: isSelected ? AppShadows.subtle(context) : null,
                    ),
                    child: Text(
                      cat['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFA1A1AA)
                                : AppTheme.slate700),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: ResponsiveContainer(
        child: _isLoading
            ? ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 4,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) => ShimmerLoader.box(
                  context: context,
                  height: 180,
                  borderRadius: BorderRadius.circular(22),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off_rounded,
                            size: 48,
                            color: AppTheme.coral500,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : AppTheme.slate600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _fetchNearbyLandmarks();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                    itemCount: _filteredLandmarks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final landmark = _filteredLandmarks[index];
                      final imageUrl = landmark.imageAsset.isNotEmpty
                          ? '${Config.imagesUrl}/${landmark.imageAsset}'
                          : null;

                      final bool isSpeakingThis = tourService.isSpeaking &&
                          tourService.currentSpeakingLandmarkId == landmark.id;

                      return TactileBounce(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            LandmarkResultScreen.routeName,
                            arguments: {'landmark': landmark},
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.slate850 : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSpeakingThis
                                  ? AppTheme.emeraldLive
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: isSpeakingThis ? 1.5 : 1.0,
                            ),
                            boxShadow: AppShadows.subtle(context),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover Image
                              if (imageUrl != null)
                                SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return ShimmerLoader.box(
                                            context: context,
                                            borderRadius: BorderRadius.zero,
                                          );
                                        },
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                          color: isDark
                                              ? AppTheme.slate800
                                              : Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),

                                      // Distance Chip floating top right
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.65),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.near_me_rounded,
                                                color: AppTheme.coral500,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${landmark.distance.toStringAsFixed(1)} km',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
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

                              // Details & Audio Action
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            landmark.name,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            landmark.shortDescription,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFFA1A1AA)
                                                  : AppTheme.slate500,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Audio Play / Pause Action
                                    TactileBounce(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (isSpeakingThis) {
                                          tourService.stop();
                                        } else {
                                          tourService
                                              .playSpecificLandmark(landmark);
                                        }
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSpeakingThis
                                              ? AppTheme.emeraldLive
                                              : (isDark
                                                  ? AppTheme.slate800
                                                  : AppTheme.coral50),
                                          shape: BoxShape.circle,
                                          boxShadow: isSpeakingThis
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.emeraldLive
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 12,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          isSpeakingThis
                                              ? Icons.pause_rounded
                                              : Icons.volume_up_rounded,
                                          color: isSpeakingThis
                                              ? Colors.white
                                              : AppTheme.coral500,
                                          size: 20,
                                        ),
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
                  ),
      ),
      bottomNavigationBar: widget.isEmbeddedInShell
          ? null
          : FloatingGlassNavBar(
              currentIndex: 1,
              onTabSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).pushNamed(HomeScreen.routeName);
                } else if (index == 2) {
                  Navigator.of(context).pushNamed(ProfileScreen.routeName);
                }
              },
              onScanPressed: () {
                Navigator.of(context).pushNamed(CameraScreen.routeName);
              },
            ),
    );
  }
}
