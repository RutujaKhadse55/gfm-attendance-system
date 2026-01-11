// lib/models/assignment_model.dart

class Assignment {
  final int? id;
  final String teacherName;
  final int batchId;
  final String role;
  final DateTime? createdAt;

  Assignment({
    this.id,
    required this.teacherName,
    required this.batchId,
    required this.role,
    this.createdAt,
  });

  // ================= FROM/TO API (MongoDB) =================

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      teacherName: json['teacherName'] ?? '',
      batchId: json['batchId'] is int
          ? json['batchId']
          : int.tryParse(json['batchId']?.toString() ?? '0') ?? 0,
      role: json['role'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'teacherName': teacherName,
      'batchId': batchId,
      'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // ================= FROM/TO SQLite =================

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      teacherName: map['teacher_name'] ?? '',
      batchId: map['batch_id'] is int
          ? map['batch_id']
          : int.tryParse(map['batch_id']?.toString() ?? '0') ?? 0,
      role: map['role'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'teacher_name': teacherName,
      'batch_id': batchId,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // ================= UTILITY =================

  Assignment copyWith({
    int? id,
    String? teacherName,
    int? batchId,
    String? role,
    DateTime? createdAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      teacherName: teacherName ?? this.teacherName,
      batchId: batchId ?? this.batchId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}