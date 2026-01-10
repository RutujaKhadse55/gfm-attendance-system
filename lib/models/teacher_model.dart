// lib/models/teacher_model.dart

class Teacher {
  final String id;
  final String name;
  final String username;
  final String mobile;
  final String email;
  final DateTime createdAt;

  Teacher({
    required this.id,
    required this.name,
    required this.username,
    required this.mobile,
    required this.email,
    required this.createdAt,
  });

  // MongoDB API
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      username: json['username'],
      mobile: json['mobile'],
      email: json['email'],
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'username': username,
      'mobile': mobile,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'mobile': mobile,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      mobile: map['mobile'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
