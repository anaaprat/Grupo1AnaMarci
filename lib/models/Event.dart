class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final String? image_url;
  final String category;
  final String? description; // Descripción del evento

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.image_url,
    required this.category,
    this.description,
  });
  factory Event.fromJson(Map<String, dynamic> json) {
    print('JSON received: $json'); 
    return Event(
      id: json['id'],
      title: json['title'] ?? 'Untitled Event',
      start_time: DateTime.parse(json['start_time']),
      image_url: json['image_url'],
      category: json['category'] ?? 'Uncategorized',
      description: json['description'],
    );
  }
}
