import 'package:cash_in_out/screens/config.dart';
import 'package:flutter/material.dart';
import '../models/client.dart';
import 'add_edit_client_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientListPage extends StatefulWidget {
  @override
  _ClientListPageState createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<Client> clients = [];

  Future<void> fetchClientsFromBackend() async {
    final response = await http.get(Uri.parse(AppConfig.clientsEndpoint));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          clients = List<Client>.from(
            data['data'].map((c) => Client.fromJson(c)),
          );
        });
      }
    }
  }

  Future<void> addClient(Client client) async {
    final response = await http.post(
      Uri.parse(AppConfig.clientsEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(client.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          clients.add(
            Client(
              id: data['id'],
              name: client.name,
              phone: client.phone,
              address: client.address,
            ),
          );
        });
      }
    }
  }

  Future<void> editClient(int index, Client client) async {
    final response = await http.put(
      Uri.parse(AppConfig.clientsEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(client.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          clients[index] = client;
        });
      }
    }
  }

  Future<void> deleteClient(int index) async {
    final clientId = clients[index].id;
    final response = await http.delete(
      Uri.parse('${AppConfig.clientsEndpoint}?id=$clientId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          clients.removeAt(index);
        });
      }
    }
  }

  void navigateToAddClient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditClientPage()),
    );
    if (result != null) addClient(result);
  }

  void navigateToEditClient(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditClientPage(client: clients[index]),
      ),
    );
    if (result != null) editClient(index, result);
  }

  @override
  void initState() {
    super.initState();
    fetchClientsFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Client Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body:
          clients.isEmpty
              ? Center(
                child: Text(
                  'No clients added yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    elevation: 4,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.only(bottom: 14),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        client.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${client.phone}\n${client.address}',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.teal[600]),
                            onPressed: () => navigateToEditClient(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[400]),
                            onPressed: () => deleteClient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddClient,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
