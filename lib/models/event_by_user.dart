class EventByUser {
  final int id;
  final String title;
  final String? description;
  final int organizer_id;
  final int category_id;
  final DateTime start_time;
  final DateTime? end_time;
  final String? location;

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

  factory EventByUser.fromJson(Map<String, dynamic> json) {
    return EventByUser(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Evento sin título',
      description: json['description'],
      organizer_id: json['organizer_id'] ?? 0,
      category_id: json['category_id'] ?? 0,
      start_time: DateTime.parse(json['start_time']),
      end_time: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'],
    );
  }
}
