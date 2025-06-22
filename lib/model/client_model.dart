// lib/models/client_model.dart
class Client {
  final String id;
  final String name;
  final String mobileNumber;
  final double amount; // Positive for 'You Will Get', negative for 'You Will Give'
  final String lastTransactionDate;

  Client({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.amount,
    required this.lastTransactionDate,
  });

  // Factory constructor to create a Client object from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'].toString(),
      name: json['name'] as String,
      mobileNumber: json['mobile_number'] as String,
      amount: double.parse(json['amount'].toString()),
      lastTransactionDate: json['last_transaction_date'] as String,
    );
  }
}
