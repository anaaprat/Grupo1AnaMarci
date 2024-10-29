import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';

class AdminScreen extends StatefulWidget {
  final String token;

  const AdminScreen({super.key, required this.token});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer ${widget.token}'}, // Utiliza el token de sesión
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _users = data['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar usuarios.')),
      );
    }
  }

  Future<void> _activateUser(int userId) async {
    await _changeUserStatus(userId, '/activate', 'Usuario activado');
  }

  Future<void> _deactivateUser(int userId) async {
    await _changeUserStatus(userId, '/deactivate', 'Usuario desactivado');
  }

  Future<void> _deleteUser(int userId) async {
    await _changeUserStatus(userId, '/deleteUser', 'Usuario eliminado');
  }

  Future<void> _changeUserStatus(int userId, String endpoint, String successMessage) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Authorization': 'Bearer ${widget.token}'}, // Utiliza el token de sesión
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      _fetchUsers(); // Recarga la lista de usuarios
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar el estado del usuario.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nombre: ${user['name']}'),
                  Text('Role: ${user['role']}'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _activateUser(user['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // Cambiado a backgroundColor
                        child: const Text('Activar'),
                      ),
                      ElevatedButton(
                        onPressed: () => _deactivateUser(user['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), // Cambiado a backgroundColor
                        child: const Text('Desactivar'),
                      ),
                      ElevatedButton(
                        onPressed: () => _deleteUser(user['id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Cambiado a backgroundColor
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
