// lib/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import '../utils/excel_parser.dart';
import '../utils/pdf_generator.dart'; // ADD THIS IMPORT
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    setState(() => _loadingData = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    await Future.wait([
      provider.loadStudents(),
      provider.loadBatches(),
      provider.loadAllAssignments(),
      provider.loadTodayAttendance(),
    ]);
    if (mounted) setState(() => _loadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final List<Widget> screens = const [
      DashboardTab(),
      StudentsTab(),
      BatchesTab(),
      AssignUsersTab(),
      ReportsTab(), // This will use the new ReportsTab below
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${provider.userName}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
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
                await provider.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedItemColor: Colors.blue.shade700,
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
            icon: Icon(Icons.class_),
            label: 'Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Users',
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
class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DateTime _selectedDate = DateTime.now();
  Map<String, int>? _summary;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() async {
    setState(() => _loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final sum = await provider.getAttendanceSummary(dateStr);
    setState(() {
      _summary = sum;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayDate = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    
    final presentCount = _summary?['present'] ?? 0;
    final absentCount = _summary?['absent'] ?? 0;
    final totalStudents = provider.students.length;
    final totalBatches = provider.batches.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            color: Colors.blue.shade700,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          provider.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Card
          Card(
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue.shade700),
              title: Text(
                todayDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Viewing: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
              trailing: IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadSummary();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _StatCard(
                title: 'Total Students',
                value: totalStudents.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Total Batches',
                value: totalBatches.toString(),
                icon: Icons.class_,
                color: Colors.purple,
              ),
              _StatCard(
                title: 'Present',
                value: presentCount.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Absent',
                value: absentCount.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Attendance Rate
          if (_summary != null && (presentCount + absentCount) > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd MMM').format(_selectedDate)} Attendance Rate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: presentCount / (presentCount + absentCount),
                      minHeight: 10,
                      backgroundColor: Colors.red.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((presentCount / (presentCount + absentCount)) * 100).toStringAsFixed(1)}% Present',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use the bottom navigation to access:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.people, color: Colors.blue.shade700),
                  title: const Text('Students Tab'),
                  subtitle: const Text('Import and manage students'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.assessment, color: Colors.blue.shade700),
                  title: const Text('Reports Tab'),
                  subtitle: const Text('Generate attendance reports'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
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
          mainAxisAlignment: MainAxisAlignment.center,
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
class StudentsTab extends StatefulWidget {
  const StudentsTab({Key? key}) : super(key: key);

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final students = provider.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.prn.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _importStudents(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Import Students (CSV/Excel)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${provider.students.length} students (${students.length} shown)',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, 
                            size: 64, 
                            color: Colors.grey.shade400
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No students found' 
                                : 'No matching students',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.grey.shade600
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Import students using Excel file',
                              style: TextStyle(
                                fontSize: 13, 
                                color: Colors.grey
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final batch = provider.batches.firstWhere(
                          (b) => b.id == student.batchId,
                          orElse: () => Batch(id: -1, name: 'Unknown'),
                        );
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'PRN: ${student.prn}\n${batch.name} | ${student.mobile}',
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ),
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

    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Importing students...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final students = await ExcelParser.parseStudentsFile(file, 0);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid student data found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final importResult = await provider.importStudents(students);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ ${importResult['imported'] ?? 0} imported, ${importResult['duplicates'] ?? 0} duplicates',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
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

// ==================== BATCHES TAB ====================
class BatchesTab extends StatelessWidget {
  const BatchesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddBatchDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create New Batch'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Batches are also created automatically from student imports',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.loadingBatches
              ? const Center(child: CircularProgressIndicator())
              : provider.batches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_, 
                            size: 64, 
                            color: Colors.grey.shade400
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No batches found',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.grey.shade600
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a batch to get started',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.batches.length,
                      itemBuilder: (context, index) {
                        final batch = provider.batches[index];
                        return FutureBuilder<int>(
                          future: provider.getStudentCountByBatch(batch.id!),
                          builder: (ctx, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple.shade700,
                                  child: const Icon(
                                    Icons.class_,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  batch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text('$count students | ID: ${batch.id}'),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Batch'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Batch Name',
            border: OutlineInputBorder(),
            hintText: 'e.g., Batch A, 2024-CS-Morning',
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a batch name')),
                );
                return;
              }

              final provider = Provider.of<AppProvider>(context, listen: false);
              final result = await provider.createBatch(nameController.text.trim());

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Batch created'),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ==================== USERS & ASSIGNMENTS TAB ====================
class AssignUsersTab extends StatefulWidget {
  const AssignUsersTab({Key? key}) : super(key: key);

  @override
  State<AssignUsersTab> createState() => _AssignUsersTabState();
}

class _AssignUsersTabState extends State<AssignUsersTab> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = Provider.of<AppProvider>(context, listen: false).getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Create User/Assignment Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateAssignmentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Teacher & Assign Batch'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Assignments Section
          if (provider.assignments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Assignments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${provider.assignments.length}'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.assignments.length,
              itemBuilder: (ctx, i) {
                final assignment = provider.assignments[i];
                final batch = provider.batches.firstWhere(
                  (b) => b.id == assignment.batchId,
                  orElse: () => Batch(id: -1, name: 'Unknown'),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: assignment.role == 'attendance_teacher'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      child: Icon(
                        assignment.role == 'attendance_teacher'
                            ? Icons.fact_check
                            : Icons.people,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      assignment.teacherName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${batch.name}\n'
                      '${assignment.role == "attendance_teacher" ? "Attendance Teacher" : "Batch Teacher"}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
            const Divider(height: 32, thickness: 2),
          ],

          // Users Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'All Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_outline, 
                          size: 48, 
                          color: Colors.grey.shade400
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final u = users[i];
                  final displayName = u['display_name'] ?? u['username'];
                  final role = u['role'] ?? 'user';
                  
                  IconData roleIcon;
                  Color roleColor;
                  
                  switch (role) {
                    case 'admin':
                      roleIcon = Icons.admin_panel_settings;
                      roleColor = Colors.red;
                      break;
                    case 'attendance_teacher':
                      roleIcon = Icons.fact_check;
                      roleColor = Colors.green;
                      break;
                    case 'batch_teacher':
                      roleIcon = Icons.people;
                      roleColor = Colors.orange;
                      break;
                    default:
                      roleIcon = Icons.person;
                      roleColor = Colors.grey;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${u['username']} • $role'),
                      trailing: role != 'admin'
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeactivateUser(context, u['username']),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'attendance_teacher';
    int? selectedBatchId;
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final provider = Provider.of<AppProvider>(context);

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Create Teacher & Assign'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: displayNameController,
                      enabled: !isCreating,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., John Doe',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      enabled: !isCreating,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., teacher001',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      enabled: !isCreating,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        border: OutlineInputBorder(),
                        hintText: 'Min. 6 characters',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'attendance_teacher',
                          child: Text('Attendance Teacher'),
                        ),
                        DropdownMenuItem(
                          value: 'batch_teacher',
                          child: Text('Batch Teacher'),
                        ),
                      ],
                      onChanged: isCreating ? null : (v) => setState(() => role = v ?? 'attendance_teacher'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Assign to Batch *',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedBatchId,
                      items: provider.batches.isEmpty
                          ? const [
                              DropdownMenuItem(
                                enabled: false,
                                child: Text('No batches available'),
                              ),
                            ]
                          : provider.batches.map((b) {
                              return DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              );
                            }).toList(),
                      onChanged: isCreating ? null : (val) => setState(() => selectedBatchId = val),
                    ),
                    if (provider.batches.isEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Create batches first in Batches tab',
                                style: TextStyle(fontSize: 12, color: Colors.orange),
                              ),
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
                  onPressed: isCreating ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isCreating || provider.batches.isEmpty
                      ? null
                      : () => _createUserAndAssignment(
                            context,
                            ctx,
                            usernameController.text.trim(),
                            passwordController.text.trim(),
                            displayNameController.text.trim(),
                            role,
                            selectedBatchId,
                            setState,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: isCreating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create & Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createUserAndAssignment(
    BuildContext context,
    BuildContext dialogContext,
    String username,
    String password,
    String displayName,
    String role,
    int? batchId,
    StateSetter setState,
  ) async {
    // Validation
    if (username.isEmpty || username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 3 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a batch'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Create user
    final userResult = await provider.createUser(
      username: username,
      password: password,
      role: role,
      displayName: displayName.isEmpty ? username : displayName,
    );

    if (userResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${userResult['message']}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create assignment
    final assignResult = await provider.createAssignment(
      teacherName: username,
      batchId: batchId,
      role: role,
    );

    if (assignResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created but assignment failed: ${assignResult['message']}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (context.mounted) {
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Teacher created and assigned successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      _refreshUsers();
    }
  }

  void _confirmDeactivateUser(BuildContext context, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Deactivate user "$username"? This cannot be undone.'),
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
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final result = await provider.deactivateUser(username);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'User deactivated'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success'] == true) {
        _refreshUsers();
      }
    }
  }
}

// ==================== REPORTS TAB WITH PDF EXPORT ====================
class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedBatchId;
  List<Map<String, dynamic>> _reportData = [];
  bool _loading = false;
  String _reportType = 'custom'; // custom, daily, weekly, monthly

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Attendance Reports',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate and export attendance reports',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Report Type Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Report Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildReportTypeChip('Daily', 'daily', Icons.today),
                      _buildReportTypeChip('Weekly', 'weekly', Icons.date_range),
                      _buildReportTypeChip('Monthly', 'monthly', Icons.calendar_month),
                      _buildReportTypeChip('Custom Range', 'custom', Icons.tune),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Selection based on report type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_reportType == 'daily') _buildDailyDatePicker(),
                  if (_reportType == 'weekly') _buildWeeklyDatePicker(),
                  if (_reportType == 'monthly') _buildMonthlyDatePicker(),
                  if (_reportType == 'custom') _buildCustomDatePicker(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Batch Filter
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Batch (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    value: _selectedBatchId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Batches'),
                      ),
                      ...provider.batches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedBatchId = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startDate != null && _endDate != null
                      ? _generateReport
                      : null,
                  icon: const Icon(Icons.search),
                  label: const Text('View Report'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _reportData.isNotEmpty ? _exportToPdf : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Results Section
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating report...'),
                  ],
                ),
              ),
            )
          else if (_reportData.isNotEmpty)
            _buildReportResults()
          else if (_startDate != null && _endDate != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data found for selected dates',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try selecting a different date range',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select dates and click "View Report"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
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

  Widget _buildReportTypeChip(String label, String value, IconData icon) {
    final isSelected = _reportType == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _reportType = value;
            _startDate = null;
            _endDate = null;
            _reportData = [];
          });
        }
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
    );
  }

  Widget _buildDailyDatePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _startDate = picked;
            _endDate = picked;
          });
        }
      },
      icon: const Icon(Icons.calendar_today),
      label: Text(
        _startDate == null
            ? 'Select Date'
            : DateFormat('EEEE, dd MMMM yyyy').format(_startDate!),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildWeeklyDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select any day in the week',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              // Calculate week start (Monday) and end (Sunday)
              final weekday = picked.weekday;
              final startOfWeek = picked.subtract(Duration(days: weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 6));
              
              setState(() {
                _startDate = startOfWeek;
                _endDate = endOfWeek;
              });
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            _startDate == null
                ? 'Select Week'
                : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select any day in the month',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              // Calculate month start and end
              final startOfMonth = DateTime(picked.year, picked.month, 1);
              final endOfMonth = DateTime(picked.year, picked.month + 1, 0);
              
              setState(() {
                _startDate = startOfMonth;
                _endDate = endOfMonth;
              });
            }
          },
          icon: const Icon(Icons.calendar_month),
          label: Text(
            _startDate == null
                ? 'Select Month'
                : DateFormat('MMMM yyyy').format(_startDate!),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDatePicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: _endDate ?? DateTime.now(),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _startDate == null
                  ? 'Start Date'
                  : DateFormat('dd MMM yyyy').format(_startDate!),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: _startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _endDate == null
                  ? 'End Date'
                  : DateFormat('dd MMM yyyy').format(_endDate!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportResults() {
    // Calculate summary
    int totalPresent = 0;
    int totalAbsent = 0;
    
    for (var record in _reportData) {
      final count = record['count'] as int;
      if (record['status'] == 'Present') {
        totalPresent += count;
      } else {
        totalAbsent += count;
      }
    }

    final total = totalPresent + totalAbsent;
    final percentage = total > 0 ? ((totalPresent / total) * 100).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        totalPresent.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Text('Present', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        totalAbsent.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const Text('Absent', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.percent, color: Colors.blue.shade700, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Text('Rate', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Results Header
        Row(
          children: [
            Text(
              '${_reportData.length} records found',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _reportData = []),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Results Table
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Count', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _reportData.map((record) {
                final status = record['status'] as String;
                final color = status == 'Present' ? Colors.green : Colors.red;
                
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('dd MMM yyyy').format(DateTime.parse(record['date'])))),
                    DataCell(Text(record['batch_name'] ?? 'N/A')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(record['count'].toString())),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date range'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    final data = await provider.getAttendanceReport(
      startDate: startStr,
      endDate: endStr,
      batchId: _selectedBatchId,
    );

    setState(() {
      _reportData = data;
      _loading = false;
    });
  }

  void _exportToPdf() async {
    if (_reportData.isEmpty) return;

    setState(() => _loading = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

      late File pdfFile;

      if (_reportType == 'daily') {
        final summary = await provider.getAttendanceSummary(startStr);
        pdfFile = await PdfGenerator.generateDailyReport(
          date: startStr,
          data: _reportData,
          summary: summary,
        );
      } else if (_reportType == 'weekly') {
        pdfFile = await PdfGenerator.generateWeeklyReport(
          startDate: startStr,
          endDate: endStr,
          data: _reportData,
          batchId: _selectedBatchId,
        );
      } else if (_reportType == 'monthly') {
        pdfFile = await PdfGenerator.generateMonthlyReport(
          startDate: startStr,
          endDate: endStr,
          data: _reportData,
          batchId: _selectedBatchId,
        );
      } else {
        // Custom report - use weekly format
        pdfFile = await PdfGenerator.generateWeeklyReport(
          startDate: startStr,
          endDate: endStr,
          data: _reportData,
          batchId: _selectedBatchId,
        );
      }

      setState(() => _loading = false);

      if (mounted) {
        await PdfGenerator.sharePdf(pdfFile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}