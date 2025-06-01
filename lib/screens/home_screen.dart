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
      appBar: AppBar(
        title: const Text('Cash In-Out'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddClientScreen(),
                    ),
                  );
                  if (result == true) {
                    _homeContentKey.currentState?.refreshClients();
                  }
                },

                tooltip: 'Add Client',
                child: const Icon(Icons.add),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  @override
  void initState() {
    super.initState();
    print('HomeContent: initState called');
    fetchClients();
  }

  Future<void> fetchClients() async {
    print('HomeContent: Starting fetchClients');
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      print('HomeContent: Making HTTP request');
      final response = await http.get(
        Uri.parse('http://10.0.2.2/backend/clients.php'),
      );
      print('HomeContent: Response status code: ${response.statusCode}');
      print('HomeContent: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('HomeContent: Decoded data: $data');

        if (data['success'] == true) {
          setState(() {
            clients = List<Map<String, dynamic>>.from(data['clients']);
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

  Future<void> refreshClients() async {
    await fetchClients();
  }

  @override
  Widget build(BuildContext context) {
    print(
      'HomeContent: Building widget. isLoading: $isLoading, error: $error, clients count: ${clients.length}',
    );
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : clients.isEmpty
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
                              (context) =>
                                  ClientManagementScreen(client: client),
                        ),
                      ).then((_) => fetchClients());
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
                          children: [Text('₹${client['balance'] ?? 0}')],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
