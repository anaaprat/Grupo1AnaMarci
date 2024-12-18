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
  late UserService userService;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    eventDetails = fetchEventDetails();
  }

  Future<Event?> fetchEventDetails() async {
    try {
      // Obtener eventos del usuario
      final events = await userService.getUserEvents(widget.userId);
      final eventJson = events.firstWhere(
        (event) => event['id'] == widget.eventId,
        orElse: () => null,
      );

      if (eventJson == null) throw Exception('Evento no encontrado');

      // Obtener la lista de categorías
      final fetchedCategories = await userService.getCategories();

      // Buscar el nombre de la categoría correspondiente al category_id
      final category_id = eventJson['category_id'];
      String category_name = 'Categoría no especificada';

      if (category_id != null) {
        final matchedCategory = fetchedCategories.firstWhere(
          (category) => category['id'] == category_id,
          orElse: () => null,
        );

        if (matchedCategory != null) {
          category_name = matchedCategory['name'];
        }
      }

      // Asignar el nombre de la categoría al evento
      eventJson['category'] = category_name;

      return Event.fromJson(eventJson);
    } catch (e) {
      print('Error fetching event details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      constraints:
          const BoxConstraints(maxHeight: 600), // Altura máxima del modal
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            FutureBuilder<Event?>(
              future: eventDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('No se encontraron detalles del evento');
                }

                final event = snapshot.data!;
                return Column(
                  children: [
                    // Imagen
                    event.image_url != null && event.image_url!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              event.image_url!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                                child: Icon(Icons.image, size: 60)),
                          ),

                    const SizedBox(height: 12),
                    // Título
                    Text(event.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),
                    Divider(color: Colors.deepPurpleAccent),

                    // Detalles del evento
                    _buildDetailRow(Icons.category, 'Category',
                        event.category_name ?? 'No especificada'),
                    _buildDetailRow(Icons.date_range, 'Start Time',
                        event.start_time.toString()),
                    _buildDetailRow(Icons.access_time, 'End Time',
                        event.end_time?.toString() ?? '---'),
                    _buildDetailRow(
                        Icons.location_on, 'Location', event.location ?? '---'),
                    _buildDetailRow(Icons.person, 'Organizer ID',
                        event.organizer_id.toString()),
                    _buildDetailRow(Icons.description, 'Description',
                        event.description ?? '---'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value ?? '---'}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
