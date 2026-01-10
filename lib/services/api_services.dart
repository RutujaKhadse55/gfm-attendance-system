// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/attendance_model.dart';
import '../models/followup_model.dart';

class ApiService {
  static String? _authToken;
  
  // Store auth token
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Get auth token
  static Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }
  
  // Clear auth token
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Common headers
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
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await setAuthToken(data['token']);
          return {
            'success': true,
            'user': User.fromJson(data['user']),
            'token': data['token'],
          };
        }
      }
      
      return {'success': false, 'message': 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<void> logout() async {
    await clearAuthToken();
  }
  
  // ==================== STUDENTS ====================
  
  static Future<Map<String, dynamic>> importStudents(List<Map<String, dynamic>> students) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.studentsUrl}/import'),
        headers: await _getHeaders(),
        body: json.encode({'students': students}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'imported': data['imported'] ?? 0,
          'duplicates': data['duplicates'] ?? 0,
        };
      }
      
      return {'success': false, 'message': 'Import failed'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<List<Student>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.studentsUrl),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> studentsJson = data['students'] ?? [];
        return studentsJson.map((json) => Student.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> addStudent(Student student) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.studentsUrl),
        headers: await _getHeaders(),
        body: json.encode(student.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Student added successfully'};
      }
      
      return {'success': false, 'message': 'Failed to add student'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== TEACHERS ====================
  
  static Future<List<Teacher>> getTeachers() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.teachersUrl),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> teachersJson = data['teachers'] ?? [];
        return teachersJson.map((json) => Teacher.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> addTeacher(Map<String, dynamic> teacherData) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.teachersUrl),
        headers: await _getHeaders(),
        body: json.encode(teacherData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Teacher added successfully'};
      }
      
      final data = json.decode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Failed to add teacher'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> updateTeacher(String id, Map<String, dynamic> teacherData) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.teachersUrl}/$id'),
        headers: await _getHeaders(),
        body: json.encode(teacherData),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Teacher updated successfully'};
      }
      
      return {'success': false, 'message': 'Failed to update teacher'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteTeacher(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.teachersUrl}/$id'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Teacher deleted successfully'};
      }
      
      return {'success': false, 'message': 'Failed to delete teacher'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== ATTENDANCE ====================
  
  static Future<Map<String, dynamic>> markAttendance(List<Map<String, dynamic>> attendanceData) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.attendanceUrl),
        headers: await _getHeaders(),
        body: json.encode({'attendance': attendanceData}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Attendance marked successfully'};
      }
      
      return {'success': false, 'message': 'Failed to mark attendance'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<List<Attendance>> getAttendanceByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${AppConfig.attendanceUrl}/date/$dateStr'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> attendanceJson = data['attendance'] ?? [];
        return attendanceJson.map((json) => Attendance.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> updateAttendance(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.attendanceUrl}/$id'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Attendance updated successfully'};
      }
      
      return {'success': false, 'message': 'Failed to update attendance'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  // ==================== FOLLOW-UP ====================
  
  static Future<Map<String, dynamic>> addFollowUp(Map<String, dynamic> followUpData, List<File>? documents) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.followUpUrl),
      );
      
      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Add fields
      request.fields['studentId'] = followUpData['studentId'];
      request.fields['teacherId'] = followUpData['teacherId'];
      request.fields['notes'] = followUpData['notes'];
      request.fields['date'] = followUpData['date'];
      
      // Add files
      if (documents != null) {
        for (var doc in documents) {
          request.files.add(await http.MultipartFile.fromPath('documents', doc.path));
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Follow-up added successfully'};
      }
      
      return {'success': false, 'message': 'Failed to add follow-up'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<List<FollowUp>> getFollowUpsByStudent(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.followUpUrl}/student/$studentId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> followUpsJson = data['followUps'] ?? [];
        return followUpsJson.map((json) => FollowUp.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching follow-ups: $e');
      return [];
    }
  }
  
  // ==================== REPORTS ====================
  
  static Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${AppConfig.reportsUrl}/daily/$dateStr'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return {'success': false, 'message': 'Failed to fetch report'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<Map<String, dynamic>> getWeeklyReport(DateTime startDate, DateTime endDate) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${AppConfig.reportsUrl}/weekly?start=$startStr&end=$endStr'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return {'success': false, 'message': 'Failed to fetch report'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
  
  static Future<String?> downloadReportPdf(String reportType, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${AppConfig.reportsUrl}/pdf/$reportType/$dateStr'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return response.body; // This should be the PDF file path/URL
      }
      
      return null;
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }
}