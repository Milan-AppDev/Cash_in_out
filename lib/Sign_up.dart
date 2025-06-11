import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/home_screen.dart';
import 'services/payment_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _userName;
  String? _userPhone;

  final String baseUrl = 'http://localhost:8080/backend'; // XAMPP local backend

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final mobile = _mobileController.text.trim();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/request_otp.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mobile': mobile}),
        );
        final data = jsonDecode(response.body);
        setState(() => _isLoading = false);
        if (data['success']) {
          setState(() => _otpSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP sent to $mobile (for testing: ${data['otp']})')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );
      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);
      if (data['success']) {
        setState(() {
          _userName = data['user']['name'];
          _userPhone = data['user']['phone'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $_userName!')),
        );
        // Navigate to HomeScreen with user info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              paymentService: PaymentService(baseUrl: baseUrl),
              userName: data['user']['name'],
              userPhone: data['user']['phone'],
              userId: int.tryParse(data['user']['id'].toString()) ?? 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP verification failed')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            'Cash In-Out',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(
                    Icons.phone_android,
                    size: 64,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sign In...",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            enabled: !_otpSent,
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                                return 'Enter a valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Enter OTP',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                counterText: '',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _otpSent
                                      ? _verifyOtp
                                      : _sendOtp,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(_otpSent ? 'Verify OTP' : 'Send OTP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
