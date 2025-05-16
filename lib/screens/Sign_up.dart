import 'package:cash_in_out/screens/otp_screen.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final mobile = _mobileController.text.trim();
      Future.delayed(const Duration(seconds: 1), () async {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(mobileNumber: mobile),
            ),
          ),
        ).showSnackBar(SnackBar(content: Text('OTP sent to $mobile')));
      });
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
                Text(
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
                              onPressed: _isLoading ? null : _sendOtp,
                              child:
                                  _isLoading
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
                                      : const Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
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
