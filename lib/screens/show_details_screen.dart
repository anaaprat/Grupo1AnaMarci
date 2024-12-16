import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/Event.dart';

class ShowDetailsScreen extends StatefulWidget {
  final int eventId;
  final String token;
  final int userId;

  const ShowDetailsScreen({
    Key? key,
    required this.eventId,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  State<ShowDetailsScreen> createState() => _ShowDetailsScreenState();
}

class _ShowDetailsScreenState extends State<ShowDetailsScreen> {
  late Future<Event?> eventDetails;
  late Future<List<dynamic>> categories;
  late UserService userService;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    eventDetails = fetchEventDetails();
    categories = userService.getCategories();
  }

  Future<Event?> fetchEventDetails() async {
    try {
      final events = await userService.getUserEvents(widget.userId);
      final eventJson = events.firstWhere(
        (event) => event['id'] == widget.eventId,
        orElse: () => null,
      );
      if (eventJson == null) throw Exception('Evento no encontrado');
      return Event.fromJson(eventJson);
    } catch (e) {
      return null;
    }
  }

  String getCategoryName(int categoryId, List<dynamic> categoryList) {
    if (categoryId == 0) {
      return 'Sin categoría asignada';
    }

    final category = categoryList.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => null,
    );

    if (category == null) {
      print('No se encontró categoría para ID: $categoryId');
      return 'Categoría desconocida';
    }

    return category['name'] ?? 'Categoría desconocida';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Evento'),
      ),
      body: FutureBuilder<Event?>(
        future: eventDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text('No se encontraron detalles para este evento.'));
          }

          final event = snapshot.data!;
          return FutureBuilder<List<dynamic>>(
            future: categories,
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (categorySnapshot.hasError) {
                return Center(
                    child: Text(
                        'Error al cargar las categorías: ${categorySnapshot.error}'));
              } else if (!categorySnapshot.hasData) {
                return const Center(
                    child: Text('No se encontraron categorías.'));
              }

              final categoryList = categorySnapshot.data!;
              final categoryName =
                  getCategoryName(event.category_id!, categoryList);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Categoría: $categoryName',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ubicación: ${event.location ?? 'No especificada'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Inicio: ${event.start_time}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fin: ${event.end_time}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Descripción:',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description ?? 'Sin descripción',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Organizador ID: ${event.organizer_id}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
