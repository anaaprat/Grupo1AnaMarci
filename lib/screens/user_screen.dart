import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  final String token; 

  const UserScreen(
      {super.key, required this.token});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Map<String, dynamic> _userData = {}; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'), 
      headers: {
        'Authorization': 'Bearer ${widget.token}', 
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

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
                  const Text(
                    'Esta es la pantalla de usuario',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text('Nombre: ${_userData['name']}'),
                  Text('Correo: ${_userData['email']}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Volver al Login'),
                  ),
                ],
              ),
      ),
    );
  }
}
