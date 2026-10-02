class Config {
  // Use the IP address detected earlier
  // Use localhost for USB Reverse Tunnel
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String predictUrl = '$baseUrl/predict';
  static const String imagesUrl = '$baseUrl/images';
  static const String landmarksUrl = '$baseUrl/landmarks';
  static const String nearbyUrl = '$baseUrl/nearby';
  static const String weatherUrl = '$baseUrl/weather';
}
