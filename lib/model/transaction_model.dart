
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'got' or 'given'
  final String category; // Added category

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  // Factory constructor to create a Transaction from a JSON map (from PHP API)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(), // Ensure ID is string
      description: json['description'] ?? '', // Handle null description
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['transaction_date']), // Parse date string
      type: json['type'],
      category: json['category'] ?? 'Other', // Handle null category
    );
  }

  // Helper for display formatting (optional, but convenient)
  String get formattedDate => DateFormat('dd MMM yy - hh:mm a').format(date);
}
