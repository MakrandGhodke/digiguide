import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';
import 'landmark_result_screen.dart';
import 'favorites_screen.dart';
import '../models/landmark.dart';
import '../services/recent_history_service.dart';
import '../services/weather_service.dart';
import 'package:provider/provider.dart';
import '../services/audio_tour_service.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _currentWeather;
  bool _loadingWeather = true;
  Map<String, WeatherData> _landmarkWeatherCache = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingWeather = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingWeather = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: AppTheme.slate600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Darmstadt, Germany',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Weather Badge
          if (_currentWeather != null && !_loadingWeather)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentWeather!.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentWeather!.temperature}°C',
                    style: TextStyle(
                      color: AppTheme.slate700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.coral500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.of(context).pushNamed(FavoritesScreen.routeName);
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: GestureDetector(
              onTap: () => _startSearch(context),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'Search a landmark',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Camera Action Area
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(CameraScreen.routeName);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.slate700, AppTheme.slate900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.slate900.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Landmark',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Point your camera to discover',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    CameraScreen.routeName,
                    arguments: {'mode': 'gallery'},
                  );
                },
                icon: const Icon(
                  Icons.upload_file_outlined,
                  color: AppTheme.slate700,
                ),
                label: const Text(
                  'Upload from Gallery',
                  style: TextStyle(color: AppTheme.slate700),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey[200]!, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Audio Tour Button
            Consumer<AudioTourService>(
              builder: (context, tourService, child) {
                final bool isActive = tourService.isEnabled;
                return GestureDetector(
                  onTap: () {
                    tourService.toggleTour(!isActive);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isActive
                              ? "Audio Tour Started! Walk near a landmark."
                              : "Audio Tour Stopped.",
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.coral500 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? AppTheme.coral500 : Colors.grey[200]!,
                        width: 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.coral500.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withOpacity(0.2)
                                : AppTheme.coral50.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? Icons.headset : Icons.headset_off,
                            color: isActive ? Colors.white : AppTheme.coral500,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isActive
                                  ? 'Audio Tour Active'
                                  : 'Start Audio Tour',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppTheme.slate700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              isActive
                                  ? 'Walking near landmarks...'
                                  : 'Enable auto-narration',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white.withOpacity(0.9)
                                    : AppTheme.slate500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "ON",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Recently Discovered
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Recently Discovered',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ValueListenableBuilder<List<Landmark>>(
              valueListenable: RecentHistoryService().recentLandmarksNotifier,
              builder: (context, landmarks, child) {
                if (landmarks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'No recent discoveries yet. Start scanning!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return Column(
                  children: landmarks.map((landmark) {
                    final imageUrl = landmark.imageAsset.isNotEmpty
                        ? '${Config.imagesUrl}/${landmark.imageAsset}'
                        : 'https://images.unsplash.com/photo-1564507592333-c60657eea523?fit=crop&w=200&h=200';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            LandmarkResultScreen.routeName,
                            arguments: {'landmark': landmark},
                          );
                        },
                        child: FutureBuilder<WeatherData?>(
                          future: _getWeatherForLandmark(landmark),
                          builder: (context, snapshot) {
                            final weather = snapshot.data;
                            return _buildRecentItem(
                              landmark.name,
                              'Lat: ${landmark.lat.toStringAsFixed(1)}, Lng: ${landmark.lng.toStringAsFixed(1)}',
                              weather != null
                                  ? '${weather.temperature}°'
                                  : '--',
                              weather?.condition ?? 'Loading...',
                              imageUrl,
                              weatherIcon: weather?.icon,
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home, 'Home', true, null),
            _buildNavItem(
              context,
              Icons.qr_code_scanner,
              'Scan',
              false,
              CameraScreen.routeName,
            ),
            _buildNavItem(
              context,
              Icons.explore_outlined,
              'Explore',
              false,
              ExploreScreen.routeName,
            ),
            _buildNavItem(
              context,
              Icons.person_outline,
              'Profile',
              false,
              ProfileScreen.routeName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(
    String name,
    String location,
    String temp,
    String weather,
    String imageUrl, {
    String? weatherIcon,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero, // Padding handled by parent ListView
      elevation: 0, // Flat elegant look, or 1-2 for subtle depth
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.cardTheme.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.slate500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.slate500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? AppTheme.slate700
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (weatherIcon != null)
                              Text(
                                weatherIcon,
                                style: const TextStyle(fontSize: 12),
                              )
                            else
                              Icon(
                                Icons.cloud,
                                size: 12,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : AppTheme.slate600,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              temp,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : AppTheme.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weather,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    String? routeName,
  ) {
    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          Navigator.of(context).pushNamed(routeName);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.coral500 : AppTheme.slate400),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.coral500 : AppTheme.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

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
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
    final results = _landmarks
        .where((l) => l.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final landmark = results[index];
        return ListTile(
          title: Text(landmark.name),
          subtitle: Text(landmark.shortDescription),
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
