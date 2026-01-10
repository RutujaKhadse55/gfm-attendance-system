// lib/models/attendance_model.dart

class Attendance {
  final String id;
  final String studentId;
  final String teacherId;
  final DateTime date;
  final String status; // 'Present' or 'Absent'
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from JSON (MongoDB API)
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'],
      studentId: json['studentId'],
      teacherId: json['teacherId'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert to JSON (for API)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'date': date.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'date': date.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (SQLite)
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['studentId'],
      teacherId: map['teacherId'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
