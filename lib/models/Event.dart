// event_model.dart


class Event {
  int id;
  String title;
  DateTime start_time;
  String? image_url;
  String category;

  Event({
    required this.id,
    required this.title,
    required this.start_time,
    this.image_url,
    required this.category,
  });

  // Constructor principal desde JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      start_time: DateTime.parse(json['start_time']),
      image_url: json['image_url'],
      category: json['category'],
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
    };
  }
}
