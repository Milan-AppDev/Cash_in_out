import 'package:flutter/material.dart';
import '../models/client.dart';
import 'add_installment.dart';
import 'monthly_installments.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class InstallmentsListScreen extends StatefulWidget {
  const InstallmentsListScreen({super.key});

  @override
  State<InstallmentsListScreen> createState() => _InstallmentsListScreenState();
}

class _InstallmentsListScreenState extends State<InstallmentsListScreen> {
  List installments = [];
  Map<int, String> clientNames = {};

  @override
  void initState() {
    super.initState();
    fetchClients(); // First get client names
    fetchInstallments(); // Then get installment data
  }

  Future<void> fetchInstallments() async {
    final response = await http.get(
      Uri.parse('http://$ip/backend/installments.php?type=plans'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          installments = data['data'];
        });
      }
    }
  }

  Future<void> fetchClients() async {
    final response = await http.get(
      Uri.parse('http://$ip/backend/clients.php'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        final clients = List<Client>.from(
          data['data'].map((c) => Client.fromJson(c)),
        );
        setState(() {
          clientNames = {for (var client in clients) client.id!: client.name};
        });
      }
    }
  }

  void _navigateToAddInstallment() async {
    final response = await http.get(
      Uri.parse('http://$ip/backend/clients.php'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        final clients = List<Client>.from(
          data['data'].map((c) => Client.fromJson(c)),
        );
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddInstallmentPlanPage(clients: clients),
          ),
        );

        if (result == true) {
          fetchInstallments();
        }
      } else {
        showError("Failed to load clients");
      }
    } else {
      showError("Failed to connect to server");
    }
  }

  void _openMonthlyInstallments(int planId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonthlyInstallmentsPage(planId: planId),
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installments')),
      body:
          installments.isEmpty
              ? const Center(child: Text('No Installment Plans Found'))
              : ListView.builder(
                itemCount: installments.length,
                itemBuilder: (context, index) {
                  final i = installments[index];
                  final clientId = i['client_id'];
                  final clientName =
                      clientNames[clientId] ?? 'Client #$clientId';

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      onTap: () => _openMonthlyInstallments(i['id']),
                      title: Text('Client: $clientName'),
                      subtitle: Text(
                        'Total: ₹${i['total_amount']}, Months: ${i['months']}, Start: ${i['start_date']}',
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddInstallment,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
