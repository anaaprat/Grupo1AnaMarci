import 'package:eventify/services/admin_service.dart';
import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final String token;
  final int userId;
  final String currentName;

  const EditUserScreen({
    super.key,
    required this.token,
    required this.userId,
    required this.currentName,
  });

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;
  late AdminService adminService;

  @override
  void initState() {
    super.initState();
    adminService = AdminService(token: widget.token); 
    _nameController = TextEditingController(
        text: widget.currentName); 
  }

  Future<void> _onUpdatePressed() async {
    final updatedName = _nameController.text;

    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      final response =
          await adminService.updateUser(widget.userId, updatedName);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.of(context).pop(true); 
      } else {
        throw Exception(response['message'] ?? 'Failed to update user.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onUpdatePressed, 
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
