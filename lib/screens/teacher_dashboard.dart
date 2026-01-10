// lib/screens/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/followup_model.dart';
import 'login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AttendanceTab(),
    FollowUpTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher - ${provider.currentUser?.fullName ?? "Teacher"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await provider.loadStudents();
              await provider.loadTodayAttendance();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data refreshed')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await provider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add),
            label: 'Follow-Up',
          ),
        ],
      ),
    );
  }
}

// ==================== ATTENDANCE TAB ====================
class AttendanceTab extends StatefulWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceStatus = {}; // studentId -> status
  bool _loading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loadStudents();
    final attendance = await provider.loadAttendanceByDate(_selectedDate);

    // Initialize attendance status
    _attendanceStatus.clear();
    for (var att in attendance) {
      if (att.studentId != null && att.status != null) {
        _attendanceStatus[att.studentId!] = att.status!;
      }
    }

    // Set default "Present" for students without attendance
    for (var student in provider.students) {
      if (student.id != null && !_attendanceStatus.containsKey(student.id)) {
        _attendanceStatus[student.id!] = 'Present';
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final students = provider.students;

    final presentCount =
        _attendanceStatus.values.where((s) => s == 'Present').length;
    final absentCount =
        _attendanceStatus.values.where((s) => s == 'Absent').length;

    return Column(
      children: [
        // Date Selector
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadAttendance();
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ),

        // Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          presentCount.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Present', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          absentCount.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const Text('Absent', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Student List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? const Center(child: Text('No students found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final studentId = student.id ?? '';
                        final status = _attendanceStatus[studentId] ?? 'Present';
                        final isPresent = status == 'Present';
                        final studentName = student.name ?? '-';
                        final studentPrn = student.prn ?? '-';
                        

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isPresent ? Colors.green : Colors.red,
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : '-',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(studentName),
                            subtitle: Text('Roll: $studentPrn'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: isPresent,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                  onChanged: (value) {
                                    setState(() {
                                      _attendanceStatus[studentId] =
                                          value ? 'Present' : 'Absent';
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
        if (students.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAttendance,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.blue,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'SUBMIT ATTENDANCE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _submitAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Attendance'),
        content: const Text(
          'Are you sure you want to submit attendance?\n\n'
          'This will update all attendance records for the selected date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final attendanceData = _attendanceStatus.entries.map((entry) {
      return {
        'studentId': entry.key,
        'teacherId': provider.currentUser!.id,
        'date': _selectedDate.toIso8601String(),
        'status': entry.value,
      };
    }).toList();

    final result = await provider.markAttendance(attendanceData);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Attendance submitted'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      await _loadAttendance();
    }
  }
}

// ==================== FOLLOW-UP TAB ====================
class FollowUpTab extends StatefulWidget {
  const FollowUpTab({Key? key}) : super(key: key);

  @override
  State<FollowUpTab> createState() => _FollowUpTabState();
}

class _FollowUpTabState extends State<FollowUpTab> {
  String _selectedFilter = 'all'; // all, absent, present

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final students = provider.students;

    // Filter students based on selection
    final filteredStudents = students.where((student) {
      final studentId = student.id ?? '';
      if (_selectedFilter == 'all') return true;
      final status = provider.getStudentAttendanceStatus(studentId) ?? '';
      if (_selectedFilter == 'absent') return status == 'Absent';
      if (_selectedFilter == 'present') return status == 'Present';
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'all');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Absent'),
                  selected: _selectedFilter == 'absent',
                  selectedColor: Colors.red.shade100,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'absent');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Present'),
                  selected: _selectedFilter == 'present',
                  selectedColor: Colors.green.shade100,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'present');
                  },
                ),
              ),
            ],
          ),
        ),

        // Student List
        Expanded(
          child: filteredStudents.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentId = student.id ?? '';
                    final status =
                        provider.getStudentAttendanceStatus(studentId) ?? '';
                    final followUps = provider.getStudentFollowUps(studentId);
                    final studentName = student.name ?? '-';
                    final studentPrn = student.prn ?? '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              status == 'Absent' ? Colors.red : Colors.green,
                          child: Text(
                            studentName.isNotEmpty
                                ? studentName[0].toUpperCase()
                                : '-',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(studentName),
                        subtitle: Text('Roll: $studentPrn\nStatus: ${status.isNotEmpty ? status : "Not marked"}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Contact Info
                                _InfoRow(
                                  icon: Icons.phone,
                                  label: 'Mobile',
                                  value: student.mobile ?? '-',
                                ),
                                _InfoRow(
                                  icon: Icons.phone_android,
                                  label: 'Parent Mobile',
                                  value: student.parentMobile ?? '-',
                                ),
                                _InfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: student.email ?? '-',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== INFO ROW ====================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
