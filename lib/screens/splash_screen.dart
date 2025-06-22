import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the navigation after a short delay
    _navigateToLogin();
  }

  // Asynchronous function to navigate to the LoginScreen
  _navigateToLogin() async {
    // Simulate some loading or initialization time for your app
    await Future.delayed(const Duration(seconds: 3), () {});

    // Check if the widget is still mounted (in the widget tree) before navigating
    // This prevents errors if the user pops the screen before the delay finishes
    if (mounted) {
      // Navigate to the LoginScreen and replace the current route (splash screen)
      // This means the user cannot go back to the splash screen using the back button
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal, // Background color for the splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Your app logo or a prominent icon
            Icon(
              Icons.lock_open, // Example icon
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20), // Spacing below the icon
            Text(
              'Secure Login App', // Your app's title
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10), // Spacing below the title
            // A loading indicator to show something is happening
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Color of the spinner
            ),
          ],
        ),
      ),
    );
  }
}