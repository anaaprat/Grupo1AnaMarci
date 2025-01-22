import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Event.dart';
import '../api_constants.dart';

class UserService {
  final String token;

  UserService({required this.token});

  // Método genérico para obtener datos de la API
  Future<dynamic> _fetchData(String endpoint,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    final response = body == null
        ? await http.get(uri, headers: headers)
        : await http.post(uri, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true) {
        return decoded['data'];
      } else {
        throw Exception('Error: ${decoded['message']}');
      }
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  // Obtener todas las categorías
  Future<List<dynamic>> getCategories() async {
    final data = await _fetchData('categories');
    return data is List ? data : [];
  }

  // Obtener todos los eventos
  Future<List<dynamic>> getAllEvents() async {
    final data = await _fetchData('events');
    return data is List ? data : [];
  }

  Future<List<Event>> getAllEventsMap() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'), // Reemplaza con tu URL real
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body) as Map<String, dynamic>;
      final eventList = responseBody['data'] as List<dynamic>;
      return eventList
          .map((event) => Event.fromJson(event as Map<String, dynamic>))
          .toList();
    } else {
      print('Error: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Error al obtener los eventos: ${response.statusCode}');
    }
  }

  // Obtener eventos por usuario
  Future<List<dynamic>> getUserEvents(int userId) async {
    final data = await _fetchData('eventsByUser', body: {'id': userId});
    return data is List ? data : [];
  }

  // Registrar un evento
  Future<bool> registerEvent(int userId, int eventId) async {
    final response = await _fetchData(
      'registerEvent',
      body: {
        'user_id': userId,
        'event_id': eventId,
        'registered_at': DateTime.now().toIso8601String(),
      },
    );
    return response is Map &&
        response.containsKey('user_id') &&
        response.containsKey('event_id');
  }

  // Desregistrar de un evento
  Future<bool> unregisterEvent(int userId, int eventId) async {
    final response = await _fetchData('unregisterEvent',
        body: {'user_id': userId, 'event_id': eventId});
    return response is Map &&
        response.containsKey('user_id') &&
        response.containsKey('event_id');
  }

  // Obtener todos los usuarios
  Future<List<dynamic>> getAllUsers() async {
    final data = await _fetchData('users');
    return data is List ? data : [];
  }
}
