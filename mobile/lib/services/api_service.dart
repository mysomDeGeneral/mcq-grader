/// ApiService handles communication with backend APIs and Cloudinary for MCQ Marker.
///
/// ## Responsibilities
/// - Uploads images to Cloudinary and retrieves their URLs.
/// - Sends images directly to the backend for processing and grading.
/// - Calls marking endpoints to grade scripts based on uploaded images.
/// - Manages multipart/form-data and JSON requests.
///
/// ## Main Methods
/// - `processImageAndUpload`: Orchestrates image upload and marking.
/// - `uploadImageToCloudinary`: Uploads an image file to Cloudinary.
/// - `sendImageDirectly`: Sends image and metadata directly to backend.
/// - `markImage`: Calls backend to mark a script using an image URL.
///
/// ## Dependencies
/// - [http]: For HTTP requests.
/// - [flutter_dotenv]: For environment variables (API URLs, Cloudinary config).
///
/// ## Usage
/// Instantiate and use ApiService to handle image uploads and script grading.
/// 
/// Example:
/// ```dart
/// final api = ApiService();
/// final result = await api.processImageAndUpload(path, testId, endNumber, false);
/// ```
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // Future<dynamic> processImageAndUpload(
  //     String imagePath, String testId, int endNumber, bool schemeOrPaper) async {
  //   try {
  //     // Upload image to Cloudinary
  //     final uploadedImageUrl = await _uploadImageToCloudinary(imagePath);

  //     if (uploadedImageUrl == null) {
  //       throw Exception('Failed to upload image.');
  //     }

  //     // Call marking API
  //     return await markImage(uploadedImageUrl, testId, endNumber, schemeOrPaper);
  //   } catch (e) {
  //     print('Error processing image: $e');
  //     throw Exception('Error processing image: $e');
  //   }
  // }

  Future<dynamic> processImageAndUpload(
      String imagePath, String testId, int endNumber, bool schemeOrPaper) async {
    try {
      return await sendImageDirectly(imagePath, testId, endNumber, schemeOrPaper);
    } catch (e) {
      print('Error processing image: $e');
      throw Exception('Error processing image: $e');
    }
  }


  Future<String?> uploadImageToCloudinary(String imagePath) async {
    try {
      final file = File(imagePath);
      final request = http.MultipartRequest(
          'POST', Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload"))
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> sendImageDirectly(
      String imagePath, String testId, int endNumber, bool schemeOrPaper) async {
    try {
      final file = File(imagePath);
      final url = '$baseUrl/process_direct';

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        file.path,
        filename: file.path.split('/').last
      ));
      
      // Add other fields
      request.fields['test_id'] = testId;
      request.fields['end_number'] = endNumber.toString();
      request.fields['scheme_or_paper'] = schemeOrPaper.toString();
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to process image: ${response.body}');
        throw Exception('Failed to process image: ${response.body}');
      }
    } catch (e) {
      print('Error sending image directly: $e');
      throw Exception('Error sending image directly: $e');
    }
  }

  Future<dynamic> markImage(
      String imageUrl, String testId, int endNumber, bool schemeOrPaper) async {
    try {
      String url = '$baseUrl/mark';

      // Request body
      Map<String, dynamic> body = {
        'image_url': imageUrl,
        'test_id': testId,
        'end_number': endNumber,
        'scheme_or_paper': schemeOrPaper,
      };

      // Include markScheme only if schemeOrPaper is true
      // if (schemeOrPaper && markScheme != null) {
      //   body['mark_scheme'] = markScheme;
      // }

      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response: ${response.body}');  

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to mark image: ${response.body}');
        throw Exception('Failed to mark image: ${response.body}');
      }
    } catch (e) {
      print('Error marking image: $e');
      throw Exception('Error marking image: $e');
    }
  }
}
