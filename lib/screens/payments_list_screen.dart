import 'package:cash_in_out/screens/add_payment.dart';
import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/client.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentsListPage extends StatefulWidget {
  const PaymentsListPage({super.key});

  @override
  State<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<PaymentsListPage> {
  List<Payment> payments = [];
  Future<void> fetchPayments() async {
    final ip = '192.168.160.251';
    final response = await http.get(
      Uri.parse('http://$ip/backend/payments.php'),
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            payments = List<Payment>.from(
              data['data'].map((p) => Payment.fromJson(p)),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch payments')),
          );
        }
      } catch (e) {
        print('JSON parse error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data format error')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to fetch payments')));
    }
  }

  Future<List<Client>> fetchClients() async {
    final ip = '192.168.160.251';
    final response = await http.get(
      Uri.parse('http://$ip/backend/clients.php'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return List<Client>.from(data['data'].map((c) => Client.fromJson(c)));
      }
    }
    return [];
  }

  void navigateToAddPayment() async {
    final clients = await fetchClients();

    if (clients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No clients available')));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPaymentPage(clients: clients)),
    );

    if (result == true) {
      fetchPayments();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments List')),
      body:
          payments.isEmpty
              ? const Center(child: Text('No payments found'))
              : ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('₹${p.amount.toStringAsFixed(2)}'),
                      subtitle: Text('${p.tag} - ${p.note}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.status,
                            style: TextStyle(
                              color:
                                  p.status == 'sent'
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                          Text(
                            p.timestamp.toLocal().toString().split('.')[0],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddPayment,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
