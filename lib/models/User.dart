class User {
  int id;
  String name;
  String? email;
  String? role;
  DateTime? emailVerifiedAt;
  String? profilePicture;
  bool actived;
  bool deleted;

  User({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.emailVerifiedAt,
    this.profilePicture,
    required this.actived,
    required this.deleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      profilePicture: json['profilePicture'],
      actived: json['actived'] == 1,
      deleted: json['deleted'] == 1,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role, '
        'emailVerifiedAt: $emailVerifiedAt, profilePicture: $profilePicture, '
        'actived: $actived, deleted: $deleted}';
  }
}
