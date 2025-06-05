import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // Required for ByteData
import 'package:share_plus/share_plus.dart'; // Import share_plus
import '../utils/backend_config.dart'; // Import BackendConfig

// import 'package:permission_handler/permission_handler.dart'; // Uncomment if storage permissions are needed

class ClientReportScreen extends StatefulWidget {
  final int clientId;
  final String clientName;

  const ClientReportScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientReportScreen> createState() => _ClientReportScreenState();
}

class _ClientReportScreenState extends State<ClientReportScreen> {
  bool isLoading = true;
  String error = '';
  int? userId;
  double clientBalance = 0.0;
  double clientTotalGot = 0.0;
  double clientTotalGiven = 0.0;
  List<Map<String, dynamic>> _clientTransactions = [];

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
      fetchClientReportData();
    } else {
      setState(() {
        error = 'User not logged in';
        isLoading = false;
      });
    }
  }

  Future<void> fetchClientReportData() async {
    if (userId == null || widget.clientId <= 0) return;

    setState(() {
      isLoading = true;
      error = '';
      _clientTransactions = []; // Clear previous transactions
    });

    // Build the URL with parameters
    String url =
        '${BackendConfig.baseUrl}/fetch_all_transactions.php?user_id=$userId&client_id=${widget.clientId}';
    if (_startDate != null) {
      url += '&start_date=' + DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      url += '&end_date=' + DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    print('ClientReportScreen: Fetching data from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            _clientTransactions = List<Map<String, dynamic>>.from(
              data['transactions'] ?? [],
            );
            clientBalance =
                double.tryParse(data['client_balance']?.toString() ?? '0.0') ??
                0.0;
            clientTotalGot =
                double.tryParse(
                  data['client_total_got']?.toString() ?? '0.0',
                ) ??
                0.0;
            clientTotalGiven =
                double.tryParse(
                  data['client_total_given']?.toString() ?? '0.0',
                ) ??
                0.0;
            isLoading = false;
          });
          print(
            'ClientReportScreen: Data loaded successfully. Transactions count: ${_clientTransactions.length}',
          );
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load report data';
            isLoading = false;
          });
          print('ClientReportScreen: Failed to load data: ${data['message']}');
        }
      } else {
        setState(() {
          error =
              'Failed to load report data: Status code ${response.statusCode}';
          isLoading = false;
        });
        print(
          'ClientReportScreen: Failed to load data: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching report data: $e';
        isLoading = false;
      });
      print('ClientReportScreen: Error fetching report data: $e');
    }
  }

  // Function to delete a transaction
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
          print('ClientReportScreen: Transaction deleted successfully.');
          // Refresh both transactions and summary data after deletion
          fetchClientReportData();
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to delete transaction';
            isLoading = false;
          });
          print(
            'ClientReportScreen: Failed to delete transaction: ${data['message']}',
          );
        }
      } else {
        setState(() {
          error =
              'Failed to delete transaction: Status code ${response.statusCode}';
          isLoading = false;
        });
        print(
          'ClientReportScreen: Failed to delete transaction: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        error = 'Error deleting transaction: $e';
        isLoading = false;
      });
      print('ClientReportScreen: Error deleting transaction: $e');
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
        // Clear end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
      fetchClientReportData(); // Fetch data with new date range
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
        // Clear start date if it's after the new end date
        if (_startDate != null && _startDate!.isAfter(_endDate!)) {
          _startDate = null;
        }
      });
      fetchClientReportData(); // Fetch data with new date range
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
          _startDate = null;
          _endDate = null;
          _selectStartDate(context); // Prompt user to select a single day
          break;
        case 'date_range':
          _startDate = null;
          _endDate = null;
          // User will use the buttons to select the range after this
          break;
      }
    });

    if (value != 'single_day' && value != 'date_range') {
      // Don't fetch immediately for single day or date range
      fetchClientReportData();
    }
  }

  // Function to generate the PDF report
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final currencyFormatPdf = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    final dateFormatPdf = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${widget.clientName} Statement',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    // Assuming phone number is available in the client data, replace with actual data source if different
                    pw.Text(
                      'Phone Number: N/A',
                      style: pw.TextStyle(fontSize: 12),
                    ), // Placeholder for phone number
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${_startDate != null ? dateFormatPdf.format(_startDate!) : ''} - ${_endDate != null ? dateFormatPdf.format(_endDate!) : ''}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary Cards
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildPdfSummaryCard(
                    'Opening Balance',
                    currencyFormatPdf.format(0.00),
                    PdfColors.black,
                  ), // Placeholder
                  _buildPdfSummaryCard(
                    'Total Debit(-)',
                    currencyFormatPdf.format(clientTotalGiven),
                    PdfColors.red,
                  ), // Total Given as Debit
                  _buildPdfSummaryCard(
                    'Total Credit(+)',
                    currencyFormatPdf.format(clientTotalGot),
                    PdfColors.green,
                  ), // Total Got as Credit
                  _buildPdfSummaryCard(
                    'Net Balance',
                    currencyFormatPdf.format(clientBalance),
                    clientBalance >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Transactions Table
              pw.Text(
                'Transactions',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildPdfTransactionsTable(
                currencyFormatPdf,
              ), // Build transaction table
              pw.SizedBox(height: 20),

              // Report Generated Timestamp
              pw.Text(
                'Report Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper function to build summary cards for PDF
  pw.Expanded _buildPdfSummaryCard(
    String title,
    String amount,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build the transactions table for PDF
  pw.Table _buildPdfTransactionsTable(NumberFormat currencyFormatPdf) {
    // Calculate running balance for the PDF table
    double runningBalance = 0.00; // Starting balance is 0 for the report period
    List<pw.TableRow> rows = [
      pw.TableRow(
        children: [
          pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Debit(-)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
          pw.Text(
            'Credit(+)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
          pw.Text(
            'Balance',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    ];

    for (var transaction in _clientTransactions) {
      final isGot = transaction['type'] == 'got';
      final amount = double.parse(transaction['amount'].toString());
      final date = DateTime.parse(transaction['date']);
      final formattedDate = DateFormat('dd MMM').format(date);

      if (isGot) {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }

      rows.add(
        pw.TableRow(
          children: [
            pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10)),
            pw.Text(
              transaction['description'] ?? '',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              isGot ? '' : currencyFormatPdf.format(amount),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
              textAlign: pw.TextAlign.right,
            ),
            pw.Text(
              isGot ? currencyFormatPdf.format(amount) : '',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.green),
              textAlign: pw.TextAlign.right,
            ),
            pw.Text(
              currencyFormatPdf.format(runningBalance),
              style: pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
      );
    }

    // Grand Total Row
    rows.add(
      pw.TableRow(
        children: [
          pw.Text(
            'Grand Total',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(''), // Empty cells for details and debit/credit
          pw.Text(''),
          pw.Text(''),
          pw.Text(
            currencyFormatPdf.format(runningBalance),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // Date
        1: const pw.FlexColumnWidth(), // Details
        2: const pw.FixedColumnWidth(60), // Debit
        3: const pw.FixedColumnWidth(60), // Credit
        4: const pw.FixedColumnWidth(60), // Balance
      },
      children: rows,
    );
  }

  // Function to save the PDF to the device
  Future<void> _saveAndLaunchPdf() async {
    // Request storage permission if needed (usually not required for app-specific directories)
    // if (await Permission.storage.request().isGranted) {
    try {
      final pdfBytes = await _generatePdf(PdfPageFormat.a4);
      final dir =
          await getApplicationDocumentsDirectory(); // Or getExternalStorageDirectory() for shared storage
      final file = File(
        '${dir.path}/client_report_${widget.clientId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      // Optionally, open the PDF after saving
      // You can use the `open_file` package for this
      // await OpenFile.open(file.path);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report saved to ${file.path}')));

      print('PDF saved successfully to: ${file.path}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
      print('Error saving PDF: $e');
    }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Storage permission denied')),
    //   );
    // }
  }

  // Function to generate and share the PDF report
  Future<void> _sharePdfReport() async {
    setState(() {
      isLoading = true; // Show loading indicator while sharing
      error = '';
    });

    try {
      final pdfBytes = await _generatePdf(PdfPageFormat.a4);
      final tempDir = await getTemporaryDirectory(); // Get temporary directory
      final tempFile = File(
        '${tempDir.path}/client_report_${widget.clientId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
      await tempFile.writeAsBytes(pdfBytes);

      // Use share_plus to share the temporary file
      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'Client Report for ${widget.clientName}');

      // Optional: Delete the temporary file after sharing
      // await tempFile.delete();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to share PDF: $e';
        isLoading = false;
      });
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Report for ${widget.clientName}'),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Balance
                    Container(
                      color: Colors.blue[900],
                      child: Padding(
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
                                color: Colors.white,
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
                                        currencyFormat.format(clientTotalGot),
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
                                color: Colors.white,
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
                                        currencyFormat.format(clientTotalGiven),
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
                    ),
                    // Here
                    // Client Transactions Header and Date Pickers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
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
                                child: TextButton(
                                  onPressed: () => _selectStartDate(context),
                                  child: Text(
                                    _startDate == null
                                        ? 'Select Start Date'
                                        : 'Start: ${dateFormat.format(_startDate!)}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _selectEndDate(context),
                                  child: Text(
                                    _endDate == null
                                        ? 'Select End Date'
                                        : 'End: ${dateFormat.format(_endDate!)}',
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
                                      value: 'this_month',
                                      child: Text('This Month'),
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
                                      value: 'last_week',
                                      child: Text('Last week'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'last_month',
                                      child: Text('Last month'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_range',
                                      child: Text('Date Range'),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Display Client Transactions
                          _clientTransactions.isEmpty &&
                                  !isLoading &&
                                  error.isEmpty
                              ? Text(
                                'No transactions found for this client.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    NeverScrollableScrollPhysics(), // Disable ListView scrolling
                                itemCount: _clientTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction =
                                      _clientTransactions[index];
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
                                              // No client name needed here as it's a client-specific report
                                              transaction['client_name'] ??
                                                  'Unknown Client', // Display client name
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
                                            // Delete button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.grey,
                                              ),
                                              onPressed:
                                                  () => _deleteTransaction(
                                                    transaction['id'],
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 32),
          Expanded(
            child: GestureDetector(
              onTap: _saveAndLaunchPdf,
              child: Container(
                child: Card(
                  color: Colors.blue[900],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.download, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Download",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _sharePdfReport,
              child: Container(
                child: Card(
                  color: Colors.blue[900],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.share, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "  Share",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
