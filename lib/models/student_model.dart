class Student {
  // DB fields
  final String prn;            // PRIMARY KEY in DB
  final String name;
  final String mobile;
  final String parentMobile;
  final String email;
  final int batchId;

  // API-only fields (optional)
  final String? id;            // MongoDB _id
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

  // ================= API =================

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      prn: json['rollNumber'],               // API rollNumber → DB prn
      name: json['name'],
      mobile: json['mobile'],
      parentMobile: json['parentMobile'],
      email: json['email'],
      batchId: json['batchId'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'rollNumber': prn,
      'name': name,
      'mobile': mobile,
      'parentMobile': parentMobile,
      'email': email,
      'batchId': batchId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ================= SQLITE =================

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      prn: map['prn'],
      name: map['name'],
      mobile: map['mobile'],
      parentMobile: map['parent_mobile'],
      email: map['email'],
      batchId: map['batch_id'],
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
}
