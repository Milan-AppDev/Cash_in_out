import 'package:cash_in_out/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int? userId;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditingClient = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client['name']);
    _phoneController = TextEditingController(text: widget.client['phone']);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
    if (userId != null) {
      _fetchTransactions();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2/backend_new/transactions.php?client_id=${widget.client['id']}&user_id=$userId',
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
        SnackBar(content: Text('Error fetching transactions: $e')),
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

  Future<void> _deleteTransaction(int transactionId) async {
    if (userId == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2/backend_new/transactions.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': transactionId, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to delete transaction'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateClient() async {
    if (userId == null) return;

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2/backend_new/clients.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.client['id'],
          'user_id': userId,
          'name': _nameController.text,
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _isEditingClient = false;
            // Update the client data in the widget to reflect changes immediately
            widget.client['name'] = _nameController.text;
            widget.client['phone'] = _phoneController.text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to update client'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update client')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating client: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalGot - _totalGiven;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client['name']),
        actions: [
          IconButton(
            icon: Icon(_isEditingClient ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditingClient = !_isEditingClient;
              });
              // If exiting edit mode without saving, reset controllers (optional)
              if (!_isEditingClient) {
                _nameController.text = widget.client['name'];
                _phoneController.text = widget.client['phone'];
              }
            },
          ),
          if (_isEditingClient) // Show Save button only in edit mode
            IconButton(icon: const Icon(Icons.save), onPressed: _updateClient),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_isEditingClient)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          // Save button is in AppBar now
                        ],
                      ),
                    ) // Show client details when not editing
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue,
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    balance > 0
                                        ? 'You Will Get'
                                        : balance < 0
                                        ? 'You Will Give'
                                        : 'Settled Up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(balance.abs()),
                                    style: TextStyle(
                                      color:
                                          balance > 0
                                              ? Colors.green
                                              : balance < 0
                                              ? Colors.red
                                              : Colors.black,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildBalanceCard(
                                'You will get',
                                currencyFormat.format(_totalGot),
                                Colors.green,
                              ),
                              _buildBalanceCard(
                                'You will give',
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
                              DateFormat('MMM d, y h:mm a').format(date),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isGot ? '+' : '-'}${currencyFormat.format(amount)}',
                                  style: TextStyle(
                                    color: isGot ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      () =>
                                          _deleteTransaction(transaction['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'got',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddTransactionScreen(
                        clientId: widget.client['id'],
                        transactionType: 'got',
                      ),
                ),
              );
              if (result == true) {
                _fetchTransactions(); // Refresh after adding transaction
              }
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'given',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddTransactionScreen(
                        clientId: widget.client['id'],
                        transactionType: 'given',
                      ),
                ),
              );
              if (result == true) {
                _fetchTransactions(); // Refresh after adding transaction
              }
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
