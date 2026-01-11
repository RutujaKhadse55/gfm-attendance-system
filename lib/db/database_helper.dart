// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart' as models;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gfm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS assignments_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_name TEXT NOT NULL,
          batch_id INTEGER NOT NULL,
          role TEXT NOT NULL DEFAULT 'attendance_teacher',
          UNIQUE(teacher_name, batch_id)
        )
      ''');
      
      await db.execute('''
        INSERT INTO assignments_new (id, teacher_name, batch_id, role)
        SELECT id, teacher_name, batch_id, 'attendance_teacher' FROM assignments
      ''');
      
      await db.execute('DROP TABLE assignments');
      await db.execute('ALTER TABLE assignments_new RENAME TO assignments');
    }
    
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE attendance ADD COLUMN proof_path TEXT');
      } catch (e) {
        debugPrint('Column proof_path already exists or migration failed: $e');
      }
    }
    
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE follow_ups ADD COLUMN proof_file_id TEXT');
      } catch (e) {
        debugPrint('Column proof_file_id already exists or migration failed: $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students (
        prn TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        parent_mobile TEXT NOT NULL,
        email TEXT NOT NULL,
        batch_id INTEGER NOT NULL
      )
    ''');

    // Batches table
    await db.execute('''
      CREATE TABLE batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Assignments table
    await db.execute('''
      CREATE TABLE assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_name TEXT NOT NULL,
        batch_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'attendance_teacher',
        UNIQUE(teacher_name, batch_id)
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_prn TEXT NOT NULL,
        batch_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        proof_path TEXT,
        UNIQUE(student_prn, date)
      )
    ''');

    // Follow-ups table
    await db.execute('''
      CREATE TABLE follow_ups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attendance_id INTEGER NOT NULL,
        reason TEXT NOT NULL,
        proof_path TEXT,
        proof_file_id TEXT,
        timestamp INTEGER NOT NULL,
        UNIQUE(attendance_id)
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        display_name TEXT,
        created_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'display_name': 'Administrator',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'is_active': 1,
    });
  }

  // ==================== STUDENTS ====================
  
  Future<Map<String, dynamic>> insertStudent(models.Student student) async {
    final db = await database;
    try {
      await db.insert('students', student.toMap());
      return {'success': true, 'message': 'Student added successfully'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'success': false, 'message': 'Student PRN already exists'};
      }
      return {'success': false, 'message': 'Database error: ${e.toString()}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> insertStudentsBatch(List<models.Student> students) async {
    final db = await database;
    int successCount = 0;
    int duplicateCount = 0;
    List<String> errors = [];
    
    await db.transaction((txn) async {
      for (var student in students) {
        try {
          await txn.insert('students', student.toMap());
          successCount++;
        } on DatabaseException catch (e) {
          if (e.isUniqueConstraintError()) {
            duplicateCount++;
          } else {
            errors.add('${student.prn}: ${e.toString()}');
          }
        } catch (e) {
          errors.add('${student.prn}: ${e.toString()}');
        }
      }
    });
    
    return {
      'success': successCount,
      'duplicates': duplicateCount,
      'errors': errors.length,
      'errorDetails': errors,
    };
  }

  Future<List<models.Student>> getAllStudents({int? limit, int? offset}) async {
    final db = await database;
    final result = await db.query(
      'students',
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => models.Student.fromMap(map)).toList();
  }

  Future<List<models.Student>> getStudentsByBatch(int batchId) async {
    final db = await database;
    final result = await db.query(
      'students',
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'name',
    );
    return result.map((map) => models.Student.fromMap(map)).toList();
  }

  Future<List<models.Student>> getStudentsByBatches(List<int> batchIds) async {
    if (batchIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = List.filled(batchIds.length, '?').join(',');
    final result = await db.query(
      'students',
      where: 'batch_id IN ($placeholders)',
      whereArgs: batchIds,
      orderBy: 'batch_id, name',
    );
    return result.map((map) => models.Student.fromMap(map)).toList();
  }

  Future<int> getStudentCountByBatch(int batchId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE batch_id = ?',
      [batchId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== BATCHES ====================
  
  Future<Map<String, dynamic>> insertBatch(models.Batch batch) async {
    final db = await database;
    try {
      final id = await db.insert('batches', batch.toMap());
      return {'success': true, 'id': id, 'message': 'Batch created'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'success': false, 'message': 'Batch name already exists'};
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> ensureBatchesExist(Set<int> batchIds) async {
    final db = await database;
    for (var batchId in batchIds) {
      final existing = await db.query('batches', where: 'id = ?', whereArgs: [batchId]);
      if (existing.isEmpty) {
        await db.insert('batches', {
          'id': batchId,
          'name': 'Batch $batchId',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<List<models.Batch>> getAllBatches() async {
    final db = await database;
    final result = await db.query('batches', orderBy: 'name');
    return result.map((map) => models.Batch.fromMap(map)).toList();
  }

  Future<models.Batch?> getBatchById(int id) async {
    final db = await database;
    final result = await db.query('batches', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return models.Batch.fromMap(result.first);
  }

  // ==================== ASSIGNMENTS ====================
  
  Future<Map<String, dynamic>> insertAssignment(models.Assignment assignment) async {
    final db = await database;
    try {
      if (assignment.batchId != -1) {
        final batch = await getBatchById(assignment.batchId);
        if (batch == null) {
          return {'success': false, 'message': 'Batch does not exist'};
        }
      }

      final user = await getUserByUsername(assignment.teacherName);
      if (user == null) {
        return {'success': false, 'message': 'Teacher does not exist'};
      }

      final id = await db.insert('assignments', assignment.toMap());
      return {'success': true, 'id': id, 'message': 'Assignment created'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'success': false, 'message': 'Teacher already assigned to this batch'};
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment(int assignmentId) async {
    final db = await database;
    try {
      final deleted = await db.delete(
        'assignments',
        where: 'id = ?',
        whereArgs: [assignmentId],
      );
      
      if (deleted > 0) {
        return {'success': true, 'message': 'Assignment deleted successfully'};
      } else {
        return {'success': false, 'message': 'Assignment not found'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<List<models.Assignment>> getAssignmentsByTeacher(String teacherName) async {
    final db = await database;
    final result = await db.query(
      'assignments',
      where: 'teacher_name = ?',
      whereArgs: [teacherName],
    );
    return result.map((map) => models.Assignment.fromMap(map)).toList();
  }

  Future<List<models.Assignment>> getAssignmentsByTeacherAndRole(
    String teacherName,
    String role,
  ) async {
    final db = await database;
    final result = await db.query(
      'assignments',
      where: 'teacher_name = ? AND role = ?',
      whereArgs: [teacherName, role],
    );
    return result.map((map) => models.Assignment.fromMap(map)).toList();
  }

  Future<List<models.Assignment>> getAllAssignments() async {
    final db = await database;
    final result = await db.query('assignments');
    return result.map((map) => models.Assignment.fromMap(map)).toList();
  }

  Future<bool> isTeacherAssignedToBatch(String teacherName, int batchId) async {
    final db = await database;
    final result = await db.query(
      'assignments',
      where: 'teacher_name = ? AND batch_id = ?',
      whereArgs: [teacherName, batchId],
    );
    return result.isNotEmpty;
  }

  // ==================== ATTENDANCE ====================
  
  Future<Map<String, dynamic>> markAttendance(models.Attendance attendance) async {
    final db = await database;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = {
        ...attendance.toMap(),
        'updated_at': now,
        'created_at': attendance.createdAt ?? now,
      };

      final id = await db.insert(
        'attendance',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {'success': true, 'id': id, 'message': 'Attendance saved'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> markAttendanceBatch(List<models.Attendance> attendanceList) async {
    final db = await database;
    int successCount = 0;
    int errorCount = 0;

    await db.transaction((txn) async {
      for (var attendance in attendanceList) {
        try {
          final now = DateTime.now().millisecondsSinceEpoch;
          final map = {
            ...attendance.toMap(),
            'updated_at': now,
            'created_at': attendance.createdAt ?? now,
          };

          await txn.insert(
            'attendance',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }
    });

    return {
      'success': successCount,
      'errors': errorCount,
    };
  }

  Future<List<models.Attendance>> getAttendanceByBatchAndDate(
    int batchId,
    String date,
  ) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'batch_id = ? AND date = ?',
      whereArgs: [batchId, date],
    );
    return result.map((map) => models.Attendance.fromMap(map)).toList();
  }

  Future<List<models.Attendance>> getAttendanceByBatchesAndDate(
    List<int> batchIds,
    String date,
  ) async {
    if (batchIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = List.filled(batchIds.length, '?').join(',');
    final result = await db.query(
      'attendance',
      where: 'batch_id IN ($placeholders) AND date = ?',
      whereArgs: [...batchIds, date],
    );
    return result.map((map) => models.Attendance.fromMap(map)).toList();
  }

  Future<List<models.AbsentStudentDetail>> getAbsentStudents(
    int batchId,
    String date,
  ) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        s.prn, s.name, s.mobile, s.parent_mobile, s.email, s.batch_id,
        a.id as att_id, a.student_prn, a.batch_id as att_batch, 
        a.date, a.status, a.created_at,
        f.id as fu_id, f.attendance_id, f.reason, f.proof_path, f.timestamp
      FROM students s
      INNER JOIN attendance a ON s.prn = a.student_prn
      LEFT JOIN follow_ups f ON a.id = f.attendance_id
      WHERE a.batch_id = ? AND a.date = ? AND a.status = 'Absent'
      ORDER BY s.name
    ''', [batchId, date]);

    return result.map((row) {
      final student = models.Student.fromMap({
        'prn': row['prn'],
        'name': row['name'],
        'mobile': row['mobile'],
        'parent_mobile': row['parent_mobile'],
        'email': row['email'],
        'batch_id': row['batch_id'],
      });

      final attendance = models.Attendance.fromMap({
        'id': row['att_id'],
        'student_prn': row['student_prn'],
        'batch_id': row['att_batch'],
        'date': row['date'],
        'status': row['status'],
        'created_at': row['created_at'],
      });

      models.FollowUp? followUp;
      if (row['fu_id'] != null) {
        followUp = models.FollowUp.fromMap({
          'id': row['fu_id'],
          'attendance_id': row['attendance_id'],
          'reason': row['reason'],
          'proof_path': row['proof_path'],
          'timestamp': row['timestamp'],
        });
      }

      return models.AbsentStudentDetail(
        student: student,
        attendance: attendance,
        followUp: followUp,
      );
    }).toList();
  }

  Future<List<models.Attendance>> getAllAttendance({int? limit, int? offset}) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => models.Attendance.fromMap(map)).toList();
  }

  Future<Map<String, int>> getAttendanceSummaryByDate(String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM attendance
      WHERE date = ?
      GROUP BY status
    ''', [date]);

    int present = 0, absent = 0;
    for (var row in result) {
      if (row['status'] == 'Present') {
        present = row['count'] as int;
      } else if (row['status'] == 'Absent') {
        absent = row['count'] as int;
      }
    }

    return {'present': present, 'absent': absent};
  }

  Future<List<Map<String, dynamic>>> getAttendanceReport({
    String? startDate,
    String? endDate,
    int? batchId,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND a.date >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClause += ' AND a.date <= ?';
      whereArgs.add(endDate);
    }
    if (batchId != null) {
      whereClause += ' AND a.batch_id = ?';
      whereArgs.add(batchId);
    }

    final result = await db.rawQuery('''
      SELECT 
        a.date,
        a.batch_id,
        b.name as batch_name,
        a.status,
        COUNT(*) as count
      FROM attendance a
      INNER JOIN batches b ON a.batch_id = b.id
      WHERE $whereClause
      GROUP BY a.date, a.batch_id, a.status
      ORDER BY a.date DESC, b.name, a.status
    ''', whereArgs);

    return result;
  }

  // ==================== FOLLOW-UPS ====================
  
  Future<Map<String, dynamic>> insertFollowUp(models.FollowUp followUp) async {
    final db = await database;
    try {
      final attResult = await db.query(
        'attendance',
        where: 'id = ?',
        whereArgs: [followUp.attendanceId],
      );
      
      if (attResult.isEmpty) {
        return {'success': false, 'message': 'Attendance record not found'};
      }
      
      final id = await db.insert('follow_ups', followUp.toMap());
      return {'success': true, 'id': id, 'message': 'Follow-up recorded'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'success': false, 'message': 'Follow-up already exists for this attendance'};
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<models.FollowUp?> getFollowUpByAttendanceId(int attendanceId) async {
    final db = await database;
    final result = await db.query(
      'follow_ups',
      where: 'attendance_id = ?',
      whereArgs: [attendanceId],
    );
    if (result.isEmpty) return null;
    return models.FollowUp.fromMap(result.first);
  }

  Future<List<Map<String, dynamic>>> getFollowUpsReport({
    String? startDate,
    String? endDate,
    int? batchId,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND a.date >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClause += ' AND a.date <= ?';
      whereArgs.add(endDate);
    }
    if (batchId != null) {
      whereClause += ' AND a.batch_id = ?';
      whereArgs.add(batchId);
    }

    final result = await db.rawQuery('''
      SELECT 
        f.*,
        a.date,
        a.student_prn,
        s.name as student_name,
        s.mobile,
        s.parent_mobile,
        b.name as batch_name
      FROM follow_ups f
      INNER JOIN attendance a ON f.attendance_id = a.id
      INNER JOIN students s ON a.student_prn = s.prn
      INNER JOIN batches b ON a.batch_id = b.id
      WHERE $whereClause
      ORDER BY f.timestamp DESC
    ''', whereArgs);

    return result;
  }

  // ==================== USERS ====================

  Future<Map<String, dynamic>> insertUser(
    String username,
    String password,
    String role,
    String? displayName,
  ) async {
    final db = await database;
    try {
      if (!['admin', 'attendance_teacher', 'batch_teacher'].contains(role)) {
        return {'success': false, 'message': 'Invalid role'};
      }

      final id = await db.insert('users', {
        'username': username,
        'password': password,
        'role': role,
        'display_name': displayName ?? username,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_active': 1,
      });
      return {'success': true, 'id': id, 'message': 'User created'};
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return {'success': false, 'message': 'Username already exists'};
      }
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'role, display_name',
    );
  }

  Future<Map<String, dynamic>> deactivateUser(String username) async {
    final db = await database;
    try {
      final updated = await db.update(
        'users',
        {'is_active': 0},
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
      );
      if (updated == 0) return {'success': false, 'message': 'User not found or already deactivated'};
      return {'success': true, 'message': 'User deactivated'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== UTILITY ====================
  
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gfm.db');
    await deleteDatabase(path);
    _database = null;
  }
}