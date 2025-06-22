import 'package:cash/screens/add_clients.dart';
import 'package:cash/screens/client_management.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cash/model/client_model.dart'; // Import the centralized Client model
import 'package:cash/screens/profile_screen.dart'; // NEW: Import the ProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Global balance data, fetched from API
  double _totalBalance = 0.00;
  double _youWillGet = 0.00;
  double _youWillGive = 0.00;

  // For currency formatting (Indian Rupee)
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN', // Indian locale
    symbol: '₹', // Indian Rupee symbol
    decimalDigits: 2,
  );

  String _searchQuery = '';
  String _sortBy = 'name_asc'; // Default sort by name A-Z
  int _selectedIndex = 0; // For Bottom Navigation Bar

  List<Client> _allClients = [];
  bool _isClientsLoading = true; // Loading state for clients list
  bool _isGlobalBalancesLoading = true; // Loading state for global balances

  // IMPORTANT: Replace with your actual API URL
  static const String _apiBaseUrl = 'http://localhost/api'; // For Android Emulator
  // Consider using HTTPS in production!

  @override
  void initState() {
    super.initState();
    _fetchGlobalBalances(); // Fetch global balances
    _fetchClients(); // Fetch individual clients
  }

  // Function to fetch global balances from the backend API
  Future<void> _fetchGlobalBalances() async {
    setState(() {
      _isGlobalBalancesLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/get_global_balances.php'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (mounted) {
          if (responseData['success']) {
            setState(() {
              _youWillGet = responseData['total_got'];
              _youWillGive = responseData['total_given'];
              _totalBalance = responseData['total_balance'];
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to fetch global balances: ${responseData['message']}')),
            );
            // Reset balances on error
            setState(() {
              _youWillGet = 0.0;
              _youWillGive = 0.0;
              _totalBalance = 0.0;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error fetching global balances: ${response.statusCode}')),
          );
        }
        // Reset balances on error
        setState(() {
          _youWillGet = 0.0;
          _youWillGive = 0.0;
          _totalBalance = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error fetching global balances: $e')),
        );
      }
      // Reset balances on error
      setState(() {
        _youWillGet = 0.0;
        _youWillGive = 0.0;
        _totalBalance = 0.0;
      });
    } finally {
      setState(() {
        _isGlobalBalancesLoading = false;
      });
    }
  }

  // Function to fetch clients from the backend API
  Future<void> _fetchClients() async {
    setState(() {
      _isClientsLoading = true; // Show loading indicator
    });

    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/get_clients.php'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (mounted) {
          if (responseData['success']) {
            final List<dynamic> clientJsonList = responseData['clients'];
            setState(() {
              _allClients = clientJsonList.map((json) => Client.fromJson(json)).toList();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to fetch clients: ${responseData['message']}')),
            );
            _allClients = []; // Clear list on error
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error fetching clients: ${response.statusCode}')),
          );
        }
        _allClients = []; // Clear list on error
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error fetching clients: $e')),
        );
      }
      _allClients = []; // Clear list on error
    } finally {
      setState(() {
        _isClientsLoading = false; // Hide loading indicator
      });
    }
  }


  List<Client> get _filteredAndSortedClients {
    List<Client> clients = _allClients.where((client) {
      final nameLower = client.name.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || client.mobileNumber.contains(queryLower); // Search by name or mobile
    }).toList();

    // Sort clients based on selected option
    switch (_sortBy) {
      case 'name_asc':
        clients.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        clients.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'amount_high':
        clients.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_low':
        clients.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return clients;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Implement actual navigation for other tabs here
    if (index == 1) { // Reports Tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports Screen Coming Soon!')),
      );
    } else if (index == 2) { // Profile Tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen(userId: '1',)), // Navigate to ProfileScreen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Very light grey/off-white background
      extendBody: true, // This is key to allow the FAB and BottomNavBar to float above body content
      appBar: AppBar(
        title: const Text('Cash In-Out', style: TextStyle(color: Color(0xFF333333), fontSize: 20)), // Font size for app bar title
        backgroundColor: const Color(0xFFF0F0F0), // Same as background for seamless look
        foregroundColor: const Color(0xFF333333), // Dark icons/text on app bar
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea( // Use SafeArea to avoid status bar overlap
        child: Column( // Use Column for fixed header and scrollable body
          children: [
            // --- Total Balance Section ---
            Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners
                color: const Color(0xFF2C2C2C), // Dark grey card background for balance
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0), // Reduced vertical padding
                  child: _isGlobalBalancesLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF8BC34A))) // Light green loading for balance
                      : Column(
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                fontSize: 20, // Slightly reduced font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white70, // Lighter text color for dark background
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced spacing
                            Text(
                              _currencyFormat.format(_totalBalance),
                              style: TextStyle(
                                fontSize: 34, // Slightly reduced font size
                                fontWeight: FontWeight.bold,
                                color: (_totalBalance >= 0 ? const Color(0xFF8BC34A) : const Color(0xFFFF7043)), // Dynamic green/orange accent
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // --- Get Money / Give Money Cards ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // Reduced padding
              child: _isGlobalBalancesLoading
                  ? Row(
                      children: [
                        Expanded(child: Center(child: CircularProgressIndicator(color: const Color(0xFF8BC34A)))), // Green loader
                        SizedBox(width: 10),
                        Expanded(child: Center(child: CircularProgressIndicator(color: const Color(0xFFFF7043)))), // Orange loader
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildMoneyCard(
                            context,
                            title: 'You Will Get',
                            amount: _youWillGet,
                            cardColor: Colors.white, // White background for card
                            amountColor: const Color(0xFF8BC34A), // Green for text/icon
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 10), // Reduced spacing
                        Expanded(
                          child: _buildMoneyCard(
                            context,
                            title: 'You Will Give',
                            amount: _youWillGive,
                            cardColor: Colors.white, // White background for card
                            amountColor: const Color(0xFFFF7043), // Orange for text/icon
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20), // Reduced spacing

            // --- Search Bar and Sort Option ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // Reduced padding
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 16), // Font size
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 20), // Icon size
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white, // White text field background
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // Compact padding
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2), // Accent color on focus
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          borderSide: BorderSide.none,
                        ),
                        isDense: true, // Make input more compact
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Reduced spacing
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // White button background
                      borderRadius: BorderRadius.circular(10.0), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.sort, color: Color(0xFF666666), size: 20), // Icon size
                      color: Colors.white, // White popup menu background
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners for popup menu
                      onSelected: (String result) {
                        setState(() {
                          _sortBy = result;
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'name_asc',
                          child: Text('Name (A-Z)', style: TextStyle(color: Color(0xFF333333), fontSize: 15)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'name_desc',
                          child: Text('Name (Z-A)', style: TextStyle(color: Color(0xFF333333), fontSize: 15)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'amount_high',
                          child: Text('Amount (High to Low)', style: TextStyle(color: Color(0xFF333333), fontSize: 15)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'amount_low',
                          child: Text('Amount (Low to High)', style: TextStyle(color: Color(0xFF333333), fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Reduced spacing

            // --- Client Information Display (Scrollable) ---
            Expanded( // This makes the client list take all available space and enables its own scrolling
              child: RefreshIndicator( // RefreshIndicator wrapped around the scrollable list
                onRefresh: () async {
                  await _fetchGlobalBalances(); // Refresh global balances
                  await _fetchClients();        // Refresh client list
                },
                color: const Color(0xFFFF7043), // Accent color for refresh indicator
                child: _isClientsLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF7043)), // Accent color
                      )
                    : _filteredAndSortedClients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 70, // Slightly reduced icon size
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No clients found',
                                  style: TextStyle(
                                    fontSize: 18, // Slightly reduced font size
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add your first client to get started',
                                  style: TextStyle(
                                    fontSize: 14, // Slightly reduced font size
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder( // Use ListView.builder for efficient scrolling
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // Reduced padding
                            itemCount: _filteredAndSortedClients.length,
                            itemBuilder: (context, index) {
                              final client = _filteredAndSortedClients[index];
                              return _buildClientListItem(context, client);
                            },
                          ),
              ),
            ),
            // The FAB padding should now be part of the Scaffold's bottom padding itself
            // or handled by the bottomNavigationBar padding if it's placed there.
            // No explicit SliverToBoxAdapter for padding is needed here anymore.
          ],
        ),
      ),
      bottomNavigationBar: Padding( // Add padding around the bottom navigation bar to make it "float"
        padding: const EdgeInsets.all(12.0), // Adjusted padding
        child: ClipRRect( // Apply ClipRRect to round all corners of the bottom bar
          borderRadius: BorderRadius.circular(18.0), // Adjusted radius
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: const Color(0xFFFF7043), // Accent color for selected icon
            unselectedItemColor: const Color(0xFF666666), // Dark grey for unselected
            backgroundColor: Colors.white, // White bottom nav bar
            elevation: 10,
            type: BottomNavigationBarType.fixed, // Ensures all labels are visible
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), // Font size
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11), // Font size
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled, size: 24), // Icon size
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded, size: 24), // Icon size
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 24), // Icon size
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      // Custom positioned button for "Add New Client"
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positions it on the right
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12.0, bottom: 12.0), // Adjusted padding
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddClientScreen()),
            );
            if (result == true) {
              // Refresh both global balances and client list after adding a new client
              _fetchGlobalBalances();
              _fetchClients();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7043), // Distinct accent color
            foregroundColor: Colors.white, // White text on accent button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Adjusted rounded corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Compact padding
            elevation: 8,
            minimumSize: const Size(160, 45), // Ensure it's a "medium box"
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min, // Make row only as wide as its children
            children: [
              Icon(Icons.add, size: 24), // Adjusted icon size
              SizedBox(width: 6), // Reduced spacing
              Text(
                'Add Client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Adjusted font size
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the "You Will Get" and "You Will Give" cards
  Widget _buildMoneyCard(BuildContext context, {
    required String title,
    required double amount,
    required Color cardColor, // New parameter for card background color
    required Color amountColor, // New parameter for amount text color
    required IconData icon,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners
      color: cardColor, // Use the specific background color
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0), // Reduced padding
        child: Column(
          children: [
            Icon(icon, color: amountColor, size: 28), // Adjusted icon size
            const SizedBox(height: 6), // Reduced spacing
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14, // Slightly reduced font size
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666), // Darker grey for text on light background
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              _currencyFormat.format(amount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, // Slightly reduced font size
                fontWeight: FontWeight.bold,
                color: amountColor, // Use the specific amount color
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a client information card (updated for new light mode)
  Widget _buildClientListItem(BuildContext context, Client client) {
    Color amountColor = client.amount >= 0 ? const Color(0xFF8BC34A) : const Color(0xFFFF7043);
    String amountPrefix = client.amount >= 0 ? 'Gets:' : 'Gives:';
    // NEW: Dynamic background color for the client card
    Color cardBackgroundColor = client.amount >= 0 ? Colors.green.shade50 : Colors.red.shade50;


    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6.0), // Reduced margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Adjusted rounded corners
      color: cardBackgroundColor, // Apply dynamic background color
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0), // Compact padding
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0E0E0), // Light grey avatar background
          radius: 26, // Slightly reduced radius
          child: Text(
            client.name[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 18, // Adjusted font size
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333), // Dark text for avatar
            ),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16, // Adjusted font size
            color: Color(0xFF333333), // Dark text for title
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3), // Reduced spacing
            Text(
              client.mobileNumber, // Display mobile number
              style: const TextStyle(
                fontSize: 13, // Adjusted font size
                color: Color(0xFF666666), // Medium grey for subtitle
              ),
            ),
            const SizedBox(height: 3), // Reduced spacing
            Text(
              'Last activity: ${client.lastTransactionDate}',
              style: const TextStyle(
                fontSize: 12, // Adjusted font size
                color: Color(0xFF999999), // Light grey for last activity
              ),
            ),
            const SizedBox(height: 3), // Reduced spacing
            Text(
              '$amountPrefix ${_currencyFormat.format(client.amount.abs())}', // Show absolute value with prefix
              style: TextStyle(
                fontSize: 14, // Adjusted font size
                fontWeight: FontWeight.w600,
                color: amountColor, // Dynamic color based on amount
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)), // Adjusted icon size
        onTap: () {
          // Navigate to ClientDetailScreen when a client is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientDetailScreen(client: client),
            ),
          );
        },
      ),
    );
  }
}
