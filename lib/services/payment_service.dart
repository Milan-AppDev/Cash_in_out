import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/transaction.dart';

class PaymentService {
  final String baseUrl; // Your API base URL

  PaymentService({required this.baseUrl});

  // Create a new payment
  Future<bool> createPayment(Payment payment) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_payment.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payment.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  // Get all payments for a user
  Future<List<Payment>> getPayments(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_payments.php?user_id=$userId"),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        final List<dynamic> paymentsJson = data['payments'];
        return paymentsJson.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load payments');
      }
    } catch (e) {
      throw Exception('Error loading payments: $e');
    }
  }

  // Edit a payment
  Future<bool> editPayment(Payment payment) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/edit_payment.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payment.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to edit payment');
      }
    } catch (e) {
      throw Exception('Error editing payment: $e');
    }
  }

  // Delete a payment
  Future<bool> deletePayment(int paymentId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_payment.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payment_id': paymentId}),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete payment');
      }
    } catch (e) {
      throw Exception('Error deleting payment: $e');
    }
  }

  // Get all transactions (for admin or all users)
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_all_transactions.php"),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        final List<dynamic> transactionsJson = data['transactions'];
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Error loading transactions: $e');
    }
  }
}
