// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../db/database_helper.dart';
import '../services/api_services.dart';
import '../models/app_models.dart';

/// Hybrid Provider: Uses SQLite for local storage + MongoDB backend for sync
/// - SQLite: Fast local operations, works offline
/// - MongoDB: Cloud sync, multi-device support
class AppProvider extends ChangeNotifier {
  // ==================== STATE ====================
  Map<String, dynamic>? _currentUser;
  List<Student> _students = [];
  List<Batch> _batches = [];
  List<Assignment> _assignments = [];
  List<Attendance> _todayAttendance = [];
  
  bool _loading = false;
  bool _loadingStudents = false;
  bool _loadingBatches = false;
  bool _loadingAssignments = false;
  bool _syncInProgress = false;
  String? _error;
  String _jwtToken = '';

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Backend sync mode
  bool _useBackend = true;
  bool get useBackend => _useBackend;
  bool get syncInProgress => _syncInProgress;

  // ==================== GETTERS ====================
  Map<String, dynamic>? get currentUser => _currentUser;
  List<Student> get students => _students;
  List<Batch> get batches => _batches;
  List<Assignment> get assignments => _assignments;
  List<Attendance> get todayAttendance => _todayAttendance;
  
  bool get loading => _loading;
  bool get loadingStudents => _loadingStudents;
  bool get loadingBatches => _loadingBatches;
  bool get loadingAssignments => _loadingAssignments;
  String? get error => _error;
  String get jwtToken => _jwtToken;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isAttendanceTeacher => _currentUser?['role'] == 'attendance_teacher';
  bool get isBatchTeacher => _currentUser?['role'] == 'batch_teacher';
  bool get isTeacher => isAttendanceTeacher || isBatchTeacher;

  String get userName => _currentUser?['display_name'] ?? _currentUser?['username'] ?? 'User';
  String get userId => _currentUser?['username'] ?? '';
  String get userRole => _currentUser?['role'] ?? '';

  void setJwtToken(String token) {
    _jwtToken = token;
    notifyListeners();
  }

  void toggleBackendMode(bool enabled) {
    _useBackend = enabled;
    notifyListeners();
  }

  // ==================== AUTHENTICATION ====================
  Future<bool> login(String username, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // ALWAYS try local authentication first for reliability
      final localUser = await _db.authenticateUser(username, password);
      
      if (localUser == null) {
        _setError('Invalid username or password');
        _setLoading(false);
        return false;
      }

      // Set current user from local database
      _currentUser = localUser;

      // If backend is enabled, try to sync but don't fail login if it fails
      if (_useBackend) {
        try {
          final backendResult = await ApiService.login(username, password);
          
          if (backendResult['success'] == true && backendResult['token'] != null) {
            _jwtToken = backendResult['token'];
            debugPrint('✅ Backend login successful, JWT token obtained');
          } else {
            debugPrint('⚠️ Backend login failed, continuing with local auth');
          }
        } catch (e) {
          debugPrint('⚠️ Backend login error (continuing with local): $e');
          // Don't fail login, just continue with local
        }
      }

      // Load data based on role
      if (isAdmin) {
        await Future.wait([
          loadStudents(),
          loadBatches(),
          loadAllAssignments(),
          loadTodayAttendance(),
        ]);
      } else if (isAttendanceTeacher) {
        await loadBatches();
        await loadStudents();
        await loadTodayAttendance();
      } else if (isBatchTeacher) {
        await loadAssignedBatches();
        await loadStudents();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Login error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    if (_useBackend && _jwtToken.isNotEmpty) {
      try {
        await ApiService.logout();
      } catch (e) {
        debugPrint('Backend logout error: $e');
      }
    }
    
    _currentUser = null;
    _students.clear();
    _batches.clear();
    _assignments.clear();
    _todayAttendance.clear();
    _jwtToken = '';
    _error = null;
    notifyListeners();
  }

  // ==================== STUDENTS ====================
  Future<void> loadStudents() async {
    if (_loadingStudents) return;
    
    try {
      _loadingStudents = true;
      notifyListeners();

      // ALWAYS load from local database first
      if (isAdmin || isAttendanceTeacher) {
        _students = await _db.getAllStudents();
      } else if (isBatchTeacher) {
        final batchIds = _assignments.map((a) => a.batchId).toList();
        if (batchIds.isNotEmpty) {
          _students = await _db.getStudentsByBatches(batchIds);
        } else {
          _students = [];
        }
      }

      _loadingStudents = false;
      notifyListeners();
    } catch (e) {
      _setError('Error loading students: ${e.toString()}');
      _students = [];
      _loadingStudents = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> importStudents(List<Student> students) async {
    try {
      _setLoading(true);

      // 1. Import to local database first
      final batchIds = students.map((s) => s.batchId).toSet();
      await _db.ensureBatchesExist(batchIds);
      
      final result = await _db.insertStudentsBatch(students);
      
      // 2. Try backend sync if enabled
      if (_useBackend && _jwtToken.isNotEmpty && result['success'] > 0) {
        try {
          final studentsData = students.map((s) => {
            'name': s.name,
            'rollNumber': s.prn,
            'mobile': s.mobile,
            'parentMobile': s.parentMobile,
            'email': s.email,
            'batchId': s.batchId,
          }).toList();
          
          final backendResult = await ApiService.importStudents(studentsData);
          debugPrint('✅ Students synced to MongoDB: ${backendResult['imported']} imported');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
        }
      }

      await loadStudents();
      await loadBatches();
      
      _setLoading(false);
      return {
        'success': true,
        'imported': result['success'],
        'duplicates': result['duplicates'],
        'errors': result['errors'],
        'message': 'Successfully imported ${result['success']} students',
      };
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Import error: ${e.toString()}'};
    }
  }

  Future<List<Student>> getStudentsByBatch(int batchId) async {
    try {
      return await _db.getStudentsByBatch(batchId);
    } catch (e) {
      debugPrint('Error loading students by batch: $e');
      return [];
    }
  }

  // ==================== BATCHES ====================
  Future<void> loadBatches() async {
    if (_loadingBatches) return;
    
    _loadingBatches = true;
    notifyListeners();
    
    try {
      _batches = await _db.getAllBatches();
    } catch (e) {
      _setError('Error loading batches: ${e.toString()}');
      _batches = [];
    }
    
    _loadingBatches = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createBatch(String name) async {
    try {
      // 1. Save to local SQLite
      final batch = Batch(name: name);
      final result = await _db.insertBatch(batch);
      
      // 2. Sync to MongoDB
      if (result['success'] == true && _useBackend && _jwtToken.isNotEmpty) {
        try {
          await ApiService.createBatch(name);
          debugPrint('✅ Batch synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
        }
      }
      
      if (result['success'] == true) {
        await loadBatches();
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== ATTENDANCE ====================
  Future<void> loadTodayAttendance() async {
    try {
      _setLoading(true);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Load from local database
      if (isAdmin || isAttendanceTeacher) {
        final allAttendance = await _db.getAllAttendance();
        _todayAttendance = allAttendance.where((a) => a.date == today).toList();
      } else if (isBatchTeacher) {
        final batchIds = _assignments.map((a) => a.batchId).toList();
        if (batchIds.isNotEmpty) {
          _todayAttendance = await _db.getAttendanceByBatchesAndDate(batchIds, today);
        }
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Error loading attendance: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> markAttendanceBatch(List<Attendance> attendanceList) async {
    try {
      // 1. Save to local database first
      final result = await _db.markAttendanceBatch(attendanceList);
      
      if (result['success'] > 0) {
        await loadTodayAttendance();
        
        // 2. Try backend sync if enabled
        if (_useBackend && _jwtToken.isNotEmpty) {
          try {
            final attendanceData = attendanceList.map((a) => {
              'studentId': a.studentPrn,
              'teacherId': userId,
              'batchId': a.batchId,
              'date': a.date,
              'status': a.status,
            }).toList();
            
            await ApiService.markAttendance(attendanceData);
            debugPrint('✅ Attendance synced to MongoDB: ${result['success']} records');
          } catch (e) {
            debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
          }
        }
        
        return {
          'success': true,
          'message': 'Attendance saved successfully',
          'count': result['success'],
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to save attendance',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<List<Attendance>> getAttendanceByBatchAndDate(int batchId, String date) async {
    try {
      return await _db.getAttendanceByBatchAndDate(batchId, date);
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      return [];
    }
  }

  // ==================== FOLLOW-UP ====================
  Future<Map<String, dynamic>> saveFollowUp(FollowUp followUp) async {
    try {
      // 1. Save to local database
      final result = await _db.insertFollowUp(followUp);
      
      // 2. Try backend sync if enabled
      if (_useBackend && _jwtToken.isNotEmpty && result['success'] == true) {
        try {
          final followUpData = {
            'studentId': followUp.attendanceId.toString(),
            'teacherId': userId,
            'notes': followUp.reason,
            'reason': followUp.reason,
            'date': DateTime.now().toIso8601String(),
          };
          
          List<File>? documents;
          if (followUp.proofPath != null) {
            documents = [File(followUp.proofPath!)];
          }
          
          await ApiService.addFollowUp(followUpData, documents);
          debugPrint('✅ Follow-up synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
        }
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<List<AbsentStudentDetail>> getAbsentStudents(int batchId, String date) async {
    try {
      return await _db.getAbsentStudents(batchId, date);
    } catch (e) {
      debugPrint('Error loading absent students: $e');
      return [];
    }
  }

  // ==================== ASSIGNMENTS ====================
  Future<void> loadAssignedBatches() async {
    try {
      if (_currentUser == null) return;
      
      final username = _currentUser!['username'];
      _assignments = await _db.getAssignmentsByTeacher(username);
      
      final batchIds = _assignments.map((a) => a.batchId).toList();
      if (batchIds.isNotEmpty) {
        final allBatches = await _db.getAllBatches();
        _batches = allBatches.where((b) => b.id != null && batchIds.contains(b.id)).toList();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error loading assigned batches: ${e.toString()}');
    }
  }

  Future<void> loadAllAssignments() async {
    if (_loadingAssignments) return;
    
    _loadingAssignments = true;
    notifyListeners();
    
    try {
      _assignments = await _db.getAllAssignments();
    } catch (e) {
      _setError('Error loading assignments: ${e.toString()}');
      _assignments = [];
    }
    
    _loadingAssignments = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createAssignment({
    String? teacherName,
    required int batchId,
    String role = 'attendance_teacher',
  }) async {
    try {
      // 1. Save to local SQLite
      final assignment = Assignment(
        teacherName: teacherName ?? userId,
        batchId: batchId,
        role: role,
      );
      
      final result = await _db.insertAssignment(assignment);
      
      // 2. Sync to MongoDB
      if (result['success'] == true && _useBackend && _jwtToken.isNotEmpty) {
        try {
          final assignmentData = {
            'teacherName': teacherName ?? userId,
            'teacherId': teacherName ?? userId,
            'batchId': batchId,
            'role': role,
          };
          
          await ApiService.createAssignment(assignmentData);
          debugPrint('✅ Assignment synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
        }
      }
      
      if (result['success'] == true) {
        await loadAllAssignments();
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment(int assignmentId) async {
    try {
      // 1. Delete from local SQLite
      final result = await _db.deleteAssignment(assignmentId);
      
      // 2. Sync to MongoDB
      if (result['success'] == true && _useBackend && _jwtToken.isNotEmpty) {
        try {
          await ApiService.deleteAssignment(assignmentId.toString());
          debugPrint('✅ Assignment deletion synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local delete successful): $e');
        }
      }
      
      if (result['success'] == true) {
        await loadAllAssignments();
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== USERS ====================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      return await _db.getAllUsers();
    } catch (e) {
      _setError('Error loading users: ${e.toString()}');
      return [];
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String role,
    String? displayName,
  }) async {
    try {
      // 1. Save to local SQLite
      final result = await _db.insertUser(username, password, role, displayName);
      
      // 2. Sync to MongoDB
      if (result['success'] == true && _useBackend && _jwtToken.isNotEmpty) {
        try {
          final userData = {
            'username': username,
            'password': password,
            'role': role,
            'displayName': displayName ?? username,
            'name': displayName ?? username,
          };
          
          await ApiService.createUser(userData);
          debugPrint('✅ User synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local save successful): $e');
        }
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deactivateUser(String username) async {
    try {
      // 1. Get all assignments for this user
      final userAssignments = await _db.getAssignmentsByTeacher(username);
      
      // 2. Delete all assignments from local database
      for (var assignment in userAssignments) {
        if (assignment.id != null) {
          await _db.deleteAssignment(assignment.id!);
          
          // Sync assignment deletion to MongoDB
          if (_useBackend && _jwtToken.isNotEmpty) {
            try {
              await ApiService.deleteAssignment(assignment.id.toString());
              debugPrint('✅ Assignment ${assignment.id} deletion synced to MongoDB');
            } catch (e) {
              debugPrint('⚠️ MongoDB assignment delete sync failed: $e');
            }
          }
        }
      }
      
      // 3. Deactivate user in local SQLite
      final result = await _db.deactivateUser(username);
      
      // 4. Sync user deactivation to MongoDB
      if (result['success'] == true && _useBackend && _jwtToken.isNotEmpty) {
        try {
          await ApiService.deactivateUser(username);
          debugPrint('✅ User deactivation synced to MongoDB');
        } catch (e) {
          debugPrint('⚠️ MongoDB sync failed (local deactivation successful): $e');
        }
      }
      
      // 5. Reload assignments to update UI
      await loadAllAssignments();
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== REPORTS ====================
  Future<Map<String, int>> getAttendanceSummary(String date) async {
    try {
      return await _db.getAttendanceSummaryByDate(date);
    } catch (e) {
      debugPrint('Error getting attendance summary: $e');
      return {'present': 0, 'absent': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceReport({
    String? startDate,
    String? endDate,
    int? batchId,
  }) async {
    try {
      return await _db.getAttendanceReport(
        startDate: startDate,
        endDate: endDate,
        batchId: batchId,
      );
    } catch (e) {
      debugPrint('Error getting attendance report: $e');
      return [];
    }
  }

  Future<int> getStudentCountByBatch(int batchId) async {
    try {
      return await _db.getStudentCountByBatch(batchId);
    } catch (e) {
      debugPrint('Error getting student count: $e');
      return 0;
    }
  }

  // ==================== OTHER METHODS ====================
  Future<List<Attendance>> getAllAttendance() async {
    try {
      return await _db.getAllAttendance();
    } catch (e) {
      debugPrint('Error loading all attendance: $e');
      return [];
    }
  }

  Future<FollowUp?> getFollowUpByAttendanceId(int attendanceId) async {
    try {
      return await _db.getFollowUpByAttendanceId(attendanceId);
    } catch (e) {
      debugPrint('Error loading follow-up: $e');
      return null;
    }
  }

  Future<List<Assignment>> getTeacherAssignmentsByRole(
    String teacherName,
    String role,
  ) async {
    try {
      return await _db.getAssignmentsByTeacherAndRole(teacherName, role);
    } catch (e) {
      debugPrint('Error loading teacher assignments by role: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> closeDatabase() async {
    try {
      await _db.closeDatabase();
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }

  Future<void> resetDatabase() async {
    try {
      await _db.resetDatabase();
      _batches = [];
      _students = [];
      _assignments = [];
      _todayAttendance = [];
      logout();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
}