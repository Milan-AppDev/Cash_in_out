import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transactions_screen.dart';
import 'Sign_up.dart'; // Make sure this file has a class SignUpScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash In-Out',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),

      // ✅ Uncomment the screen you want to preview:
      //home: SignUpScreen(),
       //home: HomeScreen(),
       //home: DashboardScreen(),
      // home: ProfileScreen(),
       home: TransactionsScreen(),

      // You can keep routes if you plan to use Navigator later
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
