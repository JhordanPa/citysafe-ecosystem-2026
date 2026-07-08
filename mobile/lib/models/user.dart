class User {
  final int id;
  final String username;
  final String role;

  User({required this.id, required this.username, this.role = 'ciudadano'});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['rol'] ?? json['role'] ?? 'ciudadano',
    );
  }
}
