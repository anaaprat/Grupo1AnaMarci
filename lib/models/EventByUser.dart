class EventByUser {
  final int id;
  final String title;
  final String? description; // Opcional
  final int organizer_id; // ID del organizador
  final int category_id; // ID de la categoría
  final DateTime start_time; // Fecha y hora de inicio
  final DateTime? end_time; // Opcional, puede ser null
  final String? location; // Ubicación opcional

  EventByUser({
    required this.id,
    required this.title,
    this.description,
    required this.organizer_id,
    required this.category_id,
    required this.start_time,
    this.end_time,
    this.location,
  });

  // Factory para mapear un JSON al modelo EventByUser
  factory EventByUser.fromJson(Map<String, dynamic> json) {
    return EventByUser(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Event',
      description: json['description'],
      organizer_id: json['organizer_id'] ?? 0,
      category_id: json['category_id'] ?? 0,
      start_time: DateTime.parse(json['start_time']),
      end_time: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'],
    );
  }

  // Método para convertir el modelo EventByUser a un JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizer_id': organizer_id,
      'category_id': category_id,
      'start_time': start_time.toIso8601String(),
      'end_time': end_time?.toIso8601String(),
      'location': location,
    };
  }
}
