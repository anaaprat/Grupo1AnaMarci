class User {
  int id;
  String name;
  String? email;
  String role;
  DateTime? email_verified_at;
  String? profilePicture;
  bool actived;
  bool email_confirmed;
  bool deleted;
  String? remember_token;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.email_verified_at,
    this.profilePicture,
    required this.actived,
    required this.email_confirmed,
    required this.deleted,
    this.remember_token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      email_verified_at: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      profilePicture: json['profilePicture'],
      actived: json['actived'] ?? false,
      email_confirmed: json['email_confirmed'] ?? false,
      deleted: json['deleted'] ?? false,
      remember_token: json['remember_token'],
    );
  }

  factory User.fromFetchUsers(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      email_confirmed: json['email_confirmed'] ?? false,
      email_verified_at: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      actived: json['actived'] ?? false,
      deleted: json['deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'email_verified_at': email_verified_at?.toIso8601String(),
      'profilePicture': profilePicture,
      'actived': actived,
      'email_confirmed': email_confirmed,
      'deleted': deleted,
      'remember_token': remember_token,
    };
  }
}
