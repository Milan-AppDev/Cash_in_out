import 'package:flutter/material.dart';
import '../models/client.dart';
import 'payment.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  List<Payment> payments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body:
          payments.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No payments yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        'Payment #${payment.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Amount: ₹${payment.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due Date: ${payment.dueDate.toString().split(' ')[0]}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment.status.toString().split('.').last,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          // Navigate to payment details
                        },
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add payment screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partiallyPaid:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }
}
