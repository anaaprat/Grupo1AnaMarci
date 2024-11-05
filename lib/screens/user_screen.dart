import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  final String token;

  const UserScreen({super.key, required this.token});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic> _userData = {};
  List<dynamic> _events = [];
  bool _isEventsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchEvents(); // Llamamos a la función para obtener eventos al iniciar la pantalla
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
      );

      print("HTTP status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          setState(() {
            _userData = data['data'];
          });
          print("Datos del usuario: $_userData");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron datos del usuario.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos del usuario. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos del usuario.')),
      );
    }
  }

  Future<void> _fetchEvents() async {
    // Llama al método fetchEvents en ApiService para obtener la lista de eventos
    final events = await apiService.fetchEvents(widget.token);
    setState(() {
      _events = events ?? [];
      _isEventsLoading = false;
    });
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
                  Text('Nombre: ${_userData['name'] ?? 'No disponible'}'),
                  Text('Correo: ${_userData['email'] ?? 'No disponible'}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Volver al Login'),
                  ),
                  const SizedBox(height: 20),
                  // Sección para mostrar la lista de eventos
                  const Text(
                    'Eventos Disponibles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _isEventsLoading
                      ? const CircularProgressIndicator()
                      : _events.isEmpty
                          ? const Text('No hay eventos disponibles.')
                          : Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  final event = _events[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(
                                      title: Text(event['title']),
                                      subtitle: Text(
                                        'Categoría: ${event['category']}\nFecha: ${event['start_time']}',
                                      ),
                                      leading: event['image_url'] != null
                                          ? Image.network(event['image_url'])
                                          : const Icon(Icons.event),
                                    ),
                                  );
                                },
                              ),
                            ),
                ],
              ),
      ),
    );
  }
}
