class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final String? image_url;
  final String category;
  final String? description; // Campo opcional para la descripción del evento
  final String? location; // Campo opcional para la ubicación del evento

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.image_url,
    required this.category,
    this.description,
    this.location,
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
    };
  }
}
