import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/installment.dart';

class PaymentEntryScreen extends StatefulWidget {
  final String baseUrl;
  final int clientId;

  const PaymentEntryScreen({
    Key? key,
    required this.baseUrl,
    required this.clientId,
  }) : super(key: key);

  @override
  _PaymentEntryScreenState createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  List<Installment> _installments = [];

  @override
  void dispose() {
    _totalAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addInstallment() {
    setState(() {
      _installments.add(
        Installment(
          id: UniqueKey().toString(),
          paymentId: '',
          amount: 0,
          dueDate: DateTime.now(),
          status: InstallmentStatus.pending,
        ),
      );
    });
  }

  void _removeInstallment(int index) {
    setState(() {
      _installments.removeAt(index);
    });
  }

  double get _totalInstallmentAmount {
    return _installments.fold(0, (sum, item) => sum + item.amount);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a due date')));
      return;
    }
    if (_installments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one installment')),
      );
      return;
    }
    if (_totalInstallmentAmount !=
        double.tryParse(_totalAmountController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Installment amounts must sum to total amount')),
      );
      return;
    }

    final payment = Payment(
      id: '',
      clientId: widget.clientId.toString(),
      totalAmount: double.parse(_totalAmountController.text),
      paidAmount: 0,
      createdDate: DateTime.now(),
      dueDate: _dueDate!,
      description: _descriptionController.text,
      status: PaymentStatus.pending,
      installments: _installments,
    );

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/add_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payment.toJson()),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment added successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add payment: \${data["message"]}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Total Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter total amount';
                  if (double.tryParse(value) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due Date: \${_dueDate!.toLocal().toString().split('
                          ')[0]}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDueDate(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Installments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ..._installments.asMap().entries.map((entry) {
                int index = entry.key;
                Installment installment = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: installment.amount.toString(),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(labelText: 'Amount'),
                          onChanged: (val) {
                            setState(() {
                              _installments[index] = installment.copyWith(
                                amount: double.tryParse(val) ?? 0,
                              );
                            });
                          },
                        ),
                        ListTile(
                          title: Text(
                            'Due Date: \${installment.dueDate.toLocal().toString().split('
                            ')[0]}',
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: installment.dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                _installments[index] = installment.copyWith(
                                  dueDate: picked,
                                );
                              });
                            }
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeInstallment(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addInstallment,
                child: Text('Add Installment'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPayment,
                child: Text('Submit Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
