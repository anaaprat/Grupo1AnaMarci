import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditUserScreen extends StatefulWidget {
  final String token;
  final int userId;
  final String currentName;
  final String currentRole;

  const EditUserScreen({
    super.key,
    required this.token,
    required this.userId,
    required this.currentName,
    required this.currentRole,
  });

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  Future<void> _updateUser() async {
    final updatedName = _nameController.text;

    final response = await ApiService().updateUser(
      widget.token,
      widget.userId,
      {
        'name': updatedName,
      },
    );

    if (response['success'] == true) {
      Navigator.of(context)
          .pop(true); // Devuelve true si la actualización es exitosa
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit User')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
