/// LoginScreen provides the user interface and logic for signing in to MCQ Marker.
///
/// ## Responsibilities
/// - Collects user email and password.
/// - Validates input and handles authentication via UserProvider.
/// - Shows loading indicator during sign-in.
/// - Displays error feedback on failed login.
/// - Navigates to registration or main dashboard as appropriate.
/// - Animates motivational text and displays app branding.
///
/// ## Main Methods
/// - `_login`: Handles form validation and triggers authentication.
/// - `loadingCircleOrRow`: Shows loading spinner or "Sign In" text.
///
/// ## Usage
/// Use this screen as the entry point for user authentication.
/// 
/// Example:
/// ```dart
/// Navigator.of(context).pushReplacement(
///   MaterialPageRoute(builder: (context) => const Login()),
/// );
/// ```
import 'package:flutter/material.dart';
import 'package:mcq_marker/providers/provider.dart';
import 'package:mcq_marker/screens/register_screen.dart';
import 'package:mcq_marker/screens/test_screen.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool signInButtonPressed = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

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
            'Sign In',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Orbitron',
              color: Color.fromRGBO(29, 53, 87, 1.0),
            ),
          );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => signInButtonPressed = true);

      final success = await Provider.of<UserProvider>(
        context,
        listen: false,
      ).login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CreateTestPage(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() => signInButtonPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            Center(
              child: Image.asset(
                'assets/images/layered-waves-haikei.png',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
              ),
            ),
            // Content
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
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  // Animated text
                  SizedBox(
                    height: 50.0,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontFamily: 'Orbitron',
                        color: Color.fromRGBO(29, 53, 87, 1.0),
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TyperAnimatedText('Your grading solution.'),
                          TyperAnimatedText('Fast, accurate, and easy.'),
                          TyperAnimatedText('Automate your workflow.'),
                        ],
                        repeatForever: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50.0),
                  // Login form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              fillColor: Colors.white.withOpacity(0.8),
                              filled: true,
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: signInButtonPressed ? null : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                backgroundColor: const Color.fromRGBO(168, 218, 220, 1.0),
                              ),
                              child: loadingCircleOrRow(signInButtonPressed),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          // Register link
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Don\'t have an account? Register here',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                color: Color.fromRGBO(29, 53, 87, 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}