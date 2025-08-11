/// PreviewScreen displays a scanned image for review before processing or uploading.
///
/// ## Responsibilities
/// - Shows the scanned image for user confirmation.
/// - Allows retaking the scan, uploading to Cloudinary, or processing for grading.
/// - Handles image upload and processing via ApiService.
/// - Shows loading indicators and error feedback during operations.
///
/// ## Parameters
/// - [imagePath]: Path to the scanned image file.
/// - [schemeOrPaper]: Indicates if the image is a marking scheme or student paper.
/// - [testId]: ID of the test associated with the image.
/// - [endNumber]: Number of questions in the test.
///
/// ## Main Methods
/// - `_upload`: Uploads the image to Cloudinary.
/// - `_processImage`: Processes the image for grading and navigates to test details.
/// - `_navigateToScanScreen`: Navigates back to the scan screen for retake.
///
/// ## Usage
/// Use this screen after scanning to confirm, upload, or process the image.
/// 
/// Example:
/// ```dart
/// PreviewScreen(
///   imagePath: filePath,
///   schemeOrPaper: false,
///   testId: 'abc123',
///   endNumber: 50,
/// )
/// ```
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mcq_marker/screens/scan_screen.dart';
import 'package:mcq_marker/screens/testdetail_screen.dart';
import 'package:mcq_marker/services/api_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; 

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final bool schemeOrPaper;
  final String testId;
  final int endNumber;

  const PreviewScreen({Key? key, required this.imagePath, required this.schemeOrPaper, required this.testId, required this.endNumber}) : super(key: key);

  @override
  PreviewScreenState createState() => PreviewScreenState();
}

class PreviewScreenState extends State<PreviewScreen> {
  bool _isProcessing = false;
  final bool _isUploading = false;
  String? _uploadedImageUrl;
  final ApiService _apiService = ApiService();

  Future <void> _upload() async {
         await _apiService.uploadImageToCloudinary(widget.imagePath);

  }

  Future<void> _processImage() async {
  setState(() {
    _isProcessing = true;
  });

  try {
    await _apiService.processImageAndUpload(widget.imagePath, widget.testId, widget.endNumber, widget.schemeOrPaper);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestDetailPage(testId: widget.testId, endNumber: widget.endNumber)
        ),
      );
  } catch (e) {
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error processing image: $e')),
    );
  }
}

void _navigateToScanScreen(bool schemeOrPaper, String testId, int endNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(schemeOrPaper: schemeOrPaper, testId: testId, endNumber: endNumber),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview',
        style: TextStyle(
            fontFamily: 'Rampart_One',
            color: Color.fromRGBO(29, 53, 87, 1.0),
            fontWeight: FontWeight.bold,
            ),
          ),
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),
          if (_uploadedImageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Uploaded to: $_uploadedImageUrl',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _navigateToScanScreen(widget.schemeOrPaper, widget.testId, widget.endNumber),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processImage,
                      icon: _isProcessing
                          ? LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.white,
                              size: 20,
                            )
                          : const Icon(Icons.check),
                      label: const Text('Process'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 20,
                        )
                      : const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}