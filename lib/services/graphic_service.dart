import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import 'package:eventify/models/Category.dart';
import 'package:eventify/models/Event.dart';

class GraphicService {
  final String token;

  GraphicService({required this.token});

  /// Obtiene las categorías disponibles
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return List<Category>.from(data.map((json) => Category.fromJson(json)));
    } else {
      throw Exception('Error fetching categories');
    }
  }

  /// Obtiene todos los eventos organizados por el organizador
  Future<List<Event>> fetchEventsByOrganizer(int organizerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventsByOrganizer'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'id': organizerId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return List<Event>.from(
            responseData['data'].map((json) => Event.fromJson(json)));
      }
    }
    throw Exception('Error fetching events by organizer');
  }

  /// Obtiene todos los eventos registrados por un usuario
  Future<List<Event>> fetchRegisteredEvents(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventsByUser'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Event>.from(
          jsonResponse['data'].map((json) => Event.fromJson(json)));
    } else {
      throw Exception('Failed to fetch events by user');
    }
  }

  /// Obtiene todos los usuarios
  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'] ?? [];
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  /// Cuenta los registros por evento organizado
  Future<Map<int, int>> fetchRegisteredCount(int organizerId) async {
    Map<int, int> data = {};
    final eventsOrg = await fetchEventsByOrganizer(organizerId);
    final eventsOrgId = eventsOrg.map((event) => event.id).toList();
    final users = await fetchUsers();

    for (var user in users) {
      final userId = user['id'].toString();
      final eventsUser = await fetchRegisteredEvents(userId);

      for (var event in eventsUser) {
        if (eventsOrgId.contains(event.id)) {
          data.update(event.id, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    return data;
  }

  /// Cuenta los registros por mes y categoría
  Future<Map<String, int>> fetchRegisteredCountByMonthAndCategory(
      int organizerId, String? category) async {
    final registeredCounts = await fetchRegisteredCount(organizerId);
    final events = await fetchEventsByOrganizer(organizerId);

    final filteredEvents = category != null
        ? events.where((event) => event.category_name == category).toList()
        : events;

    Map<String, int> data = {};
    final now = DateTime.now();
    final fourMonthsAgo = DateTime(now.year, now.month - 4, now.day);

    for (var event in filteredEvents) {
      if (registeredCounts.containsKey(event.id)) {
        final startTime = event.start_time;

        if (startTime.isAfter(fourMonthsAgo) && startTime.isBefore(now)) {
          String monthKey =
              "${startTime.year}-${startTime.month.toString().padLeft(2, '0')}";

          data.update(
            monthKey,
            (value) => value + registeredCounts[event.id]!,
            ifAbsent: () => registeredCounts[event.id]!,
          );
        }
      }
    }

    return data;
  }
}
