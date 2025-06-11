import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import 'add_client_screen.dart';
// import 'login.dart';
import 'client_management_screen.dart';
import 'package:intl/intl.dart';
import '../utils/backend_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<_HomeContentState> _homeContentKey =
      GlobalKey<_HomeContentState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(key: _homeContentKey),
      const ReportScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Cash In-Out';
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Cash In-Out';
        break;
      case 1:
        appBarTitle = 'Reports';
        break;
      case 2:
        appBarTitle = 'Profile';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[900],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool isLoading = true;
  String error = '';
  int? userId;
  double totalBalance = 0.0;
  double totalGot = 0.0;
  double totalGiven = 0.0;

  String _searchQuery = '';
  String? _sortOption;

  @override
  void initState() {
    super.initState();
    print('HomeContent: initState called');
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
    if (userId != null) {
      fetchClients();
    } else {
      setState(() {
        error = 'User not logged in';
        isLoading = false;
      });
    }
  }

  Future<void> fetchClients() async {
    if (userId == null) {
      setState(() {
        error = 'User not logged in';
        isLoading = false;
      });
      return;
    }

    print('HomeContent: Starting fetchClients');
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      print('HomeContent: Making HTTP request');
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/clients.php?user_id=$userId'),
      );
      print('HomeContent: Response status code: ${response.statusCode}');
      print('HomeContent: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('HomeContent: Decoded data: $data');

        if (data['success'] == true) {
          setState(() {
            clients = List<Map<String, dynamic>>.from(data['clients']);
            totalBalance =
                double.tryParse(data['total_balance'].toString()) ?? 0.0;
            totalGot = double.tryParse(data['total_got'].toString()) ?? 0.0;
            totalGiven = double.tryParse(data['total_given'].toString()) ?? 0.0;
            isLoading = false;
          });
          _applyFilterAndSort();
          print(
            'HomeContent: Clients loaded successfully. Count: ${clients.length}',
          );
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load clients';
            isLoading = false;
          });
          print('HomeContent: Error from backend: $error');
        }
      } else {
        setState(() {
          error = 'Failed to load clients';
          isLoading = false;
        });
        print('HomeContent: HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
      print('HomeContent: Exception caught: $e');
    }
  }

  Future<void> deleteClient(int id) async {
    if (userId == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BackendConfig.baseUrl}/clients.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client deleted successfully')),
          );
          fetchClients();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to delete client'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete client')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _applyFilterAndSort() {
    List<Map<String, dynamic>> tempList = List.from(clients);

    // Apply filter
    if (_searchQuery.isNotEmpty) {
      tempList =
          tempList.where((client) {
            final name = client['name']?.toString().toLowerCase() ?? '';
            final phone = client['phone']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).toList();
    }

    // Apply sort
    if (_sortOption != null) {
      tempList.sort((a, b) {
        switch (_sortOption) {
          case 'name_asc':
            return (a['name'] ?? '').compareTo(b['name'] ?? '');
          case 'name_desc':
            return (b['name'] ?? '').compareTo(a['name'] ?? '');
          case 'balance_asc':
            final balanceA =
                double.tryParse(a['balance']?.toString() ?? '0.0') ?? 0.0;
            final balanceB =
                double.tryParse(b['balance']?.toString() ?? '0.0') ?? 0.0;
            return balanceA.compareTo(balanceB);
          case 'balance_desc':
            final balanceA =
                double.tryParse(a['balance']?.toString() ?? '0.0') ?? 0.0;
            final balanceB =
                double.tryParse(b['balance']?.toString() ?? '0.0') ?? 0.0;
            return balanceB.compareTo(balanceA);
          default:
            return 0;
        }
      });
    }

    setState(() {
      _filteredClients = tempList;
    });
  }

  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'HomeContent: Building widget. isLoading: $isLoading, error: $error, clients count: ${clients.length}',
    );
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      children: [
        // Total Balance Card
        Container(
          color: Colors.blue[900],
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalBalance),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: totalBalance >= 0
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 16.0,
                  left: 16.0,
                  bottom: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBalanceSummaryCard(
                      'You Will Get',
                      totalGot,
                      Colors.green,
                    ),
                    _buildBalanceSummaryCard(
                      'You Will give',
                      totalGiven,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search and Sort Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilterAndSort();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort Options Pop-up Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort), // Sort icon
                onSelected: (String value) {
                  setState(() {
                    _sortOption = value;
                  });
                  _applyFilterAndSort();
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'name_asc',
                      child: Text('Name (A-Z)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'name_desc',
                      child: Text('Name (Z-A)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'balance_asc',
                      child: Text('Balance (Low to High)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'balance_desc',
                      child: Text('Balance (High to Low)'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
        // Existing client list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredClients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No clients found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first client to get started',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = _filteredClients[index];
                        final String clientName = client['name'] ?? '';
                        final double clientBalance =
                            double.tryParse(client['balance']?.toString() ?? '0.0') ?? 0.0;
                        final String lastTransactionDateString = client['last_transaction_date'] ?? '';

                        DateTime? lastTransactionDate;
                        if (lastTransactionDateString.isNotEmpty) {
                          try {
                            lastTransactionDate = DateTime.parse(lastTransactionDateString);
                          } catch (e) {
                            print('Error parsing date: $e');
                          }
                        }

                        final String timeAgoText = lastTransactionDate != null
                            ? _timeAgo(lastTransactionDate)
                            : 'No recent activity';

                        final Color balanceColor = clientBalance >= 0 ? Colors.green : Colors.red;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
            context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ClientManagementScreen(client: client),
                              ),
                            ).then((_) {
                              print(
                                'HomeContent: Returned from ClientManagementScreen. Refreshing clients...',
                              );
                              fetchClients();
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  clientName.isNotEmpty ? clientName[0].toUpperCase() : '',
                                  style: TextStyle(color: Colors.blue[800]),
                                ),
                              ),
                              title: Text(
                                clientName,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(timeAgoText),
                              trailing: Text(
                                '₹${clientBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: balanceColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddClientScreen(),
              ),
            ).then((_) => fetchClients());
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
            color: const Color.fromARGB(255, 121, 14, 86),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_box, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add New Client',
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
      ],
    );
  }

  Widget _buildBalanceCard(String title, String amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard(String title, double amount, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
