class Client {
  final int id;
  final String name;
  final String phone;
  final String address;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
    );
  }
} 