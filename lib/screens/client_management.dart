import 'package:cash/screens/addtransactionscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cash/model/client_model.dart';
import 'package:cash/model/transaction_model.dart'; // Import the new transaction screen

// Define a simple Transaction model that can parse from API response
// class Transaction {
//   final String id;
//   final String description;
//   final double amount;
//   final DateTime date;
//   final String type; // 'got' or 'given'
//   final String category; // Added category

//   Transaction({
//     required this.id,
//     required this.description,
//     required this.amount,
//     required this.date,
//     required this.type,
//     required this.category, // Initialize category
//   });

//   // Factory constructor to create a Transaction from a JSON map (from PHP API)
//   factory Transaction.fromJson(Map<String, dynamic> json) {
//     return Transaction(
//       id: json['id'].toString(), // Ensure ID is string
//       description: json['description'] ?? '', // Handle null description
//       amount: double.parse(json['amount'].toString()),
//       date: DateTime.parse(json['transaction_date']), // Parse date string
//       type: json['type'],
//       category: json['category'] ?? 'Other', // Handle null category
//     );
//   }
// }


class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<Transaction> _transactions = [];
  double _netBalance = 0.0;
  bool _isLoadingTransactions = true;

  // For currency formatting (Indian Rupee)
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN', // Indian locale
    symbol: '₹', // Indian Rupee symbol
    decimalDigits: 2,
  );

  // IMPORTANT: Replace with your actual API URL
  // Use your machine's IP address if testing on a physical device,
  // or '10.0.2.2' for Android Emulator to access localhost.
  static const String _apiBaseUrl = 'http://localhost/api';

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Fetch transactions when the screen initializes
  }

  // Function to fetch transactions for the current client from the backend API
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoadingTransactions = true; // Show loading indicator
    });

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get_transactions.php?client_id=${widget.client.id}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (mounted) {
          if (responseData['success']) {
            final List<dynamic> transactionJsonList = responseData['transactions'];
            List<Transaction> fetchedTransactions = transactionJsonList
                .map((json) => Transaction.fromJson(json))
                .toList();

            // Sort transactions by date (most recent first)
            fetchedTransactions.sort((a, b) => b.date.compareTo(a.date));

            double calculatedNetBalance = 0.0;
            for (var t in fetchedTransactions) {
              if (t.type == 'got') {
                calculatedNetBalance += t.amount;
              } else {
                calculatedNetBalance -= t.amount;
              }
            }

            setState(() {
              _transactions = fetchedTransactions;
              _netBalance = calculatedNetBalance;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to fetch transactions: ${responseData['message']}')),
            );
            setState(() {
              _transactions = []; // Clear list on error
              _netBalance = 0.0;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error fetching transactions: ${response.statusCode}')),
          );
        }
        setState(() {
          _transactions = []; // Clear list on error
          _netBalance = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error fetching transactions: $e')),
        );
      }
      setState(() {
        _transactions = []; // Clear list on error
        _netBalance = 0.0;
      });
    } finally {
      setState(() {
        _isLoadingTransactions = false; // Hide loading indicator
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Determine color for net balance text
    Color netBalanceColor = _netBalance >= 0 ? const Color(0xFF8BC34A) : const Color(0xFFFF7043);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Very light grey/off-white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F0), // Same as background for seamless look
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        // No title in AppBar as requested, client name is in body
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // Reduced padding to give more vertical room
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards horizontally
                children: [
                  // Client Name and Mobile Number Section - Aligned to Start (Left)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name, // Use widget.client.name
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333), // Dark text
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.client.mobileNumber, // Use widget.client.mobileNumber
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF666666), // Medium grey for mobile
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Net Balance Card (with all-side radius)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0), // All-side radius
                    ),
                    color: const Color(0xFF2C2C2C), // Dark grey background
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Net Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70, // Lighter text color
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft, // Align amount to left
                            child: Text(
                              _currencyFormat.format(_netBalance), // Use dynamic net balance
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: netBalanceColor, // Dynamic color
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Report, WhatsApp, SMS Options (with all-side radius)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.description_outlined,
                          label: 'Report',
                          iconColor: const Color(0xFF4285F4), // Blue for Report
                          textColor: const Color(0xFF4285F4),
                          cardColor: Colors.white,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report feature coming soon!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.access_alarm, // Assuming WhatsApp icon exists or similar
                          label: 'WhatsApp',
                          iconColor: const Color(0xFF25D366), // WhatsApp Green
                          textColor: const Color(0xFF25D366),
                          cardColor: Colors.white,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('WhatsApp feature coming soon!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.sms_outlined,
                          label: 'SMS',
                          iconColor: const Color(0xFFFF7043), // Accent Orange
                          textColor: const Color(0xFFFF7043),
                          cardColor: Colors.white,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SMS feature coming soon!')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Entries Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0), // Small padding to align with cards
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ENTRIES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333), // Dark text
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'YOU GAVE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7043), // Orange text
                              ),
                            ),
                            SizedBox(width: 16), // Spacing between "YOU GAVE" and "YOU GOT"
                            Text(
                              'YOU GOT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8BC34A), // Green text
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            // Transaction List - Use Expanded to fill remaining space
            _isLoadingTransactions
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF7043)), // Accent color
                    ),
                  )
                : _transactions.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add your first transaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding to align with other content
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            // Determine card color based on transaction type
                            Color transactionCardBgColor = transaction.type == 'got' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE); // Light green for got, light red for given
                            Color amountTextColor = transaction.type == 'got' ? const Color(0xFF8BC34A) : const Color(0xFFFF7043);
                            Color borderColor = transaction.type == 'got' ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);

                            return Card(
                              elevation: 2, // Less elevation for list items
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Rounded corners for each transaction entry
                              ),
                              color: Colors.white, // Main card background
                              child: Container(
                                decoration: BoxDecoration(
                                  color: transactionCardBgColor, // Background color based on type
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: borderColor, // Lighter border
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yy - hh:mm a').format(transaction.date),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999), // Light grey date/time
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column( // Column to show description and category
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                transaction.description.isEmpty ? 'No description' : transaction.description,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF333333), // Dark text for description
                                                ),
                                              ),
                                              if (transaction.category.isNotEmpty) // Show category if available
                                                Text(
                                                  'Category: ${transaction.category}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF999999),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20), // Space between description and amounts
                                        Row(
                                          children: [
                                            // "You Gave" amount
                                            if (transaction.type == 'given')
                                              Text(
                                                _currencyFormat.format(transaction.amount),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: amountTextColor, // Red for given amount
                                                ),
                                              )
                                            else
                                              const SizedBox(width: 70), // Placeholder for alignment (adjust width as needed)

                                            const SizedBox(width: 16), // Space between given/got amounts

                                            // "You Got" amount
                                            if (transaction.type == 'got')
                                              Text(
                                                _currencyFormat.format(transaction.amount),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: amountTextColor, // Green for got amount
                                                ),
                                              )
                                            else
                                              const SizedBox(width: 70), // Placeholder for alignment (adjust width as needed)
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            // Removed the fixed SizedBox(height: 100) here, rely on bottomNavigationBar padding
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to AddTransactionScreen for "You Got"
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        client: widget.client, // Pass the client object
                        transactionType: 'got', // Specify transaction type
                      ),
                    ),
                  );
                  // If a transaction was added, refresh the list
                  if (result == true) {
                    _fetchTransactions(); // Refresh transactions
                  }
                },
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: const Text('YOU GOT', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A), // Green button
                  foregroundColor: Colors.white, // White text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  elevation: 8,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to AddTransactionScreen for "You Gave"
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        client: widget.client, // Pass the client object
                        transactionType: 'given', // Specify transaction type
                      ),
                    ),
                  );
                  // If a transaction was added, refresh the list
                  if (result == true) {
                    _fetchTransactions(); // Refresh transactions
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, size: 28),
                label: const Text('YOU GAVE', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043), // Orange/Red button
                  foregroundColor: Colors.white, // White text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  elevation: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for action buttons (Report, WhatsApp, SMS)
  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners for action buttons
      ),
      color: cardColor,
      child: InkWell( // Use InkWell for tap effect
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
