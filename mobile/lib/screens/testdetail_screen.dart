/// TestDetailPage displays detailed information and management options for a single MCQ test.
///
/// ## Responsibilities
/// - Shows all scripts for the selected test, including scores and answers.
/// - Allows marking schemes and scripts to be scanned and added.
/// - Enables selection and bulk deletion of scripts.
/// - Displays summary statistics and exports results via Excel.
/// - Handles connectivity changes, loading, and error states gracefully.
///
/// ## Parameters
/// - [testId]: The ID of the test to display.
/// - [endNumber]: Number of questions in the test.
///
/// ## Main Methods & Widgets
/// - `_fetchTestDetails`: Loads scripts and test info from backend.
/// - `_toggleSelectionMode`: Enables multi-select for bulk script deletion.
/// - `_confirmDeleteSelectedScripts`: Confirms and deletes selected scripts.
/// - `_navigateToScanScreen`: Navigates to scan screen for marking scheme or script.
/// - `_showShareModal`: Exports summary mark sheet via ExportService.
/// - `_showActionModal`: Presents marking options (scheme/script).
/// - `_buildScriptsTab`: Lists all scripts and their scores.
/// - `_buildErrorView`: Displays connection or loading errors.
/// - Uses [SummaryTab] widget for summary statistics.
///
/// ## Usage
/// Use this screen to manage scripts, view results, and export summaries for a test.
/// 
/// Example:
/// ```dart
/// TestDetailPage(testId: 'abc123', endNumber: 50)
/// ```
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:mcq_marker/screens/scan_screen.dart';
import 'package:mcq_marker/services/test_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mcq_marker/widgets/summary_tab.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mcq_marker/screens/answers_screen.dart';
import 'package:mcq_marker/services/export_service.dart';


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

class TestDetailPage extends StatefulWidget {
  final String testId;
  final int endNumber;

  const TestDetailPage({Key? key, required this.testId, required this.endNumber}) : super(key: key);

  @override
  State<TestDetailPage> createState() => _TestDetailPageState();
}

class _TestDetailPageState extends State<TestDetailPage>
    with SingleTickerProviderStateMixin {
  final TestService _testService = TestService();
  final ExportService _exportService = ExportService();
  List _scripts = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedScripts = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = "";
  Map<String, dynamic>? _test;
  int _currentTabIndex = 0;
  late TabController _tabController;
  StreamSubscription? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _fetchTestDetails();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _hasError) {
        _fetchTestDetails();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _onTabChange() {
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
        if (_currentTabIndex != 0) {
          _isSelectionMode = false;
          _selectedScripts.clear();
        }
      });
    }
  }

  Future<void> _fetchTestDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = "";
      _selectedScripts.clear();
      _isSelectionMode = false;
    });

    try {
      final scripts = await _testService.getTestScripts(widget.testId);
      final testDetails = await _testService.getTest(widget.testId);
      
      if (mounted) {
        setState(() {
          _scripts = scripts;
          _test = testDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      Fluttertoast.showToast(
        msg: "Failed to load test details: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _refreshData() async {
    return _fetchTestDetails();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedScripts.clear();
      }
    });
  }

  // Helper methods for calculating summary data
  double _calculateAverageScore(List scripts) {
    if (scripts.isEmpty) return 0.0;
    final totalScore = scripts.fold<double>(0.0, (sum, script) => sum + ((script['score'] as num?)?.toDouble() ?? 0.0));
    return totalScore / scripts.length;
  }

  double _calculateHighestScore(List scripts) {
    if (scripts.isEmpty) return 0.0;
    return scripts.map((s) => (s['score'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b);
  }

  double _calculateLowestScore(List scripts) {
    if (scripts.isEmpty) return 0.0;
    return scripts.map((s) => (s['score'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a < b ? a : b);
  }


  void _confirmDeleteSelectedScripts(BuildContext context) {
    if (_selectedScripts.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No scripts selected',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }
    bool isDialogProcessing = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
          title: const Text('Delete Selected Scripts'),
          content: Text(
              'Are you sure you want to delete ${_selectedScripts.length} selected script(s)?'),
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
                  for (String scriptId in _selectedScripts) {
                    await _testService.deleteScript(widget.testId, scriptId);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _fetchTestDetails();
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
      }),
    );
  }

  void _navigateToScanScreen(bool schemeOrPaper, String testId) {
    if (!schemeOrPaper &&
        (_test == null ||
            _test!['scheme'] == null ||
            _test!['scheme'].isEmpty)) {
      Fluttertoast.showToast(
        msg: "Please add a marking scheme before marking scripts",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(
            schemeOrPaper: schemeOrPaper, testId: testId, endNumber: widget.endNumber),
      ),
    ).then((_) {
      _fetchTestDetails();
    });
  }

  // Show share modal when FAB is pressed on summary tab
void _showShareModal() {
    if (_scripts.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No data to export',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(241, 250, 238, 1.0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Export Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Export detailed mark sheet with all student results',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Export Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  // Call to export service
                  _exportService.exportSummary(
                    context: context,
                    test: _test,
                    scripts: _scripts,
                    endNumber: widget.endNumber,
                    totalScripts: _scripts.length,
                    averageScore: _calculateAverageScore(_scripts),
                    highestScore: _calculateHighestScore(_scripts),
                    lowestScore: _calculateLowestScore(_scripts),
                  );
                },
                icon: const Icon(
                  Icons.file_download,
                  color: Color.fromRGBO(29, 53, 87, 1.0),
                  size: 24,
                ),
                label: const Text(
                  'Export Excel File',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Color.fromRGBO(29, 53, 87, 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Show action selection modal when FAB is pressed
  void _showActionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(241, 250, 238, 1.0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Choose Action',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                color: Color.fromRGBO(29, 53, 87, 1.0),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mark Scheme Button
            Container(
              width: double.infinity,
              height: 60,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToScanScreen(true, widget.testId);
                },
                icon: const Icon(
                  Icons.assignment,
                  color: Color.fromRGBO(29, 53, 87, 1.0),
                  size: 24,
                ),
                label: const Text(
                  'Mark Scheme',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Color.fromRGBO(29, 53, 87, 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            
            // Mark Script Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: (_test == null ||
                        _test!['scheme'] == null ||
                        _test!['scheme'].isEmpty)
                    ? null
                    : () {
                        Navigator.pop(context);
                        _navigateToScanScreen(false, widget.testId);
                      },
                icon: Icon(
                  Icons.camera_alt,
                  color: (_test == null ||
                          _test!['scheme'] == null ||
                          _test!['scheme'].isEmpty)
                      ? Colors.grey
                      : const Color.fromRGBO(29, 53, 87, 1.0),
                  size: 24,
                ),
                label: Text(
                  'Mark Script',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: (_test == null ||
                            _test!['scheme'] == null ||
                            _test!['scheme'].isEmpty)
                        ? Colors.grey
                        : const Color.fromRGBO(29, 53, 87, 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_test == null ||
                          _test!['scheme'] == null ||
                          _test!['scheme'].isEmpty)
                      ? Colors.grey[300]
                      : const Color.fromRGBO(168, 218, 220, 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            
            if (_test == null ||
                _test!['scheme'] == null ||
                _test!['scheme'].isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add a marking scheme first',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scriptsWithScores = _scripts.where((script) => script['score'] != null).toList();
    scriptsWithScores.sort((a, b) => a['score'].compareTo(b['score']));

    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
      
      // Center Floating Action Button (changes based on tab)
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _currentTabIndex == 0 ? _showActionModal : _showShareModal,
          backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
          elevation: 8,
          shape: const CircleBorder(),
          child: Icon(
            _currentTabIndex == 0 ? Icons.camera_alt : Icons.share,
            color: const Color.fromRGBO(29, 53, 87, 1.0),
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
                    if (_scripts.isNotEmpty && _currentTabIndex == 0)
                      IconButton(
                        icon: Icon(
                          _isSelectionMode ? Icons.cancel : Icons.select_all,
                          color: const Color.fromRGBO(29, 53, 87, 1.0),
                          size: 28,
                        ),
                        onPressed: _toggleSelectionMode,
                        tooltip: _isSelectionMode ? 'Cancel Selection' : 'Select Scripts',
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                        size: 28,
                      ),
                      onPressed: _isLoading ? null : _refreshData,
                      tooltip: 'Refresh',
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
                    if (_isSelectionMode && _currentTabIndex == 0)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                        onPressed: () => _confirmDeleteSelectedScripts(context),
                        tooltip: 'Delete Selected',
                      )
                    else
                      const SizedBox.shrink(),
                    // Extra space to balance the layout
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      appBar: AppBar(
        title: Text(
          _test?['name']?.toString().toUpperCase() ?? 'TEST DETAILS',
          style: const TextStyle(
            fontFamily: 'Rampart_One',
            color: Color.fromRGBO(29, 53, 87, 1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        elevation: 0,
        centerTitle: true,
        actions: const [
        ],
      ),
      
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: const Color.fromRGBO(29, 53, 87, 1.0), size: 50),
            )
          : _hasError
              ? _buildErrorView()
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(168, 218, 220, 0.3),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _tabController.animateTo(0);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: _currentTabIndex == 0
                                      ? const Color.fromRGBO(168, 218, 220, 1.0)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                child: Center(
                                  child: Text(
                                    'SCRIPTS (${_scripts.length})',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.bold,
                                      color: _currentTabIndex == 0
                                          ? const Color.fromRGBO(29, 53, 87, 1.0)
                                          : const Color.fromRGBO(69, 123, 157, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _tabController.animateTo(1);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: _currentTabIndex == 1
                                      ? const Color.fromRGBO(168, 218, 220, 1.0)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                child: Center(
                                  child: Text(
                                    'SUMMARY',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.bold,
                                      color: _currentTabIndex == 1
                                          ? const Color.fromRGBO(29, 53, 87, 1.0)
                                          : const Color.fromRGBO(69, 123, 157, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildScriptsTab(),
                            SummaryTab(
                                scripts: _scripts,
                                endNumber: widget.endNumber,
                                test: _test),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildScriptsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _scripts.isEmpty
          ? Center(
              child: ListView(
                shrinkWrap: true,
                children: const [
                  Center(child: Text("No scripts available")),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _scripts.length,
              itemBuilder: (context, index) {
                final script = _scripts[index];
                final String scriptId = script['_id']?.toString() ?? 'script_$index';
                final bool isSelected = _selectedScripts.contains(scriptId);
                final String indexNumber = script['index_number']?.toString() ?? 'N/A';
                final dynamic score = script['score'];
                final String scoreText = score?.toString() ?? 'N/A';
                
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
                                    _selectedScripts.add(scriptId);
                                  } else {
                                    _selectedScripts.remove(scriptId);
                                  }
                                });
                              },
                            )
                          : null,
                      title: Text(
                        indexNumber,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Orbitron',
                          color: Color.fromRGBO(69, 123, 157, 1.0),
                        ),
                      ),
                      subtitle: Text(
                        'SCORE: $scoreText',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Orbitron',
                          color: Color.fromRGBO(69, 123, 157, 1.0),
                        ),
                      ),
                      trailing: score != null 
                          ? const Icon(
                              Icons.visibility,
                              color: Color.fromRGBO(69, 123, 157, 1.0),
                            )
                          : const Icon(
                              Icons.pending,
                              color: Colors.orange,
                            ),
                      onTap: _isSelectionMode
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedScripts.remove(scriptId);
                                } else {
                                  _selectedScripts.add(scriptId);
                                }
                              });
                            }
                          : () {
                              if (script['score'] != null) {
                                final rawIndexNumber = script['index_number'];
                                
                                if (rawIndexNumber != null && rawIndexNumber.toString().isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnswersScreen(
                                        indexNumber: rawIndexNumber.toString(),
                                        answers: script['answers'],
                                        endNumber: widget.endNumber,
                                      ),
                                    ),
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Script data is incomplete. Cannot show answers.",
                                    backgroundColor: Colors.orange,
                                    textColor: Colors.white,
                                  );
                                }
                              } else {
                                Fluttertoast.showToast(
                                  msg: "This script has not been marked yet.",
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                );
                              }
                            },
                    ),
                    const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                  ],
                );
              },
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
                  : "Failed to load test details. Please check your connection.",
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
            onPressed: _fetchTestDetails,
          ),
        ],
      ),
    );
  }
}