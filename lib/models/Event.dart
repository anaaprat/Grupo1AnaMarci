class Event {
  final int id;
  final String title;
  final DateTime start_time;
  final DateTime? end_time;
  final String? image_url;
  final String? category;
  final String? category_name;
  final int? category_id;
  final int? organizer_id;
  final double? latitude;
  final double? longitude;
  final int? max_atendees;
  final String? description;
  final String? location;
  final int? price;
  final int? deleted;

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.end_time,
    this.image_url,
    this.category,
    this.category_name,
    this.category_id,
    this.organizer_id,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.max_atendees,
    this.price,
    this.deleted,
  });

factory Event.fromJson(Map<String, dynamic> json) {
  return Event(
    id: json['id'] ?? 0,
    title: json['title'] ?? 'No title',
    start_time: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
    end_time: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
    description: json['description'] ?? 'No description',
    category_id: json['category_id'] ?? 0,
    organizer_id: json['organizer_id'] ?? 0,
    category: json['category'] ?? 'General',
    category_name: json['category_name'] ?? 'General',
    location: json['location'] ?? 'No location',
    latitude: json['latitude'] != null ? json['latitude'].toDouble() : null, // Convertir a double
    longitude: json['longitude'] != null ? json['longitude'].toDouble() : null, // Convertir a double
    max_atendees: json['max_atendees'] ?? 0,
    price: json['price'] != null ? (json['price'] as num).toInt() : 0, // Asegurar tipo int
    image_url: json['image_url']?.isNotEmpty == true ? json['image_url'] : null,
    deleted: json['deleted'] ?? 0,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': start_time.toIso8601String(),
      'end_time': end_time?.toIso8601String(),
      'description': description,
      'category_id': category_id,
      'organizer_id': organizer_id,
      'category': category,
      'category_name': category_name,
      'location': location,
      'latitude': null, // Opcional
      'longitude': null, // Opcional
      'max_attendees': null, // Opcional
      'price': price,
      'image_url': image_url,
      'deleted': deleted,
    };
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, start_time: $start_time, end_time: $end_time, image_url: $image_url, category: $category, category_id: $category_id, category_name: $category_name, organizer_id: $organizer_id, description: $description, location: $location, latitude: $latitude, longitude: $longitude, max_atendees: $max_atendees, price: $price, deleted: $deleted}';
  }
}
