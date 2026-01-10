// lib/models/followup_model.dart

class FollowUp {
  final String id;
  final String studentId;
  final String teacherId;
   final String attendanceId;
  final String notes;
  final List<String> documentUrls;
  final DateTime date;
  final DateTime createdAt;

  FollowUp({
    required this.id,
    required this.studentId,
    required this.teacherId,
     required this.attendanceId,
    required this.notes,
    required this.documentUrls,
    required this.date,
    required this.createdAt,
  });

  // MongoDB API
  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['_id'] ?? json['id'],
      studentId: json['studentId'],
      teacherId: json['teacherId'],
       attendanceId: json['attendanceId'],
      notes: json['notes'],
      documentUrls: List<String>.from(json['documentUrls'] ?? []),
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'teacherId': teacherId,
       'attendanceId': attendanceId,
      'notes': notes,
      'documentUrls': documentUrls,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
        'attendanceId': attendanceId,
      'notes': notes,
      'documentUrls': documentUrls.join(','), // store as comma-separated string
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'],
      studentId: map['studentId'],
      teacherId: map['teacherId'],
        attendanceId: map['attendanceId'],
      notes: map['notes'],
      documentUrls: map['documentUrls'] != null
          ? (map['documentUrls'] as String).split(',')
          : [],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
