import 'package:cash_in_out/models/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/backend_config.dart'; // Import BackendConfig
import 'package:cash_in_out/screens/transaction_detail_screen.dart'; // Import the new screen

// import 'package:permission_handler/permission_handler.dart'; // Uncomment if storage permissions are needed

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isLoading = true;
  String error = '';
  int? userId;
  double totalBalance = 0.0;
  double totalGot = 0.0;
  double totalGiven = 0.0;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions =
      []; // New list for filtered results

  DateTime? _startDate; // State variable for start date
  DateTime? _endDate; // State variable for end date

  final TextEditingController _searchController =
      TextEditingController(); // Search bar controller
  String _searchQuery = ''; // State variable for search query

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
    _searchController.addListener(
      _onSearchChanged,
    ); // Listen for search input changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterTransactions(); // Filter transactions whenever search query changes
    });
  }

  void _filterTransactions() {
    if (_searchQuery.isEmpty) {
      _filteredTransactions = _allTransactions; // Show all if no search query
    } else {
      _filteredTransactions =
          _allTransactions.where((transaction) {
            final String amount =
                transaction['amount'].toString().toLowerCase();
            final String description =
                transaction['description']?.toString().toLowerCase() ?? '';
            return amount.contains(_searchQuery) ||
                description.contains(_searchQuery);
          }).toList();
    }
  }

  Future<void> _loadUserIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      fetchReportData();
      fetchAllTransactions(); // Initial fetch without date range
    } else {
      setState(() {
        error = 'User not logged in';
        isLoading = false;
      });
    }
  }

  Future<void> fetchReportData() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/clients.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            totalBalance =
                double.tryParse(data['total_balance'].toString()) ?? 0.0;
            totalGot = double.tryParse(data['total_got'].toString()) ?? 0.0;
            totalGiven = double.tryParse(data['total_given'].toString()) ?? 0.0;
            isLoading = false;
          });
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load report data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load report data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchAllTransactions() async {
    if (userId == null) return;

    setState(() {
      isLoading = true; // Set loading to true when fetching transactions
      error = '';
      // _allTransactions = []; // No need to clear here, done by _filterTransactions
    });

    // Build the URL with date parameters
    String url =
        '${BackendConfig.baseUrl}/fetch_all_transactions.php?user_id=$userId';
    if (_startDate != null) {
      url += '&start_date=' + DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      url += '&end_date=' + DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    print('ReportScreen: Fetching transactions from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            _allTransactions = List<Map<String, dynamic>>.from(
              data['transactions'],
            );
            _filterTransactions(); // Filter after fetching all transactions
            isLoading = false;
          });
          print(
            'ReportScreen: All transactions loaded successfully. Count: ${_allTransactions.length}',
          );
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load transactions';
            isLoading = false;
          });
          print(
            'ReportScreen: Failed to load transactions: ${data['message']}',
          );
        }
      } else {
        setState(() {
          error =
              'Failed to load transactions: Status code ${response.statusCode}';
          isLoading = false;
        });
        print(
          'ReportScreen: Failed to load transactions: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching transactions: $e';
        isLoading = false;
      });
      print('ReportScreen: Error fetching transactions: $e');
    }
  }

  // Function to show date picker for start date
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      fetchAllTransactions(); // Fetch transactions with new date range
    }
  }

  // Function to show date picker for end date
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime(2000), // End date cannot be before start date
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      fetchAllTransactions(); // Fetch transactions with new date range
    }
  }

  // Function to handle time period selection from the pop-up menu
  Future<void> _handleTimePeriodSelection(String? value) async {
    if (value == null) return;

    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    setState(() {
      switch (value) {
        case 'all_time':
          _startDate = null;
          _endDate = null;
          break;
        case 'this_month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(
            now.year,
            now.month + 1,
            0,
          ); // Last day of the current month
          break;
        case 'today':
          _startDate = startOfToday;
          _endDate = startOfToday.add(
            const Duration(days: 1, microseconds: -1),
          ); // End of today
          break;
        case 'last_week':
          DateTime lastWeekStart = startOfToday.subtract(
            Duration(days: startOfToday.weekday + 6),
          );
          DateTime lastWeekEnd = startOfToday.subtract(
            Duration(days: startOfToday.weekday),
          );
          _startDate = DateTime(
            lastWeekStart.year,
            lastWeekStart.month,
            lastWeekStart.day,
          );
          _endDate = DateTime(
            lastWeekEnd.year,
            lastWeekEnd.month,
            lastWeekEnd.day,
            23,
            59,
            59,
          );
          break;
        case 'last_month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0); // Last day of last month
          break;
        case 'single_day':
          // Handled by _selectStartDate and _selectEndDate which are already there
          _startDate = null;
          _endDate = null;
          _selectStartDate(context); // Prompt user to select a single day
          break;
        case 'date_range':
          // Handled by _selectStartDate and _selectEndDate which are already there
          _startDate = null;
          _endDate = null;
          _selectEndDate(context);
          _selectStartDate(context);
          break;
      }
    });

    if (value != 'single_day' && value != 'date_range') {
      // Don't fetch immediately for single day or date range
      fetchAllTransactions();
    }
  }

  // Function to delete a transaction (copied from client_management_screen.dart)
  Future<void> _deleteTransaction(int transactionId) async {
    if (userId == null) return; // Ensure user is logged in

    // Optionally show a confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(false), // Return false on cancel
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed:
                  () =>
                      Navigator.of(context).pop(true), // Return true on confirm
            ),
          ],
        );
      },
    );

    if (!confirmDelete) return; // If user cancels, do nothing

    setState(() {
      isLoading = true; // Show loading indicator while deleting
      error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/delete_transaction.php'),
        body: {'transaction_id': transactionId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          print('ReportScreen: Transaction deleted successfully.');
          // Refresh transactions after deletion
          fetchAllTransactions();
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to delete transaction';
            isLoading = false;
          });
          print(
            'ReportScreen: Failed to delete transaction: ${data['message']}',
          );
        }
      } else {
        setState(() {
          error =
              'Failed to delete transaction: Status code ${response.statusCode}';
          isLoading = false;
        });
        print(
          'ReportScreen: Failed to delete transaction: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        error = 'Error deleting transaction: $e';
        isLoading = false;
      });
      print('ReportScreen: Error deleting transaction: $e');
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isGot = transaction['type'] == 'got';
    final amount = double.parse(transaction['amount'].toString());
    final date = DateTime.parse(transaction['date']);
    final formattedDate = DateFormat('dd MMM yy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    final description = transaction['description']?.toString();

    final runningBalance =
        transaction['running_balance'] != null
            ? double.parse(transaction['running_balance'].toString())
            : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
            ),
          ),
        );
        fetchAllTransactions();
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Information Container (Date, Time, Description, Balance)
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$formattedDate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        ' • $formattedTime',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
            // YOU GAVE Container
            Container(
              height: 100,
              width: 100, // Fixed width for 'YOU GAVE' column
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 22,
              ), // Added padding
              margin: const EdgeInsets.only(
                left: 8,
              ), // Spacing from previous container
              child: Text(
                isGot ? '' : '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            // YOU GOT Container
            Container(
              height: 100,
              width: 100, // Fixed width for 'YOU GOT' column
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 22,
              ), // Added padding
              margin: const EdgeInsets.only(
                left: 8,
              ), // Spacing from previous container
              child: Text(
                isGot ? '₹${amount.toStringAsFixed(0)}' : '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                // This Column is directly under Scaffold.body, allowing Expanded children
                children: [
                  // Total Balance Summary Cards (Fixed height)
                  Container(
                    color: Colors.blue[900],
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 16.0,
                            left: 16.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'You Will Get',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currencyFormat.format(totalGot),
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'You Will Give',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currencyFormat.format(totalGiven),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // All Transactions Header and Date Pickers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(),
                        GestureDetector(
                          onTap: () => _selectStartDate(context),
                          child: Expanded(
                            child: Row(
                              children: [
                                Text(
                                  '${_startDate != null ? DateFormat('dd MMM yy').format(_startDate!) : 'Start Date'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _selectStartDate(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                        GestureDetector(
                          onTap: () => _selectEndDate(context),
                          child: Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${_endDate != null ? DateFormat('dd MMM yy').format(_endDate!) : 'End Date'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _selectEndDate(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: _handleTimePeriodSelection,
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'all_time',
                                child: Text('All Time'),
                              ),
                              const PopupMenuItem(
                                value: 'this_month',
                                child: Text('This Month'),
                              ),
                              const PopupMenuItem(
                                value: 'today',
                                child: Text('Today'),
                              ),
                              const PopupMenuItem(
                                value: 'last_week',
                                child: Text('Last Week'),
                              ),
                              const PopupMenuItem(
                                value: 'last_month',
                                child: Text('Last Month'),
                              ),
                              const PopupMenuItem(
                                value: 'single_day',
                                child: Text('Single Day'),
                              ),
                              const PopupMenuItem(
                                value: 'date_range',
                                child: Text('Date Range'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText:
                            'Search transactions by amount or description',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  // Transaction Headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ENTRIES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(
                          width: 260, // Match the width of the amounts column
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width:
                                    100, // Match the width of 'YOU GAVE' column
                                alignment: Alignment.centerRight,
                                child: const Text(
                                  'YOU GAVE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                width:
                                    100, // Match the width of 'YOU GOT' column
                                alignment: Alignment.centerRight,
                                child: const Text(
                                  'YOU GOT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Transaction List
                  Expanded(
                    // Crucial for ListView.builder inside a Column
                    child:
                        _filteredTransactions
                                .isEmpty // Use filtered transactions here
                            ? const Center(
                              child: Text('No transactions found.'),
                            )
                            : ListView.builder(
                              itemCount:
                                  _filteredTransactions
                                      .length, // Use filtered transactions count
                              itemBuilder: (context, index) {
                                final transaction =
                                    _filteredTransactions[index]; // Use filtered transactions
                                return _buildTransactionItem(transaction);
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
