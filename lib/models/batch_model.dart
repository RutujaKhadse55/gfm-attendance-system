// lib/models/batch_model.dart

class Batch {
  final int? id;           // SQLite auto-increment ID
  final String name;
  final DateTime? createdAt;

  Batch({
    this.id,
    required this.name,
    this.createdAt,
  });

  // ================= FROM/TO API (MongoDB) =================

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // ================= FROM/TO SQLite =================

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      name: map['name'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // ================= UTILITY =================

  Batch copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}