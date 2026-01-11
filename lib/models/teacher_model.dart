// lib/models/teacher_model.dart

class Teacher {
  final String? id;              // MongoDB _id (optional for new records)
  final String name;
  final String username;
  final String mobile;
  final String email;
  final DateTime? createdAt;

  Teacher({
    this.id,
    required this.name,
    required this.username,
    required this.mobile,
    required this.email,
    this.createdAt,
  });

  // ================= FROM/TO API (MongoDB) =================

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'username': username,
      'mobile': mobile,
      'email': email,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // ================= FROM/TO SQLite =================

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'username': username,
      'mobile': mobile,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // ================= UTILITY =================

  Teacher copyWith({
    String? id,
    String? name,
    String? username,
    String? mobile,
    String? email,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}