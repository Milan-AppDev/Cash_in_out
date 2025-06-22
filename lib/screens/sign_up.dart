import 'package:cash/screens/login.dart'; // Import the LoginScreen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for JSON encoding/decoding

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // Add loading state

  // IMPORTANT: Replace with your actual API URL
  static const String _apiBaseUrl = 'http://localhost/api'; // For Android Emulator
  // Consider using HTTPS in production!

  // Function to handle the sign-up logic
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      final String email = _emailController.text;
      final String password = _passwordController.text;

      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/register.php'), // Your register API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': email,
            'password': password,
          }),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (mounted) {
            if (responseData['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(responseData['message'])),
              );
              // Navigate to login screen after successful registration
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); // Go back to login screen
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${responseData['message']}')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server error: ${response.statusCode}')),
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

  // Basic password validation regex
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]|:;"<>,.?/~`]).{8,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Very light grey/off-white background
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Color(0xFF333333), fontSize: 20)), // Font size for title
        backgroundColor: const Color(0xFFF0F0F0), // Same as background for seamless look
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F0F0), // Lightest grey
              Color(0xFFE0E0E0), // Slightly darker grey
              Color(0xFFD0D0D0), // Even darker grey
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), // Adjusted padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, // Adjusted size
                    height: 100, // Adjusted size
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white, // White circle background
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          blurRadius: 10, // Adjusted blur
                          offset: const Offset(0, 6), // Adjusted offset
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_add,
                        size: 50, // Adjusted icon size
                        color: Color(0xFFFF7043), // Accent color for icon
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Adjusted spacing
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 30, // Adjusted font size
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333), // Dark text for title
                    ),
                  ),
                  const SizedBox(height: 25), // Adjusted spacing
                  Card(
                    elevation: 10, // Adjusted elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0), // Adjusted radius
                    ),
                    color: Colors.white, // White card background
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Adjusted padding
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Color(0xFF333333), fontSize: 16), // Font size
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email, color: Color(0xFFFF7043), size: 20), // Icon size
                                hintText: 'Enter your email',
                                hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0), // Light grey fill color
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // Compact padding
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true, // Make input more compact
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18), // Adjusted spacing
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Color(0xFF333333), fontSize: 16), // Font size
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF7043), size: 20), // Icon size
                                hintText: 'Enter your password',
                                hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF666666), // Medium grey icon color
                                    size: 20, // Icon size
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0), // Light grey fill color
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // Compact padding
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true, // Make input more compact
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (!_passwordRegex.hasMatch(value)) {
                                  return 'Password must be at least 8 characters long, and contain at least one uppercase letter, one lowercase letter, one digit, and one special character.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8), // Adjusted spacing
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0), // Adjusted padding
                                child: Text(
                                  'Min 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char',
                                  style: const TextStyle(
                                    fontSize: 11, // Adjusted font size
                                    color: Color(0xFF999999), // Light grey hint text
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18), // Adjusted spacing
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              style: const TextStyle(color: Color(0xFF333333), fontSize: 16), // Font size
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF7043), size: 20), // Icon size
                                hintText: 'Confirm your password',
                                hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                labelText: 'Confirm Password',
                                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF666666), // Medium grey icon color
                                    size: 20, // Icon size
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0), // Light grey fill color
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // Compact padding
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true, // Make input more compact
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25), // Adjusted spacing
                            SizedBox(
                              width: double.infinity,
                              height: 50, // Adjusted height
                              child: _isLoading // Show CircularProgressIndicator when loading
                                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7043))) // Accent color
                                  : ElevatedButton(
                                      onPressed: _signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF7043), // Accent color
                                        foregroundColor: Colors.white, // White text on bright button
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0), // Adjusted rounded corners
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                                        elevation: 8,
                                      ),
                                      child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18), // Adjusted spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Color(0xFF666666), fontSize: 14), // Font size
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero), // Remove default text button padding
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFFFF7043), // Accent color
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Font size
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
