import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import '../models/student_model.dart';

class ExcelParser {
  /// Detects file type and parses student list
  static Future<List<Student>> parseStudentsFile(
    File file,
    int batchId, // REQUIRED – comes from UI selection
  ) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'csv') {
      return _parseCsv(file, batchId);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(file, batchId);
    }

    throw Exception('Unsupported file format');
  }

  // ================= CSV PARSER =================

  static Future<List<Student>> _parseCsv(File file, int batchId) async {
    try {
      final input = await file.readAsString();
      final rows = const CsvToListConverter().convert(input);

      if (rows.length < 2) return [];

      final students = <Student>[];

      // Skip header row
      for (final row in rows.skip(1)) {
        if (row.length < 5) continue;

        final prn = row[1].toString().trim();
        final name = row[0].toString().trim();

        if (prn.isEmpty || name.isEmpty) continue;

        students.add(
          Student(
            prn: prn,
            name: name,
            mobile: row[2].toString().trim(),
            parentMobile: row[3].toString().trim(),
            email: row[4].toString().trim(),
            batchId: batchId,
            createdAt: DateTime.now(),
          ),
        );
      }

      return students;
    } catch (e) {
      print('CSV parse error: $e');
      return [];
    }
  }

  // ================= EXCEL PARSER =================

  static Future<List<Student>> _parseExcel(File file, int batchId) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) return [];

      final sheet = excel.tables.values.first;
      if (sheet.rows.length < 2) return [];

      final students = <Student>[];

      // Skip header row
      for (final row in sheet.rows.skip(1)) {
        if (row.length < 5) continue;

        final prn = row[1]?.value.toString().trim() ?? '';
        final name = row[0]?.value.toString().trim() ?? '';

        if (prn.isEmpty || name.isEmpty) continue;

        students.add(
          Student(
            prn: prn,
            name: name,
            mobile: row[2]?.value.toString().trim() ?? '',
            parentMobile: row[3]?.value.toString().trim() ?? '',
            email: row[4]?.value.toString().trim() ?? '',
            batchId: batchId,
            createdAt: DateTime.now(),
          ),
        );
      }

      return students;
    } catch (e) {
      print('Excel parse error: $e');
      return [];
    }
  }
}
