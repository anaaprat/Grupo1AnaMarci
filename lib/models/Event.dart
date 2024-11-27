class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final String? image_url; // Campo opcional para la URL de la imagen
  final String category;
  final String? description; // Campo opcional para la descripción
  final String? location; // Campo opcional para la ubicación
  final DateTime? end_time; // Campo opcional para la hora de finalización
  final int? organizer_id; // Campo opcional para el ID del organizador
  final int? category_id; // Campo opcional para el ID de la categoría

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.image_url,
    required this.category,
    this.description,
    this.location,
    this.end_time,
    this.organizer_id,
    this.category_id,
  });

  // Constructor desde JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0, // Valor por defecto si falta el ID
      title: json['title'] ?? 'Untitled Event', // Valor por defecto para el título
      start_time: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      image_url: json['image_url'], // Puede ser null
      category: json['category'] ?? 'Uncategorized', // Categoría por defecto
      description: json['description'], // Puede ser null
      location: json['location'], // Puede ser null
      end_time: DateTime.tryParse(json['end_time'] ?? ''), // Puede ser null
      organizer_id: json['organizer_id'], // Puede ser null
      category_id: json['category_id'], // Puede ser null
    );
  }

  // Método para convertir un objeto Event a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': start_time.toIso8601String(),
      'image_url': image_url,
      'category': category,
      'description': description,
      'location': location,
      'end_time': end_time?.toIso8601String(),
      'organizer_id': organizer_id,
      'category_id': category_id,
    };
  }
}
