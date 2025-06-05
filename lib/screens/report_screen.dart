import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/backend_config.dart'; // Import BackendConfig

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

  DateTime? _startDate; // State variable for start date
  DateTime? _endDate; // State variable for end date

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
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
      _allTransactions = []; // Clear previous transactions
    });

    // Build the URL with date parameters
    String url = '${BackendConfig.baseUrl}/fetch_all_transactions.php?user_id=$userId';
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
          // Selecting this will just clear the range and let user pick via buttons
          _startDate = null;
          _endDate = null;
          _selectStartDate(context); // Prompt user to select a single day
          break;
        case 'date_range':
          // Handled by _selectStartDate and _selectEndDate which are already there
          // Selecting this will just clear the range and let user pick via buttons
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      // appBar: AppBar(title: const Text('Report')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance
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
                                            style: TextStyle(
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
                                            style: TextStyle(
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
                    // You Will Give / You Will Get Summary
                    // All Transactions (Placeholder)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectStartDate(context),
                                  child: Container(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          _startDate == null
                                              ? 'Select Start Date'
                                              : 'Start: ${dateFormat.format(_startDate!)}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectEndDate(context),
                                  child: Container(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          _endDate == null
                                              ? 'Select End Date'
                                              : 'End: ${dateFormat.format(_endDate!)}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Pop-up menu for time period selection
                              PopupMenuButton<String>(
                                icon: Icon(Icons.filter_list), // Filter icon
                                onSelected: _handleTimePeriodSelection,
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                      value: 'all_time',
                                      child: Text('All time'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'today',
                                      child: Text('Today'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'single_day',
                                      child: Text('Single Day'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'this_month',
                                      child: Text('This Month'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'last_week',
                                      child: Text('Last week'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'last_month',
                                      child: Text('Last month'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_range',
                                      child: Text('Date RAnge'),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _allTransactions.isEmpty &&
                                  !isLoading &&
                                  error.isEmpty
                              ? Text(
                                'No transactions found.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _allTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _allTransactions[index];
                                  final isGot = transaction['type'] == 'got';
                                  final amount = double.parse(
                                    transaction['amount'].toString(),
                                  );
                                  final date = DateTime.parse(
                                    transaction['date'],
                                  );
                                  final formattedDate = DateFormat(
                                    'MMM d, y',
                                  ).format(date);
                                  final formattedTime = DateFormat(
                                    'h:mm a',
                                  ).format(date);

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isGot
                                              ? Colors.green.withOpacity(0.05)
                                              : Colors.red.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isGot
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              transaction['client_name'] ??
                                                  'Unknown Client',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '₹${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color:
                                                    isGot
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          transaction['description'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Type: ${isGot ? 'You Got' : 'You Gave'}',
                                              style: TextStyle(
                                                color:
                                                    isGot
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '$formattedDate $formattedTime',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
