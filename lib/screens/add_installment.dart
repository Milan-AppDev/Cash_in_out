// 📁 lib/screens/add_installment_plan.dart
import 'package:flutter/material.dart';
import '../models/client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AddInstallmentPlanPage extends StatefulWidget {
  final List<Client> clients;

  const AddInstallmentPlanPage({super.key, required this.clients});

  @override
  State<AddInstallmentPlanPage> createState() => _AddInstallmentPlanPageState();
}

class _AddInstallmentPlanPageState extends State<AddInstallmentPlanPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedClientId;
  double _amount = 0.0;
  int _months = 1;
  DateTime _startDate = DateTime.now();

  Future<void> _submitInstallmentPlan() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final body = json.encode({
      'client_id': _selectedClientId,
      'amount': _amount,
      'months': _months,
      'start_date': _startDate.toIso8601String().split('T')[0],
    });

    final response = await http.post(
      Uri.parse('http://$ip/backend/installments.php'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = json.decode(response.body);
    if (data['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to create plan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Installment Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Client'),
                items: widget.clients.map((client) {
                  return DropdownMenuItem<int>(
                    value: client.id,
                    child: Text(client.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedClientId = val),
                validator: (val) => val == null ? 'Please select client' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Total Amount'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || double.tryParse(val) == null || double.parse(val) <= 0
                        ? 'Enter valid amount'
                        : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of Months',
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (val) =>
                    val == null || int.tryParse(val) == null || int.parse(val) <= 0
                        ? 'Enter valid month count'
                        : null,
                onSaved: (val) => _months = int.parse(val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Start Date: ${_startDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitInstallmentPlan,
                child: const Text('Create Installment Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
