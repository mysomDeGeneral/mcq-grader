/// UserProvider manages authentication state and user/session data for MCQ Marker.
///
/// This provider handles:
/// - User authentication (login, registration, auto-login, logout)
/// - Storing and retrieving user token and profile data
/// - Session-related data such as selected test, student, and image file paths
/// - Notifying listeners on state changes for UI updates
///
/// ## Usage
/// Wrap your app with a Provider for UserProvider to access authentication and session data throughout the app.
///
/// ## Main Methods
/// - `register(email, displayName, password)`: Registers a new user.
/// - `login(email, password)`: Logs in an existing user.
/// - `tryAutoLogin()`: Attempts to restore session from saved token.
/// - `logout()`: Signs out and clears user/session data.
/// - Setters for test, student, and other session-specific fields.
///
/// ## Dependencies
/// - Relies on [AuthService] for backend authentication and user data retrieval.
///
/// ## Example
/// ```dart
/// final userProvider = Provider.of<UserProvider>(context);
/// if (userProvider.isLoggedIn) { ... }
/// ```
import 'package:flutter/material.dart';
import 'package:mcq_marker/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  String? _token;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();

  // Additional Data
  String? _testDocId;
  String? _studentDocId;
  int? _endNumber;
  final String _appName = 'mcq grader';
  String? _testName;
  String? _code;
  String? _class;
  String? _chosenStudent;
  String? _storageImageFilePath;

  // Getters
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _token != null;
  String get appName => _appName;
  String? get testDocId => _testDocId ?? '';
  String? get studentDocId => _studentDocId ?? '';
  int? get endNumber => _endNumber;
  String? get testName => _testName ?? '';
  String? get code => _code ?? '';
  String? get userClass => _class ?? '';
  String? get chosenStudent => _chosenStudent;
  String? get storageImageFilePath => _storageImageFilePath;

  UserProvider() {
    tryAutoLogin();
  }

  Future<void> initialize() async {
    try {
      _isLoggedIn = await _authService.isAuthenticated();
      if (_isLoggedIn) {
        _token = await _authService.getToken();
        _userData = await _authService.getUserData();
      }      
    } catch (e) {
      debugPrint('Error initializing UserProvider: $e');
      _isLoggedIn = false;
    }
  }


  // Registration Method
  Future<bool> register(String email, String displayName, String password) async {
    try {
      final userData = await _authService.register(email, displayName, password);
      if (userData.isNotEmpty) {
        _token = userData['access_token'];
        _userData = userData;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Registration failed: $e");
    }
    return false;
  }

  // Login Method
  Future<bool> login(String email, String password) async {
    bool success = await _authService.signIn(email, password);
    if (success) {
      _token = await _authService.getToken();
      _isLoggedIn = true;
      _userData = await _authService.getUserData();
      notifyListeners();
    }
    return success;
  }

  // Try Auto Login
  Future<bool> tryAutoLogin() async {
    _token = await _authService.getToken();
    if (_token == null) return false;
    _isLoggedIn = true;
    _userData = await _authService.getUserData();
    notifyListeners();
    return true;
  }

  // Logout
  Future<void> logout() async {
    await _authService.signOut();
    _token = null;
    _isLoggedIn = false;
    _userData = null;
    notifyListeners();
  }

  // Setters for additional data
  void setTestDocID(String id) {
    _testDocId = id;
    notifyListeners();
  }

  void setStudentDocId(String id) {
    _studentDocId = id;
    notifyListeners();
  }

  void setEndNumber(int val) {
    _endNumber = val;
    notifyListeners();
  }

  void setTestName(String name) {
    _testName = name;
    notifyListeners();
  }

  void setCode(String code) {
    _code = code;
    notifyListeners();
  }

  void setClass(String className) {
    _class = className;
    notifyListeners();
  }

  void setChosenStudent(String student) {
    _chosenStudent = student;
    notifyListeners();
  }

  void setStorageImageFilePath(String path) {
    _storageImageFilePath = path;
    notifyListeners();
  }
}
