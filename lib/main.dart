import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'sign_up.dart';
import 'services/payment_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final String baseUrl = 'http://localhost:8080/backend';

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService(baseUrl: baseUrl);

    return MaterialApp(
      title: 'Cash In-Out',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: SignUpScreen(), 
    );
  }
}
