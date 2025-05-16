import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/client_list_page.dart';

void main() {
  runApp(CashInOutApp());
}

class CashInOutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash In-Out',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF4ECDC4)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: ClientListPage(),
    );
  }
}
