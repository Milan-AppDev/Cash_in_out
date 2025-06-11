import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/backend_config.dart';
import 'package:pdf/pdf.dart'; // Import pdf
import 'package:pdf/widgets.dart' as pw; // Import pdf widgets
import 'package:printing/printing.dart'; // Import printing
import 'package:flutter/services.dart'; // Import for Uint8List

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
  String? _clientPhoneNumber; // New state variable for client's phone number

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
            _clientPhoneNumber =
                data['client_phone']
                    ?.toString(); // Get client phone number from response
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

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final String clientPhoneNumber =
        _clientPhoneNumber ?? 'N/A'; // Use fetched client phone number
    final String reportDateRange =
        '(${_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : ''}${_endDate != null ? ' - ' + DateFormat('dd MMM yyyy').format(_endDate!) : ''})';

    // Calculate opening balance for the report period
    double openingBalance = 0.0; // Placeholder for now

    // Prepare data for the PDF table and calculate running balance
    final List<List<String>> tableRows = [];
    double currentRunningBalance =
        openingBalance; // Start with the opening balance for the table

    // Add the table header as a separate row for styling control
    tableRows.add(['Date', 'Details', 'Debit(-)', 'Credit(+)', 'Balance']);

    // Add opening balance as the first entry in the table data for consistency with image
    tableRows.add([
      DateFormat(
        'dd MMM',
      ).format(_startDate ?? DateTime.now()), // Or a specific date if available
      'Opening Balance',
      '',
      '',
      '₹ ${openingBalance.toStringAsFixed(2)} Cr', // Assuming opening balance is credit for display
    ]);

    for (var transaction in _clientTransactions) {
      final date = DateFormat(
        'dd MMM',
      ).format(DateTime.parse(transaction['date']));
      final details = transaction['description']?.toString() ?? '';
      final amount = double.parse(transaction['amount'].toString());

      String debit = '';
      String credit = '';
      if (transaction['type'] == 'given') {
        debit = '₹ ${amount.toStringAsFixed(2)}';
        currentRunningBalance -= amount;
      } else {
        credit = '₹ ${amount.toStringAsFixed(2)}';
        currentRunningBalance += amount;
      }

      final balanceString =
          '₹ ${currentRunningBalance.abs().toStringAsFixed(2)} '
          '${currentRunningBalance >= 0 ? 'Cr' : 'Db'}';

      tableRows.add([date, details, debit, credit, balanceString]);
    }

    final grandTotalDebit = clientTotalGiven; // Already calculated
    final grandTotalCredit = clientTotalGot; // Already calculated
    final grandNetBalance =
        clientTotalGot - clientTotalGiven; // Already calculated

    // Add Grand Total row
    tableRows.add([
      'Grand Total',
      '',
      '₹ ${grandTotalDebit.toStringAsFixed(2)}',
      '₹ ${grandTotalCredit.toStringAsFixed(2)}',
      '₹ ${grandNetBalance.abs().toStringAsFixed(2)} '
          '${grandNetBalance >= 0 ? 'Cr' : 'Db'}',
    ]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 20,
          marginRight: 20,
          marginTop: 20,
          marginBottom: 20,
        ),
        header: (context) {
          return pw.Column(
            children: [
              pw.Container(
                color: PdfColors.blue,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('+917046021424', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.white)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text('Khatabook', style: pw.TextStyle(font: ttf, color: PdfColors.white, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '${widget.clientName} Statement',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf, color: PdfColors.black),
                    ),
                    pw.Text('Phone Number: ${clientPhoneNumber}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.black)),
                    pw.Text(reportDateRange, style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.black)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              // Summary Boxes
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryBox(
                    'Opening Balance',
                    '₹ ${openingBalance.toStringAsFixed(2)}',
                    '',
                    ttf,
                    '(on ${DateFormat('dd MMM yyyy').format(_startDate ?? DateTime.now())})',
                    PdfColors.black,
                  ),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox(
                    'Total Debit(-)',
                    '₹ ${clientTotalGiven.toStringAsFixed(2)}',
                    '',
                    ttf,
                    '',
                    PdfColors.black,
                  ),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox(
                    'Total Credit(+)',
                    '₹ ${clientTotalGot.toStringAsFixed(2)}',
                    '',
                    ttf,
                    '',
                    PdfColors.black,
                  ),
                  pw.SizedBox(width: 8),
                  _buildSummaryBox(
                    'Net Balance',
                    '₹ ${grandNetBalance.abs().toStringAsFixed(2)}',
                    grandNetBalance >= 0 ? 'Cr' : 'Db',
                    ttf,
                    grandNetBalance >= 0 ? '(${widget.clientName} will get)' : '(${widget.clientName} will give)',
                    grandNetBalance >= 0 ? PdfColors.green : PdfColors.red, // Keep original colors for Net Balance
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Text('No. of Entries: ${_clientTransactions.length} (All)', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.black)),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (context) => [
          pw.Table.fromTextArray(
            columnWidths: {
              0: pw.FlexColumnWidth(1.5), // Date
              1: pw.FlexColumnWidth(3), // Details
              2: pw.FlexColumnWidth(2), // Debit
              3: pw.FlexColumnWidth(2), // Credit
              4: pw.FlexColumnWidth(2), // Balance
            },
            headers: tableRows[0], // Set the first row as headers
            data: tableRows.sublist(1), // Remaining rows are data
            headerStyle: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, font: ttf, color: PdfColors.white), // Style for header
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue), // Background for header
            cellStyle: pw.TextStyle(fontSize: 9, font: ttf), // Default cell style
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
            cellDecoration: (index, data, rowNum) {
              // Apply conditional background color for Debit and Credit columns
              if (rowNum == data.length - 1) { // Grand Total row
                return pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                );
              } else if (index == 2 && data.isNotEmpty) { // Debit column
                return pw.BoxDecoration(
                  color: PdfColors.red50, // Light red
                  border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                );
              } else if (index == 3 && data.isNotEmpty) { // Credit column
                return pw.BoxDecoration(
                  color: PdfColors.green50, // Light green
                  border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                );
              }
              return pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
              );
            },
          ),
          pw.SizedBox(height: 20),
        ],
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.black), // Divider remains outside blue background
              pw.Container(
                color: PdfColors.blue,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Report Generated: ${DateFormat('hh:mm a | dd MMM yy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.white)),
                        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.white)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text('Start Using Khatabook Now', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          pw.Text('Help: +91-9606800800', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.white)),
                          pw.Text('T&C Apply', style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper function to build summary boxes
  pw.Widget _buildSummaryBox(
    String title,
    String value,
    String suffix,
    pw.Font font,
    String subText,
    PdfColor valueColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: value,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    pw.TextSpan(
                      text: ' ' + suffix,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: valueColor,
                      ),
                    ),
                ],
              ),
            ),
            if (subText.isNotEmpty)
              pw.Text(
                subText,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> downloadPdf() async {
    final pdfBytes = await generatePdf();
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> sharePdf() async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'report_${widget.clientName.replaceAll(" ", "_")}.pdf', // Use widget.clientName
    );
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

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Report - ${widget.clientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                // This Column is directly under Scaffold.body, allowing Expanded children
                children: [
                  // Client Balance / Summary Cards (Fixed height content)
                  Container(
                    color: Colors.blue[900],
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
                                    '₹${clientTotalGot.toStringAsFixed(0)}',
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
                                    '₹${clientTotalGiven.toStringAsFixed(0)}',
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
                  // Date Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
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
                        Expanded(
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
                          width: 220, // Match the width of the amounts column
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width:
                                    90, // Match the width of 'YOU GAVE' column
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
                                    90, // Match the width of 'YOU GOT' column
                                alignment: Alignment.centerRight,
                                child: const Text(
                                  'YOU GOT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ), // Space for delete button
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
                        _clientTransactions.isEmpty
                            ? const Center(
                              child: Text(
                                'No transactions found for this client.',
                              ),
                            )
                            : ListView.builder(
                              itemCount: _clientTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _clientTransactions[index];
                                return _buildTransactionItem(transaction);
                              },
                            ),
                  ),
                  // PDF Buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: downloadPdf,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Download PDF',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: sharePdf,
                            icon: const Icon(Icons.share, color: Colors.white),
                            label: const Text(
                              'Share PDF',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
