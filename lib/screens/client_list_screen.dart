import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';

class ClientListScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;

  const ClientListScreen({
    Key? key,
    required this.baseUrl,
    required this.userId,
  }) : super(key: key);

  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late Future<List<Client>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = fetchClients();
  }

  Future<List<Client>> fetchClients() async {
    final response = await http.get(
      Uri.parse('${widget.baseUrl}/get_clients.php?user_id=\${widget.userId}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final clientsJson = data['clients'] as List;
        return clientsJson.map((json) => Client.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load clients');
      }
    } else {
      throw Exception('Failed to load clients');
    }
  }

  Future<void> _addOrEditClient({Client? client}) async {
    final nameController = TextEditingController(text: client?.name ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(
      text: client?.address ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(client == null ? 'Add Client' : 'Edit Client'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save'),
              ),
            ],
          ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final address = addressController.text.trim();

      if (name.isEmpty || phone.isEmpty || address.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('All fields are required')));
        return;
      }

      if (client == null) {
        await _addClient(name, phone, address);
      } else {
        await _editClient(client.id, name, phone, address);
      }

      setState(() {
        _clientsFuture = fetchClients();
      });
    }
  }

  Future<void> _addClient(String name, String phone, String address) async {
    final response = await http.post(
      Uri.parse('${widget.baseUrl}/add_client.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'name': name,
        'phone': phone,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body);
    if (!data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add client: \${data["message"]}')),
      );
    }
  }

  Future<void> _editClient(
    int clientId,
    String name,
    String phone,
    String address,
  ) async {
    final response = await http.post(
      Uri.parse('${widget.baseUrl}/edit_client.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': clientId,
        'name': name,
        'phone': phone,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body);
    if (!data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update client: \${data["message"]}')),
      );
    }
  }

  Future<void> _deleteClient(int clientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Client'),
            content: Text('Are you sure you want to delete this client?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/delete_client.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'client_id': clientId}),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _clientsFuture = fetchClients();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete client: \${data["message"]}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clients'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addOrEditClient(),
          ),
        ],
      ),
      body: FutureBuilder<List<Client>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading clients: \${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No clients found.'));
          } else {
            final clients = snapshot.data!;
            return ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  title: Text(client.name),
                  subtitle: Text(client.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _addOrEditClient(client: client),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteClient(client.id),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
