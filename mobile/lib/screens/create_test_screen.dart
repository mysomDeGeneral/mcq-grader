/// CreateTestScreen provides a form UI for creating a new MCQ test.
///
/// ## Responsibilities
/// - Collects course name, course code, class name, number of questions, and description.
/// - Validates user input and submits test data to the backend via TestService.
/// - Shows loading indicator and feedback on success or error.
/// - Animates form appearance for improved UX.
///
/// ## Parameters
/// - [testService]: Instance of TestService for backend operations.
/// - [onTestCreated]: Callback triggered after successful test creation.
///
/// ## Main Methods
/// - `_createTest`: Handles form submission and test creation.
/// - `_buildFormField`: Builds styled input fields for the form.
///
/// ## Usage
/// Navigate to this screen to create a new test.
/// 
/// Example:
/// ```dart
/// CreateTestScreen(
///   testService: myTestService,
///   onTestCreated: () { ... },
/// )
/// ```
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mcq_marker/services/test_service.dart';

class CreateTestScreen extends StatefulWidget {
  final TestService testService;
  final VoidCallback onTestCreated;

  const CreateTestScreen({
    Key? key,
    required this.testService,
    required this.onTestCreated,
  }) : super(key: key);

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _endNumberController = TextEditingController();
  
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _classNameController.dispose();
    _courseCodeController.dispose();
    _endNumberController.dispose();
    super.dispose();
  }

  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int endNumber = int.parse(_endNumberController.text);
      await widget.testService.createTest(
        _classNameController.text.trim(),
        _courseCodeController.text.trim(),
        _descriptionController.text.trim(),
        _nameController.text.trim(),
        endNumber,
      );

      if (mounted) {
        widget.onTestCreated();
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: 'Test created successfully!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(241, 250, 238, 1.0),
      appBar: AppBar(
        title: const Text(
          'Create New Test',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Color.fromRGBO(29, 53, 87, 1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(29, 53, 87, 1.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.quiz,
                        size: 48,
                        color: Color.fromRGBO(69, 123, 157, 1.0),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create a New MCQ Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          color: Color.fromRGBO(29, 53, 87, 1.0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to create your test',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Form Fields
                _buildFormField(
                  controller: _nameController,
                  label: 'Course Name',
                  icon: Icons.school,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: _courseCodeController,
                  label: 'Course Code',
                  icon: Icons.code,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter course code';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: _classNameController,
                  label: 'Class Name',
                  icon: Icons.class_,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter class name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: _endNumberController,
                  label: 'Number of Questions',
                  icon: Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of questions';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildFormField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 32),
                
                // Create Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color.fromRGBO(29, 53, 87, 1.0),
                            ),
                          )
                        : const Text(
                            'Create Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              color: Color.fromRGBO(29, 53, 87, 1.0),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel Button
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                      color: Color.fromRGBO(69, 123, 157, 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          color: Color.fromRGBO(29, 53, 87, 1.0),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: const Color.fromRGBO(69, 123, 157, 1.0),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            color: Color.fromRGBO(69, 123, 157, 1.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromRGBO(168, 218, 220, 1.0),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}