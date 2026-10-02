import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class WeatherData {
  final int temperature;
  final String condition;
  final String icon;
  final int humidity;
  final String recommendation;
  final String bestTime;
  final String rating;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.recommendation,
    required this.bestTime,
    required this.rating,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num?)?.round() ?? 0,
      condition: json['condition'] ?? 'Unknown',
      icon: json['icon'] ?? '🌡️',
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] ?? '',
      bestTime: json['bestTime'] ?? '',
      rating: json['rating'] ?? 'Unknown',
    );
  }
}

class WeatherService {
  static Future<WeatherData?> fetchWeather(double lat, double lon) async {
    try {
      final uri = Uri.parse('${Config.weatherUrl}?lat=$lat&lon=$lon');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }
}
