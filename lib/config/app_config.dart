
class AppConfig {
  // Base URL - CHANGE THIS to your server IP/domain
  // For Android Emulator use: 'http://10.0.2.2:3000/api'
  // For physical device on same network: 'http://192.168.x.x:3000/api'
  // For iOS Simulator use: 'http://localhost:3000/api'
  // For production: 'https://yourdomain.com/api'
  static const String baseUrl = 'http://10.81.180.166:4000/api';
  
  // Auth endpoints
  static const String loginUrl = '$baseUrl/auth/login';
  
  // Student endpoints
  static const String studentsUrl = '$baseUrl/students';
  static const String studentsImportUrl = '$baseUrl/students/import';
  
  // Teacher endpoints
  static const String teachersUrl = '$baseUrl/teachers';
  
  // Batch endpoints
  static const String batchesUrl = '$baseUrl/batches';
  
  // Assignment endpoints
  static const String assignmentsUrl = '$baseUrl/assignments';
  
  // Attendance endpoints
  static const String attendanceUrl = '$baseUrl/attendance';
  
  // Follow-up endpoints
  static const String followUpUrl = '$baseUrl/followup';
  
  // Reports endpoints
  static const String reportsUrl = '$baseUrl/reports';
  
  // User management endpoints
  static const String usersUrl = '$baseUrl/users';
  
  // Statistics endpoints
  static const String statisticsUrl = '$baseUrl/statistics';
  
  // File upload endpoint
  static const String proofUploadUrl = '$followUpUrl';
  
  // Upload base URL (for viewing uploaded files)
  static const String uploadsBaseUrl = 'http://10.0.2.2:4000/uploads';
  // For physical device: 'http://192.168.x.x:4000/uploads'

  // App settings
  static const int requestTimeout = 30; // seconds
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedFileTypes = ['jpg', 'jpeg', 'png', 'pdf'];
}
