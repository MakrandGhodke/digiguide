import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/landmark.dart';
import '../services/audio_tour_service.dart';
import '../services/recent_history_service.dart';
import '../services/weather_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/tactile_bounce.dart';
import 'camera_screen.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'landmark_result_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _currentWeather;
  bool _loadingWeather = true;
  final Map<String, WeatherData> _landmarkWeatherCache = {};
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Castles & Palaces',
    'Parks & Nature',
    'Historic Sites',
    'Museums',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loadingWeather = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _loadingWeather = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final weather = await WeatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _loadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  Future<WeatherData?> _getWeatherForLandmark(Landmark landmark) async {
    final cacheKey = '${landmark.lat},${landmark.lng}';
    if (_landmarkWeatherCache.containsKey(cacheKey)) {
      return _landmarkWeatherCache[cacheKey];
    }

    final weather = await WeatherService.fetchWeather(
      landmark.lat,
      landmark.lng,
    );
    if (weather != null) {
      _landmarkWeatherCache[cacheKey] = weather;
    }
    return weather;
  }

  void _startSearch(BuildContext context) {
    showSearch(context: context, delegate: LandmarkSearchDelegate());
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true, // Allows content to flow behind floating frosted glass nav
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // -------------------------------------------------------------
              // 1. COLLAPSIBLE MODERN APP BAR WITH GREETING & STATUS CHIPS
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveLayout.screenPadding(context).copyWith(
                    top: 16,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Location Pill & Action Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Location Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.slate800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: AppShadows.subtle(context),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 14,
                                  color: AppTheme.coral500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Darmstadt, Germany',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right Actions: Live Weather & Favorites
                          Row(
                            children: [
                              // Weather Pill
                              if (_currentWeather != null && !_loadingWeather)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.slate800
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: AppShadows.subtle(context),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentWeather!.icon,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${_currentWeather!.temperature}°C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: isDark
                                              ? AppTheme.slate100
                                              : AppTheme.slate800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_loadingWeather)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ShimmerLoader.box(
                                    context: context,
                                    width: 70,
                                    height: 32,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),

                              // Favorites Pill
                              TactileBounce(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    FavoritesScreen.routeName,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.slate800
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: AppShadows.subtle(context),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      size: 18,
                                      color: AppTheme.coral500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Editorial Headline
                      Text(
                        _getTimeGreeting(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Where to explore today?',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 2. SEARCH BAR WITH FROSTED ACCENTS
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveLayout.screenPadding(context).copyWith(
                    bottom: 20,
                  ),
                  child: TactileBounce(
                    onTap: () => _startSearch(context),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.slate850 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: AppShadows.subtle(context),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? AppTheme.slate400
                                : AppTheme.slate500,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search landmarks, castles, monuments...',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.slate400
                                    : AppTheme.slate500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.slate700
                                  : AppTheme.slate100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: isDark
                                  ? AppTheme.slate300
                                  : AppTheme.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 3. HERO AI VISION SCANNER CARD
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveLayout.screenPadding(context).copyWith(
                    bottom: 20,
                  ),
                  child: _buildHeroScannerCard(context),
                ),
              ),

              // -------------------------------------------------------------
              // 4. LIVE AUDIO TOUR ISLAND (DYNAMIC STATUS)
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveLayout.screenPadding(context).copyWith(
                    bottom: 24,
                  ),
                  child: _buildAudioTourIsland(context),
                ),
              ),

              // -------------------------------------------------------------
              // 5. CATEGORY FILTER CAROUSEL
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildCategorySelector(context),
                ),
              ),

              // -------------------------------------------------------------
              // 6. SECTION HEADER: RECENT DISCOVERIES
              // -------------------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveLayout.screenPadding(context).copyWith(
                    bottom: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent Discoveries',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.coral500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AI Memory',
                              style: TextStyle(
                                color: AppTheme.coral500,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TactileBounce(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            ExploreScreen.routeName,
                          );
                        },
                        child: Text(
                          'Explore All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.coral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 7. RESPONSIVE DISCOVERY FEED (BENTO GRID / ADAPTIVE COLUMNS)
              // -------------------------------------------------------------
              SliverPadding(
                padding: ResponsiveLayout.screenPadding(context).copyWith(
                  bottom: 120, // Extra space for floating frosted nav bar
                ),
                sliver: _buildRecentDiscoveriesList(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FloatingGlassNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushNamed(CameraScreen.routeName);
          } else if (index == 2) {
            Navigator.of(context).pushNamed(ExploreScreen.routeName);
          } else if (index == 3) {
            Navigator.of(context).pushNamed(ProfileScreen.routeName);
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO SCANNER CARD: Apple HIG Aesthetics & Vision AI Reticle
  // ---------------------------------------------------------------------------
  Widget _buildHeroScannerCard(BuildContext context) {
    return TactileBounce(
      onTap: () {
        Navigator.of(context).pushNamed(CameraScreen.routeName);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppGradients.sunsetCoral,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.coralGlow,
        ),
        child: Stack(
          children: [
            // Ambient Geometric Highlight Circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Visual Recognition Engine',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lens Reticle Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.crop_free_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Scan Landmark',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Point your camera to identify historical context, architecture, & trivia instantly.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Primary Camera Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: AppTheme.coral600,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Open Camera',
                              style: TextStyle(
                                color: AppTheme.coral600,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Gallery Quick Picker
                      TactileBounce(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            CameraScreen.routeName,
                            arguments: {'mode': 'gallery'},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  // ---------------------------------------------------------------------------
  // LIVE AUDIO TOUR ISLAND: Dynamic Audio State & Waveform
  // ---------------------------------------------------------------------------
  Widget _buildAudioTourIsland(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AudioTourService>(
      builder: (context, tourService, child) {
        final bool isActive = tourService.isEnabled;

        return TactileBounce(
          onTap: () {
            tourService.toggleTour(!isActive);
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !isActive
                      ? "Audio Tour Activated! Walk near any landmark."
                      : "Audio Tour Paused.",
                ),
                backgroundColor: !isActive
                    ? AppTheme.emeraldLive
                    : AppTheme.slate800,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? const Color(0xFF0F2E23)
                      : const Color(0xFFE8FDF4))
                  : (isDark ? AppTheme.slate850 : Colors.white),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive
                    ? AppTheme.emeraldLive.withValues(alpha: 0.4)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.emeraldLive.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : AppShadows.subtle(context),
            ),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.emeraldLive
                        : (isDark
                            ? AppTheme.slate800
                            : AppTheme.coral50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive
                        ? Icons.headphones_rounded
                        : Icons.headphones_outlined,
                    color: isActive ? Colors.white : AppTheme.coral500,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isActive ? 'Audio Tour Active' : 'Start Audio Tour',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? (isDark ? Colors.white : const Color(0xFF065F46))
                                  : (isDark ? Colors.white : AppTheme.slate800),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.emeraldLive,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'GPS beacon active • Auto-narrating nearby sites'
                            : 'Enable hands-free audio narration on the go',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch / Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.emeraldLive
                        : (isDark
                            ? AppTheme.slate700
                            : AppTheme.slate100),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isActive ? 'ON' : 'START',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? Colors.white
                          : (isDark ? AppTheme.slate300 : AppTheme.slate600),
                      letterSpacing: 0.5,
                    ),
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
  // CATEGORY SELECTOR CAROUSEL
  // ---------------------------------------------------------------------------
  Widget _buildCategorySelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: ResponsiveLayout.screenPadding(context),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return TactileBounce(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
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
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.slate300 : AppTheme.slate700),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECENT DISCOVERIES FEED: RESPONSIVE BENTO / GRID LAYOUT
  // ---------------------------------------------------------------------------
  Widget _buildRecentDiscoveriesList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<List<Landmark>>(
      valueListenable: RecentHistoryService().recentLandmarksNotifier,
      builder: (context, landmarks, child) {
        if (landmarks.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.slate850 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.coral500.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      size: 36,
                      color: AppTheme.coral500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No recent discoveries yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan a landmark or explore Darmstadt to build your travel collection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter landmarks if category selected
        final filtered = _selectedCategory == 'All'
            ? landmarks
            : landmarks
                .where((l) =>
                    l.category.toLowerCase() == _selectedCategory.toLowerCase())
                .toList();

        final displayList = filtered.isEmpty ? landmarks : filtered;
        final int columns = ResponsiveLayout.gridColumns(context);

        // Render responsive grid
        if (columns == 1) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final landmark = displayList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildDiscoveryCard(context, landmark),
                );
              },
              childCount: displayList.length,
            ),
          );
        } else {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final landmark = displayList[index];
                return _buildDiscoveryCard(context, landmark);
              },
              childCount: displayList.length,
            ),
          );
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MODERN DISCOVERY CARD: Image, Weather Pill & Tactile Tap
  // ---------------------------------------------------------------------------
  Widget _buildDiscoveryCard(BuildContext context, Landmark landmark) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imageUrl = landmark.imageAsset.isNotEmpty
        ? '${Config.imagesUrl}/${landmark.imageAsset}'
        : 'https://images.unsplash.com/photo-1564507592333-c60657eea523?fit=crop&w=400&h=400';

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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: AppShadows.subtle(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Landmark Image with smooth loading and error fallback
              SizedBox(
                width: 124,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ShimmerLoader.box(
                          context: context,
                          width: 124,
                          height: 124,
                          borderRadius: BorderRadius.zero,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? AppTheme.slate800 : Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),

                    // Subtle gradient overlay for image contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            landmark.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Coordinates / Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: AppTheme.coral500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Lat: ${landmark.lat.toStringAsFixed(2)}, Lng: ${landmark.lng.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.slate400
                                        : AppTheme.slate500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Live Weather Chip for Landmark
                      FutureBuilder<WeatherData?>(
                        future: _getWeatherForLandmark(landmark),
                        builder: (context, snapshot) {
                          final weather = snapshot.data;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.slate800
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (weather?.icon != null) ...[
                                      Text(
                                        weather!.icon,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      weather != null
                                          ? '${weather.temperature}°C'
                                          : '--°C',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.slate200
                                            : AppTheme.slate800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // View Chevron
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? AppTheme.slate800
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: isDark
                                      ? AppTheme.slate400
                                      : AppTheme.slate600,
                                ),
                              ),
                            ],
                          );
                        },
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
}

// =============================================================================
// LANDMARK SEARCH DELEGATE (UPGRADED AESTHETICS)
// =============================================================================
class LandmarkSearchDelegate extends SearchDelegate {
  List<Landmark> _landmarks = [];

  LandmarkSearchDelegate() {
    _fetchLandmarks();
  }

  Future<void> _fetchLandmarks() async {
    try {
      final response = await http.get(Uri.parse(Config.landmarksUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['landmarks'] != null) {
          final List<dynamic> list = data['landmarks'];
          _landmarks = list.map((json) => Landmark.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching landmarks for search: $e");
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppTheme.obsidian900 : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppTheme.slate50 : AppTheme.slate900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: isDark ? AppTheme.slate500 : AppTheme.slate400,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final results = _landmarks
        .where((l) => l.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppTheme.slate600 : AppTheme.slate400,
            ),
            const SizedBox(height: 12),
            Text(
              'No landmarks match "$query"',
              style: TextStyle(
                color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? AppTheme.slate800 : const Color(0xFFF1F5F9),
      ),
      itemBuilder: (context, index) {
        final landmark = results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
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
          title: Text(
            landmark.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            landmark.shortDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            size: 20,
          ),
          onTap: () {
            Navigator.of(context).pushNamed(
              LandmarkResultScreen.routeName,
              arguments: {'landmark': landmark},
            );
          },
        );
      },
    );
  }
}
