import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/client.dart';
import '../screens/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_edit_payment.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({Key? key}) : super(key: key);

  @override
  _PaymentsListScreenState createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  List<Payment> payments = [];
  List<Client> clients = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load both clients and payments
    await fetchClients();
    await fetchPaymentsFromBackend();
  }

  Future<void> fetchClients() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(AppConfig.clientsEndpoint));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            clients = List<Client>.from(
              data['data'].map((c) => Client.fromJson(c)),
            );
          });
        } else {
          _showError(data['message'] ?? 'Failed to load clients');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception when loading clients: $e');
      _showError('Error loading clients: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPaymentsFromBackend() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Make GET request to the payments endpoint
      final response = await http.get(
        Uri.parse(AppConfig.paymentsEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          // Convert JSON data to Payment objects
          final List<dynamic> paymentData = jsonData['data'];
          
          setState(() {
            payments = paymentData.map((json) => Payment.fromJson(json)).toList();
            isLoading = false;
          });
        } else {
          _showError(jsonData['message'] ?? 'Failed to load payments');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception when loading payments: $e');
      _showError('Error loading payments: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.paymentsEndpoint}?id=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh payments list after deletion
          fetchPaymentsFromBackend();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError(data['message'] ?? 'Failed to delete payment');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting payment: $e');
    }
  }

  void navigateToAddPayment() async {
    if (clients.isEmpty) {
      _showError('Please add clients first before creating payments');
      return;
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPaymentPage(
          clients: clients,
        ),
      ),
    );
    
    // Refresh data when returning from add screen
    fetchPaymentsFromBackend();
  }

  void navigateToEditPayment(int index) async {
    final payment = payments[index];
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPaymentPage(
          payment: payment,
          clients: clients,
        ),
      ),
    );
    
    // Refresh data when returning from edit screen
    fetchPaymentsFromBackend();
  }

  // Helper method to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String getStatusText(PaymentStatus status) {
    return status.toString().split('.').last;
  }

  Color getStatusColor(PaymentStatus status) {
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
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPaymentsFromBackend,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? Center(
                  child: Text(
                    'No payments found.\nTap + to add a new payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPaymentsFromBackend,
                  child: ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  payment.clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(payment.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  getStatusText(payment.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total: ${currencyFormat.format(payment.totalAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Paid: ${currencyFormat.format(payment.paidAmount)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Created: ${dateFormat.format(payment.createdDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Due: ${dateFormat.format(payment.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DateTime.now().isAfter(payment.dueDate) &&
                                              payment.status != PaymentStatus.completed
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (payment.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  payment.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') {
                                navigateToEditPayment(index);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Payment'),
                                    content: const Text(
                                      'Are you sure you want to delete this payment?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deletePayment(payment.id);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          navigateToAddPayment();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
