// lib/models/follow_up_model.dart

class FollowUp {
  final int? id;
  final int attendanceId;        // References attendance.id
  final String reason;
  final String? proofPath;
  final String? proofFileId;     // Backend file ID
  final int timestamp;

  FollowUp({
    this.id,
    required this.attendanceId,
    required this.reason,
    this.proofPath,
    this.proofFileId,
    required this.timestamp,
  });

  // ================= FROM/TO API (MongoDB) =================

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      attendanceId: json['attendanceId'] is int
          ? json['attendanceId']
          : int.tryParse(json['attendanceId']?.toString() ?? '0') ?? 0,
      reason: json['reason'] ?? '',
      proofPath: json['proofPath'],
      proofFileId: json['proofFileId'],
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'attendanceId': attendanceId,
      'reason': reason,
      if (proofPath != null) 'proofPath': proofPath,
      if (proofFileId != null) 'proofFileId': proofFileId,
      'timestamp': timestamp,
    };
  }

  // ================= FROM/TO SQLite =================

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'],
      attendanceId: map['attendance_id'] is int
          ? map['attendance_id']
          : int.tryParse(map['attendance_id']?.toString() ?? '0') ?? 0,
      reason: map['reason'] ?? '',
      proofPath: map['proof_path'],
      proofFileId: map['proof_file_id'],
      timestamp: map['timestamp'] is int
          ? map['timestamp']
          : int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'attendance_id': attendanceId,
      'reason': reason,
      if (proofPath != null) 'proof_path': proofPath,
      if (proofFileId != null) 'proof_file_id': proofFileId,
      'timestamp': timestamp,
    };
  }

  // ================= UTILITY =================

  FollowUp copyWith({
    int? id,
    int? attendanceId,
    String? reason,
    String? proofPath,
    String? proofFileId,
    int? timestamp,
  }) {
    return FollowUp(
      id: id ?? this.id,
      attendanceId: attendanceId ?? this.attendanceId,
      reason: reason ?? this.reason,
      proofPath: proofPath ?? this.proofPath,
      proofFileId: proofFileId ?? this.proofFileId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}