import 'package:flutter/material.dart';
import 'dart:io';
import '../models/landmark.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';
import '../config.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../services/auth_service.dart';

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

  // Feedback State
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
        // Backward compatibility
        _landmarks = [args['landmark'] as Landmark];
      }

      _capturedImage = args['imageFile'] as File?;

      // LOGIC: Show List View if first item is not a visual match AND we have alternatives
      if (_landmarks.isNotEmpty) {
        final first = _landmarks[0];
        // Show details if:
        // 1. Visual match (high confidence)
        // 2. Proximity match (medium confidence fallback)
        bool showDetails =
            first.matchType == 'visual' || first.matchType == 'proximity';

        if (showDetails) {
          _showListView = false;
        } else {
          if (_landmarks.length > 1) {
            _showListView = true;
          } else {
            _showListView = false;
          }
        }
      }

      // Fetch weather for the first landmark
      if (_landmarks.isNotEmpty && _weather == null) {
        _fetchWeather(_landmarks[0]);
      }
    }
  }

  Future<void> _submitFeedback(bool isGood, Landmark landmark) async {
    if (_feedbackSubmitted) return;
    if (landmark.imageId == null) return;

    setState(() {
      _feedbackSubmitted = true;
    });

    try {
      final token = AuthService.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to submit feedback')),
        );
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
          'comments': isGood ? 'Good match' : 'Bad match',
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isGood
                    ? 'Thanks! We\'ll use this to improve.'
                    : 'Thanks for the feedback.',
              ),
              backgroundColor: isGood ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit feedback')),
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
      setState(() {
        _weather = weather;
      });
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showListView) {
      return _buildListView();
    } else {
      return _buildDetailView(_landmarks[0]);
    }
  }

  // ... (_buildListView, _buildFactRow remain same)

  Widget _buildListView() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Nearby Landmarks",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name == HomeScreen.routeName);
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.cardTheme.color,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.slate500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "We couldn't identify this exactly, but here are some landmarks nearby:",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _landmarks.length,
              itemBuilder: (context, index) {
                final landmark = _landmarks[index];
                // Skip "Unknown" in the list if we have other options
                if (landmark.id == '-1' || landmark.id == 'unknown')
                  return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardTheme.color,
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _onLandmarkSelected(landmark),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Thumbnail (if we had actual images, we'd load them. For now use icon)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.coral500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.place,
                              color: AppTheme.coral500,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  landmark.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  landmark.shortDescription,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.slate500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions,
                                      size: 12,
                                      color: AppTheme.slate400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${landmark.distance.toStringAsFixed(1)} km away',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.slate300,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(Landmark landmark) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 1. FIXED IMAGE HEADER (Non-scrolling)
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // LOGIC: Prefer captured image if available
                _capturedImage != null
                    ? Image.file(_capturedImage!, fit: BoxFit.cover)
                    : (landmark.imageAsset.isNotEmpty
                          ? Image.network(
                              '${Config.imagesUrl}/${landmark.imageAsset}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: Colors.grey);
                              },
                            )
                          : Container(color: Colors.grey)),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black26,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) =>
                              route.settings.name == HomeScreen.routeName,
                        );
                      },
                    ),
                  ),
                ),

                // WEATHER BADGE (Top Right, Left of Favorite)
                if (_weather != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 64, // To the left of the favorite button
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _weather!.condition.toLowerCase().contains('rain')
                                ? Icons.water_drop
                                : _weather!.condition.toLowerCase().contains(
                                    'cloud',
                                  )
                                ? Icons.cloud
                                : Icons.wb_sunny,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_weather!.temperature}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // FAVORITE BUTTON (Top Right)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFav = favProvider.isFavorite(landmark.id);
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black26,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                          ),
                          onPressed: () {
                            favProvider.toggleFavorite(landmark);
                          },
                        ),
                      );
                    },
                  ),
                ),

                // FEEDBACK BUTTONS (Top Right or Bottom Right)
                // Only show if we have an imageId (meaning it was a prediction)
                if (landmark.imageId != null && !_feedbackSubmitted)
                  Positioned(
                    bottom: 20,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFeedbackButton(true, landmark),
                          Container(
                            height: 16,
                            width: 1,
                            color: Colors.white30,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          _buildFeedbackButton(false, landmark),
                        ],
                      ),
                    ),
                  ),

                // Title Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 120, // Make room for feedback buttons
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        landmark.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24, // Slightly smaller to fit
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              landmark.distance > 0
                                  ? '${landmark.distance.toStringAsFixed(1)} km away'
                                  : 'Lat: ${landmark.lat.toStringAsFixed(2)}, Lng: ${landmark.lng.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
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

          // 3. TABS (Fixed)
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: AppTheme.coral500,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Culture'),
              Tab(text: 'Facts'),
            ],
          ),

          // 4. SCROLLABLE TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // History
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        landmark.history.isNotEmpty
                            ? landmark.history
                            : landmark.longDescription,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // PROXIMITY FALLBACK: Show alternatives if this was a loose match
                      if (landmark.matchType == 'proximity' &&
                          _landmarks.length > 1) ...[
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          "Not what you're looking for?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Since we couldn't see the landmark clearly, we guessed based on your location. Here are other nearby places:",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._landmarks
                            .skip(1)
                            .map(
                              (alt) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: theme.cardTheme.color,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.coral500.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.place,
                                      color: AppTheme.coral500,
                                    ),
                                  ),
                                  title: Text(
                                    alt.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${alt.distance.toStringAsFixed(1)} km away',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _onLandmarkSelected(alt),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                // Culture
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    landmark.longDescription.isNotEmpty
                        ? landmark.longDescription
                        : "Cultural information is being updated.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Facts
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: landmark.facts.isNotEmpty
                        ? landmark.facts
                              .map(
                                (fact) => _buildFactRow('Did you know?', fact),
                              )
                              .toList()
                        : [_buildFactRow('Info', 'No facts available.')],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(bool isGood, Landmark landmark) {
    return InkWell(
      onTap: _feedbackSubmitted
          ? null
          : () => _submitFeedback(isGood, landmark),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          isGood ? Icons.thumb_up : Icons.thumb_down,
          color: _feedbackSubmitted
              ? Colors.white24
              : (isGood ? Colors.greenAccent : Colors.redAccent),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFactRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.slate500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
