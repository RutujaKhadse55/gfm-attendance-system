// lib/screens/attendance_teacher_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import 'login_screen.dart';

class AttendanceTeacherScreen extends StatefulWidget {
  const AttendanceTeacherScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceTeacherScreen> createState() => _AttendanceTeacherScreenState();
}

class _AttendanceTeacherScreenState extends State<AttendanceTeacherScreen> {
  int? _selectedBatchId;
  List<Student> _students = [];
  Map<String, String> _attendanceStatus = {};
  Map<String, Attendance> _existingAttendance = {};
  bool _loading = false;
  bool _submitting = false;
  DateTime _selectedDate = DateTime.now();
  int _presentCount = 0;
  int _absentCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBatches();
    });
  }

  void _loadBatches() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loadBatches();
  }

  void _loadStudents() async {
    if (_selectedBatchId == null) return;

    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final students = await provider.getStudentsByBatch(_selectedBatchId!);

    if (students.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found in this batch'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _loading = false);
      return;
    }

    // Load existing attendance
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final existingAttendanceList =
        await provider.getAttendanceByBatchAndDate(_selectedBatchId!, dateStr);

    Map<String, String> statusMap = {};
    Map<String, Attendance> attMap = {};

    for (var att in existingAttendanceList) {
      statusMap[att.studentPrn] = att.status;
      attMap[att.studentPrn] = att;
    }

    // Initialize status for students without records
    for (var student in students) {
      if (!statusMap.containsKey(student.prn)) {
        statusMap[student.prn] = 'Present';
      }
    }

    _updateCounts(statusMap);

    setState(() {
      _students = students;
      _attendanceStatus = statusMap;
      _existingAttendance = attMap;
      _loading = false;
    });
  }

  void _updateCounts(Map<String, String> statusMap) {
    int present = 0;
    int absent = 0;

    for (var status in statusMap.values) {
      if (status == 'Present') {
        present++;
      } else if (status == 'Absent') {
        absent++;
      }
    }

    setState(() {
      _presentCount = present;
      _absentCount = absent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayDate = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${provider.userName}'),
        backgroundColor: Colors.green.shade700,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainView(provider, todayDate),
    );
  }

  Widget _buildMainView(AppProvider provider, String todayDate) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Date Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          todayDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _students = [];
                          _attendanceStatus = {};
                          _existingAttendance = {};
                          _presentCount = 0;
                          _absentCount = 0;
                        });
                        _loadStudents();
                      }
                    },
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: Text(
                      _selectedDate.day == DateTime.now().day
                          ? 'Change'
                          : DateFormat('dd MMM').format(_selectedDate),
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
              prefixIcon: Icon(Icons.class_, color: Colors.green.shade700),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            value: _selectedBatchId,
            items: provider.batches.map((batch) {
              return DropdownMenuItem(
                value: batch.id,
                child: Text(batch.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBatchId = val;
                _students = [];
                _attendanceStatus = {};
                _existingAttendance = {};
                _presentCount = 0;
                _absentCount = 0;
              });
              _loadStudents();
            },
          ),
          const SizedBox(height: 16),

          // Summary Stats
          if (_students.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    _students.length.toString(),
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    _presentCount.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    _absentCount.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Students List
          Expanded(
            child: _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedBatchId == null
                              ? 'Select a batch to mark attendance'
                              : 'No students in this batch',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (ctx, i) {
                      final student = _students[i];
                      final status = _attendanceStatus[student.prn] ?? 'Present';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                status == 'Present' ? Colors.green : Colors.red,
                            child: Text(
                              student.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('PRN: ${student.prn}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Present'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: status == 'Present',
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                onChanged: (val) {
                                  setState(() {
                                    _attendanceStatus[student.prn] =
                                        val ? 'Present' : 'Absent';
                                    _updateCounts(_attendanceStatus);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Submit Button
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAttendance() async {
    // Validation
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a batch'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students to submit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✅ Present',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('$_presentCount students'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '❌ Absent',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('$_absentCount students'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${_students.length} students',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final now = DateTime.now().millisecondsSinceEpoch;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      List<Attendance> attendanceList = [];
      for (var student in _students) {
        final status = _attendanceStatus[student.prn] ?? 'Present';

        final attendance = Attendance(
          studentPrn: student.prn,
          batchId: _selectedBatchId!,
          date: dateStr,
          status: status,
          createdAt: now,
        );

        attendanceList.add(attendance);
      }

      final result = await provider.markAttendanceBatch(attendanceList);

      setState(() => _submitting = false);

      if (mounted) {
        // FIX: Check for 'success' as bool, not int
        final bool isSuccess = result['success'] == true;
        
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Attendance submitted successfully! (${result['count'] ?? attendanceList.length} records)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          _loadStudents(); // Reload to show updated data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message'] ?? 'Failed to submit attendance'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}