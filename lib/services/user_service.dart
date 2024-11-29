import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../models/Event.dart'; 
import '../models/Category.dart'; 

class UserService {
  final String token;

  UserService({required this.token});

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
      throw Exception('Failed to load events');
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(
      String token, String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          final List users = data['data'];

          final user = users.firstWhere(
            (u) =>
                u['email']?.trim().toLowerCase() ==
                userEmail.trim().toLowerCase(),
            orElse: () => null,
          );

          if (user != null) {
            return user;
          } else {
            return null; 
          }
        } else {
          throw Exception('Estructura inesperada en la respuesta.');
        }
      } else {
        throw Exception(
            'Error al obtener datos de usuarios. Código: ${response.statusCode}');
      }
    } catch (e) {
      return null; 
    }
  }

  Future<Map<String, dynamic>> fetchEventsByUser(int userId) async {
    final String url = "$baseUrl/eventsByUser";
    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$url?id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error: $e',
      };
    }
  }

  Future<void> registerEvent(int userId, int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registerEvent'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'event_id': eventId,
        'registered_at': DateTime.now().toIso8601String(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      // Operación exitosa
    } else {
      throw Exception('Error: ${data['message'] ?? 'Unexpected error'}');
    }
  }

  Future<void> unregisterEvent(int userId, int eventId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/unregisterEvent'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'event_id': eventId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      // Operación exitosa
    } else {
      throw Exception('Error: ${data['message'] ?? 'Unexpected error'}');
    }
  }
}
