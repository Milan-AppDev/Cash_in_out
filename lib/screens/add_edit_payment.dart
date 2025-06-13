import 'package:cash_in_out/screens/payments_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/client.dart';
import '../screens/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEditPaymentPage extends StatefulWidget {
  final List<Client> clients;
  final Payment? payment;

  const AddEditPaymentPage({super.key, required this.clients, this.payment});

  @override
  State<AddEditPaymentPage> createState() => _AddEditPaymentPageState();
}

class _AddEditPaymentPageState extends State<AddEditPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  late Client selectedClient;
  late TextEditingController _totalAmountController;
  late TextEditingController _paidAmountController;
  late TextEditingController _descriptionController;
  DateTime? _createdDate;
  DateTime? _dueDate;
  PaymentStatus _status = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    _totalAmountController = TextEditingController();
    _paidAmountController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.payment != null) {
      selectedClient = widget.clients.firstWhere(
        (c) => c.id.toString() == widget.payment!.clientId,
        orElse: () => widget.clients.first,
      );
      _totalAmountController.text = widget.payment!.totalAmount.toString();
      _paidAmountController.text = widget.payment!.paidAmount.toString();
      _descriptionController.text = widget.payment!.description;
      _createdDate = widget.payment!.createdDate;
      _dueDate = widget.payment!.dueDate;
      _status = widget.payment!.status;
    } else {
      selectedClient = widget.clients.first;
      _createdDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  Future<void> savePayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator if needed
        setState(() {});

        final payment = Payment(
          id: widget.payment?.id ?? '',
          clientId: selectedClient.id.toString(),
          clientName: selectedClient.name,
          totalAmount: double.parse(_totalAmountController.text),
          paidAmount:
              _paidAmountController.text.isEmpty
                  ? 0.0
                  : double.parse(_paidAmountController.text),
          createdDate: _createdDate!,
          dueDate: _dueDate!,
          description: _descriptionController.text,
          status: _status,
        );

        final response = await http.post(
          Uri.parse(AppConfig.paymentsEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payment.toJson()),
        );

        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            payment.id = data['id'].toString();

            print("Navigation attempting...");

            // Use a slight delay before navigation
            await Future.delayed(Duration(milliseconds: 100));

            // Don't display SnackBar before navigation
            if (mounted) {
              // Check if widget is still mounted
              print("Widget is mounted, navigating...");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Payment saved successfully"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => PaymentsListScreen()),
                (route) => false,
              );
            }
          } else {
            _showError(data['message'] ?? "Unknown error");
          }
        } else {
          _showError("Failed to save payment.");
        }
      } catch (e) {
        print("Error during save or navigation: $e");
        _showError("Error: $e");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _pickDate(BuildContext context, bool isDueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate! : _createdDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _createdDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment == null ? 'Add Payment' : 'Edit Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Client>(
                value: selectedClient,
                onChanged: (val) => setState(() => selectedClient = val!),
                items:
                    widget.clients.map((client) {
                      return DropdownMenuItem<Client>(
                        value: client,
                        child: Text(client.name),
                      );
                    }).toList(),
                decoration: const InputDecoration(labelText: 'Client'),
              ),
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Paid Amount'),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return null;
                  }

                  try {
                    double value = double.parse(val);
                    if (value < 0) {
                      return 'Amount cannot be negative';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }

                  return null;
                },
              ),
              ListTile(
                title: Text('Created Date: ${format.format(_createdDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, false),
              ),
              ListTile(
                title: Text('Due Date: ${format.format(_dueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, true),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<PaymentStatus>(
                value: _status,
                onChanged: (val) => setState(() => _status = val!),
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    PaymentStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: savePayment, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
