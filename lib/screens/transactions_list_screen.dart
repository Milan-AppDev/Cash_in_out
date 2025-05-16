import 'package:flutter/material.dart';
import 'transaction.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<Transaction> transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Icon(
                          _getTransactionTypeIcon(transaction.type),
                          color: _getTransactionTypeColor(transaction.type),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transaction #${transaction.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Amount: ₹${transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${transaction.transactionDate.toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (transaction.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${transaction.notes}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        // TODO: Navigate to transaction details
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add transaction screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.adjustment:
        return Icons.tune;
      case TransactionType.cancellation:
        return Icons.cancel;
    }
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Colors.green;
      case TransactionType.refund:
        return Colors.orange;
      case TransactionType.adjustment:
        return Colors.blue;
      case TransactionType.cancellation:
        return Colors.red;
    }
  }
} 