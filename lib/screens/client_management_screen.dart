import 'package:cash_in_out/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_in_out/screens/client_report_screen.dart';
import '../utils/backend_config.dart';

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
        Uri.parse('${BackendConfig.baseUrl}/transactions.php?client_id=${widget.client['id']}&user_id=$userId'),
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
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/delete_transaction.php'),
        body: { 'transaction_id': transactionId.toString() },
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
        Uri.parse('${BackendConfig.baseUrl}/clients.php'),
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
        centerTitle: false,
        title: Text(widget.client['name']),
        actions: [
          IconButton(
            icon: Icon(
              _isEditingClient ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
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
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _updateClient,
            ),
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
                      color: Colors.blue[900],
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
                          const SizedBox(height: 10),
                          // Action buttons row
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.receipt_long,
                                      label: 'Report',
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ClientReportScreen(
                                                  clientId: widget.client['id'],
                                                  clientName:
                                                      widget.client['name'],
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.radar_sharp,
                                      label: 'WhatsApp',
                                      color: Colors.green,
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'WhatsApp sharing coming soon',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.sms,
                                      label: 'SMS',
                                      color: Colors.orange,
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'SMS feature coming soon',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return _buildTransactionItem(transaction);
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 28),
          TextButton(
            // heroTag: 'got',
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

            child: Card(
              color: Colors.green,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white),
                    const Text(
                      '  You Got',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            // heroTag: 'given',
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

            child: Card(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.remove, color: Colors.white),
                    const Text(
                      '  You Gave',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isGot = transaction['type'] == 'got';
    final amount = double.parse(transaction['amount'].toString());
    final date = DateTime.parse(transaction['date']);
    final formattedDate = DateFormat('MMM d, y').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isGot ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isGot
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left side - Date and Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            // Right side - Amount and Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isGot ? 'You will get' : 'You will give',
                  style: TextStyle(
                    color: isGot ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isGot ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
