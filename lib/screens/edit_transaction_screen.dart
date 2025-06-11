import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../utils/backend_config.dart';

class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  int? userId;

  late DateTime _selectedDate; // State variable for selected date
  String? _selectedCategory; // State variable for selected category
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Salary',
    'Freelance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction['amount']?.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction['description']?.toString(),
    );
    _selectedDate = DateTime.parse(widget.transaction['date']);
    _selectedCategory = widget.transaction['category']?.toString();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateTransaction() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final response = await http.put(
          Uri.parse('${BackendConfig.baseUrl}/transactions.php'), // Assuming PUT for update
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'id': widget.transaction['id'], // Pass transaction ID for update
            'client_id': widget.transaction['client_id'],
            'user_id': userId,
            'amount': double.parse(_amountController.text),
            'description': _descriptionController.text,
            'type': widget.transaction['type'],
            'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'category': _selectedCategory,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction updated successfully'),
                ),
              );
              Navigator.pop(context, true); // Return true to indicate success
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(data['message'] ?? 'Failed to update transaction'),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update transaction')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGot = widget.transaction['type'] == 'got';
    final Color primaryColor = isGot ? Colors.green[700]! : Colors.red[700]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Edit ${isGot ? 'Money Received' : 'Money Given'}',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter Amount',
                            prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                            ),
                            labelStyle: TextStyle(color: primaryColor),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Details (Optional)',
                            prefixIcon: Icon(Icons.description, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                            ),
                            labelStyle: TextStyle(color: primaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: primaryColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                                    ),
                                    labelStyle: TextStyle(color: primaryColor),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_selectedDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category, color: primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                                  ),
                                  labelStyle: TextStyle(color: primaryColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    hint: const Text('Select Category'),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    },
                                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateTransaction, // Call update function
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text(
                          'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 