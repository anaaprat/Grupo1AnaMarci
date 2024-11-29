class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final String? image_url; 
  final String category;
  final String? description;
  final String? location; 
  final DateTime? end_time; 
  final int? organizer_id; 
  final int? category_id; 

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

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Event', 
      start_time: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      image_url: json['image_url'], 
      category: json['category'] ?? 'Uncategorized', 
      description: json['description'], 
      location: json['location'], 
      end_time: DateTime.tryParse(json['end_time'] ?? ''), 
      organizer_id: json['organizer_id'], 
      category_id: json['category_id'], 
    );
  }

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
