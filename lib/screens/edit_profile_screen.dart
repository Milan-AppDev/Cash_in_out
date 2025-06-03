import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _addressController = TextEditingController(text: widget.user['address'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _cityController = TextEditingController(text: widget.user['city'] ?? '');
    _stateController = TextEditingController(text: widget.user['state'] ?? '');

    // Initialize gender if available
    if (_genders.contains(widget.user['gender'])) {
      _selectedGender = widget.user['gender'];
    }

    // Initialize date of birth if available
    if (widget.user['date_of_birth'] != null) {
      try {
        _selectedDateOfBirth = DateTime.parse(widget.user['date_of_birth']);
      } catch (e) {
        // Handle parsing error if date format from backend is unexpected
        print('Error parsing date of birth: ${widget.user['date_of_birth']} - $e');
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Prepare data to send to backend
      final Map<String, dynamic> updatedData = {
        'user_id': userId,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _selectedGender,
        'email': _emailController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'date_of_birth': _selectedDateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
            : null,
      };

      // Remove null or empty values to avoid sending unnecessary data
      updatedData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2/backend_new/profile.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updatedData),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
              // Navigate back and indicate success
              Navigator.pop(context, true);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(data['message'] ?? 'Failed to update profile.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile: Server error.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    // Username (Read-only)
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 16),

                    // State
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth Picker
                    ListTile(
                      title: Text(
                        _selectedDateOfBirth == null
                            ? 'Select Date of Birth'
                            : 'Date of Birth: ${DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateOfBirth(context),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 