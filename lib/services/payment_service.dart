import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/installment.dart';
import '../models/transaction.dart';

class PaymentService {
  final String baseUrl; // Your API base URL
  
  PaymentService({required this.baseUrl});

  // Create a new payment
  Future<Payment> createPayment(Payment payment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payment.toJson()),
      );

      if (response.statusCode == 201) {
        return Payment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  // Get all payments
  Future<List<Payment>> getPayments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payments'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      throw Exception('Error loading payments: $e');
    }
  }

  // Get payment by ID
  Future<Payment> getPaymentById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payments/$id'));

      if (response.statusCode == 200) {
        return Payment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load payment');
      }
    } catch (e) {
      throw Exception('Error loading payment: $e');
    }
  }

  // Add installment to payment
  Future<Installment> addInstallment(Installment installment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/installments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(installment.toJson()),
      );

      if (response.statusCode == 201) {
        return Installment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add installment');
      }
    } catch (e) {
      throw Exception('Error adding installment: $e');
    }
  }

  // Record a transaction
  Future<Transaction> recordTransaction(Transaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction.toJson()),
      );

      if (response.statusCode == 201) {
        return Transaction.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to record transaction');
      }
    } catch (e) {
      throw Exception('Error recording transaction: $e');
    }
  }

  // Get transactions by payment ID
  Future<List<Transaction>> getTransactionsByPaymentId(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/payment/$paymentId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Error loading transactions: $e');
    }
  }

  // Update payment status
  Future<Payment> updatePaymentStatus(
    String paymentId, 
    PaymentStatus status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/payments/$paymentId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status.toString()}),
      );

      if (response.statusCode == 200) {
        return Payment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }
} 