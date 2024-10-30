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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _roleController.text = widget.currentRole;
  }

  Future<void> _updateUser() async {
    final response = await apiService.updateUser(
      widget.token,
      widget.userId,
      {'name': _nameController.text, 'role': _roleController.text},
    );

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado')),
      );
      Navigator.pop(context, true); // Devuelve "true" para indicar éxito
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Rol'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _updateUser,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
