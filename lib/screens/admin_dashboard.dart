// lib/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../utils/excel_parser.dart';
import '../utils/pdf_generator.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardTab(),
    StudentsTab(),
    TeachersTab(),
    ReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard - ${provider.currentUser?.fullName ?? "Admin"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await provider.loadStudents();
              await provider.loadTeachers();
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Teachers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// ==================== DASHBOARD TAB ====================
class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayDate = DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now());
    
    final presentCount = provider.todayAttendance.where((a) => a.status == 'Present').length;
    final absentCount = provider.todayAttendance.where((a) => a.status == 'Absent').length;
    final totalStudents = provider.students.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    todayDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Students',
                  value: totalStudents.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Teachers',
                  value: provider.teachers.length.toString(),
                  icon: Icons.person,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Present Today',
                  value: presentCount.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Absent Today',
                  value: absentCount.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Attendance Rate
          if (provider.todayAttendance.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Attendance Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: presentCount / (presentCount + absentCount),
                      minHeight: 10,
                      backgroundColor: Colors.red.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((presentCount / (presentCount + absentCount)) * 100).toStringAsFixed(1)}% Present',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STUDENTS TAB ====================
class StudentsTab extends StatelessWidget {
  const StudentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _importStudents(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Students (CSV/Excel)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.students.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Import students to get started',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.students.length,
                      itemBuilder: (context, index) {
                        final student = provider.students[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(student.name[0].toUpperCase()),
                          ),
                          title: Text(student.name),
                          subtitle: Text(
                            'Roll: ${student.prn}\nMobile: ${student.mobile}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _importStudents(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'xlsx', 'xls'],
  );

  if (result == null) return;

  final file = File(result.files.single.path!);

  final provider = Provider.of<AppProvider>(context, listen: false);

  final students = await ExcelParser.parseStudentsFile(
    file,
    0, // fallback safety
  );

  if (!context.mounted) return;

  if (students.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No valid student data found in file'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final importResult = await provider.importStudents(
    students.map((s) => s.toJson()).toList(),
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${importResult['imported'] ?? 0} students imported\n'
        '${importResult['duplicates'] ?? 0} duplicates skipped',
      ),
      backgroundColor: Colors.green,
    ),
  );
}
}

// ==================== TEACHERS TAB ====================
class TeachersTab extends StatelessWidget {
  const TeachersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTeacherDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Teacher'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.teachers.isEmpty
                  ? const Center(child: Text('No teachers found'))
                  : ListView.builder(
                      itemCount: provider.teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = provider.teachers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Text(
                              teacher.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(teacher.name),
                          subtitle: Text(
                            'Username: ${teacher.username}\nMobile: ${teacher.mobile}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditTeacherDialog(context, teacher);
                              } else if (value == 'delete') {
                                _deleteTeacher(context, teacher.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddTeacherDialog(BuildContext context) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Teacher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              final result = await provider.addTeacher({
                'name': nameController.text,
                'username': usernameController.text,
                'password': passwordController.text,
                'mobile': mobileController.text,
                'email': emailController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Teacher added'),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTeacherDialog(BuildContext context, Teacher teacher) {
    final nameController = TextEditingController(text: teacher.name);
    final mobileController = TextEditingController(text: teacher.mobile);
    final emailController = TextEditingController(text: teacher.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              final result = await provider.updateTeacher(teacher.id, {
                'name': nameController.text,
                'mobile': mobileController.text,
                'email': emailController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Teacher updated'),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteTeacher(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: const Text('Are you sure you want to delete this teacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              final result = await provider.deleteTeacher(id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Teacher deleted'),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== REPORTS TAB ====================
class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date for Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : () => _exportDailyReport(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Daily Report (PDF)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : () => _exportWeeklyReport(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Weekly Report (PDF)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.orange,
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _exportDailyReport(BuildContext context) async {
    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final pdfPath = await provider.downloadReportPdf('daily', _selectedDate);

    setState(() => _loading = false);

    if (!mounted) return;

    if (pdfPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to: $pdfPath'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Open PDF viewer
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportWeeklyReport(BuildContext context) async {
    final startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endDate = startDate.add(const Duration(days: 6));

    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final pdfPath = await provider.downloadReportPdf('weekly', startDate);

    setState(() => _loading = false);

    if (!mounted) return;

    if (pdfPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weekly report saved to: $pdfPath'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}