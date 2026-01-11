// lib/utils/excel_parser.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/app_models.dart' as models;

class ExcelParser {
  /// Parse students from Excel or CSV file
  /// Expected columns: PRN, Name, Mobile, Parent Mobile, Email, Batch ID
  static Future<List<models.Student>> parseStudentsFile(
    File file,
    int headerRow,
  ) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'csv') {
      return await _parseCSV(file, headerRow);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return await _parseExcel(file, headerRow);
    }

    throw Exception('Unsupported file format: $extension');
  }

  static Future<List<models.Student>> _parseCSV(File file, int headerRow) async {
    try {
      final input = await file.readAsString();
      final rows = const CsvToListConverter().convert(input);

      if (rows.length <= headerRow + 1) {
        return [];
      }

      final List<models.Student> students = [];

      // Start from headerRow + 1 to skip header
      for (int i = headerRow + 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          // Expected format: PRN, Name, Mobile, Parent Mobile, Email, Batch ID
          if (row.length >= 6) {
            final prn = row[0]?.toString().trim() ?? '';
            final name = row[1]?.toString().trim() ?? '';
            final mobile = row[2]?.toString().trim() ?? '';
            final parentMobile = row[3]?.toString().trim() ?? '';
            final email = row[4]?.toString().trim() ?? '';
            final batchIdStr = row[5]?.toString().trim() ?? '';

            // Validate required fields
            if (prn.isEmpty || name.isEmpty) {
              continue; // Skip rows with missing required data
            }

            int batchId;
            try {
              batchId = int.parse(batchIdStr);
            } catch (_) {
              continue; // Skip rows with invalid batch ID
            }

            students.add(models.Student(
              prn: prn,
              name: name,
              mobile: mobile,
              parentMobile: parentMobile,
              email: email,
              batchId: batchId,
            ));
          }
        } catch (e) {
          // Skip malformed rows
          continue;
        }
      }

      return students;
    } catch (e) {
      throw Exception('Error parsing CSV: ${e.toString()}');
    }
  }

  static Future<List<models.Student>> _parseExcel(File file, int headerRow) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final List<models.Student> students = [];

      // Get the first sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        return [];
      }

      final rows = sheet.rows;
      if (rows.length <= headerRow + 1) {
        return [];
      }

      // Start from headerRow + 1 to skip header
      for (int i = headerRow + 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell == null || cell?.value == null)) {
          continue;
        }

        try {
          // Expected format: PRN, Name, Mobile, Parent Mobile, Email, Batch ID
          if (row.length >= 6) {
            final prn = row[0]?.value?.toString().trim() ?? '';
            final name = row[1]?.value?.toString().trim() ?? '';
            final mobile = row[2]?.value?.toString().trim() ?? '';
            final parentMobile = row[3]?.value?.toString().trim() ?? '';
            final email = row[4]?.value?.toString().trim() ?? '';
            final batchIdStr = row[5]?.value?.toString().trim() ?? '';

            // Validate required fields
            if (prn.isEmpty || name.isEmpty) {
              continue; // Skip rows with missing required data
            }

            int batchId;
            try {
              batchId = int.parse(batchIdStr);
            } catch (_) {
              // Try parsing as double and converting to int
              try {
                batchId = double.parse(batchIdStr).toInt();
              } catch (_) {
                continue; // Skip rows with invalid batch ID
              }
            }

            students.add(models.Student(
              prn: prn,
              name: name,
              mobile: mobile,
              parentMobile: parentMobile,
              email: email,
              batchId: batchId,
            ));
          }
        } catch (e) {
          // Skip malformed rows
          continue;
        }
      }

      return students;
    } catch (e) {
      throw Exception('Error parsing Excel: ${e.toString()}');
    }
  }

  /// Generate sample CSV template
  static String generateSampleCSV() {
    return 'PRN,Name,Mobile,Parent Mobile,Email,Batch ID\n'
        '21001,John Doe,9876543210,9876543211,john@example.com,1\n'
        '21002,Jane Smith,9876543212,9876543213,jane@example.com,1\n'
        '21003,Bob Johnson,9876543214,9876543215,bob@example.com,2\n';
  }

  /// Validate student data
  static Map<String, dynamic> validateStudent(models.Student student) {
    List<String> errors = [];

    if (student.prn.isEmpty) {
      errors.add('PRN is required');
    }

    if (student.name.isEmpty) {
      errors.add('Name is required');
    }

    if (student.mobile.isEmpty) {
      errors.add('Mobile is required');
    } else if (!RegExp(r'^\d{10}$').hasMatch(student.mobile)) {
      errors.add('Mobile must be 10 digits');
    }

    if (student.parentMobile.isEmpty) {
      errors.add('Parent mobile is required');
    } else if (!RegExp(r'^\d{10}$').hasMatch(student.parentMobile)) {
      errors.add('Parent mobile must be 10 digits');
    }

    if (student.email.isEmpty) {
      errors.add('Email is required');
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(student.email)) {
      errors.add('Invalid email format');
    }

    if (student.batchId <= 0) {
      errors.add('Valid batch ID is required');
    }

    return {
      'valid': errors.isEmpty,
      'errors': errors,
    };
  }
}