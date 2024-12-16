class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final DateTime? end_time;
  final String? image_url;
  final String? category; 
  final int? category_id; 
  final int? organizer_id;
  final String? description;
  final String? location;

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.end_time,
    this.image_url,
    this.category,
    this.category_id,
    this.organizer_id,
    this.description,
    this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Event',
      start_time: DateTime.parse(json['start_time']),
      end_time:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      image_url: json['image_url'],
      category: json['category'], 
      category_id:
          json['category_id'], 
      organizer_id: json['organizer_id'] ?? 0,
      description: json['description'],
      location: json['location'],
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, start_time: $start_time, end_time: $end_time, '
        'image_url: $image_url, category: $category, category_id: $category_id, '
        'organizer_id: $organizer_id, description: $description, location: $location}';
  }
}
