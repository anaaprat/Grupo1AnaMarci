import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';

class UserScreen extends StatefulWidget {
  final String token;  // Parámetro token

  const UserScreen({super.key, required this.token});  // Constructor que recibe el token

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Map<String, dynamic> _userData = {};  // Datos del usuario

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'), // Endpoint de ejemplo para el usuario
      headers: {
        'Authorization': 'Bearer ${widget.token}',  // Uso del token
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _userData = data['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos del usuario.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla de Usuario'),
      ),
      body: Center(
        child: _userData.isEmpty
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Nombre: ${_userData['name']}'),
                  Text('Correo: ${_userData['email']}'),
                ],
              ),
      ),
    );
  }
}
