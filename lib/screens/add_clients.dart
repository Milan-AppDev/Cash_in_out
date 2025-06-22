import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
 // Import the centralized Client model

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  bool _isLoading = false;

  // IMPORTANT: Replace with your actual API URL
  static const String _apiBaseUrl = 'http://localhost/api'; // For Android Emulator
  // Consider using HTTPS in production!

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      final String name = _nameController.text.trim();
      final String mobileNumber = _mobileNumberController.text.trim();

      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/add_client.php'), // Your add client API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'name': name,
            'mobile_number': mobileNumber,
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
            if (responseData['success']) {
              // Pop back to the previous screen (HomeScreen)
              Navigator.pop(context, true); // Pass true to indicate success
            }
          }
        } else {
          // Handle specific HTTP errors if needed
          String errorMessage = 'Server error: ${response.statusCode}. Please try again.';
          if (response.statusCode == 409) { // Example: Conflict for duplicate mobile number
            errorMessage = responseData['message'] ?? 'Client with this mobile number already exists.';
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect to server: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Very light grey/off-white background
      appBar: AppBar(
        title: const Text('Add New Client', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))), // Dark text
        backgroundColor: const Color(0xFFF0F0F0), // Same as background for seamless look
        foregroundColor: const Color(0xFF333333), // Dark icons/text on app bar
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Rounded corners
              color: Colors.white, // White card background
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 80,
                        color: Color(0xFFFF7043), // Accent color for icon
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFF333333)), // Dark input text color
                        decoration: InputDecoration(
                          labelText: 'Client Name',
                          labelStyle: const TextStyle(color: Color(0xFF666666)), // Label text color
                          hintText: 'e.g., John Doe',
                          hintStyle: const TextStyle(color: Color(0xFF999999)),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFFF7043)), // Accent color for icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0), // Light grey fill color
                          focusedBorder: OutlineInputBorder( // Accent color on focus
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder( // Consistent border for enabled state
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the client\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mobileNumberController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Color(0xFF333333)), // Dark input text color
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: const TextStyle(color: Color(0xFF666666)), // Label text color
                          hintText: 'e.g., 9876543210',
                          hintStyle: const TextStyle(color: Color(0xFF999999)),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF7043)), // Accent color for icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0), // Light grey fill color
                           focusedBorder: OutlineInputBorder( // Accent color on focus
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder( // Consistent border for enabled state
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the mobile number';
                          }
                          // Basic 10-digit mobile number validation
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                            return 'Please enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7043))) // Accent color
                            : ElevatedButton.icon(
                                onPressed: _addClient,
                                icon: const Icon(Icons.check_circle_outline, size: 28),
                                label: const Text('Add Client', style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7043), // Accent button color
                                  foregroundColor: Colors.white, // White text on bright button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0), // Rounded corners
                                  ),
                                  elevation: 8,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
