import 'package:eventify/screens/editUser_screen.dart';
import 'package:eventify/screens/login_screen.dart';
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
      headers: {'Authorization': 'Bearer ${widget.token}'},
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
    final response = await http.post(
      Uri.parse('$baseUrl/activate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario activado.')),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al activar usuario.')),
      );
    }
  }

  Future<void> _deactivateUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deactivate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario desactivado.')),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar usuario.')),
      );
    }
  }

  Future<void> _deleteUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deleteUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado.')),
      );
      _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar usuario.')),
      );
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isActivated = user['actived'] ==
              true; // Asegúrate de que 'actived' esté bien definido.

          return Dismissible(
            key: ValueKey(user['id']),
            background: Container(
              color: isActivated ? Colors.orange : Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    isActivated ? Icons.block : Icons.check,
                    color: Colors.white,
                  ),
                  Text(
                    isActivated ? 'Desactivar' : 'Activar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Colors.white)),
                  SizedBox(width: 20),
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                isActivated
                    ? await _deactivateUser(user['id'])
                    : await _activateUser(user['id']);
              } else if (direction == DismissDirection.endToStart) {
                await showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Editar Usuario'),
                          onTap: () async {
                            Navigator.pop(context); // Cierra el modal
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditUserScreen(
                                  token: widget.token,
                                  userId: user['id'],
                                  currentName: user['name'],
                                  currentRole: user['role'],
                                ),
                              ),
                            );

                            if (result == true) {
                              _fetchUsers(); // Actualiza la lista de usuarios si la edición fue exitosa
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Eliminar Usuario'),
                          onTap: () async {
                            Navigator.pop(context);
                            await _deleteUser(user['id']);
                          },
                        ),
                      ],
                    );
                  },
                );
              }
              return false;
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user['imageUrl'] ??
                          'https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nombre: ${user['name']}'),
                        Text('Role: ${user['role']}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
