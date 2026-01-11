// lib/utils/pdf_generator.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfGenerator {
  /// Generate Daily Attendance Report
  static Future<File> generateDailyReport({
    required String date,
    required List<Map<String, dynamic>> data,
    required Map<String, int> summary,
  }) async {
    final pdf = pw.Document();
    final dateFormatted = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Daily Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    dateFormatted,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color:PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Present', summary['present'] ?? 0, PdfColors.green),
                _buildSummaryCard('Absent', summary['absent'] ?? 0, PdfColors.red),
                _buildSummaryCard('Total', (summary['present'] ?? 0) + (summary['absent'] ?? 0), PdfColors.blue),
              ],
            ),
            pw.SizedBox(height: 30),

            // Attendance Table
            if (data.isNotEmpty) ...[
              pw.Text(
                'Batch-wise Attendance',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildAttendanceTable(data),
            ] else
              pw.Center(
                child: pw.Text(
                  'No attendance records found',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey,
                  ),
                ),
              ),

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'GFM System',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return _savePdf(pdf, 'Daily_Report_${DateFormat('yyyy-MM-dd').format(DateTime.parse(date))}.pdf');
  }

  /// Generate Weekly Attendance Report
  static Future<File> generateWeeklyReport({
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> data,
    int? batchId,
  }) async {
    final pdf = pw.Document();
    final start = DateFormat('dd MMM yyyy').format(DateTime.parse(startDate));
    final end = DateFormat('dd MMM yyyy').format(DateTime.parse(endDate));

    // Calculate summary
    final summary = _calculateSummary(data);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Weekly Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '$start - $end',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                  if (batchId != null)
                    pw.Text(
                      'Batch ID: $batchId',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Present', summary['present']!, PdfColors.green),
                _buildSummaryCard('Absent', summary['absent']!, PdfColors.red),
                _buildSummaryCard('Days', summary['days']!, PdfColors.blue),
              ],
            ),
            pw.SizedBox(height: 30),

            // Data Table
            if (data.isNotEmpty) ...[
              pw.Text(
                'Detailed Records',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildAttendanceTable(data),
            ] else
              pw.Center(
                child: pw.Text(
                  'No attendance records found for this period',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey,
                  ),
                ),
              ),

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'GFM System',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple700,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return _savePdf(pdf, 'Weekly_Report_${DateFormat('yyyy-MM-dd').format(DateTime.parse(startDate))}_to_${DateFormat('yyyy-MM-dd').format(DateTime.parse(endDate))}.pdf');
  }

  /// Generate Monthly Attendance Report
  static Future<File> generateMonthlyReport({
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> data,
    int? batchId,
  }) async {
    final pdf = pw.Document();
    final monthYear = DateFormat('MMMM yyyy').format(DateTime.parse(startDate));

    // Calculate summary
    final summary = _calculateSummary(data);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Monthly Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    monthYear,
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                  if (batchId != null)
                    pw.Text(
                      'Batch ID: $batchId',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Present', summary['present']!, PdfColors.green),
                _buildSummaryCard('Absent', summary['absent']!, PdfColors.red),
                _buildSummaryCard('Avg %', summary['percentage']!, PdfColors.blue),
              ],
            ),
            pw.SizedBox(height: 30),

            // Data Table
            if (data.isNotEmpty) ...[
              pw.Text(
                'Monthly Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildAttendanceTable(data),
            ] else
              pw.Center(
                child: pw.Text(
                  'No attendance records found for this month',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey,
                  ),
                ),
              ),

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'GFM System',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return _savePdf(pdf, 'Monthly_Report_${monthYear.replaceAll(' ', '_')}.pdf');
  }

  // Helper: Build summary card
  static pw.Widget _buildSummaryCard(String label, int value, PdfColor color) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: color.shade(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build attendance table
  static pw.Widget _buildAttendanceTable(List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Batch', isHeader: true),
            _buildTableCell('Status', isHeader: true),
            _buildTableCell('Count', isHeader: true),
          ],
        ),
        // Data rows
        ...data.map((record) {
          final status = record['status'] as String;
          final color = status == 'Present' ? PdfColors.green : PdfColors.red;
          
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('dd MMM').format(DateTime.parse(record['date']))),
              _buildTableCell(record['batch_name'] ?? 'N/A'),
              _buildTableCell(status, textColor: color),
              _buildTableCell(record['count'].toString()),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Helper: Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }

  // Helper: Calculate summary from data
  static Map<String, int> _calculateSummary(List<Map<String, dynamic>> data) {
    int presentCount = 0;
    int absentCount = 0;
    final uniqueDates = <String>{};

    for (var record in data) {
      uniqueDates.add(record['date']);
      final count = record['count'] as int;
      if (record['status'] == 'Present') {
        presentCount += count;
      } else {
        absentCount += count;
      }
    }

    final total = presentCount + absentCount;
    final percentage = total > 0 ? ((presentCount / total) * 100).round() : 0;

    return {
      'present': presentCount,
      'absent': absentCount,
      'days': uniqueDates.length,
      'percentage': percentage,
    };
  }

  // Helper: Save PDF to file
  static Future<File> _savePdf(pw.Document pdf, String filename) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Share or print PDF
  static Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  /// Preview PDF before saving
  static Future<void> previewPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}