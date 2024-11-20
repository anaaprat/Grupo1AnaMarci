import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../models/Event.dart'; // Importa el modelo de eventos
import '../models/Category.dart'; // Importa el modelo de categorías

class UserService {
  final String token;

  UserService({required this.token});

  // Método para obtener categorías y devolver una lista de objetos `Category`
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Método para obtener eventos y devolver una lista de objetos `Event`
  Future<List<Event>> fetchEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Event>.from(data['data'].map((json) => Event.fromJson(json)));
    } else {
      print("Failed to load events. Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception('Failed to load events');
    }
  }

  Future<Map<String, dynamic>> registerEvent({
    required int userId,
    required int eventId,
    required DateTime registeredAt,
  }) async {
    final url = Uri.parse('$baseUrl/registerEvent');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'event_id': eventId,
        'registered_at': registeredAt.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to register event. Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception('Failed to register event');
    }
  }

  Future<Map<String, dynamic>> unregisterEvent({
    required int userId,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/unregisterEvent');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'event_id': eventId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to unregister event. Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception('Failed to unregister event');
    }
  }
}
