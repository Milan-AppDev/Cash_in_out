import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/payment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

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
  String _status = 'sent';
  bool _isInstallment = false;
  int? _selectedInstallmentId;
  List<Map<String, dynamic>> _pendingInstallments = [];

  Future<void> fetchPendingInstallments(int clientId) async {
    final response = await http.get(
      Uri.parse(
        'http://$ip/backend/installments.php?type=pending&client_id=$clientId',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _pendingInstallments = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    }
  }

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
      installmentId: _isInstallment ? _selectedInstallmentId : null,
    );

    final response = await http.post(
      Uri.parse('http://$ip/backend/payments.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newPayment.toJson()),
    );

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
                onChanged: (val) {
                  setState(() {
                    _selectedClientId = val;
                    _selectedInstallmentId = null;
                    _pendingInstallments.clear();
                  });
                  if (_isInstallment && val != null) {
                    fetchPendingInstallments(val);
                  }
                },
                validator:
                    (val) => val == null ? 'Please select a client' : null,
              ),

              CheckboxListTile(
                title: const Text("Is this an installment payment?"),
                value: _isInstallment,
                onChanged: (val) {
                  if (_selectedClientId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select client first'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isInstallment = val!;
                    _selectedInstallmentId = null;
                    if (val) {
                      fetchPendingInstallments(_selectedClientId!);
                    }
                  });
                },
              ),

              if (_isInstallment && _pendingInstallments.isNotEmpty)
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Pending Month',
                  ),
                  items:
                      _pendingInstallments.map((item) {
                        return DropdownMenuItem<int>(
                          value: int.parse(item['id'].toString()),
                          child: Text(
                            '${item['month_year']} - ₹${item['amount']}',
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    final selected = _pendingInstallments.firstWhere(
                      (element) => int.parse(element['id'].toString()) == val,
                    );
                    setState(() {
                      _selectedInstallmentId = val;
                      _amount = double.parse(selected['amount'].toString());
                    });
                  },
                  validator:
                      (val) =>
                          _isInstallment && val == null
                              ? 'Select a pending installment'
                              : null,
                ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                keyboardType: TextInputType.number,
                enabled: !_isInstallment,
                onChanged: (val) {
                  if (!_isInstallment) {
                    _amount = double.tryParse(val) ?? 0.0;
                  }
                },
                validator: (val) {
                  if (_isInstallment) return null;
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final num? parsed = num.tryParse(val);
                  if (parsed == null || parsed <= 0)
                    return 'Enter a valid amount';
                  return null;
                },
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Tag'),
                onSaved: (val) => _tag = val ?? '',
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Enter a tag'
                            : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note'),
                onSaved: (val) => _note = val ?? '',
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Enter a note'
                            : null,
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
