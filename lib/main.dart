import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transactions_screen.dart';
import 'Sign_up.dart'; // Make sure this file has a class SignUpScreen
import 'services/payment_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define the backend base URL here
  final String baseUrl =
      'http://localhost/your_backend_api'; // Change this to your actual backend URL

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService(baseUrl: baseUrl);

    return MaterialApp(
      title: 'Cash In-Out',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),

      // Pass paymentService to HomeScreen
      home: HomeScreen(paymentService: paymentService),

      // You can keep routes if you plan to use Navigator later
      routes: {
        '/home': (context) => HomeScreen(paymentService: paymentService),
      },
    );
  }
}
