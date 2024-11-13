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
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _users = data['data'].map((userJson) {
          userJson['actived'] = userJson['actived'] == 1;
          return userJson;
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users.')),
      );
    }
  }

  Future<void> _changeUserStatus(int userId, bool isActivated) async {
    final endpoint = isActivated ? '/activate' : '/deactivate';
    final actionMessage = isActivated ? 'activated' : 'deactivated';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': userId}),
      );

      final responseBody = jsonDecode(response.body);

      if (responseBody['success']) {
        setState(() {
          final userIndex = _users.indexWhere((user) => user['id'] == userId);
          if (userIndex != -1) {
            _users[userIndex]['actived'] = isActivated;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $actionMessage successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseBody['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deleteUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': userId}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted.')),
        );
        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${responseBody['message'] ?? 'Could not delete user.'}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: ${e.toString()}')),
      );
    }
  }

  String _getRoleName(String role) {
    return role == 'u' ? 'User' : 'Organizer';
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wait'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Confirm logout
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmLogout,
        ),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];

          return Dismissible(
            key: ValueKey(user['id']),
            background: Container(
              color: user['actived'] ? Colors.orange : Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    user['actived'] ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user['actived'] ? 'Deactivate' : 'Activate',
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
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                          'Are you sure you want to delete this user?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                return confirmed ?? false;
              } else if (direction == DismissDirection.startToEnd) {
                await _changeUserStatus(user['id'], !user['actived']);
                return false;
              }
              return false;
            },
            onDismissed: (direction) async {
              if (direction == DismissDirection.endToStart) {
                await _deleteUser(user['id']);
              }
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${user['name']}'),
                          Text(
                              'Role: ${_getRoleName(user['role'])}'), // Mostrar rol completo
                          Text(
                              'Status: ${user['actived'] ? 'Activated' : 'Deactivated'}'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
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
                          _fetchUsers(); // Refresca la lista de usuarios tras la actualización
                        }
                      },
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
