// lib/models/assignment_model.dart

class Assignment {
  final String id; // MongoDB _id
  final String teacherName;
  final int batchId;
  final String role;

  Assignment({
    required this.id,
    required this.teacherName,
    required this.batchId,
    required this.role,
  });

  // ===== MongoDB =====
  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['_id'] ?? json['id'],
      teacherName: json['teacherName'] ?? json['teacher_name'],
      batchId: json['batchId'] ?? json['batch_id'],
      role: json['role'] ?? 'attendance_teacher',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teacherName': teacherName,
      'batchId': batchId,
      'role': role,
    };
  }

  // ===== SQLite =====
  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'].toString(),
      teacherName: map['teacher_name'],
      batchId: map['batch_id'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id) ?? 0, // SQLite expects int primary key
      'teacher_name': teacherName,
      'batch_id': batchId,
      'role': role,
    };
  }
}
