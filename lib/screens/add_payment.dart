import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/payment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPaymentPage extends StatefulWidget {
  final List<Client> clients;

  const AddPaymentPage({super.key, required this.clients});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedClientId;
  double _amount = 0.0;
  String _tag = '';
  String _note = '';
  String _status = 'sent'; // sent or received
  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newPayment = Payment(
      clientId: _selectedClientId!,
      amount: _amount,
      timestamp: DateTime.now(),
      tag: _tag,
      note: _note,
      status: _status,
    );

    final ip = '192.168.160.251';
    final response = await http.post(
      Uri.parse('http://$ip/backend/payments.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newPayment.toJson()),
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        Navigator.pop(context, true); // success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${jsonResponse['message'] ?? "Unknown"}'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server Error: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Client'),
                items:
                    widget.clients.map((client) {
                      return DropdownMenuItem<int>(
                        value: client.id!,
                        child: Text(client.name),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _selectedClientId = val),
                validator:
                    (val) => val == null ? 'Please select a client' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _amount = double.parse(val!),
                validator:
                    (val) => val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tag'),
                onSaved: (val) => _tag = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note'),
                onSaved: (val) => _note = val ?? '',
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                value: _status,
                onChanged: (val) => setState(() => _status = val!),
                items: const [
                  DropdownMenuItem(value: 'sent', child: Text('Sent')),
                  DropdownMenuItem(value: 'received', child: Text('Received')),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPayment,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
