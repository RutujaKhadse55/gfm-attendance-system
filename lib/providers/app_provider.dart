// lib/providers/app_provider.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/attendance_model.dart';
import '../models/followup_model.dart';
import '../services/api_services.dart';

class AppProvider extends ChangeNotifier {
  // ==================== PRIVATE STATE ====================
  User? _currentUser;
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  List<Attendance> _todayAttendance = [];
  Map<String, List<FollowUp>> _followUps = {};

  bool _loading = false;
  String? _error;

  // ==================== GETTERS ====================
  User? get currentUser => _currentUser;
  List<Student> get students => _students;
  List<Teacher> get teachers => _teachers;
  List<Attendance> get todayAttendance => _todayAttendance;
  bool get loading => _loading;
  String? get error => _error;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isTeacher => _currentUser?.role == 'teacher';

  // ==================== AUTHENTICATION ====================
  Future<bool> login(String username, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await ApiService.login(username, password);

      if (result['success'] == true) {
        _currentUser = result['user'];

        // Load initial data based on role
        if (isAdmin) {
          await Future.wait([loadStudents(), loadTeachers()]);
        } else if (isTeacher) {
          await loadStudents();
          await loadTodayAttendance();
        }

        _setLoading(false);
        return true;
      }

      _setError(result['message'] ?? 'Login failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _currentUser = null;
    _students.clear();
    _teachers.clear();
    _todayAttendance.clear();
    _followUps.clear();
    notifyListeners();
  }

  // ==================== STUDENTS ====================
  Future<void> loadStudents() async {
    try {
      _setLoading(true);
      _students = await ApiService.getStudents();
      _setLoading(false);
    } catch (e) {
      _setError('Error loading students: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> importStudents(List<Map<String, dynamic>> students) async {
    try {
      _setLoading(true);
      final result = await ApiService.importStudents(students);

      if (result['success'] == true) {
        await loadStudents();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> addStudent(Student student) async {
    try {
      final result = await ApiService.addStudent(student);

      if (result['success'] == true) {
        await loadStudents();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== TEACHERS ====================
  Future<void> loadTeachers() async {
    try {
      _setLoading(true);
      _teachers = await ApiService.getTeachers();
      _setLoading(false);
    } catch (e) {
      _setError('Error loading teachers: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> addTeacher(Map<String, dynamic> teacherData) async {
    try {
      final result = await ApiService.addTeacher(teacherData);

      if (result['success'] == true) {
        await loadTeachers();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateTeacher(String id, Map<String, dynamic> teacherData) async {
    try {
      final result = await ApiService.updateTeacher(id, teacherData);

      if (result['success'] == true) {
        await loadTeachers();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteTeacher(String id) async {
    try {
      final result = await ApiService.deleteTeacher(id);

      if (result['success'] == true) {
        await loadTeachers();
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
      _todayAttendance = await ApiService.getAttendanceByDate(DateTime.now());
      _setLoading(false);
    } catch (e) {
      _setError('Error loading attendance: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<List<Attendance>> loadAttendanceByDate(DateTime date) async {
    try {
      return await ApiService.getAttendanceByDate(date);
    } catch (e) {
      _setError('Error loading attendance: ${e.toString()}');
      return [];
    }
  }

  Future<Map<String, dynamic>> markAttendance(List<Map<String, dynamic>> attendanceData) async {
    try {
      final result = await ApiService.markAttendance(attendanceData);

      if (result['success'] == true) {
        await loadTodayAttendance();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateAttendance(String id, String status) async {
    try {
      final result = await ApiService.updateAttendance(id, status);

      if (result['success'] == true) {
        await loadTodayAttendance();
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  String? getStudentAttendanceStatus(String studentId) {
    try {
      final attendance = _todayAttendance.firstWhere((a) => a.studentId == studentId);
      return attendance.status;
    } catch (_) {
      return null;
    }
  }

  // ==================== FOLLOW-UP ====================
  Future<Map<String, dynamic>> addFollowUp(
    Map<String, dynamic> followUpData,
    List<File>? documents,
  ) async {
    try {
      final result = await ApiService.addFollowUp(followUpData, documents);

      if (result['success'] == true) {
        await loadFollowUps(followUpData['studentId']);
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> loadFollowUps(String studentId) async {
    try {
      final followUps = await ApiService.getFollowUpsByStudent(studentId);
      _followUps[studentId] = followUps;
      notifyListeners();
    } catch (e) {
      _setError('Error loading follow-ups: ${e.toString()}');
    }
  }

  List<FollowUp> getStudentFollowUps(String studentId) {
    return _followUps[studentId] ?? [];
  }

  // ==================== REPORTS ====================
  Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    try {
      return await ApiService.getDailyReport(date);
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getWeeklyReport(DateTime startDate, DateTime endDate) async {
    try {
      return await ApiService.getWeeklyReport(startDate, endDate);
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<String?> downloadReportPdf(String reportType, DateTime date) async {
    try {
      return await ApiService.downloadReportPdf(reportType, date);
    } catch (e) {
      _setError('Error downloading PDF: ${e.toString()}');
      return null;
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
}
