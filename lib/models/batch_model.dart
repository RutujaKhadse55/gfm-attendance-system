// lib/models/batch_model.dart

class Batch {
  final String id; // for MongoDB _id
  final String name;

  Batch({required this.id, required this.name});

  // ===== MongoDB =====
  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['_id'] ?? json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }

  // ===== SQLite =====
  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'].toString(), // SQLite id is int, convert to string
      name: map['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id) ?? 0, // SQLite expects int primary key
      'name': name,
    };
  }
}
