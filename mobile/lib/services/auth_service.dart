/// AuthService manages user authentication and session persistence for MCQ Marker.
///
/// ## Responsibilities
/// - Registers new users and saves their authentication tokens and profile data.
/// - Signs in users and persists tokens and user data locally.
/// - Fetches user profile data from the backend.
/// - Signs out users and clears session data.
/// - Checks authentication status and token validity.
/// - Provides methods to get/set tokens and user data using SharedPreferences.
///
/// ## Main Methods
/// - `register`: Registers a new user and saves session data.
/// - `signIn`: Authenticates user and saves session data.
/// - `signOut`: Clears authentication and user data.
/// - `isAuthenticated`: Checks if the user is logged in and token is valid.
/// - `getToken`, `getUserData`: Retrieves stored token and user profile.
///
/// ## Dependencies
/// - [http]: For backend communication.
/// - [shared_preferences]: For local session storage.
/// - [dart_jsonwebtoken]: For JWT decoding and validation.
/// - [flutter_dotenv]: For environment variables.
///
/// ## Usage
/// Instantiate and use AuthService for authentication flows.
/// 
/// Example:
/// ```dart
/// final auth = AuthService();
/// final success = await auth.signIn(email, password);
/// ```
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AuthService {
  final String backendURL = dotenv.env['BASE_URL'] ?? '';
  // final String baseUrl = '$BASE_URL/users';
  final String tokenKey = 'auth_token';
  final String userKey = 'user_data';

  String get baseUrl => '$backendURL/users';

  Future<Map<String, dynamic>> register(
      String email, String displayName, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'displayName': displayName,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _saveToken(userData['access_token']);
        await _saveUserData(userData['user']);
        return userData;
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        await _saveToken(tokenData['access_token']);
        await _fetchAndSaveUserData();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> _fetchAndSaveUserData() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await _saveUserData(userData);
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final jwt = JWT.decode(token);
      final exp = jwt.payload['exp'];

      if (exp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now < exp;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
}
