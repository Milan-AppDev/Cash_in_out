import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting and date formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cash/model/client_model.dart';
 // Import ClientDetailScreen to use its Transaction model

class AddTransactionScreen extends StatefulWidget {
  final Client client;
  final String transactionType; // 'got' or 'given'

  const AddTransactionScreen({
    super.key,
    required this.client,
    required this.transactionType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Salary',
    'Freelance',
    'Other',
  ];

  // For currency formatting (Indian Rupee)

  // IMPORTANT: Replace with your actual API URL
  static const String _apiBaseUrl = 'http://localhost/api'; // For Android Emulator

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF7043), // Accent orange for primary elements
              onPrimary: Colors.white, // White text on accent
              surface: Colors.white, // White background for date picker itself
              onSurface: Color(0xFF333333), // Dark text on surface
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7043), // Accent orange for buttons
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final double amount = double.parse(_amountController.text);
      final String details = _detailsController.text.trim();
      final String category = _selectedCategory ?? 'Other'; // Default to 'Other' if not selected

      // Prepare data for API
      final Map<String, dynamic> transactionData = {
        'client_id': widget.client.id, // Assuming client model has an ID
        'amount': amount,
        'description': details,
        'category': category,
        'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'type': widget.transactionType, // 'got' or 'given'
      };

      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/add_transaction.php'), // Your transaction API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(transactionData),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
            if (responseData['success']) {
              Navigator.pop(context, true); // Pop with true to indicate success
            }
          }
        } else {
          String errorMessage = 'Server error: ${response.statusCode}. Please try again.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect to server: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.transactionType == 'got' ? 'You Got' : 'You Gave';
    Color accentColor = widget.transactionType == 'got' ? const Color(0xFF8BC34A) : const Color(0xFFFF7043); // Green for got, Orange for gave

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Light background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F0),
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0), // Outer padding for the scroll view
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Rounded card
              color: Colors.white, // White card background
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Reduced internal padding of the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF333333)), // Dark text
                      decoration: InputDecoration(
                        labelText: 'Enter amount',
                        labelStyle: const TextStyle(color: Color(0xFF666666)),
                        hintText: 'e.g., 500',
                        hintStyle: const TextStyle(color: Color(0xFF999999)),
                        prefixIcon: Icon(Icons.currency_rupee, color: accentColor), // Rupee icon
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0), // Light grey fill
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true, // Make input field more compact
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust content padding
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Details (Optional) Field
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 3,
                      style: const TextStyle(color: Color(0xFF333333)), // Dark text
                      decoration: InputDecoration(
                        labelText: 'Details (optional)',
                        labelStyle: const TextStyle(color: Color(0xFF666666)),
                        hintText: 'e.g., reason for transaction',
                        hintStyle: const TextStyle(color: Color(0xFF999999)),
                        alignLabelWithHint: true, // Align label with hint for multiline
                        prefixIcon: Icon(Icons.notes, color: accentColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0), // Light grey fill
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true, // Make input field more compact
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust content padding
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category and Date Selection Row
                    Row(
                      children: [
                        // Category Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: const TextStyle(color: Color(0xFF666666)),
                              prefixIcon: Icon(Icons.category, color: accentColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0F0F0), // Light grey fill
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: accentColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true, // Make input field more compact
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust content padding
                            ),
                            dropdownColor: Colors.white, // Dropdown background color
                            style: const TextStyle(color: Color(0xFF333333)), // Item text color
                            icon: Icon(Icons.arrow_drop_down, color: accentColor),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 4), // Small spacing between fields

                        // Date Picker
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                labelStyle: const TextStyle(color: Color(0xFF666666)),
                                prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0), // Light grey fill
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: accentColor, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true, // Make input field more compact
                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust content padding
                              ),
                              child: Text(
                                DateFormat('dd MMM yy').format(_selectedDate),
                                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Done Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: accentColor))
                          : ElevatedButton(
                              onPressed: _addTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor, // Green for 'got', Orange for 'gave'
                                foregroundColor: Colors.white, // White text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0), // Rounded corners
                                ),
                                elevation: 8,
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Done'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
