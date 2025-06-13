import 'package:cash_in_out/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_in_out/screens/client_report_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/backend_config.dart';
import 'package:cash_in_out/screens/edit_client_screen.dart';
import 'package:cash_in_out/screens/transaction_detail_screen.dart';

class ClientManagementScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const ClientManagementScreen({super.key, required this.client});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  double _totalGot = 0;
  double _totalGiven = 0;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
    if (userId != null) {
      _fetchTransactions();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${BackendConfig.baseUrl}/transactions.php?client_id=${widget.client['id']}&user_id=$userId',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(
              data['transactions'],
            );
            _calculateTotals();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _totalGot = 0;
    _totalGiven = 0;
    for (var transaction in _transactions) {
      if (transaction['type'] == 'got') {
        _totalGot += double.parse(transaction['amount'].toString());
      } else {
        _totalGiven += double.parse(transaction['amount'].toString());
      }
    }
  }

  Future<void> _deleteTransaction(int transactionId) async {
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/delete_transaction.php'),
        body: {'transaction_id': transactionId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _fetchTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to delete transaction'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  Future<void> _launchSMS(String phoneNumber) async {
    final smsUrl = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch SMS')));
    }
  }

  void _sendSMS() async {
    final phoneNumber = widget.client['phone']?.toString() ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String message = 'Hello ${widget.client['name']}, ';
    double diff = (_totalGot - _totalGiven).abs();

    if (_totalGiven > _totalGot) {
      message += 'you have to give ₹${diff.toStringAsFixed(2)}.';
    } else if (_totalGot > _totalGiven) {
      message += 'you have to get ₹${diff.toStringAsFixed(2)}.';
    } else {
      message += 'your account is settled.';
    }

    final Uri smsUri = Uri.parse(
      'sms:${phoneNumber.replaceAll(RegExp(r'\D'), '')}?body=${Uri.encodeComponent(message)}',
    );

    try {
      if (!await canLaunchUrl(smsUri)) {
        throw 'Could not launch SMS app';
      }
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _sendWhatsApp() async {
    final phoneNumber = widget.client['phone']?.toString() ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String message = 'Hello ${widget.client['name']}, ';
    double diff = (_totalGot - _totalGiven).abs();

    if (_totalGiven > _totalGot) {
      message += 'you have to give ₹${diff.toStringAsFixed(2)}.';
    } else if (_totalGot > _totalGiven) {
      message += 'you have to get ₹${diff.toStringAsFixed(2)}.';
    } else {
      message += 'your account is settled.';
    }

    String phone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (!await canLaunchUrl(whatsappUrl)) {
        throw 'Could not launch WhatsApp';
      }
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
      onTap: () {
        final Map<String, dynamic> transactionWithClientName = Map.from(transaction);
        transactionWithClientName['client_name'] = widget.client['name'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transactionWithClientName,
            ),
          ),
        ).then((_) => _fetchTransactions());
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
    final balance = _totalGot - _totalGiven;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final phoneNumber = widget.client['phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.client['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditClientScreen(client: widget.client),
                ),
              );

              if (result == true) {
                _fetchTransactions();
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Client Details and Balance
                  Container(
                    color: Colors.blue[900],
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    balance < 0 
                                        ? 'You will get'
                                        : balance > 0 
                                            ? 'You will give'
                                            : 'Settled up',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(balance),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        balance >= 0
                                            ? Colors.green
                                            : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.receipt_long,
                                    label: 'Report',
                                    color: Colors.blue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ClientReportScreen(
                                                clientId: widget.client['id'],
                                                clientName:
                                                    widget.client['name'],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.radar_sharp,
                                    label: 'WhatsApp',
                                    color: Colors.green,
                                    onTap: _totalGot > _totalGiven ? null : _sendWhatsApp,
                                  ),
                                ),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.sms,
                                    label: 'SMS',
                                    color: Colors.orange,
                                    onTap: _totalGot > _totalGiven ? null : _sendSMS,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Client Transactions Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
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
                          width:
                              240, // Consistent with amount columns in _buildTransactionItem (70+70+40 for delete)
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
                              SizedBox(width: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Transaction List
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _transactions.isEmpty
                            ? const Center(
                              child: Text(
                                'No transactions found for this client.',
                              ),
                            )
                            : ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                return _buildTransactionItem(transaction);
                              },
                            ),
                  ),
                  // Add Transaction Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddTransactionScreen(
                                      clientId: widget.client['id'],
                                      clientName: widget.client['name'],
                                      transactionType: 'got',
                                    ),
                              ),
                            ).then((_) => _fetchTransactions());
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 10,
                            ),
                            color: Colors.green[700],
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'YOU GOT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddTransactionScreen(
                                      clientId: widget.client['id'],
                                      clientName: widget.client['name'],
                                      transactionType: 'given',
                                    ),
                              ),
                            ).then((_) => _fetchTransactions());
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 10,
                            ),
                            color: Colors.red[700],
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'YOU GAVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: onTap == null ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onTap == null ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onTap == null ? Colors.grey : color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: onTap == null ? Colors.grey : color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
