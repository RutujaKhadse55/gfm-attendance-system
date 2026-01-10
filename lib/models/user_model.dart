class User {
  final String id;
  final String username;
  final String password;
  final String role; // 'admin' or 'teacher'
  final String? fullName;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.fullName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      username: json['username'],
      password: json['password'] ?? '',
      role: json['role'],
      fullName: json['fullName'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'password': password,
      'role': role,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
