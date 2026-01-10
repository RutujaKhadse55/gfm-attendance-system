/// Global app configuration
class AppConfig {
  // Backend API endpoint
  static const String mongoDbUrl = 'mongodb+srv://gfm_record:rutuja%40123@cluster0.9mereij.mongodb.net/gfm?retryWrites=true&w=majority';
  // Alternative for mobile testing (replace with your actual server IP/domain)
  static const String backendUrl = 'http://10.81.180.166:4000/api';
  
  // Proof upload endpoint
  static String get proofUploadUrl => '$backendUrl/followups';
  static String get loginUrl => '$backendUrl/auth/login';
  static String get studentsUrl => '$backendUrl/students';
  static String get teachersUrl => '$backendUrl/teachers';
  static String get attendanceUrl => '$backendUrl/attendance';
  static String get followUpUrl => '$backendUrl/followup';
  static String get reportsUrl => '$backendUrl/reports';
  // Proof download endpoint  
  static String proofDownloadUrl(String fileId) => '$backendUrl/followups/proof/$fileId';
}
