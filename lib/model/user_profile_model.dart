class UserProfile {
  final String userId; // Unique ID for the user
  final String name;
  final String email;
  final String mobileNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? gender;
  final DateTime? dateOfBirth;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.mobileNumber,
    this.address,
    this.city,
    this.state,
    this.gender,
    this.dateOfBirth,
  });

  // Factory constructor to create a UserProfile from a JSON map (e.g., from an API)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'].toString(), // Ensure userId is a String
      name: json['name'] as String,
      email: json['email'] as String,
      mobileNumber: json['mobile_number'] as String,
      address: json['address'],
      city: json['city'],
      state: json['state'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] != null && json['date_of_birth'].isNotEmpty
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
    );
  }

  // Method to convert UserProfile object to a JSON map (e.g., for sending to an API)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'mobile_number': mobileNumber,
      'address': address,
      'city': city,
      'state': state,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
    };
  }

  // Method to create a new UserProfile instance with updated values
  UserProfile copyWith({
    String? name,
    String? email,
    String? mobileNumber,
    String? address,
    String? city,
    String? state,
    String? gender,
    DateTime? dateOfBirth,
  }) {
    return UserProfile(
      userId: userId, // Keep original userId
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}
