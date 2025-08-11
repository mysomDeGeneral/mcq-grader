/// TestScreen is the main dashboard for managing MCQ tests in MCQ Marker.
///
/// ## Responsibilities
/// - Lists all MCQ tests for the logged-in user.
/// - Allows creation, selection, and deletion of tests.
/// - Handles connectivity changes and error states gracefully.
/// - Navigates to test details, test creation, and login screens.
/// - Provides logout functionality and user feedback.
///
/// ## Main Widgets & Methods
/// - `CreateTestPage`: Full-screen page for creating new tests.
/// - `_fetchTests`: Loads tests from backend.
/// - `_toggleSelectionMode`: Enables multi-select for bulk deletion.
/// - `_confirmDeleteSelectedTests`: Confirms and deletes selected tests.
/// - `_showLogoutConfirmation`: Handles user logout.
/// - `_buildErrorView`: Displays connection or loading errors.
///
/// ## Usage
/// Use this screen as the main entry after login to manage all MCQ tests.
/// 
/// Example:
/// ```dart
/// Navigator.of(context).pushReplacement(
///   MaterialPageRoute(builder: (context) => const CreateTestPage()),
/// );
/// ```
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mcq_marker/screens/login_screen.dart';
import 'package:mcq_marker/services/test_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mcq_marker/screens/testdetail_screen.dart';
import 'package:mcq_marker/providers/provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mcq_marker/screens/create_test_screen.dart';

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

class CreateTestPage extends StatefulWidget {
  const CreateTestPage({Key? key}) : super(key: key);

  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final TestService _testService = TestService();
  List<Map<String, dynamic>>? _tests = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedTests = {};
  bool _isloading = false;
  bool _hasError = false;
  String _errorMessage = "";
  StreamSubscription? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _fetchTests();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _hasError) {
        _fetchTests();
      }
    });
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isloading = true;
      _hasError = false;
      _errorMessage = "";
      _selectedTests.clear();
      _isSelectionMode = false;
    });

    try {
      List<Map<String, dynamic>> tests = await _testService.getUserTests();
      if (mounted) {
        setState(() {
          _tests = tests;
          _isloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isloading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        Fluttertoast.showToast(
          msg: "Failed to load tests: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    return _fetchTests();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTests.clear();
      }
    });
  }

  void _confirmDeleteSelectedTests(BuildContext context) {
    if (_selectedTests.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No tests selected',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    bool isDialogProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
            title: const Text('Delete Selected Tests'),
            content: Text(
                'Are you sure you want to delete ${_selectedTests.length} selected test(s)?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              AppButton(
                text: 'Delete',
                isLoading: isDialogProcessing,
                onPressed: () async {
                  try {
                    setDialogState(() {
                      isDialogProcessing = true;
                    });

                    for (String testId in _selectedTests) {
                      await _testService.deleteTest(testId);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      setState(() {
                        _isSelectionMode = false;
                        _selectedTests.clear();
                      });
                      _fetchTests();
                    }
                  } catch (e) {
                    setDialogState(() {
                      isDialogProcessing = false;
                    });

                    Fluttertoast.showToast(
                      msg: e.toString(),
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget loadingCircleOrRow(bool isLoading, String btnName) {
    return isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          )
        : Text(
            btnName,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          );
  }

  // Navigate to full-screen create test page
  void _navigateToCreateTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestScreen(
          testService: _testService,
          onTestCreated: _fetchTests,
        ),
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
        title: const Row(
          children: [
            Icon(
              Icons.logout,
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color.fromRGBO(69, 123, 157, 1.0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(69, 123, 157, 1.0),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              Navigator.pop(context); 
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Login(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "Connection Error",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage.isNotEmpty
                  ? "Error: $_errorMessage"
                  : "Failed to load tests. Please check your connection.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(
              "Retry",
              style: TextStyle(
                  color: Color.fromRGBO(29, 53, 87, 1.0),
                  fontFamily: 'Orbitron'),
            ),
            onPressed: _fetchTests,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
      
      // Center Floating Action Button
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _navigateToCreateTest,
          backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Color.fromRGBO(29, 53, 87, 1.0),
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Bottom Navigation Bar with notch for FAB
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromRGBO(168, 218, 220, 1.0),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left side buttons
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isSelectionMode ? Icons.cancel : Icons.select_all,
                        color: const Color.fromRGBO(29, 53, 87, 1.0),
                        size: 28,
                      ),
                      onPressed: _toggleSelectionMode,
                      tooltip: _isSelectionMode ? 'Cancel Selection' : 'Select Tests',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                        size: 28,
                      ),
                      onPressed: _isloading ? null : _refreshData,
                      tooltip: 'Refresh Tests',
                    ),
                  ],
                ),
              ),
              
              // Space for the center FAB
              const SizedBox(width: 40),
              
              // Right side buttons
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                        onPressed: () => _confirmDeleteSelectedTests(context),
                        tooltip: 'Delete Selected',
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                        size: 28,
                      ),
                      onPressed: () => _showLogoutConfirmation(),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      appBar: AppBar(
        title: const Text(
          'MCQ GRADER',
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _hasError
            ? _buildErrorView()
            : _isloading
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color.fromRGBO(29, 53, 87, 1.0), size: 50),
                  )
                : _tests!.isEmpty
                    ? Center(
                        child: ListView(
                          shrinkWrap: true,
                          children: const [
                            Center(
                              child: Text("No tests available"),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: ListView.builder(
                          itemCount: _tests!.length,
                          itemBuilder: (context, index) {
                            final test = _tests![index];
                            final String testId = test['id'];
                            final bool isSelected = _selectedTests.contains(testId);

                            return Column(
                              children: [
                                ListTile(
                                  tileColor: Colors.transparent,
                                  leading: _isSelectionMode
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedTests.add(testId);
                                              } else {
                                                _selectedTests.remove(testId);
                                              }
                                            });
                                          },
                                        )
                                      : null,
                                  title: Text(
                                    (test['name'] ?? 'No name').toString().toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Orbitron',
                                        color: Color.fromRGBO(69, 123, 157, 1.0)),
                                  ),
                                  subtitle: Text(
                                    (test['course_code'] ?? 'No code'),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Orbitron',
                                        color: Color.fromRGBO(69, 123, 157, 1.0)),
                                  ),
                                  trailing: Text(
                                    (test['class_'] ?? 'No name'),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Orbitron',
                                        color: Color.fromRGBO(69, 123, 157, 1.0)),
                                  ),
                                  onTap: _isSelectionMode
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedTests.remove(testId);
                                            } else {
                                              _selectedTests.add(testId);
                                            }
                                          });
                                        }
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TestDetailPage(
                                                testId: test['id'],
                                                endNumber: test['endNumber'],
                                              ),
                                            ),
                                          ).then((_) => _fetchTests());
                                        },
                                ),
                                const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                              ],
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}