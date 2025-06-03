import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart'; // Assuming splash screen is the initial route after logout
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File class
import 'edit_profile_screen.dart'; // Import the edit profile screen
import 'package:intl/intl.dart'; // For date formatting

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Loading...';
  String _phoneNumber = 'Loading...';
  int? _userId;
  String? _profileImageUrl;
  bool _isLoading = true;
  File? _selectedImage;

  Map<String, dynamic> _userData = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    String? storedUsername = prefs.getString('username');

    if (_userId == null) {
      // Handle case where user ID is not found (shouldn't happen if logged in)
      setState(() {
        _username = 'Error';
        _phoneNumber = 'Error';
        _isLoading = false;
      });
      return;
    }

    // Use stored username immediately while fetching other data
    setState(() {
      _username = storedUsername ?? 'User';
      _isLoading = true; // Still loading phone and image
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/backend_new/profile.php?user_id=$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _userData = data; // Store all fetched data
            _username =
                _userData['username'] ??
                'User'; // Update username from fetched data
            _phoneNumber = _userData['phone'] ?? 'N/A';
            _profileImageUrl =
                _userData['profile_image_url']; // Assuming backend provides this field
          });
        } else {
          // Handle error fetching profile data
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to load profile data'),
              ),
            );
          }
          setState(() {
            _phoneNumber = 'Error';
          });
        }
      } else {
        // Handle HTTP error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load profile data: Server error'),
            ),
          );
        }
        setState(() {
          _phoneNumber = 'Error';
        });
      }
    } catch (e) {
      // Handle network or other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile data: $e')),
        );
      }
      setState(() {
        _phoneNumber = 'Error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // TODO: Implement image upload to backend here
      _uploadImage(_selectedImage!); // Call upload function
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    var uri = Uri.parse('http://10.0.2.2/backend_new/profile.php');
    var request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = _userId.toString();

    // Attach the image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image', // This should match the name in your backend ($_FILES['profile_image'])
        imageFile.path,
      ),
    );

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        // Read the response
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        if (data['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully'),
              ),
            );
            // Update the displayed image if the backend returned a new URL
            if (data['profile_image_url'] != null) {
              setState(() {
                _profileImageUrl = data['profile_image_url'];
                _selectedImage =
                    null; // Clear selected image after successful upload
              });
            } else {
              // If backend didn't return URL but reported success, maybe refetch data?
              _loadUserData(); // Or handle accordingly
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message'] ?? 'Failed to update profile image',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image: Server error'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    await prefs.remove('username'); // Clear saved username too

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  // Circle Avatar and Username Section
                  Align(
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: _pickImage, // Call _pickImage on tap
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue[100], // Placeholder color
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(
                                  _selectedImage!,
                                ) // Use FileImage for selected image
                                : (_profileImageUrl != null
                                    ? NetworkImage(
                                      'http://10.0.2.2/backend_new/' +
                                          _profileImageUrl!,
                                    )
                                    : null), // Use NetworkImage for fetched URL
                        child:
                            _selectedImage == null && _profileImageUrl == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blue[700],
                                ) // Placeholder icon
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditProfileScreen(
                                      user: _userData,
                                    ), // Pass fetched user data
                              ),
                            );
                            // If result is true, refresh profile data
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Contact Information Card
                  Card(
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Phone'),
                            subtitle: Text(_userData['phone'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Email'),
                            subtitle: Text(_userData['email'] ?? 'N/A'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal Details Card
                  Card(
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Personal Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Address'),
                            subtitle: Text(_userData['address'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Gender'),
                            subtitle: Text(_userData['gender'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.location_city),
                            title: const Text('City'),
                            subtitle: Text(_userData['city'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.map),
                            title: const Text('State'),
                            subtitle: Text(_userData['state'] ?? 'N/A'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Date of Birth'),
                            subtitle: Text(
                              _userData['date_of_birth'] != null
                                  ? DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(_userData['date_of_birth']),
                                  )
                                  : 'N/A',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
    );
  }
}
