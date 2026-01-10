
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<String?> generateDailyReport({
    required DateTime date,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Extract data
      final List<dynamic> attendance = reportData['attendance'] ?? [];
      final presentCount = attendance.where((a) => a['status'] == 'Present').length;
      final absentCount = attendance.where((a) => a['status'] == 'Absent').length;
      final totalStudents = attendance.length;
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Daily Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(date),
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem('Total Students', totalStudents.toString(), PdfColors.blue),
                      _summaryItem('Present', presentCount.toString(), PdfColors.green),
                      _summaryItem('Absent', absentCount.toString(), PdfColors.red),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Attendance Rate: ${totalStudents > 0 ? ((presentCount / totalStudents) * 100).toStringAsFixed(1) : 0}%',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 24),
            
            // Detailed Table
            pw.Text(
              'Detailed Attendance',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableCell('S.No', isHeader: true),
                    _tableCell('Student Name', isHeader: true),
                    _tableCell('Roll Number', isHeader: true),
                    _tableCell('Status', isHeader: true),
                  ],
                ),
                // Data rows
                ...attendance.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final status = record['status'] ?? 'Unknown';
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isEven ? PdfColors.white : PdfColors.grey100,
                    ),
                    children: [
                      _tableCell((index + 1).toString()),
                      _tableCell(record['studentName'] ?? 'N/A'),
                      _tableCell(record['rollNumber'] ?? 'N/A'),
                      _tableCell(
                        status,
                        textColor: status == 'Present' ? PdfColors.green : PdfColors.red,
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // Footer
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'This is a computer-generated report',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ),
      );
      
      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      final fileName = 'attendance_${DateFormat('yyyy-MM-dd').format(date)}.pdf';
      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }
  
  static Future<String?> generateWeeklyReport({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Weekly Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Weekly summary
            pw.Text(
              'Weekly Overview',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            
            pw.Text(
              'Detailed daily attendance records will be included here.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            
            pw.SizedBox(height: 24),
            
            // Footer
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'This is a computer-generated report',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ),
      );
      
      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      final fileName = 'weekly_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf';
      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }
  
  static pw.Widget _summaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }
}