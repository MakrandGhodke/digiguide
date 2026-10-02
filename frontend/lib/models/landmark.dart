class Landmark {
  final String id;
  final String name;
  final String shortDescription;
  final String longDescription;
  final double lat;
  final double lng;
  final String imageAsset;
  final String matchType;
  final String history;
  final List<String> facts;
  final String speechText;
  final double distance;
  final double score;
  final String? imageId;
  final String city;
  final String country;
  final String category;

  Landmark({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.lat,
    required this.lng,
    required this.imageAsset,
    this.history = 'No history available.',
    this.facts = const [],
    this.speechText = '',
    this.matchType = 'none',
    this.distance = 0.0,
    this.score = 0.0,
    this.imageId,
    this.city = 'Unknown City',
    this.country = 'Unknown Country',
    this.category = 'none',
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'] ?? json['filename'] ?? 'unknown',
      name: json['name'] ?? json['landmark_name'] ?? 'Unknown Landmark',
      shortDescription:
          json['shortDescription'] ??
          json['description'] ??
          'No description available.',
      longDescription:
          json['longDescription'] ??
          json['description'] ??
          'No description available.',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      imageAsset: json['imageAsset'] ?? '',
      history: json['history'] ?? 'No history available.',
      facts: (json['facts'] as List<dynamic>?)?.cast<String>() ?? [],
      speechText: json['speechText'] ?? '',
      matchType: json['matchType'] ?? 'none',
      distance: (json['distance'] ?? 0.0).toDouble(),
      score: (json['score'] ?? 0.0).toDouble(),
      imageId: json['imageId'],
      city: json['city'] ?? 'Unknown City',
      country: json['country'] ?? 'Unknown Country',
      category: json['category'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'lat': lat,
      'lng': lng,
      'imageAsset': imageAsset,
      'history': history,
      'facts': facts,
      'speechText': speechText,
      'matchType': matchType,
      'distance': distance,
      'score': score,
      'city': city,
      'country': country,
      'category': category,
    };
  }
}
