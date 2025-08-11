/// RegisterScreen provides the user interface and logic for user registration in MCQ Marker.
///
/// ## Responsibilities
/// - Collects user email, display name, password, and password confirmation.
/// - Validates input and handles registration via UserProvider.
/// - Shows loading indicator during registration.
/// - Displays error feedback on failed registration.
/// - Navigates to the test creation screen on success.
/// - Provides a link to the login screen for existing users.
/// - Animates motivational text and displays app branding.
///
/// ## Main Methods
/// - `_register`: Handles form validation and triggers registration.
/// - `loadingCircleOrRow`: Shows loading spinner or "Register" text.
///
/// ## Usage
/// Use this screen as the entry point for new user registration.
/// 
/// Example:
/// ```dart
/// Navigator.of(context).pushReplacement(
///   MaterialPageRoute(builder: (context) => const RegisterScreen()),
/// );
/// ```
import 'package:flutter/material.dart';
import 'package:mcq_marker/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mcq_marker/providers/provider.dart';
import 'package:mcq_marker/screens/test_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:animated_text_kit/animated_text_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registering = false;

   loadingCircleOrRow(bool isLoading) {
    return isLoading
        ? const SizedBox(
            height: 20.0,
            width: 20.0,
            child: CircularProgressIndicator(
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          )
        : const Text(
            'Register',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Orbitron',
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _registering = true);

      final success = await Provider.of<UserProvider>(
        context,
        listen: false,
      ).register(
        _emailController.text,
        _displayNameController.text,
        _passwordController.text,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CreateTestPage(),
          ),
        );
      }

      setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Background image (if needed)
            Center(
              child: Image.asset(
                'assets/images/layered-waves-haikei.png',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 50.0),
                    // Logo and title
                    Container(
                      height: 300,
                      width: 300,
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Expanded(
                          child: Image.asset(
                            'assets/images/data-sheet-256.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                          const Text(
                            'MCQ GRADER',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Rampart_One',
                              color: Color.fromRGBO(29, 53, 87, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Animated Text
                    SizedBox(
                      height: 50.0,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontFamily: 'Orbitron',
                          color: Color.fromRGBO(29, 53, 87, 1.0),
                        ),
                        child: AnimatedTextKit(
                          totalRepeatCount: 10,
                          pause: const Duration(milliseconds: 2500),
                          stopPauseOnTap: true,
                          animatedTexts: [
                            TyperAnimatedText('Sign up to create your first test'),
                            TyperAnimatedText('Generate test keys'),
                            TyperAnimatedText("Mark your students' scripts with ease"),
                          ],
                          onTap: () {
                            debugPrint("Tap animated text event");
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Registration Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child:    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter email';
                              if (!value.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Display Name Field
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Display Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter display name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Confirm your password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _registering ? null : _register,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
                              ),
                              child: loadingCircleOrRow(_registering),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Link to Login Page
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ),
                              );
                            },
                            child: const Text(
                              'Already have an account? Sign in here',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                 ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}