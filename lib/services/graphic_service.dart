import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class GraphicService {
  final String token;

  GraphicService({required this.token});

  Future<Map<String, int>> fetchRegisteredUsersByCategory(
      int organizerId, int categoryId) async {
    // Obtener dinámicamente los últimos 4 meses
    final now = DateTime.now();
    final List<String> lastFourMonths = List.generate(4, (index) {
      int month = now.month - index; // Restar meses (sin incluir el actual)
      int year = now.year;

      if (month <= 0) {
        // Ajustar si el mes es menor que 1
        month += 12;
        year--;
      }
      return getMonthName(month);
    }).reversed.toList(); // Invertir para obtener orden cronológico

    // Inicializar el mapa para los últimos 4 meses
    final Map<String, int> monthlyCount = {
      for (var month in lastFourMonths) month: 0,
    };

    try {
      // Llamada para obtener los eventos del organizador
      final organizerResponse = await http.post(
        Uri.parse('$baseUrl/eventsByOrganizer'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'id': organizerId.toString()},
      );

      if (organizerResponse.statusCode != 200) {
        throw Exception('Error fetching organizer events');
      }

      final events = jsonDecode(organizerResponse.body)['data'];

      // Filtrar eventos por categoría seleccionada
      final filteredEvents = events.where((event) =>
          event['category_id'] == categoryId && event['start_time'] != null);

      // Obtener usuarios registrados en esos eventos
      for (var event in filteredEvents) {
        final userResponse = await http.post(
          Uri.parse('$baseUrl/eventsByUser'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: {'id': event['id'].toString()},
        );

        if (userResponse.statusCode == 200) {
          final users = jsonDecode(userResponse.body)['data'];
          DateTime startTime = DateTime.parse(event['start_time']);

          String monthName = getMonthName(startTime.month);
          if (monthlyCount.containsKey(monthName)) {
            monthlyCount[monthName] =
                (monthlyCount[monthName] ?? 0) + (users.length as int);
          }
        }
      }

      return monthlyCount;
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

// Función auxiliar para obtener el nombre del mes
  String getMonthName(int month) {
    const List<String> months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }
}
