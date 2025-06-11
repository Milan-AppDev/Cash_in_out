import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cash_in_out/screens/edit_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isGot = transaction['type'] == 'got';
    final amount = double.parse(transaction['amount'].toString());
    final date = DateTime.parse(transaction['date']);
    final formattedDate = DateFormat('dd MMM yy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    final description = transaction['description']?.toString();
    final clientName = transaction['client_name']?.toString() ?? 'Unknown Client';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        iconTheme: const IconThemeData(color: Colors.white), // White back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Name and Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isGot ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate • $formattedTime',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Divider(height: 24),

                // Details
                const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description != null && description.isNotEmpty
                      ? description
                      : 'No description provided.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const Divider(height: 24),

                // Edit Transaction Button
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.cyan),
                  title: const Text(
                    'Edit Transaction',
                    style: TextStyle(color: Colors.cyan),
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTransactionScreen(
                          transaction: transaction,
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        // Re-fetch transaction details if needed, or simply update state
                        // For now, let's assume the passed 'transaction' map is sufficient
                        // to display updated details without another backend call
                        // if the update on EditTransactionScreen modifies the map directly.
                        // If not, a re-fetch would be necessary here.
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 