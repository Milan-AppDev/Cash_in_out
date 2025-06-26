// 📁 lib/screens/monthly_installments.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class MonthlyInstallmentsPage extends StatefulWidget {
  final int planId;

  const MonthlyInstallmentsPage({super.key, required this.planId});

  @override
  State<MonthlyInstallmentsPage> createState() =>
      _MonthlyInstallmentsPageState();
}

class _MonthlyInstallmentsPageState extends State<MonthlyInstallmentsPage> {
  List installments = [];

  @override
  void initState() {
    super.initState();
    fetchMonthlyInstallments();
  }

  Future<void> fetchMonthlyInstallments() async {
    final response = await http.get(
      Uri.parse(
        // ✅ Correct:
        'http://$ip/backend/installments.php?type=installments&plan_id=${widget.planId}',
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Installments')),
      body:
          installments.isEmpty
              ? const Center(child: Text('No installments found'))
              : ListView.builder(
                itemCount: installments.length,
                itemBuilder: (context, index) {
                  final item = installments[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Month: ${item['month_year']}'),
                      subtitle: Text('Amount: ₹${item['amount']}'),
                      trailing: Text(item['status']),
                    ),
                  );
                },
              ),
    );
  }
}
