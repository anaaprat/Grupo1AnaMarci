import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';

class OrganizerScreen extends StatefulWidget {
  final String token; 

  const OrganizerScreen(
      {super.key, required this.token}); 

  @override
  _OrganizerScreenState createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends State<OrganizerScreen> {
  List<dynamic> _events = [];
  @override
  void initState() {
    super.initState();
    _fetchOrganizerData();
  }

  Future<void> _fetchOrganizerData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/organizer/events'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _events = data['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos del organizador.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Organizador'),
      ),
      body: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return ListTile(
            title: Text(event['name']),
            subtitle: Text('Fecha: ${event['date']}'),
          );
        },
      ),
    );
  }
}
