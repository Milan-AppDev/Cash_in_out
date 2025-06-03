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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cash In-Out')),
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
  bool isLoading = true;
  String error = '';
  int? userId;
  double totalBalance = 0.0;
  double totalGot = 0.0;
  double totalGiven = 0.0;

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
        Uri.parse('http://10.0.2.2/backend_new/clients.php?user_id=$userId'),
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
        Uri.parse('http://10.0.2.2/backend_new/clients.php'),
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

  @override
  Widget build(BuildContext context) {
    print(
      'HomeContent: Building widget. isLoading: $isLoading, error: $error, clients count: ${clients.length}',
    );
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                children: [
                  Card(
                    color: Colors.blue[900],
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                margin: const EdgeInsets.all(16.0),
                                color: Colors.white,
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Balance',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(totalBalance),
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              totalBalance >= 0
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                  Expanded(
                    child:
                        clients.isEmpty
                            ? const Center(child: Text('No clients found'))
                            : ListView.builder(
                              itemCount: clients.length,
                              itemBuilder: (context, index) {
                                final client = clients[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ClientManagementScreen(
                                              client: client,
                                            ),
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
                                      title: Text(client['name'] ?? ''),
                                      subtitle: Text(client['phone'] ?? ''),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('₹${client['balance'] ?? 0}'),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed:
                                                () =>
                                                    deleteClient(client['id']),
                                          ),
                                        ],
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
                      margin: EdgeInsets.symmetric(
                        horizontal: 140,
                        vertical: 10,
                      ),
                      color: Colors.blue[900],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              "Add Client",
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
              ),
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
