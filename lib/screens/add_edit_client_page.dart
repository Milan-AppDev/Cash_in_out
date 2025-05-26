import 'package:flutter/material.dart';
import '../models/client.dart';

class AddEditClientPage extends StatefulWidget {
  final Client? client;

  AddEditClientPage({this.client});

  @override
  _AddEditClientPageState createState() => _AddEditClientPageState();
}

class _AddEditClientPageState extends State<AddEditClientPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.client?.name ?? '');
    phoneController = TextEditingController(text: widget.client?.phone ?? '');
    addressController = TextEditingController(
      text: widget.client?.address ?? '',
    );
  }

  void saveClient() {
    if (_formKey.currentState!.validate()) {
      final client = Client(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
      );
      Navigator.pop(context, client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'Add Client'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField('Client Name', nameController, TextInputType.name),
              SizedBox(height: 16),
              buildField('Phone Number', phoneController, TextInputType.phone),
              SizedBox(height: 16),
              buildField(
                'Address',
                addressController,
                TextInputType.streetAddress,
                maxLines: 3,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Client' : 'Add Client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller,
    TextInputType type, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      decoration: InputDecoration(labelText: label),
    );
  }
}
