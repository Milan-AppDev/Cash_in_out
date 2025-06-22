import 'package:cash/model/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
 // Make sure this path is correct

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile; // The profile to be edited
  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  // IMPORTANT: Replace with your actual API URL
  // For Android Emulator, use 10.0.2.2 to access localhost on your computer.
  // For a physical Android device, use your computer's actual local IP address (e.g., http://192.168.1.10/api).
  // For iOS Simulator/device, 'http://localhost' often works if your server is on the same machine.
  static const String _apiBaseUrl = 'http://localhost/api';
  // Consider using HTTPS in production!

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _mobileNumberController = TextEditingController(text: widget.userProfile.mobileNumber);
    _addressController = TextEditingController(text: widget.userProfile.address);
    _cityController = TextEditingController(text: widget.userProfile.city);
    _stateController = TextEditingController(text: widget.userProfile.state);
    _selectedGender = widget.userProfile.gender;
    _selectedDateOfBirth = widget.userProfile.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // Max 5 years old
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7043), // Accent orange
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7043),
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updatedProfile = widget.userProfile.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDateOfBirth,
      );

      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/update_user_profile.php'), // Your update profile API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            // IMPORTANT: In a real app, include your auth token here:
            // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
          },
          body: jsonEncode(updatedProfile.toJson()),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (mounted) {
            if (responseData['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(responseData['message'])),
              );
              Navigator.pop(context, updatedProfile); // Pop with the updated profile object
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${responseData['message']}')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server error: ${response.statusCode}. Please try again. ${responseData['message'] ?? ''}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect to server: $e. Is the server running?')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Light background
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF333333), fontSize: 20)),
        backgroundColor: const Color(0xFFF0F0F0),
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 70,
                      color: Color(0xFFFF7043),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(_nameController, 'Name', Icons.person,
                        validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    }),
                    const SizedBox(height: 18),
                    _buildTextField(_emailController, 'Email', Icons.email,
                        validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    }, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 18),
                    _buildTextField(_mobileNumberController, 'Mobile Number', Icons.phone,
                        validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      return null;
                    }, keyboardType: TextInputType.phone),
                    const SizedBox(height: 18),
                    _buildTextField(_addressController, 'Address', Icons.location_on),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(_cityController, 'City', Icons.location_city),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(_stateController, 'State', Icons.map),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _inputDecoration('Gender', Icons.wc),
                      items: <String>['Male', 'Female', 'Other']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () => _selectDateOfBirth(context),
                      child: InputDecorator(
                        decoration: _inputDecoration('Date of Birth', Icons.calendar_today),
                        child: Text(
                          _selectedDateOfBirth == null
                              ? 'Select Date of Birth'
                              : DateFormat('dd MMMӮ').format(_selectedDateOfBirth!),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7043)))
                          : ElevatedButton.icon(
                              onPressed: _saveProfileChanges,
                              icon: const Icon(Icons.save, size: 24),
                              label: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7043),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
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
    );
  }

  // Helper for consistent text field decoration
  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 15),
      prefixIcon: Icon(icon, color: const Color(0xFFFF7043), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );
  }

  // Helper for consistent text field creation
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {String? Function(String?)? validator, TextInputType? keyboardType}) { // Named parameters {}
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }
}
