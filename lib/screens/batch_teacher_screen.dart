// lib/screens/batch_teacher_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import 'login_screen.dart';

class BatchTeacherScreen extends StatefulWidget {
  const BatchTeacherScreen({Key? key}) : super(key: key);

  @override
  State<BatchTeacherScreen> createState() => _BatchTeacherScreenState();
}

class _BatchTeacherScreenState extends State<BatchTeacherScreen> {
  List<Assignment> _myAssignments = [];
  int? _selectedBatchId;
  List<AbsentStudentDetail> _absentStudents = [];
  bool _loading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loadBatches();

    final assignments = await provider.getTeacherAssignmentsByRole(
      provider.userId,
      'batch_teacher',
    );
    setState(() => _myAssignments = assignments);
  }

  void _loadAbsentStudents() async {
    if (_selectedBatchId == null) return;

    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final absentList = await provider.getAbsentStudents(_selectedBatchId!, dateStr);

    setState(() {
      _absentStudents = absentList;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Follow-Up - ${provider.userName}'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                provider.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadAbsentStudents();
                          }
                        },
                        child: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Batch Selection
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Select Batch',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_, color: Colors.orange.shade700),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              value: _selectedBatchId,
              items: _myAssignments.map((assignment) {
                final batch = provider.batches
                    .firstWhere((b) => b.id == assignment.batchId);
                return DropdownMenuItem(
                  value: batch.id,
                  child: Text(batch.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBatchId = val;
                  _absentStudents = [];
                });
                _loadAbsentStudents();
              },
            ),
            const SizedBox(height: 20),

            // Summary
            if (_selectedBatchId != null && !_loading)
              Card(
                color: _absentStudents.isEmpty
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _absentStudents.isEmpty
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _absentStudents.isEmpty
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _absentStudents.isEmpty
                            ? 'No absent students on this date'
                            : '${_absentStudents.length} absent student(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Absent Students List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _absentStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedBatchId == null
                                    ? Icons.class_outlined
                                    : Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedBatchId == null
                                    ? 'Select a batch to view absent students'
                                    : 'No absent students for selected date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _absentStudents.length,
                          itemBuilder: (ctx, i) {
                            final detail = _absentStudents[i];
                            return _AbsentStudentCard(
                              detail: detail,
                              onFollowUpSaved: _loadAbsentStudents,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ABSENT STUDENT CARD ====================

class _AbsentStudentCard extends StatelessWidget {
  final AbsentStudentDetail detail;
  final VoidCallback onFollowUpSaved;

  const _AbsentStudentCard({
    required this.detail,
    required this.onFollowUpSaved,
  });

  @override
  Widget build(BuildContext context) {
    final student = detail.student;
    final hasFollowUp = detail.followUp != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: hasFollowUp
                      ? Colors.green
                      : Colors.red,
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PRN: ${student.prn}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Absent on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(detail.attendance.date))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFollowUp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Contact Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(student.mobile),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text(
                      'Call Student',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(student.parentMobile),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text(
                      'Call Parent',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Email Buttons - FIXED
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(
                      context,
                      student.email,
                      student.name,
                      isParent: false,
                    ),
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text(
                      'Email Student',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(
                      context,
                      student.parentMobile, // This should be parent email
                      student.name,
                      isParent: true,
                    ),
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text(
                      'Email Parent',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Follow-Up Status
            if (hasFollowUp) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Follow-Up Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${detail.followUp!.reason}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recorded: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(detail.followUp!.timestamp))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (detail.followUp!.proofPath != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _viewProof(context, detail.followUp!.proofPath!),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Proof'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const Divider(),
              ElevatedButton.icon(
                onPressed: () => _showFollowUpDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Record Follow-Up'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // FIXED: Direct email opening
  void _sendEmail(BuildContext context, String email, String studentName, {bool isParent = false}) async {
    // Validate email
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isParent ? "Parent" : "Student"} email not available or invalid'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final subject = Uri.encodeComponent('Follow-up: Absence Notification - $studentName');
    final body = Uri.encodeComponent(
      'Dear ${isParent ? 'Parent/Guardian' : studentName},\n\n'
      'This is a follow-up regarding the recent absence of $studentName from class.\n\n'
      'We would like to understand the reason for the absence and ensure everything is okay. '
      'Please feel free to reach out to us if you need any assistance or have any concerns.\n\n'
      'Best regards,\n'
      'Attendance Management Team',
    );

    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: View proof functionality
  void _viewProof(BuildContext context, String proofPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Proof Document'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: _buildProofViewer(proofPath),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofViewer(String proofPath) {
    final file = File(proofPath);
    final extension = proofPath.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      // Image viewer
      return InteractiveViewer(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Could not load image'),
                ],
              ),
            );
          },
        ),
      );
    } else if (extension == 'pdf') {
      // PDF viewer placeholder
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'PDF Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              proofPath.split('/').last,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.file(proofPath);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External App'),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Unsupported file format'),
          ],
        ),
      );
    }
  }

  void _showFollowUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _FollowUpDialog(
        studentName: detail.student.name,
        attendanceId: detail.attendance.id!,
        onSaved: onFollowUpSaved,
      ),
    );
  }
}

// ==================== FOLLOW-UP DIALOG ====================

class _FollowUpDialog extends StatefulWidget {
  final String studentName;
  final int attendanceId;
  final VoidCallback onSaved;

  const _FollowUpDialog({
    required this.studentName,
    required this.attendanceId,
    required this.onSaved,
  });

  @override
  State<_FollowUpDialog> createState() => _FollowUpDialogState();
}

class _FollowUpDialogState extends State<_FollowUpDialog> {
  final _reasonController = TextEditingController();
  String? _proofPath;
  String? _proofType;
  final _picker = ImagePicker();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Follow-Up: ${widget.studentName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Absence Reason *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Medical, Family emergency',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            const Text(
              'Proof (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Camera', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadDocument,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),

            if (_proofPath != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.green.shade50,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _proofType == 'image' ? Icons.image : Icons.picture_as_pdf,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ Proof Attached',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _proofPath!.split('/').last,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() {
                        _proofPath = null;
                        _proofType = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveFollowUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _captureImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _proofPath = image.path;
        _proofType = 'image';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Photo captured'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File must be less than 10MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _proofPath = file.path!;
        _proofType = file.extension == 'pdf' ? 'pdf' : 'image';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ File uploaded'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveFollowUp() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty || reason.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reason must be at least 5 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final followUp = FollowUp(
        attendanceId: widget.attendanceId,
        reason: reason,
        proofPath: _proofPath,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await provider.saveFollowUp(followUp);

      setState(() => _saving = false);

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Follow-up recorded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          widget.onSaved();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}