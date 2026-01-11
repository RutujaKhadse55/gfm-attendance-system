// lib/models/attendance_model.dart

class Attendance {
  final int? id;                 // SQLite auto-increment ID / MongoDB _id
  final String studentPrn;       // Student PRN (PRIMARY reference)
  final int batchId;
  final String date;             // Format: 'yyyy-MM-dd'
  final String status;           // 'Present' or 'Absent'
  final int createdAt;           // Timestamp
  final int? updatedAt;          // Timestamp (nullable)
  final String? proofPath;       // Path to proof file (nullable)

  Attendance({
    this.id,
    required this.studentPrn,
    required this.batchId,
    required this.date,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.proofPath,
  });

  // ================= FROM/TO API (MongoDB) =================

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] != null ? int.tryParse(json['_id'].toString()) : null,
      studentPrn: json['studentPrn'] ?? '',
      batchId: json['batchId'] is int
          ? json['batchId']
          : int.tryParse(json['batchId']?.toString() ?? '0') ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'Present',
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '0') ?? 0,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is int
              ? json['updatedAt']
              : int.tryParse(json['updatedAt']?.toString() ?? '0'))
          : null,
      proofPath: json['proofPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'studentPrn': studentPrn,
      'batchId': batchId,
      'date': date,
      'status': status,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (proofPath != null) 'proofPath': proofPath,
    };
  }

  // ================= FROM/TO SQLite =================

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentPrn: map['student_prn'] ?? '',
      batchId: map['batch_id'] is int
          ? map['batch_id']
          : int.tryParse(map['batch_id']?.toString() ?? '0') ?? 0,
      date: map['date'] ?? '',
      status: map['status'] ?? 'Present',
      createdAt: map['created_at'] is int
          ? map['created_at']
          : int.tryParse(map['created_at']?.toString() ?? '0') ?? 0,
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is int
              ? map['updated_at']
              : int.tryParse(map['updated_at']?.toString() ?? '0'))
          : null,
      proofPath: map['proof_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_prn': studentPrn,
      'batch_id': batchId,
      'date': date,
      'status': status,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (proofPath != null) 'proof_path': proofPath,
    };
  }

  // ================= UTILITY =================

  Attendance copyWith({
    int? id,
    String? studentPrn,
    int? batchId,
    String? date,
    String? status,
    int? createdAt,
    int? updatedAt,
    String? proofPath,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentPrn: studentPrn ?? this.studentPrn,
      batchId: batchId ?? this.batchId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      proofPath: proofPath ?? this.proofPath,
    );
  }
}