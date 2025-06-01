import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ClientManagementScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const ClientManagementScreen({super.key, required this.client});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  double _totalGot = 0;
  double _totalGiven = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final ip = '10.0.2.2';
      final response = await http.get(
        Uri.parse(
          'http://$ip/backend/transactions.php?client_id=${widget.client['id']}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(
              data['transactions'],
            );
            _calculateTotals();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _totalGot = 0;
    _totalGiven = 0;
    for (var transaction in _transactions) {
      if (transaction['type'] == 'got') {
        _totalGot += double.parse(transaction['amount'].toString());
      } else {
        _totalGiven += double.parse(transaction['amount'].toString());
      }
    }
  }

  Future<void> _addTransaction(String type) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final ip = '10.0.2.2';
        final response = await http.post(
          Uri.parse('http://$ip/backend/transactions.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'client_id': widget.client['id'],
            'amount': double.parse(_amountController.text),
            'description': _descriptionController.text,
            'type': type,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            _amountController.clear();
            _descriptionController.clear();
            await _fetchTransactions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction added successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to add transaction'),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddTransactionDialog(String type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              type == 'got' ? 'Add Money Received' : 'Add Money Given',
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addTransaction(type);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalGot - _totalGiven;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client['name']),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () {})],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.teal,
                    child: Column(
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBalanceCard(
                              'You Got',
                              currencyFormat.format(_totalGot),
                              Colors.green,
                            ),
                            _buildBalanceCard(
                              'You Gave',
                              currencyFormat.format(_totalGiven),
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final isGot = transaction['type'] == 'got';
                        final amount = double.parse(
                          transaction['amount'].toString(),
                        );
                        final date = DateTime.parse(transaction['date']);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isGot ? Colors.green : Colors.red,
                              child: Icon(
                                isGot
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(transaction['description']),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy').format(date),
                            ),
                            trailing: Text(
                              '${isGot ? '+' : '-'}${currencyFormat.format(amount)}',
                              style: TextStyle(
                                color: isGot ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 26),
          TextButton(
            onPressed: () => _showAddTransactionDialog('got'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 44),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => _showAddTransactionDialog('give'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 44),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.remove, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
