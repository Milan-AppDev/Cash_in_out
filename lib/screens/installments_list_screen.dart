// 📁 lib/screens/installments_list_screen.dart
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

  @override
  void initState() {
    super.initState();
    fetchInstallments();
  }

  Future<void> fetchInstallments() async {
    final response = await http.get(
      Uri.parse('http://$ip/backend/installments.php?type=plans&client_id=2'),
    );
    print('Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          installments = data['data'];
        });
      }
    }
  }

  Future<List<Client>> fetchClients() async {
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

  void _navigateToAddInstallment() async {
    final clients = await fetchClients();
    if (clients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No clients available")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInstallmentPlanPage(clients: clients),
      ),
    );

    if (result == true) {
      fetchInstallments();
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
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      onTap: () => _openMonthlyInstallments(i['id']),
                      title: Text('Client ID: ${i['client_id']}'),
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
