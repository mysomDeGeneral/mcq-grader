/// Entry point for the MCQ Marker Flutter application.
///
/// This file initializes environment variables, sets device orientation,
/// manages the splash screen, and sets up the root widget with state management.
///
/// ## Responsibilities
/// - Loads environment variables using `flutter_dotenv`.
/// - Preserves and removes the native splash screen during startup.
/// - Restricts app orientation to portrait mode.
/// - Initializes the `UserProvider` for authentication and session management.
/// - Sets up the app's theme and navigation.
/// - Chooses the initial screen based on authentication state (login or test creation).
///
/// ## Main Widgets
/// - `MyApp`: Root widget, wraps the app in a `MultiProvider` for state management.
/// - `CreateTestPage` and `Login`: Shown based on user authentication.
///
/// ## Usage
/// Run this file to start the MCQ Marker app:
/// ```sh
/// flutter run
/// ```
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcq_marker/providers/provider.dart';
import 'package:mcq_marker/screens/login_screen.dart';
import 'package:mcq_marker/screens/test_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  

  final userProvider = UserProvider();
  await userProvider.initialize();  

  runApp(MyApp(userProvider: userProvider));
}

class MyApp extends StatefulWidget {
  final UserProvider userProvider;
  
  const MyApp({Key? key, required this.userProvider}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.userProvider), 
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MCQ Grader',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return userProvider.isLoggedIn ? const CreateTestPage() : const Login();
          },
        ),
      ),
    );
  }
}