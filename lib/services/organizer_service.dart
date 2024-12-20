import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eventify/models/Event.dart';
import '../api_constants.dart';

class OrganizerService {
  final String token;

  OrganizerService({required this.token});

  // Obtener eventos por organizador
  Future<List<dynamic>> getEventsByOrganizer(int organizer_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventsByOrganizer'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'id': organizer_id.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return responseData['data'];
      }
    }
    throw Exception('Error fetching events by organizer');
  }

  // Eliminar un evento
  Future<void> deleteEvent(int event_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventDelete'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id': event_id}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error deleting event: ${response.body}');
    }
  }

  // Crear un nuevo evento
  Future<void> createEvent({
    required int organizer_id,
    required String title,
    required String description,
    required int category_id,
    required String start_time,
    required String end_time,
    required String location,
    required double price,
    required String image_url,
  }) async {
    final url = Uri.parse('$baseUrl/events');
    final payload = {
      'organizer_id': organizer_id,
      'title': title,
      'description': description,
      'category_id': category_id,
      'start_time': start_time,
      'end_time': end_time,
      'location': location,
      'price': price,
      'image_url': image_url,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception('Failed to create event: ${responseBody['message']}');
      }
    } catch (e) {
      throw Exception('Error creating event: $e');
    }
  }

  /// Actualiza un evento existente
  Future<void> updateEvent(Event event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/eventUpdate'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar el evento. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar el evento');
    }
  }
}
