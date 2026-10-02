import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  static String? _token;
  static String? _email;
  static String? _name;

  /// Initialize auth state from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _email = prefs.getString(_userEmailKey);
    _name = prefs.getString(_userNameKey);
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _token != null;

  /// Get current user email
  static String? get currentEmail => _email;

  /// Get current user name
  static String? get currentName => _name;

  /// Get auth token
  static String? get token => _token;

  /// Sign up a new user
  static Future<AuthResult> signup({
    required String email,
    required String password,
    String name = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token'], email, name);
        return AuthResult(success: true);
      } else {
        final data = jsonDecode(response.body);
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Connection error: $e');
    }
  }

  /// Sign in existing user
  static Future<AuthResult> signin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token'], email, '');

        // Fetch user details
        await _fetchUserDetails();
        return AuthResult(success: true);
      } else {
        final data = jsonDecode(response.body);
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Connection error: $e');
    }
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    _token = null;
    _email = null;
    _name = null;
  }

  /// Save token to storage
  static Future<void> _saveToken(
    String token,
    String email,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    _token = token;
    _email = email;
    _name = name;
  }

  /// Fetch user details from backend
  static Future<void> _fetchUserDetails() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _name = data['name'] ?? '';
        _email = data['email'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, _name!);
        await prefs.setString(_userEmailKey, _email!);
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }
}

class AuthResult {
  final bool success;
  final String? error;

  AuthResult({required this.success, this.error});
}
