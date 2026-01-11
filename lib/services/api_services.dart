// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiService {
  static String? _authToken;
  
  static const bool _debugMode = true;
  
  static void _log(String message) {
    if (_debugMode) {
      debugPrint('🔧 [ApiService] $message');
    }
  }
  
  static void _logError(String message, dynamic error) {
    debugPrint('❌ [ApiService] $message: $error');
  }
  
  // ==================== TOKEN MANAGEMENT ====================
  
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _log('Token saved: ${token.substring(0, 20)}...');
  }
  
  static Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _log('Token retrieved: ${_authToken != null ? "Present" : "Missing"}');
    return _authToken;
  }
  
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _log('Token cleared');
  }
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // ==================== AUTHENTICATION ====================
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      _log('Login request for: $username');
      _log('URL: ${AppConfig.loginUrl}');
      
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));
      
      _log('Login response status: ${response.statusCode}');
      _log('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['token'] != null) {
          await setAuthToken(data['token']);
          _log('✅ Login successful');
          return {
            'success': true,
            'user': data['user'] ?? {'username': username},
            'token': data['token'],
          };
        }
      }
      
      _logError('Login failed', response.body);
      return {'success': false, 'message': 'Invalid credentials'};
    } catch (e) {
      _logError('Login error', e);
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
  
  static Future<void> logout() async {
    await clearAuthToken();
    _log('Logged out');
  }
  
  // ==================== STUDENTS ====================
  
  static Future<List<dynamic>> getStudents() async {
    try {
      _log('Fetching students from: ${AppConfig.studentsUrl}');
      
      final response = await http.get(
        Uri.parse(AppConfig.studentsUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get students response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final students = data['students'] ?? data['data'] ?? [];
        _log('✅ Fetched ${students.length} students');
        return students;
      }
      
      _logError('Failed to fetch students', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching students', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> importStudents(List<Map<String, dynamic>> students) async {
    try {
      _log('Importing ${students.length} students');
      _log('URL: ${AppConfig.studentsUrl}/import');
      _log('Sample data: ${students.take(1).toList()}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.studentsUrl}/import'),
        headers: await _getHeaders(),
        body: json.encode({'students': students}),
      ).timeout(const Duration(seconds: 60));
      
      _log('Import response status: ${response.statusCode}');
      _log('Import response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final imported = data['imported'] ?? data['success'] ?? students.length;
        final duplicates = data['duplicates'] ?? 0;
        _log('✅ Import successful: $imported imported, $duplicates duplicates');
        return {
          'success': true,
          'imported': imported,
          'duplicates': duplicates,
        };
      }
      
      _logError('Import failed', response.body);
      return {'success': false, 'message': 'Import failed: ${response.body}'};
    } catch (e) {
      _logError('Import error', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> addStudent(Map<String, dynamic> studentData) async {
    try {
      _log('Adding student: ${studentData['name']}');
      
      final response = await http.post(
        Uri.parse(AppConfig.studentsUrl),
        headers: await _getHeaders(),
        body: json.encode(studentData),
      ).timeout(const Duration(seconds: 30));
      
      _log('Add student response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Student added successfully');
        return {'success': true, 'message': 'Student added successfully'};
      }
      
      _logError('Failed to add student', response.body);
      return {'success': false, 'message': 'Failed to add student'};
    } catch (e) {
      _logError('Error adding student', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== BATCHES ====================
  
  static Future<List<dynamic>> getBatches() async {
    try {
      _log('Fetching batches');
      
      final response = await http.get(
        Uri.parse(AppConfig.batchesUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get batches response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final batches = data['batches'] ?? data['data'] ?? [];
        _log('✅ Fetched ${batches.length} batches');
        return batches;
      }
      
      _logError('Failed to fetch batches', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching batches', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createBatch(String name) async {
    try {
      _log('Creating batch: $name');
      
      final response = await http.post(
        Uri.parse(AppConfig.batchesUrl),
        headers: await _getHeaders(),
        body: json.encode({'name': name}),
      ).timeout(const Duration(seconds: 30));
      
      _log('Create batch response: ${response.statusCode}');
      _log('Create batch body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Batch created successfully');
        return {'success': true, 'message': 'Batch created successfully'};
      }
      
      final data = json.decode(response.body);
      _logError('Failed to create batch', response.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to create batch'};
    } catch (e) {
      _logError('Error creating batch', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== TEACHERS ====================
  
  static Future<List<dynamic>> getTeachers() async {
    try {
      _log('Fetching teachers');
      
      final response = await http.get(
        Uri.parse(AppConfig.teachersUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get teachers response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teachers = data['teachers'] ?? data['data'] ?? [];
        _log('✅ Fetched ${teachers.length} teachers');
        return teachers;
      }
      
      _logError('Failed to fetch teachers', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching teachers', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> addTeacher(Map<String, dynamic> teacherData) async {
    try {
      _log('Adding teacher: ${teacherData['name']}');
      _log('Teacher data: $teacherData');
      
      final response = await http.post(
        Uri.parse(AppConfig.teachersUrl),
        headers: await _getHeaders(),
        body: json.encode(teacherData),
      ).timeout(const Duration(seconds: 30));
      
      _log('Add teacher response: ${response.statusCode}');
      _log('Add teacher body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Teacher added successfully');
        return {'success': true, 'message': 'Teacher added successfully'};
      }
      
      final data = json.decode(response.body);
      _logError('Failed to add teacher', response.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to add teacher'};
    } catch (e) {
      _logError('Error adding teacher', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== ASSIGNMENTS ====================
  
  static Future<List<dynamic>> getAssignments() async {
    try {
      _log('Fetching assignments');
      
      final response = await http.get(
        Uri.parse(AppConfig.assignmentsUrl),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get assignments response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assignments = data['assignments'] ?? data['data'] ?? [];
        _log('✅ Fetched ${assignments.length} assignments');
        return assignments;
      }
      
      _logError('Failed to fetch assignments', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching assignments', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> assignmentData) async {
    try {
      _log('Creating assignment');
      _log('Assignment data: $assignmentData');
      
      final response = await http.post(
        Uri.parse(AppConfig.assignmentsUrl),
        headers: await _getHeaders(),
        body: json.encode(assignmentData),
      ).timeout(const Duration(seconds: 30));
      
      _log('Create assignment response: ${response.statusCode}');
      _log('Create assignment body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Assignment created successfully');
        return {'success': true, 'message': 'Assignment created successfully'};
      }
      
      final data = json.decode(response.body);
      _logError('Failed to create assignment', response.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to create assignment'};
    } catch (e) {
      _logError('Error creating assignment', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    try {
      _log('Deleting assignment: $assignmentId');
      
      final response = await http.delete(
        Uri.parse('${AppConfig.assignmentsUrl}/$assignmentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Delete assignment response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Assignment deleted successfully');
        return {'success': true, 'message': 'Assignment deleted successfully'};
      }
      
      _logError('Failed to delete assignment', response.body);
      return {'success': false, 'message': 'Failed to delete assignment'};
    } catch (e) {
      _logError('Error deleting assignment', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== ATTENDANCE ====================
  
  static Future<Map<String, dynamic>> markAttendance(List<Map<String, dynamic>> attendanceData) async {
    try {
      _log('Marking attendance for ${attendanceData.length} students');
      _log('URL: ${AppConfig.attendanceUrl}');
      _log('Sample data: ${attendanceData.take(1).toList()}');
      
      final response = await http.post(
        Uri.parse(AppConfig.attendanceUrl),
        headers: await _getHeaders(),
        body: json.encode({'attendance': attendanceData}),
      ).timeout(const Duration(seconds: 60));
      
      _log('Mark attendance response: ${response.statusCode}');
      _log('Mark attendance body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Attendance marked successfully');
        return {'success': true, 'message': 'Attendance marked successfully'};
      }
      
      _logError('Failed to mark attendance', response.body);
      return {'success': false, 'message': 'Failed to mark attendance: ${response.body}'};
    } catch (e) {
      _logError('Error marking attendance', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<List<dynamic>> getAttendanceByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      _log('Fetching attendance for date: $dateStr');
      
      final response = await http.get(
        Uri.parse('${AppConfig.attendanceUrl}/date/$dateStr'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get attendance response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attendance = data['attendance'] ?? data['data'] ?? [];
        _log('✅ Fetched ${attendance.length} attendance records');
        return attendance;
      }
      
      _logError('Failed to fetch attendance', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching attendance', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> updateAttendance(String id, String status) async {
    try {
      _log('Updating attendance: $id to $status');
      
      final response = await http.put(
        Uri.parse('${AppConfig.attendanceUrl}/$id'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 30));
      
      _log('Update attendance response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log('✅ Attendance updated successfully');
        return {'success': true, 'message': 'Attendance updated successfully'};
      }
      
      _logError('Failed to update attendance', response.body);
      return {'success': false, 'message': 'Failed to update attendance'};
    } catch (e) {
      _logError('Error updating attendance', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== FOLLOW-UP ====================
  
  static Future<Map<String, dynamic>> addFollowUp(
    Map<String, dynamic> followUpData,
    List<File>? documents,
  ) async {
    try {
      _log('Adding follow-up');
      _log('Follow-up data: $followUpData');
      _log('Documents: ${documents?.length ?? 0} files');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.followUpUrl),
      );
      
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      request.fields['studentId'] = followUpData['studentId']?.toString() ?? '';
      request.fields['teacherId'] = followUpData['teacherId']?.toString() ?? '';
      request.fields['notes'] = followUpData['notes']?.toString() ?? '';
      request.fields['reason'] = followUpData['reason']?.toString() ?? '';
      request.fields['date'] = followUpData['date']?.toString() ?? DateTime.now().toIso8601String();
      
      if (followUpData['attendanceId'] != null) {
        request.fields['attendanceId'] = followUpData['attendanceId'].toString();
      }
      
      if (documents != null) {
        for (var doc in documents) {
          _log('Adding file: ${doc.path}');
          request.files.add(await http.MultipartFile.fromPath('documents', doc.path));
        }
      }
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      
      _log('Add follow-up response: ${response.statusCode}');
      _log('Add follow-up body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _log('✅ Follow-up added successfully');
        return {
          'success': true,
          'message': 'Follow-up added successfully',
          'proofFileId': data['proofFileId'],
        };
      }
      
      _logError('Failed to add follow-up', response.body);
      return {'success': false, 'message': 'Failed to add follow-up: ${response.body}'};
    } catch (e) {
      _logError('Error adding follow-up', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<List<dynamic>> getFollowUpsByStudent(String studentId) async {
    try {
      _log('Fetching follow-ups for student: $studentId');
      
      final response = await http.get(
        Uri.parse('${AppConfig.followUpUrl}/student/$studentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get follow-ups response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final followUps = data['followUps'] ?? data['data'] ?? [];
        _log('✅ Fetched ${followUps.length} follow-ups');
        return followUps;
      }
      
      _logError('Failed to fetch follow-ups', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching follow-ups', e);
      return [];
    }
  }
  
  // ==================== REPORTS ====================
  
  static Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      _log('Fetching daily report for: $dateStr');
      
      final response = await http.get(
        Uri.parse('${AppConfig.reportsUrl}/daily/$dateStr'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Daily report response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log('✅ Daily report fetched');
        return json.decode(response.body);
      }
      
      _logError('Failed to fetch daily report', response.body);
      return {'success': false, 'message': 'Failed to fetch report'};
    } catch (e) {
      _logError('Error fetching daily report', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> getWeeklyReport(DateTime startDate, DateTime endDate) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];
      _log('Fetching weekly report: $startStr to $endStr');
      
      final response = await http.get(
        Uri.parse('${AppConfig.reportsUrl}/weekly?start=$startStr&end=$endStr'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Weekly report response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log('✅ Weekly report fetched');
        return json.decode(response.body);
      }
      
      _logError('Failed to fetch weekly report', response.body);
      return {'success': false, 'message': 'Failed to fetch report'};
    } catch (e) {
      _logError('Error fetching weekly report', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== USERS ====================
  
  static Future<List<dynamic>> getUsers() async {
    try {
      _log('Fetching users');
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Get users response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] ?? data['data'] ?? [];
        _log('✅ Fetched ${users.length} users');
        return users;
      }
      
      _logError('Failed to fetch users', response.body);
      return [];
    } catch (e) {
      _logError('Error fetching users', e);
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      _log('Creating user: ${userData['username']}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users'),
        headers: await _getHeaders(),
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 30));
      
      _log('Create user response: ${response.statusCode}');
      _log('Create user body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ User created successfully');
        return {'success': true, 'message': 'User created successfully'};
      }
      
      final data = json.decode(response.body);
      _logError('Failed to create user', response.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to create user'};
    } catch (e) {
      _logError('Error creating user', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> deactivateUser(String username) async {
    try {
      _log('Deactivating user: $username');
      
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/users/$username'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Deactivate user response: ${response.statusCode}');
      _log('Deactivate user body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ User deactivated successfully');
        return {'success': true, 'message': 'User deactivated successfully'};
      }
      
      _logError('Failed to deactivate user', response.body);
      return {'success': false, 'message': 'Failed to deactivate user'};
    } catch (e) {
      _logError('Error deactivating user', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== STATISTICS ====================
  
  static Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      _log('Fetching dashboard statistics');
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/statistics/dashboard'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      _log('Dashboard stats response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log('✅ Dashboard statistics fetched');
        return json.decode(response.body);
      }
      
      _logError('Failed to fetch statistics', response.body);
      return {'success': false, 'message': 'Failed to fetch statistics'};
    } catch (e) {
      _logError('Error fetching statistics', e);
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== HEALTH CHECK ====================
  
  static Future<bool> checkConnection() async {
    try {
      _log('Checking connection to: ${AppConfig.baseUrl}/health');
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 10));
      
      final connected = response.statusCode == 200;
      _log(connected ? '✅ Connection OK' : '❌ Connection failed: ${response.statusCode}');
      return connected;
    } catch (e) {
      _logError('Connection check failed', e);
      return false;
    }
  }
}