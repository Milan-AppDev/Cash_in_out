class Client {
  final int? id; // Optional, if your backend sends an ID
  final String name;
  final String phone;
  final String address;

  Client({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  // Factory constructor to create a Client from JSON map
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'], // make sure your backend JSON contains 'id'
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  // Method to convert Client object to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
