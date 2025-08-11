/// TestService manages CRUD operations for MCQ tests and their scripts.
///
/// ## Responsibilities
/// - Creates, retrieves, updates, and deletes MCQ tests.
/// - Manages scripts associated with each test (fetch, delete, bulk delete).
/// - Communicates with backend endpoints using authenticated requests.
///
/// ## Main Methods
/// - `createTest`: Creates a new test.
/// - `getUserTests`: Retrieves all tests for the current user.
/// - `getTest`: Fetches details for a specific test.
/// - `updateTest`: Updates test details and marking scheme.
/// - `deleteTest`: Deletes a specific test.
/// - `deleteScript`: Deletes a specific script from a test.
/// - `getTestScripts`: Retrieves all scripts for a test.
/// - `deleteAllTests`: Deletes all tests for the user.
/// - `deleteAllScripts`: Deletes all scripts for a test.
///
/// ## Dependencies
/// - [http]: For HTTP requests.
/// - [flutter_dotenv]: For environment variables.
/// - [AuthService]: For authentication and token management.
///
/// ## Usage
/// Instantiate and use TestService to manage tests and scripts.
/// 
/// Example:
/// ```dart
/// final testService = TestService();
/// final tests = await testService.getUserTests();
/// ```
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TestService {
  final String backendURL = dotenv.env['BASE_URL'] ?? '';
  final AuthService _authService = AuthService();

  String get baseUrl => '$backendURL/tests/'; 


  // Create a new test
  Future<Map<String, dynamic>> createTest(String className, String courseCode, 
      String description, String name, int endNumber) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'class_': className,
        'course_code': courseCode,
        'description': description,
        'name': name.toLowerCase(),
        'endNumber': endNumber,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create test: ${response.body}');
    }
  }

  // Get all tests for the current user
  Future<List<Map<String, dynamic>>> getUserTests() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> testsJson = jsonDecode(response.body);
            return testsJson.map((test) => test as Map<String, dynamic>).toList();
    } else {
        throw Exception('Failed to load tests: ${response.body}');
      }
    }
 Future<Map<String, dynamic>> getTest(String testId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$testId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load test: ${response.body}');
    }
  }

  // Update a test
  Future<Map<String, dynamic>> updateTest(String testId, String className, 
      String courseCode, String description, String name, int endNumber, List scheme) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl$testId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'class_': className,
        'course_code': courseCode,
        'description': description,
        'name': name.toLowerCase(),
        'endNumber': endNumber,
        'scheme': scheme
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update test: ${response.body}');
    }
  }

  // Delete a test
  Future<void> deleteTest(String testId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl$testId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    // print('code: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete test: ${response.body}');
    }
  }

  Future<void>deleteScript(String testId, String indexNumber) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl$testId/scripts/$indexNumber'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    // print('code: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete script: ${response.body}');
    }
  }

Future<List<Map<String, dynamic>>> getTestScripts(String testId) async {
  final token = await _authService.getToken();
  if (token == null) {
    throw Exception('Not authenticated');
  }

  final response = await http.get(
    Uri.parse('$baseUrl$testId/scripts'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  // print("Scripts: ${response.body} ");

  if (response.statusCode == 200) {
    final List<dynamic> scriptsJson = jsonDecode(response.body);
    return scriptsJson.map((script) => script as Map<String, dynamic>).toList();
  } else {
    throw Exception('Failed to load test scripts: ${response.body}');
  }
}

Future<void> deleteAllTests() async {
  final token = await _authService.getToken();
  if (token == null) {
    throw Exception('Not authenticated');
  }

  final response = await http.delete(
    Uri.parse(baseUrl), 
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to delete all tests: ${response.body}');
  }
}

Future<void> deleteAllScripts(String testId) async {
  final token = await _authService.getToken();
  if (token == null) {
    throw Exception('Not authenticated');
  }

  final response = await http.delete(
    Uri.parse('$baseUrl$testId/scripts'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to delete all scripts: ${response.body}');
  }
}
}