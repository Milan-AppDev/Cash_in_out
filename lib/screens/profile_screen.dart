import 'package:cash/model/user_profile_model.dart';
import 'package:cash/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
 // Import the EditProfileScreen
import 'package:intl/intl.dart'; // For date formatting

class ProfileScreen extends StatefulWidget {
  final String userId; // Pass the user ID, e.g., from login

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile; // Make it nullable
  bool _isLoading = true;
  String? _errorMessage;

  // IMPORTANT: Replace with your actual API URL
  // For Android Emulator, use 10.0.2.2 to access localhost on your computer.
  // For a physical Android device, use your computer's actual local IP address (e.g., http://192.168.1.10/api).
  // For iOS Simulator/device, 'http://localhost' often works if your server is on the same machine.
  static const String _apiBaseUrl = 'http://localhost/api';
  // Consider using HTTPS in production!

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetches user profile data from the backend
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous error message
    });

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get_user_profile.php?user_id=${widget.userId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Add Authorization header with JWT token if using authentication
          // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (mounted) { // Check if the widget is still in the tree
          if (responseData['success']) {
            setState(() {
              _userProfile = UserProfile.fromJson(responseData['profile']);
            });
          } else {
            setState(() {
              _errorMessage = responseData['message'] ?? 'Failed to load profile.';
              _userProfile = null; // Clear profile on failure
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error loading profile: ${response.statusCode}. Please try again.';
            _userProfile = null; // Clear profile on server error
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error fetching profile: $e. Is the server running?';
          _userProfile = null; // Clear profile on network error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_userProfile != null) {
      final UserProfile? updatedProfile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            userProfile: _userProfile!, // Pass the current profile data
          ),
        ),
      );

      if (updatedProfile != null) {
        // If the edit screen returned an updated profile, refresh the current screen's state
        setState(() {
          _userProfile = updatedProfile;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit profile: Profile data not loaded.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Light background
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Color(0xFF333333), fontSize: 20)),
        backgroundColor: const Color(0xFFF0F0F0),
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 24, color: Color(0xFFFF7043)),
            onPressed: _isLoading ? null : _navigateToEditProfile, // Disable if loading
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7043)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 70, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchUserProfile, // Allow retrying fetch
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7043),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _userProfile == null // Fallback if no error message but profile is null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Profile data not available.', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchUserProfile, // Allow retrying fetch
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7043),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Load Profile'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator( // Added RefreshIndicator for pull-to-refresh
                      onRefresh: _fetchUserProfile,
                      color: const Color(0xFFFF7043),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if content is small
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Profile Photo and Name Section
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFFFF7043).withOpacity(0.2), // Light accent color
                                    child: Text(
                                      _userProfile!.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF7043), // Accent color
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _userProfile!.name,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 24, color: Color(0xFF666666)),
                                        onPressed: _navigateToEditProfile, // Call the navigation method
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Contact Information Card
                            _buildInfoCard(
                              title: 'Contact Information',
                              icon: Icons.contact_phone,
                              children: [
                                _buildInfoRow(Icons.phone, _userProfile!.mobileNumber),
                                _buildInfoRow(Icons.email, _userProfile!.email),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Address Information Card (Optional, only if address exists)
                            if ((_userProfile!.address != null && _userProfile!.address!.isNotEmpty) ||
                                (_userProfile!.city != null && _userProfile!.city!.isNotEmpty) ||
                                (_userProfile!.state != null && _userProfile!.state!.isNotEmpty))
                              _buildInfoCard(
                                title: 'Address',
                                icon: Icons.location_on,
                                children: [
                                  _buildInfoRow(Icons.place, '${_userProfile!.address ?? ''}${_userProfile!.city != null && _userProfile!.city!.isNotEmpty ? ', ${_userProfile!.city}' : ''}${_userProfile!.state != null && _userProfile!.state!.isNotEmpty ? ', ${_userProfile!.state}' : ''}'),
                                ],
                              ),
                            if ((_userProfile!.address != null && _userProfile!.address!.isNotEmpty) ||
                                (_userProfile!.city != null && _userProfile!.city!.isNotEmpty) ||
                                (_userProfile!.state != null && _userProfile!.state!.isNotEmpty))
                              const SizedBox(height: 20),

                            // Other Details Card (Gender, DOB)
                            if (_userProfile!.gender != null || _userProfile!.dateOfBirth != null)
                              _buildInfoCard(
                                title: 'Other Details',
                                icon: Icons.info_outline,
                                children: [
                                  if (_userProfile!.gender != null && _userProfile!.gender!.isNotEmpty)
                                    _buildInfoRow(Icons.wc, 'Gender: ${_userProfile!.gender}'),
                                  if (_userProfile!.dateOfBirth != null)
                                    _buildInfoRow(Icons.cake, 'D.O.B: ${
                                      _userProfile!.dateOfBirth != null
                                          ? DateFormat('dd MMMӮ').format(_userProfile!.dateOfBirth!)
                                          : ''
                                    }'),
                                ],
                              ),
                            const SizedBox(height: 20),


                            // Privacy Policy
                            _buildMenuItem(
                              icon: Icons.lock_outline,
                              title: 'Privacy Policy',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Privacy Policy page coming soon!')),
                                );
                              },
                            ),
                            const SizedBox(height: 10),

                            // Help & Support
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Help & Support page coming soon!')),
                                );
                              },
                            ),
                            const SizedBox(height: 10),

                            // About Us
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              title: 'About Us',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('About Us page coming soon!')),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  // Helper to build information cards
  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF7043), size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Color(0xFFF0F0F0)),
            ...children, // Spread operator to add list of widgets
          ],
        ),
      ),
    );
  }

  // Helper to build a single info row with icon and text
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build menu items like Privacy Policy, Help, About
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF424242), size: 24), // Dark grey icon
        title: Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
        onTap: onTap,
      ),
    );
  }
}
