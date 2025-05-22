import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  final PaymentService paymentService;

  const TransactionsScreen({Key? key, required this.paymentService})
    : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = widget.paymentService.getAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading transactions: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          } else {
            final transactions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final bool isCashIn = transaction.amount >= 0;
                final String date =
                    transaction.transactionDate.toLocal().toString().split(
                      ' ',
                    )[0]; // Format as YYYY-MM-DD

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      isCashIn
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                  child: Icon(
                                    isCashIn
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isCashIn ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCashIn ? 'Cash In' : 'Cash Out',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: #${transaction.id}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (isCashIn ? '+' : '-') +
                                      '₹${transaction.amount.abs()}',
                                  style: TextStyle(
                                    color: isCashIn ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
