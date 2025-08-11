/// ScanScreen provides the camera interface and logic for scanning MCQ scripts or marking schemes.
///
/// ## Responsibilities
/// - Requests camera permissions and initiates edge detection for document scanning.
/// - Saves scanned images to device storage.
/// - Navigates to PreviewScreen for review and further processing.
/// - Handles errors and permission denials gracefully.
/// - Shows loading animation during scanning.
///
/// ## Parameters
/// - [schemeOrPaper]: Indicates if scanning a marking scheme or student script.
/// - [testId]: ID of the test associated with the scan.
/// - [endNumber]: Number of questions in the test.
///
/// ## Main Methods
/// - `_requestPermissionsAndScan`: Handles permission requests and starts scanning.
/// - `_scanDocument`: Performs edge detection and saves the image.
/// - `_showErrorDialog`: Displays error messages to the user.
///
/// ## Usage
/// Use this screen to scan answer sheets or marking schemes before grading.
/// 
/// Example:
/// ```dart
/// ScanScreen(
///   schemeOrPaper: false,
///   testId: 'abc123',
///   endNumber: 50,
/// )
/// ```
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mcq_marker/screens/preview_screen.dart'; 

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            ),
    );
  }
}

class ScanScreen extends StatefulWidget {
  final bool schemeOrPaper;
  final String testId;
  final int endNumber;

  const ScanScreen({
    Key? key,
    required this.schemeOrPaper,
    required this.testId,
    required this.endNumber,
  }) : super(key: key);

  @override
  ScanScreenState createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  bool _isScanning = true;
  final List<String> _scannedPictures = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndScan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isScanning) {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      }
    }
  }

  Future<void> _requestPermissionsAndScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _scanDocument();
    } else {
      if (mounted) {
        setState(() => _isScanning = false);
        _showErrorDialog('Camera permission denied');
      }
    }
  }

  Future<void> _scanDocument() async {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _scannedPictures.clear();
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      String? documentsDirectory = (await getApplicationSupportDirectory()).path;

      String imageFilePath = '$documentsDirectory/${DateTime.now().microsecondsSinceEpoch}.jpg';

      bool success = await EdgeDetection.detectEdge(imageFilePath);

      if (success && await File(imageFilePath).exists()) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PreviewScreen(
                imagePath: imageFilePath,
                schemeOrPaper: widget.schemeOrPaper,
                testId: widget.testId,
                endNumber: widget.endNumber,
              ),
            ),
          );
        }
      } else {
        debugPrint('Edge detection failed or file does not exist');
        if (mounted) {
          setState(() => _isScanning = false);
          Navigator.of(context).pop();        }
      }
    } catch (e) {
      debugPrint('Error during edge detection: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
      appBar: AppBar(
        title: Text(
          widget.schemeOrPaper ? 'Scan Scheme' : 'Scan Script',
          style: const TextStyle(
            fontFamily: 'Rampart_One',
            color: Color.fromRGBO(29, 53, 87, 1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: const Color.fromRGBO(29, 53, 87, 1.0),
          size: 50,
        ),
      ),
    );
  }
}