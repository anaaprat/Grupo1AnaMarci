// event_model.dart

class Event {
  final int id;
  final String title;
  final DateTime startTime;
  final String imageUrl;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.imageUrl,
    required this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      startTime: DateTime.parse(json['start_time']),
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  // Si necesitas otro constructor para diferentes formatos de JSON
  factory Event.fromOrganizerJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['name'], // Asumiendo que 'name' corresponde a 'title'
      startTime: DateTime.parse(json['date']), // Asumiendo que 'date' corresponde a 'start_time'
      imageUrl: json['image_url'] ?? '', // Manejar posibles valores nulos
      category: json['category'] ?? 'General', // Valor por defecto si es necesario
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'image_url': imageUrl,
      'category': category,
    };
  }
}
