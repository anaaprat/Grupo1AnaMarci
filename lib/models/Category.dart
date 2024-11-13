// category_model.dart

class Category {
  int id;
  String name;
  String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  // Constructor principal desde JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
    );
  }

  // Método para convertir un objeto Category a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
