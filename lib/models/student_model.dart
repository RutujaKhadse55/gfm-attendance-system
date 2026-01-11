// lib/models/student_model.dart

class Student {
  // Core fields (used in both DB and API)
  final String prn;           // PRIMARY KEY in SQLite / rollNumber in API
  final String name;
  final String mobile;
  final String parentMobile;
  final String email;
  final int batchId;

  // API-only fields
  final String? id;           // MongoDB _id
  final DateTime? createdAt;

  Student({
    required this.prn,
    required this.name,
    required this.mobile,
    required this.parentMobile,
    required this.email,
    required this.batchId,
    this.id,
    this.createdAt,
  });

  // ================= FROM/TO API (MongoDB) =================
  
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      prn: json['rollNumber'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      parentMobile: json['parentMobile'] ?? '',
      email: json['email'] ?? '',
      batchId: json['batchId'] is int 
          ? json['batchId'] 
          : int.tryParse(json['batchId']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'rollNumber': prn,
      'name': name,
      'mobile': mobile,
      'parentMobile': parentMobile,
      'email': email,
      'batchId': batchId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // ================= FROM/TO SQLite =================

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      prn: map['prn'] ?? '',
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      parentMobile: map['parent_mobile'] ?? '',
      email: map['email'] ?? '',
      batchId: map['batch_id'] is int
          ? map['batch_id']
          : int.tryParse(map['batch_id']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prn': prn,
      'name': name,
      'mobile': mobile,
      'parent_mobile': parentMobile,
      'email': email,
      'batch_id': batchId,
    };
  }

  // ================= UTILITY =================

  Student copyWith({
    String? id,
    String? prn,
    String? name,
    String? mobile,
    String? parentMobile,
    String? email,
    int? batchId,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      prn: prn ?? this.prn,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      parentMobile: parentMobile ?? this.parentMobile,
      email: email ?? this.email,
      batchId: batchId ?? this.batchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}