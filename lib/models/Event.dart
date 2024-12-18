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
    this.price,
    this.deleted,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No title',
      start_time: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      end_time:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      description: json['description'] ?? 'No description',
      category_id: json['category_id'] ?? 0,
      organizer_id: json['organizer_id'] ?? 0,
      category: json['category'] ?? 'General',
      category_name: json['category_name'] ?? 'General',
      location: json['location'] ?? 'No location',
      price: json['price'] != null ? int.tryParse(json['price'].toString()) : 0,
      image_url: json['image_url'],
      deleted: json['deleted'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, start_time: $start_time, end_time: $end_time, image_url: $image_url, category: $category, category_id: $category_id, category_name: $category_name, organizer_id: $organizer_id, description: $description, location: $location, price: $price, deleted: $deleted}';
  }
}
