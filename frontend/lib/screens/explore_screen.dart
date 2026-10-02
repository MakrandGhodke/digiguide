import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // For StreamSubscription
import '../config.dart';
import '../models/landmark.dart';
import '../theme/app_theme.dart';
import 'landmark_result_screen.dart';
import '../services/audio_tour_service.dart';

class ExploreScreen extends StatefulWidget {
  static const routeName = '/explore';

  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Landmark> _nearbyLandmarks = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<Position>? _positionStream;
  String _selectedCategory = 'all';

  List<Landmark> get _filteredLandmarks {
    if (_selectedCategory == 'all') {
      return _nearbyLandmarks;
    }
    return _nearbyLandmarks
        .where((l) => l.category == _selectedCategory)
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

  void _startLocationStream() async {
    // Check permissions first (handled in fetch, but good to be safe)
    // We assume fetch runs first and handles permissions.

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
            if (position != null) {
              debugPrint(
                "ExploreScreen: Location Update: ${position.latitude}, ${position.longitude}",
              );
            }
            if (position != null && _nearbyLandmarks.isNotEmpty) {
              // Notify Audio Tour Service
              final tourService = Provider.of<AudioTourService>(
                context,
                listen: false,
              );
              tourService.checkProximity(position, _nearbyLandmarks);
            }
          },
          onError: (e) {
            print("Location Stream Error: $e");
          },
        );
  }

  Future<void> _fetchNearbyLandmarks() async {
    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      // 2. Call API
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
        if (data['landmarks'] != null) {
          final List<dynamic> list = data['landmarks'];
          debugPrint('Fetched ${list.length} landmarks'); // DEBUG
          for (var item in list) {
            debugPrint(
              'Landmark: ${item['name']}, Category: ${item['category']}',
            ); // DEBUG
          }
          setState(() {
            _nearbyLandmarks = list
                .map((json) => Landmark.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFilterChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.coral500.withOpacity(0.2),
      checkmarkColor: AppTheme.coral500,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.coral500
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.coral500
              : Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tourService = Provider.of<AudioTourService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Explore Nearby",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Nature 🌿', 'nature'),
                const SizedBox(width: 8),
                _buildFilterChip('History 🏛️', 'history'),
                const SizedBox(width: 8),
                _buildFilterChip('Urban 🏙️', 'urban'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          tourService.toggleTour(!tourService.isEnabled);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tourService.isEnabled
                    ? "Audio Tour Started! Walk near a landmark."
                    : "Audio Tour Stopped.",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: tourService.isEnabled
            ? AppTheme.coral500
            : Colors.grey,
        icon: Icon(
          tourService.isEnabled ? Icons.headset : Icons.headset_off,
          color: Colors.white,
        ),
        label: Text(
          tourService.isSpeaking
              ? "Speaking..."
              : (tourService.isEnabled ? "Tour Active" : "Start Tour"),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLandmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final landmark = _filteredLandmarks[index];
                final imageUrl = landmark.imageAsset.isNotEmpty
                    ? '${Config.imagesUrl}/${landmark.imageAsset}'
                    : null;

                final bool isSpeakingThis =
                    tourService.isSpeaking &&
                    tourService.currentSpeakingLandmarkId == landmark.id;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSpeakingThis
                        ? const BorderSide(color: AppTheme.coral500, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        LandmarkResultScreen.routeName,
                        arguments: {'landmark': landmark},
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Image
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      landmark.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isSpeakingThis)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.pause_circle_filled,
                                      ),
                                      color: AppTheme.coral500,
                                      iconSize: 32,
                                      onPressed: () {
                                        tourService.stop();
                                      },
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_fill),
                                      color: AppTheme.coral500,
                                      iconSize: 32,
                                      onPressed: () {
                                        tourService.playSpecificLandmark(
                                          landmark,
                                        );
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                landmark.shortDescription,
                                style: const TextStyle(
                                  color: AppTheme.slate500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppTheme.coral500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${landmark.distance.toStringAsFixed(1)} km away',
                                    style: const TextStyle(
                                      color: AppTheme.coral500,
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
                );
              },
            ),
    );
  }
}
