import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize classes in background to avoid blocking app startup
  FirebaseService.initializeClasses();
  runApp(const RubyAttendanceApp());
}

// ============================================================
// UTILITY: Auto‑Domain Conversion
// ============================================================
class EmailUtils {
  static String toRubyEmail(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) {
      final local = trimmed.split('@').first;
      return '$local@ruby.edu';
    }
    return '$trimmed@ruby.edu';
  }
}

// ============================================================
// UTILITY: ID Generator
// ============================================================
class IdGenerator {
  static String generateId(String prefix) {
    // Generate a random 11‑digit alphanumeric string
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    for (int i = 0; i < 11; i++) {
      result += chars[DateTime.now().millisecondsSinceEpoch % chars.length];
    }
    // Total 12 characters: prefix (1) + 11 alphanumeric
    return '$prefix$result';
  }

  static String generatePrincipalId() {
    return generateId('P');
  }

  static String generateTeacherId() {
    return generateId('T');
  }
}

// ============================================================
// UTILITY: 12‑Digit Teacher ID Generator
// ============================================================
class TeacherIdUtils {
  static String generateTeacherId(
      String collegeDomain, String principalId, int sequential) {
    final domainPart = collegeDomain.length > 6
        ? collegeDomain.substring(0, 6).toUpperCase()
        : ('${collegeDomain}XXXXX').substring(0, 6).toUpperCase();
    final principalPart = principalId.length > 3
        ? principalId.substring(0, 3).toUpperCase()
        : ('${principalId}XX').substring(0, 3).toUpperCase();
    final seqPart = sequential.toString().padLeft(3, '0');
    return '$domainPart$principalPart$seqPart';
  }
}

// ============================================================
// DEPARTMENT & SUBJECT DATA
// ============================================================
class CollegeDataUtils {
  static const Map<String, Map<String, List<String>>> departmentData = {
    'Arts & Science': {
      'BCA': ['Programming', 'Mathematics', 'DBMS', 'Operating Systems', 'Web Development'],
      'BSc': ['Physics', 'Chemistry', 'Mathematics', 'Biology', 'Environmental Science'],
      'B.Com': ['Accounting', 'Finance', 'Economics', 'Business Law', 'Marketing'],
      'BBA': ['Management', 'Organizational Behavior', 'Marketing', 'Finance', 'HR'],
      'BA English': ['Literature', 'Linguistics', 'Creative Writing', 'Grammar', 'Poetry'],
      'BA Tamil': ['Tamil Literature', 'Grammar', 'Poetry', 'History', 'Translation'],
    },
    'Engineering': {
      'CSE (Computer Science)': ['Data Structures', 'Algorithms', 'DBMS', 'Networks', 'AI', 'Operating Systems'],
      'ECE (Electronics)': ['Circuit Theory', 'Digital Electronics', 'Signals', 'Communication', 'Microprocessors'],
      'EEE (Electrical)': ['Power Systems', 'Control Systems', 'Electrical Machines', 'Circuit Analysis'],
      'Mechanical': ['Thermodynamics', 'Fluid Mechanics', 'Machine Design', 'Manufacturing'],
      'Civil': ['Structural Analysis', 'Construction Materials', 'Geotechnical', 'Surveying'],
      'AI & DS': ['Machine Learning', 'Deep Learning', 'Data Mining', 'Statistics', 'Python'],
      'IT': ['Web Development', 'Mobile Apps', 'Cloud Computing', 'Cybersecurity', 'Software Engineering'],
    },
    'Medical': {
      'MBBS': ['Anatomy', 'Physiology', 'Biochemistry', 'Pathology', 'Pharmacology', 'Medicine'],
      'BDS': ['Oral Anatomy', 'Dental Materials', 'Oral Surgery', 'Periodontics'],
      'BSc Nursing': ['Nursing Foundation', 'Medical-Surgical Nursing', 'Community Health', 'Child Health'],
      'Pharmacy': ['Pharmaceutical Chemistry', 'Pharmacology', 'Pharmacognosy', 'Drug Delivery'],
      'Physiotherapy': ['Anatomy', 'Exercise Therapy', 'Electrotherapy', 'Rehabilitation'],
      'Medical Lab Technology': ['Clinical Biochemistry', 'Hematology', 'Microbiology', 'Pathology'],
    },
    'Other': {},
  };

  static List<String> getCategories() {
    return departmentData.keys.toList();
  }

  static List<String> getDepartments(String category) {
    if (category == 'Other') return [];
    return departmentData[category]?.keys.toList() ?? [];
  }

  static List<String> getSubjects(String category, String department) {
    if (category == 'Other') return [];
    return departmentData[category]?[department] ?? [];
  }
}

// ============================================================
// APP THEME & ROOT
// ============================================================
class RubyAttendanceApp extends StatelessWidget {
  const RubyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruby Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C3BFF),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C3BFF),
          secondary: Color(0xFF4CAF50),
          surface: Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: const CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Color(0xFF1A1A2E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C3BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C3BFF), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// 1. SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040), Color(0xFF2D1B69)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3BFF), Color(0xFF9B8AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C3BFF).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ruby Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Attendance Management System',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD & FORM PLACEHOLDERS (IMPLEMENTED)
// ============================================================
class CollegeManagementScreen extends StatelessWidget {
  const CollegeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('College Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final colleges = snapshot.data!.docs;
          if (colleges.isEmpty) return const Center(child: Text('No colleges found'));
          return ListView.builder(
            itemCount: colleges.length,
            itemBuilder: (context, index) {
              final data = colleges[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['name'] ?? 'College Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Domain: ${data['domain'] ?? 'N/A'} | Status: ${data['status'] ?? 'pending'}', style: const TextStyle(color: Colors.white60)),
                  trailing: const Icon(Icons.edit, color: Colors.blue),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCollegeScreen(
                          docId: colleges[index].id,
                          collegeData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCollegeStep1())),
        backgroundColor: const Color(0xFF6C3BFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ViewPrincipalsScreen extends StatelessWidget {
  const ViewPrincipalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Principals Directory')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'principal').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final principals = snapshot.data!.docs;
          if (principals.isEmpty) return const Center(child: Text('No principals found'));
          return ListView.builder(
            itemCount: principals.length,
            itemBuilder: (context, index) {
              final data = principals[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF6C3BFF), child: Icon(Icons.person, color: Colors.white)),
                  title: Text(data['name'] ?? 'Principal', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(data['email'] ?? '', style: const TextStyle(color: Colors.white60)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPrincipalFormWrapper())),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TeachersDirectory extends StatelessWidget {
  const TeachersDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teachers Directory')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.getAllTeachers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final teachers = snapshot.data!;
          if (teachers.isEmpty) return const Center(child: Text('No teachers found'));
          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final t = teachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF7B1FA2), child: Icon(Icons.school, color: Colors.white)),
                  title: Text(t['name'] ?? 'Teacher', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${t['department']} | Class: ${t['class']}', style: const TextStyle(color: Colors.white60)),
                  onTap: () {
                     // Optionally navigate to details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacher())),
        backgroundColor: const Color(0xFF7B1FA2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


// ============================================================
// PRINCIPAL DASHBOARD - MOBILE UI
// ============================================================
class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Colleges'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Teachers'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Students'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  final List<Widget> _bottomScreens = [
    const PrincipalHome(),
    const CollegeManagementScreen(),
    const PrincipalTeachers(),
    const PrincipalStudents(),
    const PrincipalSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Principal Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _bottomScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _bottomItems,
        selectedItemColor: const Color(0xFF6C3BFF),
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF1A1A2E),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4B0082), Color(0xFFE6E6FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Color(0xFF4B0082)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Principal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'principal@ruby.edu',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.schedule, 'Timetable', () => _navigateToTimetable(context)),
                _drawerItem(Icons.check_circle, 'Attendance', () => _navigateToAttendance(context)),
                _drawerItem(Icons.assessment, 'All Marks', () => _navigateToMarks(context)),
                _drawerItem(Icons.comment, 'Remarks', () => _navigateToRemarks(context)),
                _drawerItem(Icons.message, 'Messages', () => _navigateToMessages(context)),
                _drawerItem(Icons.notifications, 'Notifications', () => _navigateToNotifications(context)),
                _drawerItem(Icons.people, 'Principals List', () => _navigateToPrincipals(context)),
                const Divider(color: Colors.white24),
                _drawerItem(Icons.logout, 'Logout', () => _logout(context), color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white60),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white70),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateToTimetable(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalTimetable()));
  }

  void _navigateToAttendance(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalAttendance()));
  }

  void _navigateToMarks(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalMarks()));
  }

  void _navigateToRemarks(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalRemarks()));
  }

  void _navigateToMessages(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalMessaging()));
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrincipalNotifications()));
  }

  void _navigateToPrincipals(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewPrincipalsScreen()));
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ============================================================
// PRINCIPAL HOME
// ============================================================
class PrincipalHome extends StatelessWidget {
  const PrincipalHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final colleges = snapshot.data!.docs;
        int totalColleges = colleges.length;
        int activeColleges = 0;
        int totalPrincipals = 0;

        for (final doc in colleges) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'active') activeColleges++;
          if (data['principalAdded'] == true) totalPrincipals++;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, ${user?.email?.split('@').first ?? 'Principal'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Text(
                'Today: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statCard('🏛️', '$totalColleges', 'Colleges', Colors.blue),
                  _statCard('✅', '$activeColleges', 'Active', Colors.green),
                  _statCard('👨‍🎓', '$totalPrincipals', 'Principals', Colors.purple),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _actionChip(Icons.people, 'Teachers', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TeachersDirectory()),
                    );
                  }),
                  _actionChip(Icons.person_add, 'Add Principal', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const AddPrincipalForm()),
                    );
                  }),
                  _actionChip(Icons.business, 'Manage Colleges', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const CollegeManagementScreen()),
                    );
                  }),
                  _actionChip(Icons.schedule, 'Timetable', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const PrincipalTimetable()),
                    );
                  }),
                  _actionChip(Icons.check_circle, 'Attendance', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const PrincipalAttendance()),
                    );
                  }),
                  _actionChip(Icons.assessment, 'Marks', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const PrincipalMarks()),
                    );
                  }),
                  _actionChip(Icons.comment, 'Remarks', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const PrincipalRemarks()),
                    );
                  }),
                  _actionChip(Icons.person_add_alt, 'Add Teacher', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddTeacher()),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C3BFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

// ============================================================
// PRINCIPAL TEACHERS
// ============================================================
class PrincipalTeachers extends StatelessWidget {
  const PrincipalTeachers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final allTeachers = <Map<String, dynamic>>[];
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            allTeachers.addAll(teachers);
          }
          if (allTeachers.isEmpty) return const Center(child: Text('No teachers found'));
          return ListView.builder(
            itemCount: allTeachers.length,
            itemBuilder: (ctx, index) {
              final t = allTeachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(t['name'] ?? 'Teacher', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${t['id'] ?? 'N/A'}', style: const TextStyle(color: Colors.white60)),
                      Text('Email: ${t['email'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                      Text('Last Login: ${t['lastLogin'] != null ? DateFormat('MMM d, hh:mm a').format((t['lastLogin'] as Timestamp).toDate()) : 'Never'}', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// PRINCIPAL STUDENTS
// ============================================================
class PrincipalStudents extends StatelessWidget {
  const PrincipalStudents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Directory'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.getAllStudents(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final students = snapshot.data!;
          if (students.isEmpty) return const Center(child: Text('No students found', style: TextStyle(color: Colors.white)));
          
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (ctx, index) {
              final s = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4B0082),
                    backgroundImage: (s['photo'] as String? ?? '').isNotEmpty
                        ? MemoryImage(base64Decode(s['photo'] as String))
                        : null,
                    child: (s['photo'] as String? ?? '').isEmpty
                        ? Text(s['name']?.substring(0, 1).toUpperCase() ?? 'S', style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(s['name'] ?? 'Student', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Roll: ${s['rollNumber']} | ${s['class']} (${s['department']})', style: const TextStyle(color: Colors.white60)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudent(initialClassId: null)),
          );
        },
        backgroundColor: const Color(0xFF4B0082),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


// ============================================================
// PRINCIPAL NOTIFICATIONS
// ============================================================
class PrincipalNotifications extends StatefulWidget {
  const PrincipalNotifications({super.key});

  @override
  State<PrincipalNotifications> createState() => _PrincipalNotificationsState();
}

class _PrincipalNotificationsState extends State<PrincipalNotifications> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(data['title'] ?? 'Notification', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                      Text(
                        DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Future.delayed(const Duration(seconds: 2));
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(data['title'] ?? 'Notification'),
                        content: Text(data['message'] ?? ''),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// PRINCIPAL SETTINGS
// ============================================================
class PrincipalSettings extends StatelessWidget {
  const PrincipalSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF6C3BFF)),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.email ?? 'No email', style: const TextStyle(color: Colors.white60)),
                  if (user != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                      builder: (ctx, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        if (data != null && data['principalId'] != null) {
                          return Text(
                            'Principal ID: ${data['principalId']}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security, color: Color(0xFF6C3BFF)),
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Update your password', style: TextStyle(color: Colors.white60)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF6C3BFF)),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Ruby Attendance v1.0.0', style: TextStyle(color: Colors.white60)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Ruby Attendance',
                  applicationVersion: '1.0.0',
                  children: const [
                    Text('Smart Attendance Management System'),
                    SizedBox(height: 8),
                    Text('© 2024 Ruby Attendance'),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRINCIPAL TIMETABLE
// ============================================================
class PrincipalTimetable extends StatelessWidget {
  const PrincipalTimetable({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final classes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (BuildContext context, int index) {
            final doc = classes[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Class';
            final department = data['department'] ?? '';
            final timetableRaw = (data['timetable'] as Map<String, dynamic>?) ?? {};
            final Map<String, Map<String, String>> timetable = timetableRaw.map(
              (key, value) => MapEntry(key, Map<String, String>.from(value)),
            );
            return Card(
              child: ExpansionTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('Department: $department', style: const TextStyle(color: Colors.white60)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrincipalEditTimetable(initialClassId: doc.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTimetable(context, doc.id),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTimetableTable(timetable),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTimetable(BuildContext context, String classId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Timetable'),
        content: const Text('Are you sure you want to clear this timetable?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseService.updateTimetablePeriods(classId, {});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable cleared'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildTimetableTable(Map<String, Map<String, String>> timetable) {
    const periods = FirebaseService.periodKeys;
    const days = FirebaseService.dayKeys;
    const dayLabels = FirebaseService.dayLabels;
    const periodLabels = FirebaseService.periodLabels;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.all(color: Colors.white24),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  ...days.map((day) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      dayLabels[day] ?? day,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )),
                ],
              ),
              ...periods.map((period) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        periodLabels[period] ?? period,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white60),
                      ),
                    ),
                    ...days.map((day) {
                      final dayMap = timetable[day] ?? {};
                      final subject = dayMap[period] ?? '';
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          subject.isEmpty ? '—' : subject,
                          style: TextStyle(
                            fontWeight: subject.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: subject.isNotEmpty ? const Color(0xFF6C3BFF) : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRINCIPAL EDIT TIMETABLE
// ============================================================
class PrincipalEditTimetable extends StatefulWidget {
  final String? initialClassId;
  const PrincipalEditTimetable({super.key, this.initialClassId});

  @override
  State<PrincipalEditTimetable> createState() => _PrincipalEditTimetableState();
}

class _PrincipalEditTimetableState extends State<PrincipalEditTimetable> {
  String _selectedClassId = '';
  Map<String, Map<String, String>> _timetable = {};
  final List<String> _periods = FirebaseService.periodKeys;
  final List<String> _days = FirebaseService.dayKeys;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId ?? '';
    if (_selectedClassId.isNotEmpty) _loadTimetable(_selectedClassId);
  }

  Future<void> _loadTimetable(String classId) async {
    final data = await FirebaseService.getClassData(classId);
    final timetableRaw = (data['timetable'] as Map<String, dynamic>?) ?? {};
    final Map<String, Map<String, String>> timetable = timetableRaw.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
    if (mounted) setState(() => _timetable = timetable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Timetable')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final classes = snapshot.data!.docs;
                final items = classes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text('${data['name'] ?? 'Class'} (${data['department'] ?? ''})'),
                  );
                }).toList();

                return DropdownButtonFormField<String>(
                  initialValue: _selectedClassId.isEmpty ? null : _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    prefixIcon: Icon(Icons.class_),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Select a class')),
                    ...items,
                  ],
                  onChanged: (String? val) async {
                    if (val != null) {
                      setState(() => _selectedClassId = val);
                      await _loadTimetable(val);
                    }
                  },
                );
              },
            ),
          ),
          if (_selectedClassId.isNotEmpty)
            Expanded(
              child: _buildTimetableEditor(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimetableEditor() {
    if (_periods.isEmpty || _days.isEmpty) {
      return const Center(child: Text('No periods or days defined.', style: TextStyle(color: Colors.white)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Enter subjects (UPPERCASE)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.white24),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  ..._days.map((day) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      FirebaseService.dayLabels[day] ?? day,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )),
                ],
              ),
              ..._periods.map((period) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        FirebaseService.periodLabels[period] ?? period,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white60),
                      ),
                    ),
                    ..._days.map((day) {
                      final controller = TextEditingController(
                        text: (_timetable[day]?[period] ?? '').toUpperCase(),
                      );
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: TextFormField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                          onChanged: (String val) {
                            setState(() {
                              _timetable[day] ??= {};
                              _timetable[day]![period] = val.toUpperCase();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveTimetable,
            icon: const Icon(Icons.save),
            label: const Text('Save Timetable'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTimetable() async {
    if (_selectedClassId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final cleaned = <String, Map<String, String>>{};
      for (final day in _days) {
        if (_timetable.containsKey(day)) {
          final periodMap = _timetable[day]!;
          final filtered = <String, String>{};
          for (final period in _periods) {
            final val = periodMap[period]?.trim() ?? '';
            if (val.isNotEmpty) filtered[period] = val;
          }
          if (filtered.isNotEmpty) cleaned[day] = filtered;
        }
      }
      await FirebaseService.updateTimetablePeriods(_selectedClassId, cleaned);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ============================================================
// PRINCIPAL ATTENDANCE
// ============================================================
class PrincipalAttendance extends StatelessWidget {
  const PrincipalAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final presentStudents = <Map<String, dynamic>>[];
        final absentStudents = <Map<String, dynamic>>[];
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          final className = data['name'] ?? 'Class';
          for (final s in students) {
            final att = s['attendance'] as Map? ?? {};
            final isPresent = att[today] ?? false;
            final entry = {'name': s['name'] ?? 'Unknown', 'roll': s['rollNumber'] ?? '', 'class': className};
            if (isPresent) {
              presentStudents.add(entry);
            } else {
              absentStudents.add(entry);
            }
          }
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF1A1A2E),
                child: const TabBar(
                  tabs: [Tab(text: 'Present'), Tab(text: 'Absent')],
                  labelColor: Color(0xFF6C3BFF),
                  unselectedLabelColor: Colors.white60,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(presentStudents, Colors.green),
                    _buildList(absentStudents, Colors.red),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> students, Color color) {
    if (students.isEmpty) return Center(child: Text('No students', style: TextStyle(color: color)));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: students.length,
      itemBuilder: (BuildContext context, int index) {
        final s = students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Text(s['name']?.substring(0, 1) ?? '?', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(s['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text('Roll: ${s['roll']} | Class: ${s['class']}', style: const TextStyle(color: Colors.white60)),
          ),
        );
      },
    );
  }
}

// ============================================================
// PRINCIPAL MARKS
// ============================================================
class PrincipalMarks extends StatelessWidget {
  const PrincipalMarks({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final classes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (BuildContext context, int index) {
            final doc = classes[index];
            final data = doc.data() as Map<String, dynamic>;
            final className = data['name'] ?? 'Class';
            final department = data['department'] ?? '';
            final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            final subjects = List<String>.from(data['subjects'] ?? []);
            return Card(
              child: ExpansionTile(
                title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('$department | ${students.length} Students | Subjects: ${subjects.join(', ')}',
                    style: const TextStyle(color: Colors.white60)),
                children: students.isEmpty
                    ? [const Padding(padding: EdgeInsets.all(16), child: Text('No students', style: TextStyle(color: Colors.white60)))]
                    : students.map((s) {
                  final marksMap = (s['marks'] as Map?)?.cast<String, dynamic>() ?? {};
                  return ListTile(
                    leading: CircleAvatar(child: Text(s['name']?.substring(0, 1) ?? '?')),
                    title: Text(s['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Roll: ${s['rollNumber'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                    trailing: Wrap(
                      spacing: 8,
                      children: subjects.map((subject) {
                        final mark = marksMap[subject]?.toString() ?? '-';
                        return Chip(
                          label: Text('$subject: $mark', style: const TextStyle(fontSize: 11)),
                          backgroundColor: mark != '-' ? Colors.green.shade50 : Colors.grey.shade200,
                          labelStyle: TextStyle(color: mark != '-' ? Colors.green.shade800 : Colors.grey.shade600),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// PRINCIPAL REMARKS
// ============================================================
class PrincipalRemarks extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const PrincipalRemarks({super.key, this.onNavigate});

  @override
  State<PrincipalRemarks> createState() => _PrincipalRemarksState();
}

class _PrincipalRemarksState extends State<PrincipalRemarks> {
  String _selectedStudentId = '';
  final TextEditingController _remarkController = TextEditingController();
  String _selectedRemarkType = 'General';

  final List<String> _remarkTypes = const [
    'General', 'Good Performance', 'Needs Improvement', 'Excellent',
    'Satisfactory', 'Poor', 'Outstanding', 'Average', 'Below Average',
    'Hardworking', 'Lazy', 'Disciplined', 'Late to Class',
    'Homework Not Done', 'Participation', 'Leadership', 'Creativity',
    'Punctual', 'Irregular', 'Behaviour Issue',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').snapshots(),
            builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final students = <String, String>{};
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final classStudents = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                for (final s in classStudents) {
                  final id = s['id'] as String?;
                  final name = s['name'] as String?;
                  if (id != null && name != null) students[id] = name;
                }
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedStudentId.isEmpty ? null : _selectedStudentId,
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  prefixIcon: Icon(Icons.person),
                ),
                items: students.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (String? v) => setState(() => _selectedStudentId = v!),
              );
            },
          ),
        ),
        if (_selectedStudentId.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Remark Type', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _remarkTypes.map((type) {
                        final isSelected = _selectedRemarkType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedRemarkType = selected ? type : 'General';
                            });
                          },
                          selectedColor: const Color(0xFF6C3BFF),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _remarkController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Custom Remark (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _submitRemark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Recent Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.getRemarksForStudent(_selectedStudentId),
                    builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final remarks = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: remarks.length,
                        itemBuilder: (BuildContext context, int index) {
                          final data = remarks[index].data() as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp?;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(data['remark']?.substring(0, 1) ?? 'R'),
                              ),
                              title: Text(data['remark'] ?? '', style: const TextStyle(color: Colors.white)),
                              subtitle: Text('By: ${data['teacherName'] ?? data['teacherId'] ?? 'Unknown'}',
                                  style: const TextStyle(color: Colors.white60)),
                              trailing: Text(
                                timestamp != null
                                    ? DateFormat('MMM d, y hh:mm a').format(timestamp.toDate())
                                    : '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _submitRemark() async {
    final remarkText = _remarkController.text.trim().isNotEmpty
        ? _remarkController.text.trim()
        : _selectedRemarkType;
    if (remarkText.isEmpty || _selectedStudentId.isEmpty) return;
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final teacherName = FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Principal';
    await FirebaseService.addRemark(_selectedStudentId, remarkText, teacherId, teacherName: teacherName);
    _remarkController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remark added!')),
    );
  }
}

// ============================================================
// TEACHER DASHBOARD - MOBILE UI
// ============================================================
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attendance'),
    BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Marks'),
    BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timetable'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // Screens for bottom nav
    final List<Widget> _bottomScreens = [
      TeacherHome(onNavigate: _changeIndex),
      const TeacherAttendance(),
      const TeacherMarksDashboard(),
      const TeacherTimetable(),
      const TeacherProfile(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _bottomScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _bottomItems,
        selectedItemColor: const Color(0xFF7B1FA2),
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF1A1A2E),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF708090)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Color(0xFF7B1FA2)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Teacher',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'teacher@ruby.edu',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${FirebaseAuth.instance.currentUser?.uid ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.calendar_today, 'Calendar', () => _navigateToCalendar(context)),
                _drawerItem(Icons.comment, 'Remarks', () => _navigateToRemarks(context)),
                _drawerItem(Icons.message, 'Messages', () => _navigateToMessages(context)),
                _drawerItem(Icons.notifications, 'Notifications', () => _navigateToNotifications(context)),
                _drawerItem(Icons.class_, 'All Classes', () => _navigateToAllClasses(context)),
                _drawerItem(Icons.grade, 'All Marks', () => _navigateToAllMarks(context)),
                const Divider(color: Colors.white24),
                _drawerItem(Icons.logout, 'Logout', () => _logout(context), color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white60),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white70),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _changeIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToCalendar(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherCalendarScreen()));
  }

  void _navigateToRemarks(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherRemarksScreen()));
  }

  void _navigateToMessages(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherMessaging()));
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherNotifications()));
  }

  void _navigateToAllClasses(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAllClasses()));
  }

  void _navigateToAllMarks(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAllMarks()));
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ============================================================
// TEACHER HOME
// ============================================================
class TeacherHome extends StatelessWidget {
  final void Function(int index) onNavigate;
  const TeacherHome({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loginTime = DateFormat('hh:mm a').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data!.docs;
        final myClasses = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          return teachers.any((t) => t['email'] == user?.email);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Afternoon, ${user?.email?.split('@').first ?? 'Teacher'}!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('Today: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                  style: const TextStyle(color: Colors.white60)),
              Text('Logged in at $loginTime', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 24),
              
              // Quick Actions Grid for Teacher
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _actionCard(Icons.check_circle, 'Attendance', Colors.green, () => onNavigate(1)),
                  _actionCard(Icons.assessment, 'Add Marks', Colors.orange, () => onNavigate(2)),
                  _actionCard(Icons.schedule, 'Timetable', Colors.blue, () => onNavigate(3)),
                  _actionCard(Icons.person_add, 'Add Student', Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudent()));
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              const Text('My Assigned Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              if (myClasses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No classes assigned to you.', style: TextStyle(color: Colors.white60)),
                  ),
                ),
              ...myClasses.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final className = data['name'] ?? 'Class';
                final department = data['department'] ?? '';
                final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                int present = 0;
                for (final s in students) {
                  final att = s['attendance'] as Map? ?? {};
                  if (att[today] == true) present++;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.class_, color: Color(0xFF7B1FA2)),
                    title: Text(className, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('$department | ${students.length} Students | Present: $present',
                        style: const TextStyle(color: Colors.white60)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailScreen(
                            classId: doc.id,
                            className: className,
                            students: students,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TEACHER CALENDAR SCREEN
// ============================================================
class TeacherCalendarScreen extends StatelessWidget {
  const TeacherCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Calendar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2025),
                onDateChanged: (date) {
                  // Handle date selection
                },
              ),
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.event, color: Colors.orange),
              title: Text('Upcoming: Mid-Term Exams', style: TextStyle(color: Colors.white)),
              subtitle: Text('Starting from Dec 15, 2024', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// TEACHER REMARKS SCREEN
// ============================================================
class TeacherRemarksScreen extends StatelessWidget {
  const TeacherRemarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrincipalRemarks();
  }
}

// ============================================================
// CLASS DETAIL SCREEN
// ============================================================
class ClassDetailScreen extends StatelessWidget {
  final String classId;
  final String className;
  final List<Map<String, dynamic>> students;
  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text('$className - Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddStudent(initialClassId: classId),
                ),
              );
            },
            tooltip: 'Add Student',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudent(initialClassId: classId),
            ),
          );
        },
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _summaryChip('Total', students.length, Colors.blue),
                    _summaryChip('Present', students.where((s) {
                      final att = s['attendance'] as Map? ?? {};
                      return att[today] == true;
                    }).length, Colors.green),
                    _summaryChip('Absent', students.where((s) {
                      final att = s['attendance'] as Map? ?? {};
                      return att[today] != true;
                    }).length, Colors.red),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (BuildContext context, int index) {
                final s = students[index];
                final att = s['attendance'] as Map? ?? {};
                final isPresent = att[today] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent ? Colors.green : Colors.red,
                      child: Text(isPresent ? 'P' : 'A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(s['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Roll: ${s['rollNumber'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                    trailing: Text(
                      isPresent ? 'Present' : 'Absent',
                      style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ============================================================
// TEACHER ATTENDANCE
// ============================================================
class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({super.key});

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final classes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (BuildContext context, int index) {
            final doc = classes[index];
            final data = doc.data() as Map<String, dynamic>;
            final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            final found = teachers.where((t) => t['email'] == user?.email).toList();
            if (found.isEmpty) return const SizedBox.shrink();
            final className = data['name'] ?? 'Class';
            final department = data['department'] ?? '';
            final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.class_, color: Color(0xFF6C3BFF)),
                title: Text(className, style: const TextStyle(color: Colors.white)),
                subtitle: Text('$department | ${students.length} Students', style: const TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassAttendanceScreen(
                        classId: doc.id,
                        className: className,
                        students: students,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// CLASS ATTENDANCE SCREEN
// ============================================================
class ClassAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  final List<Map<String, dynamic>> students;
  const ClassAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.students,
  });

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  late Map<String, bool> _attendance;

  @override
  void initState() {
    super.initState();
    _attendance = {};
    for (var s in widget.students) {
      _attendance[s['id']] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Attendance'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _summaryChip('Total', widget.students.length, Colors.blue),
                        _summaryChip('Present', _attendance.values.where((v) => v == true).length, Colors.green),
                        _summaryChip('Absent', _attendance.values.where((v) => v == false).length, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: const TextStyle(color: Colors.white)),
                    Text('Time: ${DateFormat('hh:mm a').format(DateTime.now())}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.students.length,
              itemBuilder: (BuildContext context, int index) {
                final s = widget.students[index];
                final id = s['id'];
                final isPresent = _attendance[id] ?? true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                          child: Text(
                            s['rollNumber'] ?? '',
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                              Text('Roll: ${s['rollNumber'] ?? ''}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _toggleButton('Present', isPresent, () => setState(() => _attendance[id] = true)),
                            const SizedBox(width: 4),
                            _toggleButton('Absent', !isPresent, () => setState(() => _attendance[id] = false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseService.saveAttendance(widget.classId, widget.students, _attendance);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Submit Attendance'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? (label == 'Present' ? Colors.green : Colors.red) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. TEACHER PROFILE
// ============================================================
class TeacherProfile extends StatelessWidget {
  const TeacherProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, dynamic>? teacherData;
        Map<String, dynamic>? classData;
        String className = '';
        String classId = '';
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          final found = teachers.where((t) => t['email'] == user?.email).toList();
          if (found.isNotEmpty) {
            teacherData = found.first;
            classData = data;
            className = data['name'] ?? 'Class';
            classId = doc.id;
            break;
          }
        }
        if (teacherData == null) {
          return const Center(child: Text('No profile data.', style: TextStyle(color: Colors.white)));
        }

        final timetableRaw = (classData?['timetable'] as Map<String, dynamic>?) ?? {};
        final Map<String, Map<String, String>> timetable = timetableRaw.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (teacherData['photo'] as String? ?? '').isNotEmpty
                            ? MemoryImage(base64Decode(teacherData['photo'] as String))
                            : null,
                        child: (teacherData['photo'] as String? ?? '').isEmpty
                            ? Text(
                          teacherData['name']?.substring(0, 1).toUpperCase() ?? 'T',
                          style: const TextStyle(fontSize: 40, color: Color(0xFF6C3BFF)),
                        )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(teacherData['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(teacherData['email'] ?? 'No email', style: const TextStyle(color: Colors.white60)),
                      Text('Teacher ID: ${teacherData['teacherId'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(teacherData['phoneNumber'] ?? 'Not set', style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(teacherData['designation'] ?? 'Professor'),
                        backgroundColor: const Color(0xFF6C3BFF).withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Color(0xFF6C3BFF)),
                      ),
                      if (teacherData['additionalRole'] != null)
                        Chip(
                          label: Text(teacherData['additionalRole'] as String),
                          backgroundColor: Colors.orange.shade100,
                          labelStyle: const TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Weekly Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                _buildTimetableTable(timetable),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherTimetableEditor(
                          classId: classId,
                          className: className,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Timetable'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimetableTable(Map<String, Map<String, String>> timetable) {
    const periods = FirebaseService.periodKeys;
    const days = FirebaseService.dayKeys;
    const dayLabels = FirebaseService.dayLabels;
    const periodLabels = FirebaseService.periodLabels;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.all(color: Colors.white24),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  ...days.map((day) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      dayLabels[day] ?? day,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )),
                ],
              ),
              ...periods.map((period) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        periodLabels[period] ?? period,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white60),
                      ),
                    ),
                    ...days.map((day) {
                      final dayMap = timetable[day] ?? {};
                      final subject = dayMap[period] ?? '';
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          subject.isEmpty ? '—' : subject,
                          style: TextStyle(
                            fontWeight: subject.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: subject.isNotEmpty ? const Color(0xFF6C3BFF) : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TEACHER TIMETABLE
// ============================================================
class TeacherTimetable extends StatelessWidget {
  const TeacherTimetable({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, dynamic>? teacherClass;
        String className = '';
        String classId = '';
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          final found = teachers.where((t) => t['email'] == user?.email).toList();
          if (found.isNotEmpty) {
            teacherClass = data;
            className = data['name'] ?? 'Class';
            classId = doc.id;
            break;
          }
        }
        if (teacherClass == null) {
          return const Center(child: Text('No class assigned.', style: TextStyle(color: Colors.white)));
        }
        final timetableRaw = (teacherClass['timetable'] as Map<String, dynamic>?) ?? {};
        final Map<String, Map<String, String>> timetable = timetableRaw.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('$className Timetable'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherTimetableEditor(
                        classId: classId,
                        className: className,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildTimetableTable(timetable),
          ),
        );
      },
    );
  }

  Widget _buildTimetableTable(Map<String, Map<String, String>> timetable) {
    const periods = FirebaseService.periodKeys;
    const days = FirebaseService.dayKeys;
    const dayLabels = FirebaseService.dayLabels;
    const periodLabels = FirebaseService.periodLabels;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.all(color: Colors.white24),
            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  ...days.map((day) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      dayLabels[day] ?? day,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )),
                ],
              ),
              ...periods.map((period) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        periodLabels[period] ?? period,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white60),
                      ),
                    ),
                    ...days.map((day) {
                      final dayMap = timetable[day] ?? {};
                      final subject = dayMap[period] ?? '';
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          subject.isEmpty ? '—' : subject,
                          style: TextStyle(
                            fontWeight: subject.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: subject.isNotEmpty ? const Color(0xFF6C3BFF) : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TEACHER TIMETABLE EDITOR
// ============================================================
class TeacherTimetableEditor extends StatefulWidget {
  final String classId;
  final String className;
  const TeacherTimetableEditor({super.key, required this.classId, required this.className});

  @override
  State<TeacherTimetableEditor> createState() => _TeacherTimetableEditorState();
}

class _TeacherTimetableEditorState extends State<TeacherTimetableEditor> {
  Map<String, Map<String, String>> _timetable = {};
  final List<String> _periods = FirebaseService.periodKeys;
  final List<String> _days = FirebaseService.dayKeys;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final data = await FirebaseService.getClassData(widget.classId);
    final timetableRaw = (data['timetable'] as Map<String, dynamic>?) ?? {};
    final Map<String, Map<String, String>> timetable = timetableRaw.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
    if (mounted) setState(() => _timetable = timetable);
  }

  Future<void> _saveTimetable() async {
    final cleaned = <String, Map<String, String>>{};
    for (final day in _days) {
      if (_timetable.containsKey(day)) {
        final filtered = <String, String>{};
        for (final period in _periods) {
          final val = _timetable[day]?[period]?.trim() ?? '';
          if (val.isNotEmpty) filtered[period] = val;
        }
        if (filtered.isNotEmpty) cleaned[day] = filtered;
      }
    }
    await FirebaseService.updateTimetablePeriods(widget.classId, cleaned);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timetable saved!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Timetable - ${widget.className}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Table(
              border: TableBorder.all(color: Colors.white24),
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(80),
                4: FixedColumnWidth(80),
                5: FixedColumnWidth(80),
              },
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    ..._days.map((day) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        FirebaseService.dayLabels[day] ?? day,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    )),
                  ],
                ),
                ..._periods.map((period) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          FirebaseService.periodLabels[period] ?? period,
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white60),
                        ),
                      ),
                      ..._days.map((day) {
                        final controller = TextEditingController(
                          text: (_timetable[day]?[period] ?? '').toUpperCase(),
                        );
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: TextFormField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                            onChanged: (String val) {
                              setState(() {
                                _timetable[day] ??= {};
                                _timetable[day]![period] = val.toUpperCase();
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveTimetable,
              icon: const Icon(Icons.save),
              label: const Text('Save Timetable'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TEACHER MARKS DASHBOARD
// ============================================================
class TeacherMarksDashboard extends StatefulWidget {
  const TeacherMarksDashboard({super.key});

  @override
  State<TeacherMarksDashboard> createState() => _TeacherMarksDashboardState();
}

class _TeacherMarksDashboardState extends State<TeacherMarksDashboard> {
  String? _selectedClassId;
  String? _selectedSubject;
  List<Map<String, dynamic>> _students = [];
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      final classes = snapshot.docs.where((doc) {
        final data = doc.data();
        final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        return teachers.any((t) => t['email'] == user?.email);
      }).toList();

      if (classes.isNotEmpty) {
        final firstClass = classes.first;
        _selectedClassId = firstClass.id;
        final data = firstClass.data();
        _students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _subjects = List<String>.from(data['subjects'] ?? []);
        if (_subjects.isNotEmpty) _selectedSubject = _subjects.first;
      }
    } catch (e) {
      // Silent catch
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMarks(String studentId, String value) async {
    final mark = double.tryParse(value);
    if (mark == null || mark < 0 || mark > 100 || _selectedClassId == null || _selectedSubject == null) return;
    await FirebaseService.updateStudentMarks(_selectedClassId!, studentId, _selectedSubject!, mark);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Marks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final user = FirebaseAuth.instance.currentUser;
                final classes = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                  return teachers.any((t) => t['email'] == user?.email);
                }).toList();

                return DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    prefixIcon: Icon(Icons.class_),
                  ),
                  items: classes.map<DropdownMenuItem<String>>((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('${data['name'] ?? 'Class'} (${data['department'] ?? ''})'),
                    );
                  }).toList(),
                  onChanged: (String? val) async {
                    if (val != null) {
                      setState(() => _selectedClassId = val);
                      final data = await FirebaseService.getClassData(val);
                      setState(() {
                        _students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                        _subjects = List<String>.from(data['subjects'] ?? []);
                        if (_subjects.isNotEmpty) _selectedSubject = _subjects.first;
                      });
                    }
                  },
                );
              },
            ),
          ),
          if (_subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  prefixIcon: Icon(Icons.book),
                ),
                items: _subjects.map((sub) {
                  return DropdownMenuItem<String>(
                    value: sub,
                    child: Text(sub),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
              ),
            ),
          const Divider(),
          Expanded(
            child: _students.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final marksMap = (student['marks'] as Map?)?.cast<String, dynamic>() ?? {};
                final currentMark = marksMap[_selectedSubject ?? '']?.toString() ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student['rollNumber'] ?? ''),
                    ),
                    title: Text(student['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Roll: ${student['rollNumber'] ?? ''}',
                        style: const TextStyle(color: Colors.white60)),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: currentMark,
                        decoration: const InputDecoration(
                          labelText: 'Mark',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (value) => _saveMarks(student['id'], value),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. ADD TEACHER (FULL VERSION)
// ============================================================
// ============================================================
// ADD TEACHER - COMPLETE FIXED VERSION
// ============================================================
class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  State<AddTeacher> createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _completionYearController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedDepartment = '';
  String _selectedClass = '';
  String _selectedDesignation = 'Professor';
  String _selectedAdditionalRole = 'None';
  String _photoBase64 = '';
  String _resumeBase64 = '';
  bool _historyArrear = false;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _departments = [
    'Computer Science',
    'Commerce',
    'Business Administration',
    'Language Tamil',
    'Language English',
    'Hotel Management System',
    'Public Admin',
    'Fashion Technology & Costume Designing',
  ];

  List<String> _availableClasses = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        _availableClasses = snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      // Silent catch - classes will be empty
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 50);
    if (mounted) setState(() => _photoBase64 = base64Encode(compressed));
  }

  Future<void> _pickResume() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 800,
      imageQuality: 50,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 40);
    if (mounted) setState(() => _resumeBase64 = base64Encode(compressed));
  }

  Future<String?> _getOrCreateClass(String className, String department) async {
    // Try to find existing class
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('name', isEqualTo: className)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    // Create new class if it doesn't exist
    try {
      final docRef = await FirebaseFirestore.instance.collection('classes').add({
        'name': className,
        'department': department,
        'section': '',
        'students': [],
        'teachers': [],
        'timetable': {},
        'subjects': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addTeacher() async {
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }

    if (_selectedDepartment.isEmpty) {
      setState(() => _errorMessage = 'Please select a department');
      return;
    }

    if (_selectedClass.isEmpty) {
      setState(() => _errorMessage = 'Please select a class');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 STEP 1: Get or create class
      final classId = await _getOrCreateClass(_selectedClass, _selectedDepartment);
      if (classId == null) {
        setState(() => _errorMessage = 'Failed to create/find class. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      // 🔥 STEP 2: Check if email already exists
      final auth = FirebaseAuth.instance;
      try {
        // Try to create user
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final user = userCredential.user!;

        // 🔥 STEP 3: Generate 12-digit Teacher ID (Letters + Numbers)
        final teacherId = _generateTeacherId();

        // 🔥 STEP 4: Save teacher data to Firestore
        final newTeacher = {
          'id': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'qualification': _qualificationController.text.trim(),
          'experience': _experienceController.text.trim(),
          'completionYear': _completionYearController.text.trim(),
          'address': _addressController.text.trim(),
          'designation': _selectedDesignation,
          'additionalRole': _selectedAdditionalRole == 'None' ? null : _selectedAdditionalRole.toLowerCase().replaceAll(' ', '_'),
          'historyArrear': _historyArrear,
          'photo': _photoBase64,
          'resume': _resumeBase64,
          'addedAt': DateTime.now().toIso8601String(),
          'department': _selectedDepartment,
          'class': _selectedClass,
          'teacherId': teacherId,
          'lastLogin': FieldValue.serverTimestamp(),
        };

        // Save to class
        await FirebaseService.addTeacher(classId, newTeacher);

        // Save to users collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'teacher',
          'name': _nameController.text.trim(),
          'department': _selectedDepartment,
          'class': _selectedClass,
          'teacherId': teacherId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        _clearFields();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Teacher added successfully!\nID: $teacherId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        // 🔥 Handle specific Firebase Auth errors
        if (e.code == 'email-already-in-use') {
          setState(() => _errorMessage = '❌ This email is already registered. Please use a different email.');
        } else if (e.code == 'weak-password') {
          setState(() => _errorMessage = '❌ Password is too weak. Use at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          setState(() => _errorMessage = '❌ Invalid email address.');
        } else {
          setState(() => _errorMessage = '❌ Auth Error: ${e.message}');
        }
      }

    } on FirebaseException catch (e) {
      // 🔥 Handle Firestore errors
      if (e.code == 'permission-denied') {
        setState(() => _errorMessage = '❌ Permission denied. Please check Firestore rules.');
      } else {
        setState(() => _errorMessage = '❌ Firestore Error: ${e.message}');
      }
    } catch (e) {
      setState(() => _errorMessage = '❌ Unexpected Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 Generate 12-digit Teacher ID (Letters + Numbers)
  String _generateTeacherId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = 'T';
    for (int i = 0; i < 11; i++) {
      final random = DateTime.now().millisecondsSinceEpoch % chars.length;
      result += chars[random];
    }
    return result;
  }

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _qualificationController.clear();
    _experienceController.clear();
    _completionYearController.clear();
    _addressController.clear();
    setState(() {
      _photoBase64 = '';
      _resumeBase64 = '';
      _historyArrear = false;
      _selectedDepartment = '';
      _selectedClass = '';
      _errorMessage = null;
    });
  }

  void _showCreateClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Class Name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text('Department: $_selectedDepartment', style: const TextStyle(color: Colors.white60)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a class name'), backgroundColor: Colors.orange),
                );
                return;
              }
              final className = controller.text.trim();
              try {
                await FirebaseFirestore.instance.collection('classes').add({
                  'name': className,
                  'department': _selectedDepartment,
                  'section': '',
                  'students': [],
                  'teachers': [],
                  'timetable': {},
                  'subjects': [],
                  'createdAt': FieldValue.serverTimestamp(),
                });
                await _loadClasses();
                setState(() => _selectedClass = className);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Class created!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
            tooltip: 'Refresh classes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 ERROR MESSAGE DISPLAY
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Class will be auto-created if it doesn\'t exist.',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Photo & Resume
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _photoBase64.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(base64Decode(_photoBase64), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 28, color: Colors.white60),
                                SizedBox(height: 2),
                                Text('Photo', style: TextStyle(color: Colors.white60, fontSize: 10)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _pickResume,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _resumeBase64.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(base64Decode(_resumeBase64), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description, size: 28, color: Colors.white60),
                                SizedBox(height: 2),
                                Text('Resume', style: TextStyle(color: Colors.white60, fontSize: 10)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Department Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department *',
                  prefixIcon: Icon(Icons.business),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('Select a department')),
                  ..._departments.map((dept) => DropdownMenuItem<String>(value: dept, child: Text(dept))),
                ],
                onChanged: (String? v) {
                  if (v != null && v.isNotEmpty) {
                    setState(() {
                      _selectedDepartment = v;
                      _selectedClass = '';
                      _loadClasses();
                      _errorMessage = null;
                    });
                  }
                },
                validator: (String? v) => v == null || v.isEmpty ? 'Select a department' : null,
              ),
              const SizedBox(height: 10),

              // Class Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedClass.isEmpty ? null : _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class *',
                  prefixIcon: Icon(Icons.class_),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('Select a class')),
                  const DropdownMenuItem<String>(
                    value: '__create_new__',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('+ Create New Class', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  ..._availableClasses
                      .where((cls) => FirebaseService.getClassesForDepartment(_selectedDepartment).contains(cls))
                      .map((cls) => DropdownMenuItem<String>(value: cls, child: Text(cls))),
                ],
                onChanged: (String? v) {
                  if (v == '__create_new__') {
                    _showCreateClassDialog();
                  } else if (v != null && v.isNotEmpty) {
                    setState(() {
                      _selectedClass = v;
                      _errorMessage = null;
                    });
                  }
                },
                validator: (String? v) => v == null || v.isEmpty ? 'Select a class' : null,
              ),
              const SizedBox(height: 10),

              // Create New Class Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCreateClassDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create New Class'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (String? v) => v!.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email * (use @ruby.edu)',
                  prefixIcon: Icon(Icons.email),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (String? v) => v!.endsWith('@ruby.edu') ? null : 'Use @ruby.edu',
              ),
              const SizedBox(height: 10),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (String? v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 10),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (String? v) => v!.isEmpty ? 'Confirm password' : null,
              ),
              const SizedBox(height: 10),

              // Phone
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),

              // Designation
              DropdownButtonFormField<String>(
                initialValue: _selectedDesignation,
                decoration: const InputDecoration(
                  labelText: 'Designation *',
                  prefixIcon: Icon(Icons.work),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: const [
                  DropdownMenuItem(value: 'Professor', child: Text('Professor')),
                  DropdownMenuItem(value: 'Associate Professor', child: Text('Associate Professor')),
                  DropdownMenuItem(value: 'Assistant Professor', child: Text('Assistant Professor')),
                  DropdownMenuItem(value: 'Lecturer', child: Text('Lecturer')),
                ],
                onChanged: (String? v) => setState(() => _selectedDesignation = v!),
                validator: (String? v) => v == null ? 'Select designation' : null,
              ),
              const SizedBox(height: 10),

              // Qualification
              TextFormField(
                controller: _qualificationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Qualification',
                  prefixIcon: Icon(Icons.school),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),

              // Experience
              TextFormField(
                controller: _experienceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                  prefixIcon: Icon(Icons.work_history),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),

              // Completion Year
              TextFormField(
                controller: _completionYearController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Completion Year',
                  prefixIcon: Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),

              // Address
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Additional Role
              const Text('Additional Role', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['None', 'Class Incharge', 'Lab Incharge', 'Lab Supervisor'].map((role) {
                  return ChoiceChip(
                    label: Text(role, style: const TextStyle(fontSize: 12)),
                    selected: _selectedAdditionalRole == role,
                    onSelected: (bool selected) => setState(() => _selectedAdditionalRole = selected ? role : 'None'),
                    selectedColor: const Color(0xFF6C3BFF),
                    labelStyle: TextStyle(
                      color: _selectedAdditionalRole == role ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // History Arrear
              Row(
                children: [
                  const Text('History Arrear: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                  Switch(
                    value: _historyArrear,
                    onChanged: (bool v) => setState(() => _historyArrear = v),
                  ),
                  Text(
                    _historyArrear ? 'Yes' : 'No',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _historyArrear ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Teacher', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// 5. ADD STUDENT (FULL VERSION)
// ============================================================
class AddStudent extends StatefulWidget {
  final String? initialClassId;
  const AddStudent({super.key, this.initialClassId});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _fatherController = TextEditingController();
  String _selectedClassId = '';
  String _photoBase64 = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId ?? '';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 50);
    if (mounted) setState(() => _photoBase64 = base64Encode(compressed));
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a class'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newStudent = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'rollNumber': _rollController.text.trim(),
        'fatherNumber': _fatherController.text.trim(),
        'photo': _photoBase64,
        'attendance': {},
        'marks': {},
        'halfMarks': '',
        'quarterlyMarks': '',
      };
      await FirebaseService.addStudent(_selectedClassId, newStudent);
      _nameController.clear();
      _rollController.clear();
      _fatherController.clear();
      setState(() => _photoBase64 = '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _photoBase64.isNotEmpty ? MemoryImage(base64Decode(_photoBase64)) : null,
                      child: _photoBase64.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF6C3BFF),
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final user = FirebaseAuth.instance.currentUser;
                  final isPrincipal = user?.email?.endsWith('@ruby.com') ?? false;
                  var docs = snapshot.data!.docs;
                  if (!isPrincipal) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                      return teachers.any((t) => t['email'] == user?.email);
                    }).toList();
                  }
                  final items = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('${data['name'] ?? 'Class'} (${data['department'] ?? ''})'),
                    );
                  }).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedClassId.isEmpty ? null : _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Select Class *',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Select a class')),
                      ...items,
                    ],
                    onChanged: (String? v) => setState(() => _selectedClassId = v!),
                    validator: (String? v) => v == null ? 'Please select a class' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Student Name *'),
                validator: (String? v) => v!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _rollController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Roll Number *'),
                validator: (String? v) => v!.isEmpty ? 'Enter roll number' : null,
              ),
              TextFormField(
                controller: _fatherController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Father's Phone *"),
                keyboardType: TextInputType.phone,
                validator: (String? v) => v!.length < 10 ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addStudent,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 2. LOGIN SCREEN
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'teacher';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teacherIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_selectedRole == 'teacher') {
      if (_teacherIdController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        _showError('Fill all fields');
        return;
      }
      if (_teacherIdController.text.length != 12) {
        _showError('Teacher ID must be 12 digits');
        return;
      }
    } else {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError('Fill all fields');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final rawEmail = _emailController.text.trim();
      final rubyEmail = EmailUtils.toRubyEmail(rawEmail);
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: rubyEmail, password: password);

      final user = userCredential.user!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String role = 'teacher';
      if (doc.exists) {
        role = doc.data()?['role'] ?? 'teacher';
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': rubyEmail,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
        role = _selectedRole;
      }

      if (role == 'teacher') {
        final storedId = doc.data()?['teacherId'] ?? '';
        if (_teacherIdController.text.trim() != storedId) {
          _showError('Invalid Teacher ID');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (role != _selectedRole && _selectedRole != 'teacher') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': _selectedRole});
        role = _selectedRole;
      }

      if (role == 'chairman') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChairmanDashboard()),
        );
      } else if (role == 'principal') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PrincipalDashboard()),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'User not found';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email';
      } else {
        msg = e.message ?? 'Login error';
      }
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    if (_selectedRole == 'chairman') {
      gradientColors = [const Color(0xFF6C3BFF), const Color(0xFFFFD700)];
    } else if (_selectedRole == 'principal') {
      gradientColors = [const Color(0xFF4B0082), const Color(0xFFE6E6FA)];
    } else {
      gradientColors = [const Color(0xFF7B1FA2), const Color(0xFF708090)];
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    32,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _roleCard(
                              'Chairman',
                              Icons.business,
                              'chairman',
                              isSelected: _selectedRole == 'chairman',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _roleCard(
                              'Principal',
                              Icons.admin_panel_settings,
                              'principal',
                              isSelected: _selectedRole == 'principal',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _roleCard(
                              'Teacher',
                              Icons.school,
                              'teacher',
                              isSelected: _selectedRole == 'teacher',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C3BFF), Color(0xFF9B8AFF)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in as $_selectedRole',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedRole == 'teacher')
                      TextFormField(
                        controller: _teacherIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '12‑Digit Teacher ID',
                          hintText: 'e.g., C1004AP03BT001',
                          prefixIcon: Icon(Icons.badge, color: Colors.white60),
                        ),
                      ),
                    if (_selectedRole == 'teacher') const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@anything.com (auto → @ruby.edu)',
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.white60),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChairmanSignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Create a Chairman ID →',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon('in', Colors.blue.shade700),
                        const SizedBox(width: 12),
                        _socialIcon('G', Colors.red),
                        const SizedBox(width: 12),
                        _socialIcon('M', Colors.green),
                        const SizedBox(width: 12),
                        _socialIcon('Gt', Colors.white),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C3BFF), Color(0xFF9B8AFF)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'R',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String title, IconData icon, String role, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 3,
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(String letter, Color color) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ============================================================
// 3. CHAIRMAN SIGN‑UP SCREEN
// ============================================================
class ChairmanSignUpScreen extends StatefulWidget {
  const ChairmanSignUpScreen({super.key});

  @override
  State<ChairmanSignUpScreen> createState() => _ChairmanSignUpScreenState();
}

class _ChairmanSignUpScreenState extends State<ChairmanSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _panNumber = TextEditingController();
  final TextEditingController _aadhaar = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  String _photoBase64 = '';
  String _panCardBase64 = '';
  String _convertedEmail = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 50);
    setState(() {
      if (type == 'photo') {
        _photoBase64 = base64Encode(compressed);
      } else {
        _panCardBase64 = base64Encode(compressed);
      }
    });
  }

  void _updateConvertedEmail(String value) {
    setState(() {
      if (value.trim().isNotEmpty) {
        _convertedEmail = EmailUtils.toRubyEmail(value);
      } else {
        _convertedEmail = '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_password.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final chairmanEmail = _convertedEmail.isNotEmpty
          ? _convertedEmail
          : EmailUtils.toRubyEmail(_email.text);

      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: chairmanEmail,
        password: _password.text,
      );
      final user = userCredential.user!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _name.text.trim(),
        'email': chairmanEmail,
        'role': 'chairman',
        'mobile': _mobile.text.trim(),
        'panNumber': _panNumber.text.trim(),
        'aadhaar': _aadhaar.text.trim(),
        'photo': _photoBase64,
        'panCard': _panCardBase64,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChairmanPaymentScreen(
            email: chairmanEmail,
            name: _name.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already registered.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak.';
      } else {
        msg = e.message ?? 'Error';
      }
      _showError(msg);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chairman Sign‑Up'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage('photo'),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _photoBase64.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(_photoBase64),
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white60),
                            SizedBox(height: 4),
                            Text('Photo', style: TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage('pan'),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _panCardBase64.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(_panCardBase64),
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card, color: Colors.white60),
                            SizedBox(height: 4),
                            Text('PAN Card', style: TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Chairman Name', _name, Icons.person),
              _buildField('PAN Card Number', _panNumber, Icons.credit_card),
              _buildField('Aadhaar Card Number', _aadhaar, Icons.badge),
              _buildField('Mobile Number', _mobile, Icons.phone, keyboard: TextInputType.phone),
              // Email Field - Fixed duplicate issue
              TextFormField(
                controller: _email,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                onChanged: _updateConvertedEmail,
                decoration: InputDecoration(
                  labelText: 'Chairman Email',
                  hintText: 'you@gmail.com (auto → @ruby.edu)',
                  prefixIcon: const Icon(Icons.email, color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  helperText: _convertedEmail.isNotEmpty
                      ? '✅ Login Email: $_convertedEmail'
                      : 'Enter email → auto-converted to @ruby.edu',
                  helperStyle: TextStyle(
                    color: _convertedEmail.isNotEmpty ? Colors.green : Colors.white38,
                    fontSize: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField('Password', _password, Icons.lock, obscure: true),
              _buildField('Confirm Password', _confirmPassword, Icons.lock_outline, obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Proceed to Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
        validator: (String? v) => v!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

// ============================================================
// 4. CHAIRMAN PAYMENT SCREEN
// ============================================================
class ChairmanPaymentScreen extends StatelessWidget {
  final String email;
  final String name;
  const ChairmanPaymentScreen({super.key, required this.email, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Chairman Registration Payment',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ₹8,000',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 100, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'UPI ID: muhammedibrahimbca@okaxis',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scan QR or pay using UPI',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Payment Successful'),
                          content: Text('Welcome $name! You can now login with $email.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text('Go to Login'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ============================================================
// ===================== FIREBASE SERVICE =====================
// ============================================================
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, List<String>> departmentClassMap = {
    'Computer Science': ['BCA', 'BSC(CS)'],
    'Commerce': ['B.com(CA)', 'B.com(PA)'],
    'Business Administration': ['BBA'],
    'Language Tamil': ['B.A Tamil'],
    'Language English': ['B.A English'],
    'Hotel Management System': ['HMCS'],
    'Public Admin': ['B.A(PA)'],
    'Fashion Technology & Costume Designing': ['BSC(FT&CD)'],
  };

  static List<String> get departments => departmentClassMap.keys.toList();
  static List<String> getClassesForDepartment(String department) => departmentClassMap[department] ?? [];

  static const List<String> periodKeys = ['P1', 'P2', 'Break', 'P3', 'P4', 'Lunch', 'P5', 'P6'];
  static const Map<String, String> periodLabels = {
    'P1': 'P1 (9:00 - 10:00)',
    'P2': 'P2 (10:00 - 11:00)',
    'Break': 'Break (11:00 - 11:15)',
    'P3': 'P3 (11:15 - 12:15)',
    'P4': 'P4 (12:15 - 1:15)',
    'Lunch': 'Lunch (1:15 - 2:00)',
    'P5': 'P5 (2:00 - 3:00)',
    'P6': 'P6 (3:00 - 4:00)',
  };
  static const List<String> dayKeys = ['Day1', 'Day2', 'Day3', 'Day4', 'Day5'];
  static const Map<String, String> dayLabels = {
    'Day1': 'D1 (Mon)',
    'Day2': 'D2 (Tue)',
    'Day3': 'D3 (Wed)',
    'Day4': 'D4 (Thu)',
    'Day5': 'D5 (Fri)',
  };

  static Future<void> initializeClasses() async {
    final snapshot = await _firestore.collection('classes').get();
    if (snapshot.docs.isEmpty) {
      for (final dept in departments) {
        final classes = getClassesForDepartment(dept);
        for (final className in classes) {
          await _firestore.collection('classes').add({
            'name': className,
            'department': dept,
            'section': '',
            'students': [],
            'teachers': [],
            'timetable': {},
            'subjects': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  static Future<String?> getClassIdByName(String name) async {
    final snapshot = await _firestore.collection('classes').where('name', isEqualTo: name).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  static Future<Map<String, dynamic>> getClassData(String classId) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    return doc.data() as Map<String, dynamic>;
  }

  static Future<void> addStudent(String classId, Map<String, dynamic> studentData) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(
        (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    students.add(studentData);
    await _firestore.collection('classes').doc(classId).update({'students': students});
  }

  static Future<void> updateStudent(String classId, String studentId, Map<String, dynamic> updatedData) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(
        (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      students[index] = {...students[index], ...updatedData};
      await _firestore.collection('classes').doc(classId).update({'students': students});
    }
  }

  static Stream<List<Map<String, dynamic>>> getAllStudents() {
    return _firestore.collection('classes').snapshots().map((snapshot) {
      final allStudents = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        final className = data['name'] ?? 'Class';
        final department = data['department'] ?? '';
        for (final s in students) {
          allStudents.add({...s, 'class': className, 'department': department, 'classId': doc.id});
        }
      }
      return allStudents;
    });
  }

  static Future<void> addTeacher(String classId, Map<String, dynamic> teacherData) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final teachers = List<Map<String, dynamic>>.from(
        (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    teachers.add(teacherData);
    await _firestore.collection('classes').doc(classId).update({'teachers': teachers});
  }

  static Future<void> deleteTeacher(String classId, String teacherId) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final teachers = List<Map<String, dynamic>>.from(
        (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    teachers.removeWhere((t) => t['id'] == teacherId);
    await _firestore.collection('classes').doc(classId).update({'teachers': teachers});
  }

  static Stream<List<Map<String, dynamic>>> getAllTeachers() {
    return _firestore.collection('classes').snapshots().map((snapshot) {
      final allTeachers = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        final className = data['name'] ?? 'Class';
        final department = data['department'] ?? '';
        for (final t in teachers) {
          allTeachers.add({...t, 'class': className, 'department': department, 'classId': doc.id});
        }
      }
      return allTeachers;
    });
  }

  static Future<void> saveAttendance(String classId, List<Map<String, dynamic>> students, Map<String, bool> attendance) async {
    final updatedStudents = students.map((s) {
      final student = Map<String, dynamic>.from(s);
      final id = student['id'];
      if (attendance.containsKey(id)) {
        student['attendance'] = {
          ...?student['attendance'] as Map?,
          DateFormat('yyyy-MM-dd').format(DateTime.now()): attendance[id],
        };
      }
      return student;
    }).toList();
    await _firestore.collection('classes').doc(classId).update({'students': updatedStudents});
  }

  static Future<void> addSubjectsToClass(String classId, List<String> subjects) async {
    await _firestore.collection('classes').doc(classId).update({
      'subjects': subjects,
    });
  }

  static Future<List<String>> getClassSubjects(String classId) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['subjects'] ?? []);
  }

  static Future<void> updateStudentMarks(String classId, String studentId, String subject, double marks) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(
        (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final index = students.indexWhere((s) => s['id'] == studentId);
    if (index != -1) {
      final student = students[index];
      final marksMap = Map<String, dynamic>.from(student['marks'] ?? {});
      marksMap[subject] = marks;
      student['marks'] = marksMap;
      students[index] = student;
      await _firestore.collection('classes').doc(classId).update({'students': students});
    }
  }

  static Future<Map<String, dynamic>> getStudentMarks(String classId, String studentId) async {
    final doc = await _firestore.collection('classes').doc(classId).get();
    final data = doc.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(
        (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final student = students.firstWhere((s) => s['id'] == studentId, orElse: () => {});
    return student['marks'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> addRemark(String studentId, String remark, String teacherId, {String? teacherName}) async {
    await _firestore.collection('remarks').add({
      'studentId': studentId,
      'remark': remark,
      'teacherId': teacherId,
      'teacherName': teacherName ?? 'Teacher',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getRemarksForStudent(String studentId) {
    return _firestore.collection('remarks').where('studentId', isEqualTo: studentId).orderBy('timestamp', descending: true).snapshots();
  }

  static Stream<QuerySnapshot> getAllRemarks() {
    return _firestore.collection('remarks').orderBy('timestamp', descending: true).snapshots();
  }

  static Future<void> updateTimetablePeriods(String classId, Map<String, Map<String, String>> timetable) async {
    await _firestore.collection('classes').doc(classId).update({'timetable': timetable});
  }

  static Future<void> updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
}

// ============================================================
// CHAIRMAN DASHBOARD - MOBILE UI
// ============================================================
class ChairmanDashboard extends StatefulWidget {
  const ChairmanDashboard({super.key});

  @override
  State<ChairmanDashboard> createState() => _ChairmanDashboardState();
}

class _ChairmanDashboardState extends State<ChairmanDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<BottomNavigationBarItem> _bottomItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Colleges'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Teachers'),
  ];

  final List<Widget> _bottomScreens = [
    const ChairmanHomeScreen(),
    const ChairmanCollegesList(),
    const ChairmanTeachersView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Chairman Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _bottomScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _bottomItems,
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFF1A1A2E),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C3BFF), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Color(0xFF6C3BFF)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chairman',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'chairman@ruby.edu',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.dashboard, 'Dashboard', () => _navigateTo(0, context)),
                _drawerItem(Icons.info_outline, 'College Details', () => _navigateToDetails(context)),
                _drawerItem(Icons.message, 'Messaging', () => _navigateToMessaging(context)),
                _drawerItem(Icons.notifications, 'Notifications', () => _navigateToNotifications(context)),
                _drawerItem(Icons.settings, 'Settings', () => _navigateToSettings(context)),
                _drawerItem(Icons.person_add, 'Add Principal', () => _navigateToAddPrincipal(context)),
                _drawerItem(Icons.edit, 'Edit Principal', () => _navigateToEditPrincipal(context)),
                _drawerItem(Icons.person_remove, 'Delete Principal', () => _navigateToDeletePrincipal(context)),
                _drawerItem(Icons.people, 'View Teachers', () => _navigateToTeachers(context)),
                _drawerItem(Icons.add_business, 'Add College', () => _navigateToAddCollege(context)),
                const Divider(color: Colors.white24),
                _drawerItem(Icons.logout, 'Logout', () => _logout(context), color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white60),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white70),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(int index, BuildContext context) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanCollegeDetailsView()));
  }

  void _navigateToMessaging(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanMessagingView()));
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanNotificationsView()));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanSettingsView()));
  }

  void _navigateToAddPrincipal(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPrincipalForm()));
  }

  void _navigateToEditPrincipal(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPrincipalFormWrapper()));
  }

  void _navigateToDeletePrincipal(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DeletePrincipalForm()));
  }

  void _navigateToTeachers(BuildContext context) {
    setState(() => _selectedIndex = 2);
  }

  void _navigateToAddCollege(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCollegeStep1()));
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

// ============================================================
// CHAIRMAN HOME SCREEN
// ============================================================
class ChairmanHomeScreen extends StatefulWidget {
  const ChairmanHomeScreen({super.key});

  @override
  State<ChairmanHomeScreen> createState() => _ChairmanHomeScreenState();
}

class _ChairmanHomeScreenState extends State<ChairmanHomeScreen> {
  int _totalColleges = 0;
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalPrincipals = 0;
  int _totalPaid = 0;
  int _totalPending = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final collegesSnapshot = await FirebaseFirestore.instance.collection('colleges').get();
      _totalColleges = collegesSnapshot.docs.length;

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = usersSnapshot.docs;
      _totalPrincipals = users.where((d) => d.data()['role'] == 'principal').length;
      _totalTeachers = users.where((d) => d.data()['role'] == 'teacher').length;

      final classesSnapshot = await FirebaseFirestore.instance.collection('classes').get();
      int studentCount = 0;
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final students = data['students'] as List? ?? [];
        studentCount += students.length;
      }
      _totalStudents = studentCount;

      int paid = 0;
      int pending = 0;
      for (var doc in collegesSnapshot.docs) {
        final data = doc.data();
        final status = data['paymentStatus'] ?? 'pending';
        final amount = data['paymentAmount'] ?? 8000;
        if (status == 'paid') {
          paid += amount as int;
        } else {
          pending += amount as int;
        }
      }
      _totalPaid = paid;
      _totalPending = pending;
    } catch (e) {
      // Silent catch
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0E1A),
            Color(0xFF1A1040),
            Color(0xFF2D1B69),
          ],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text('Loading Dashboard...', style: TextStyle(color: Colors.white60)),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C3BFF), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Chairman!',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFFFD700), size: 20),
                    onPressed: _loadDashboardData,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Cards - 2x2 Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    icon: Icons.business,
                    value: _totalColleges.toString(),
                    label: 'Colleges',
                    color: const Color(0xFFFFD700),
                    iconBgColor: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ),
                  _buildStatCard(
                    icon: Icons.people,
                    value: _totalStudents.toString(),
                    label: 'Students',
                    color: Colors.blue,
                    iconBgColor: Colors.blue.withValues(alpha: 0.2),
                  ),
                  _buildStatCard(
                    icon: Icons.school,
                    value: _totalTeachers.toString(),
                    label: 'Teachers',
                    color: const Color(0xFF6C3BFF),
                    iconBgColor: const Color(0xFF6C3BFF).withValues(alpha: 0.2),
                  ),
                  _buildStatCard(
                    icon: Icons.admin_panel_settings,
                    value: _totalPrincipals.toString(),
                    label: 'Principals',
                    color: Colors.green,
                    iconBgColor: Colors.green.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentCard(
                            'Total Revenue',
                            '₹${_totalPaid + _totalPending}',
                            const Color(0xFFFFD700),
                            Icons.attach_money,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentCard(
                            'Collected',
                            '₹$_totalPaid',
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentCard(
                            'Pending',
                            '₹$_totalPending',
                            Colors.orange,
                            Icons.pending,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // College Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'College Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_totalColleges Active',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.business, 'Total Colleges', _totalColleges.toString(), const Color(0xFFFFD700)),
                    _buildInfoRow(Icons.people, 'Total Students', _totalStudents.toString(), Colors.blue),
                    _buildInfoRow(Icons.school, 'Total Teachers', _totalTeachers.toString(), const Color(0xFF6C3BFF)),
                    _buildInfoRow(Icons.admin_panel_settings, 'Total Principals', _totalPrincipals.toString(), Colors.green),
                    _buildInfoRow(
                      Icons.attach_money,
                      'Total Revenue',
                      '₹${_totalPaid + _totalPending}',
                      const Color(0xFFFFD700),
                    ),
                    _buildInfoRow(
                      Icons.percent,
                      'Collection Rate',
                      '${_totalPaid + _totalPending > 0 ? ((_totalPaid / (_totalPaid + _totalPending)) * 100).toStringAsFixed(1) : 0}%',
                      Colors.cyan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _actionChip('Add College', Icons.add_business, const Color(0xFFFFD700), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCollegeStep1()));
                        }),
                        _actionChip('Add Principal', Icons.person_add, const Color(0xFF6C3BFF), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPrincipalForm()));
                        }),
                        _actionChip('View Colleges', Icons.business, Colors.blue, () {
                          // Already on Colleges tab
                        }),
                        _actionChip('Attendance', Icons.check_circle, Colors.green, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanAttendanceView()));
                        }),
                        _actionChip('Payments', Icons.payment, Colors.orange, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChairmanPaymentsView()));
                        }),
                        _actionChip('Teachers', Icons.school, Colors.purple, () {
                          setState(() {
                            // Switch to Teachers tab
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAIRMAN COLLEGES LIST
// ============================================================
class ChairmanCollegesList extends StatefulWidget {
  const ChairmanCollegesList({super.key});

  @override
  State<ChairmanCollegesList> createState() => _ChairmanCollegesListState();
}

class _ChairmanCollegesListState extends State<ChairmanCollegesList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0E1A),
            Color(0xFF1A1040),
            Color(0xFF2D1B69),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Colleges'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCollegeStep1()),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('colleges')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 64, color: Colors.white24),
                    SizedBox(height: 16),
                    Text('No colleges registered yet', style: TextStyle(color: Colors.white60)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final docId = docs[index].id;
                final status = data['status'] ?? 'pending';
                final paymentStatus = data['paymentStatus'] ?? 'pending';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: status == 'active' ? Colors.green : Colors.orange,
                              child: Text(
                                (data['name'] ?? 'C')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'College',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Domain: ${data['domain'] ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      _statusChip('Status: $status', status == 'active' ? Colors.green : Colors.orange),
                                      const SizedBox(width: 6),
                                      _statusChip(
                                        'Payment: $paymentStatus',
                                        paymentStatus == 'paid' ? Colors.green : Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollegeDetailScreen(
                                      collegeId: docId,
                                      collegeData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditCollegeScreen(
                                      docId: docId,
                                      collegeData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete College'),
                                    content: Text('Are you sure you want to delete "${data['name']}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance.collection('colleges').doc(docId).delete();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('College deleted'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }
}

// ============================================================
// COLLEGE DETAIL SCREEN
// ============================================================
class CollegeDetailScreen extends StatelessWidget {
  final String collegeId;
  final Map<String, dynamic> collegeData;
  const CollegeDetailScreen({super.key, required this.collegeId, required this.collegeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collegeData['name'] ?? 'College Detail'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'College Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                    ),
                    const Divider(),
                    _detailRow('Name', collegeData['name'] ?? 'N/A'),
                    _detailRow('Domain', collegeData['domain'] ?? 'N/A'),
                    _detailRow('Address', collegeData['address'] ?? 'N/A'),
                    _detailRow('City', collegeData['city'] ?? 'N/A'),
                    _detailRow('State', collegeData['state'] ?? 'N/A'),
                    _detailRow('Phone', collegeData['phone'] ?? 'N/A'),
                    _detailRow('Email', collegeData['email'] ?? 'N/A'),
                    _detailRow('Status', collegeData['status'] ?? 'pending'),
                    _detailRow('Payment Status', collegeData['paymentStatus'] ?? 'pending'),
                    _detailRow('Principal', collegeData['principalName'] ?? 'Not Assigned'),
                    if (collegeData['principalId'] != null)
                      _detailRow('Principal ID', collegeData['principalId'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (collegeData['departments'] != null && (collegeData['departments'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Departments & Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      ...(collegeData['departments'] as List).map((dept) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dept['name'], style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: (dept['subjects'] as List?)?.map((sub) => Chip(label: Text(sub.toString()))).toList() ?? [],
                              ),
                              const Divider(color: Colors.white24),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAIRMAN COLLEGE DETAILS VIEW
// ============================================================
class ChairmanCollegeDetailsView extends StatefulWidget {
  const ChairmanCollegeDetailsView({super.key});

  @override
  State<ChairmanCollegeDetailsView> createState() => _ChairmanCollegeDetailsViewState();
}

class _ChairmanCollegeDetailsViewState extends State<ChairmanCollegeDetailsView> {
  String? _selectedCollegeId;
  Map<String, dynamic>? _collegeData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Details'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCollegeId,
                  decoration: const InputDecoration(
                    labelText: 'Select College',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'College'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCollegeId = value;
                      _collegeData = docs.firstWhere((d) => d.id == value).data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),
          ),
          if (_collegeData != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'College Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const Divider(),
                        _detailRow('Name', _collegeData!['name'] ?? 'N/A'),
                        _detailRow('Domain', _collegeData!['domain'] ?? 'N/A'),
                        _detailRow('Address', _collegeData!['address'] ?? 'N/A'),
                        _detailRow('City', _collegeData!['city'] ?? 'N/A'),
                        _detailRow('State', _collegeData!['state'] ?? 'N/A'),
                        _detailRow('Phone', _collegeData!['phone'] ?? 'N/A'),
                        _detailRow('Email', _collegeData!['email'] ?? 'N/A'),
                        _detailRow('Status', _collegeData!['status'] ?? 'pending'),
                        _detailRow('Payment Status', _collegeData!['paymentStatus'] ?? 'pending'),
                        _detailRow('Principal', _collegeData!['principalName'] ?? 'Not Assigned'),
                        if (_collegeData!['principalId'] != null)
                          _detailRow('Principal ID', _collegeData!['principalId'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(color: Colors.white38)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAIRMAN MESSAGING VIEW
// ============================================================
class ChairmanMessagingView extends StatefulWidget {
  const ChairmanMessagingView({super.key});

  @override
  State<ChairmanMessagingView> createState() => _ChairmanMessagingViewState();
}

class _ChairmanMessagingViewState extends State<ChairmanMessagingView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Chairman Announcement',
        'message': _messageController.text.trim(),
        'targetRole': 'all',
        'sentBy': 'Chairman',
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      _titleController.clear();
      _messageController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Title (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sent Messages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages sent yet', style: TextStyle(color: Colors.white60)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFD700),
                          child: Icon(Icons.message, color: Colors.black),
                        ),
                        title: Text(
                          data['title'] ?? 'Message',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                            if (data['createdAt'] != null)
                              Text(
                                DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAIRMAN NOTIFICATIONS VIEW
// ============================================================
class ChairmanNotificationsView extends StatelessWidget {
  const ChairmanNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No notifications', style: TextStyle(color: Colors.white60)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C3BFF),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                      if (data['createdAt'] != null)
                        Text(
                          DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: data['readBy'] != null && (data['readBy'] as List).isNotEmpty
                      ? const Icon(Icons.done_all, color: Colors.green)
                      : const Icon(Icons.done, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// CHAIRMAN SETTINGS VIEW
// ============================================================
class ChairmanSettingsView extends StatelessWidget {
  const ChairmanSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFFFD700)),
                title: const Text('Profile', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Update profile information', style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                onTap: () {
                  // Navigate to Profile
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen(role: 'Chairman')));
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security, color: Color(0xFFFFD700)),
                title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Update your password', style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                onTap: () {
                  // Show change password dialog
                  _showChangePasswordDialog(context);
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFFFFD700)),
                title: const Text('Notification Settings', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Configure notifications', style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon'), backgroundColor: Colors.blue),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info, color: Color(0xFFFFD700)),
                title: const Text('About', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Ruby Attendance v1.0.0', style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Ruby Attendance',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text('Smart Attendance Management System'),
                      SizedBox(height: 8),
                      Text('© 2024 Ruby Attendance'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
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
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
                );
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(newPasswordController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD PRINCIPAL FORM (WITH AUTO ID GENERATION)
// ============================================================
class AddPrincipalForm extends StatefulWidget {
  const AddPrincipalForm({super.key});

  @override
  State<AddPrincipalForm> createState() => _AddPrincipalFormState();
}

class _AddPrincipalFormState extends State<AddPrincipalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  String _selectedCollegeId = '';
  List<Map<String, dynamic>> _colleges = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('colleges').get();
      setState(() {
        _colleges = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'College',
            'domain': data['domain'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      // Silent
    }
  }

  Future<void> _addPrincipal() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }
    if (_selectedCollegeId.isEmpty) {
      setState(() => _errorMessage = 'Please select a college');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;

      // Generate unique Principal ID
      final principalId = IdGenerator.generatePrincipalId();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'role': 'principal',
        'collegeId': _selectedCollegeId,
        'collegeDomain': _colleges.firstWhere((c) => c['id'] == _selectedCollegeId)['domain'] ?? '',
        'principalId': principalId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('colleges')
          .doc(_selectedCollegeId)
          .update({
        'principalAdded': true,
        'principalEmail': _emailController.text.trim(),
        'principalId': user.uid,
        'principalName': _nameController.text.trim(),
      });

      if (!mounted) return;

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneController.clear();
      _qualificationController.clear();
      setState(() => _selectedCollegeId = '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Principal added successfully! ID: $principalId'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to add principal';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already in use.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak.';
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Principal'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              _buildTextField('Principal Name', _nameController, Icons.person),
              _buildTextField('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField('Password', _passwordController, Icons.lock, obscure: true),
              _buildTextField('Confirm Password', _confirmPasswordController, Icons.lock_outline, obscure: true),
              _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField('Qualification', _qualificationController, Icons.school),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollegeId.isEmpty ? null : _selectedCollegeId,
                decoration: const InputDecoration(
                  labelText: 'Assign to College *',
                  prefixIcon: Icon(Icons.business),
                ),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('Select a college')),
                  ..._colleges.map((college) {
                    return DropdownMenuItem<String>(
                      value: college['id'] as String,
                      child: Text('${college['name']} (${college['domain']})'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCollegeId = value ?? '';
                    _errorMessage = null;
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Select a college' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addPrincipal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Principal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Enter a valid email';
          }
          if (label == 'Phone Number' && value.length < 10) {
            return 'Enter a valid phone number';
          }
          return null;
        },
      ),
    );
  }
}

// ============================================================
// EDIT PRINCIPAL FORM WRAPPER
// ============================================================
class EditPrincipalFormWrapper extends StatefulWidget {
  const EditPrincipalFormWrapper({super.key});

  @override
  State<EditPrincipalFormWrapper> createState() => _EditPrincipalFormWrapperState();
}

class _EditPrincipalFormWrapperState extends State<EditPrincipalFormWrapper> {
  String? _selectedPrincipalId;
  Map<String, dynamic>? _selectedPrincipal;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Principal'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'principal')
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No principals found', style: TextStyle(color: Colors.white60)),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedPrincipalId,
                  decoration: const InputDecoration(
                    labelText: 'Select Principal',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'Principal'),
                          Text(
                            'ID: ${data['principalId'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrincipalId = value;
                      _selectedPrincipal = docs.firstWhere((d) => d.id == value).data() as Map<String, dynamic>;
                      _nameController.text = _selectedPrincipal?['name'] ?? '';
                      _phoneController.text = _selectedPrincipal?['phone'] ?? '';
                      _qualificationController.text = _selectedPrincipal?['qualification'] ?? '';
                    });
                  },
                );
              },
            ),
          ),
          if (_selectedPrincipal != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Principal Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                            const Divider(),
                            _infoRow('Email', _selectedPrincipal!['email'] ?? 'N/A'),
                            _infoRow('College', _selectedPrincipal!['collegeDomain'] ?? 'N/A'),
                            _infoRow('Principal ID', _selectedPrincipal!['principalId'] ?? 'N/A'),
                            _infoRow('Created', _selectedPrincipal!['createdAt'] != null
                                ? DateFormat('dd MMM yyyy').format((_selectedPrincipal!['createdAt'] as Timestamp).toDate())
                                : 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField('Name', _nameController, Icons.person),
                    _buildField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                    _buildField('Qualification', _qualificationController, Icons.school),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes'),
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

  Future<void> _saveChanges() async {
    if (_selectedPrincipalId == null) return;
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_selectedPrincipalId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Principal updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: Colors.white38)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// ============================================================
// DELETE PRINCIPAL FORM
// ============================================================
class DeletePrincipalForm extends StatefulWidget {
  const DeletePrincipalForm({super.key});

  @override
  State<DeletePrincipalForm> createState() => _DeletePrincipalFormState();
}

class _DeletePrincipalFormState extends State<DeletePrincipalForm> {
  String? _selectedPrincipalId;
  Map<String, dynamic>? _selectedPrincipal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Principal'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'principal')
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No principals found', style: TextStyle(color: Colors.white60)),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedPrincipalId,
                  decoration: const InputDecoration(
                    labelText: 'Select Principal to Delete',
                    prefixIcon: Icon(Icons.person_remove),
                  ),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Principal'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrincipalId = value;
                      _selectedPrincipal = docs.firstWhere((d) => d.id == value).data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),
          ),
          if (_selectedPrincipal != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Principal Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Divider(),
                    _infoRow('Name', _selectedPrincipal!['name'] ?? 'N/A'),
                    _infoRow('Email', _selectedPrincipal!['email'] ?? 'N/A'),
                    _infoRow('College', _selectedPrincipal!['collegeDomain'] ?? 'N/A'),
                    _infoRow('Principal ID', _selectedPrincipal!['principalId'] ?? 'N/A'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This action cannot be undone.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text('Delete "${_selectedPrincipal!['name']}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_selectedPrincipalId)
                                  .delete();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Principal deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _selectedPrincipal = null;
                                _selectedPrincipalId = null;
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete Principal'),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: Colors.white38)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAIRMAN TEACHERS VIEW
// ============================================================
class ChairmanTeachersView extends StatelessWidget {
  const ChairmanTeachersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFFFD700)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTeacher()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTeachers = <Map<String, dynamic>>[];
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            for (var t in teachers) {
              allTeachers.add({
                ...t,
                'class': data['name'] ?? 'Class',
                'department': data['department'] ?? '',
              });
            }
          }

          if (allTeachers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No teachers found', style: TextStyle(color: Colors.white60)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allTeachers.length,
            itemBuilder: (ctx, index) {
              final t = allTeachers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C3BFF),
                    child: Text(
                      (t['name'] ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(t['name'] ?? 'Teacher', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${t['email'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                      Text('Teacher ID: ${t['teacherId'] ?? 'N/A'}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('Class: ${t['class'] ?? ''}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () {
                          // Edit teacher - show dialog
                          _showEditTeacherDialog(context, t);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Teacher'),
                              content: Text('Are you sure you want to delete "${t['name']}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance.collection('users').doc(t['id']).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Teacher deleted'), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditTeacherDialog(BuildContext context, Map<String, dynamic> teacher) {
    final nameController = TextEditingController(text: teacher['name']);
    final phoneController = TextEditingController(text: teacher['phoneNumber'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
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
              try {
                await FirebaseFirestore.instance.collection('users').doc(teacher['id']).update({
                  'name': nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher updated'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAIRMAN STUDENTS VIEW
// ============================================================
class ChairmanStudentsView extends StatelessWidget {
  const ChairmanStudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Students'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFFFD700)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStudent(initialClassId: null)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStudents = <Map<String, dynamic>>[];
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            for (var s in students) {
              allStudents.add({
                ...s,
                'class': data['name'] ?? 'Class',
                'department': data['department'] ?? '',
              });
            }
          }

          if (allStudents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No students found', style: TextStyle(color: Colors.white60)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allStudents.length,
            itemBuilder: (ctx, index) {
              final s = allStudents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      (s['name'] ?? 'S')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(s['name'] ?? 'Student', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Roll: ${s['rollNumber'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                      Text('Class: ${s['class'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// CHAIRMAN ATTENDANCE VIEW
// ============================================================
class ChairmanAttendanceView extends StatelessWidget {
  const ChairmanAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          int total = 0;
          int present = 0;

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            for (var s in students) {
              total++;
              final att = s['attendance'] as Map? ?? {};
              if (att[today] == true) present++;
            }
          }

          final absent = total - present;
          final presentPercent = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0';
          final absentPercent = total > 0 ? (absent / total * 100).toStringAsFixed(1) : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Attendance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statCard('Present', present, Colors.green, '$presentPercent%'),
                    ),
                    Expanded(
                      child: _statCard('Absent', absent, Colors.red, '$absentPercent%'),
                    ),
                    Expanded(
                      child: _statCard('Total', total, Colors.blue, ''),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: present.toDouble(),
                          title: 'Present\n$presentPercent%',
                          color: Colors.green,
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: absent.toDouble(),
                          title: 'Absent\n$absentPercent%',
                          color: Colors.red,
                          radius: 40,
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, String percent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(color: Colors.white60)),
            if (percent.isNotEmpty)
              Text(percent, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAIRMAN PAYMENTS VIEW
// ============================================================
class ChairmanPaymentsView extends StatelessWidget {
  const ChairmanPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          int totalPaid = 0;
          int totalPending = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['paymentStatus'] ?? 'pending';
            final amount = data['paymentAmount'] ?? 8000;
            if (status == 'paid') {
              totalPaid += amount as int;
            } else {
              totalPending += amount as int;
            }
          }

          final totalFees = totalPaid + totalPending;
          final paidPercent = totalFees > 0 ? (totalPaid / totalFees * 100).toStringAsFixed(1) : '0';
          final pendingPercent = totalFees > 0 ? (totalPending / totalFees * 100).toStringAsFixed(1) : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _paymentCard('Total Paid', '₹$totalPaid', Colors.green),
                    ),
                    Expanded(
                      child: _paymentCard('Total Pending', '₹$totalPending', Colors.orange),
                    ),
                    Expanded(
                      child: _paymentCard('Total Colleges', '${docs.length}', Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalPaid.toDouble(),
                          title: 'Paid\n$paidPercent%',
                          color: Colors.green,
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: totalPending.toDouble(),
                          title: 'Pending\n$pendingPercent%',
                          color: Colors.orange,
                          radius: 40,
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _paymentCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHAIRMAN FEE ANALYTICS VIEW
// ============================================================
class ChairmanFeeAnalyticsView extends StatelessWidget {
  const ChairmanFeeAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Analytics'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          int totalPaid = 0;
          int totalPending = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['paymentStatus'] ?? 'pending';
            final amount = data['paymentAmount'] ?? 8000;
            if (status == 'paid') {
              totalPaid += amount as int;
            } else {
              totalPending += amount as int;
            }
          }

          final totalFees = totalPaid + totalPending;
          final collectionPercent = totalFees > 0 ? (totalPaid / totalFees * 100).toStringAsFixed(1) : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Analytics Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Revenue: ₹$totalFees',
                  style: TextStyle(fontSize: 16, color: const Color(0xFFFFD700)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _analyticsCard('Collected', '₹$totalPaid', Colors.green),
                    ),
                    Expanded(
                      child: _analyticsCard('Pending', '₹$totalPending', Colors.orange),
                    ),
                    Expanded(
                      child: _analyticsCard('Collection', '$collectionPercent%', Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collection Efficiency',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalFees > 0 ? totalPaid / totalFees : 0,
                          backgroundColor: Colors.orange,
                          color: Colors.green,
                          minHeight: 12,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$collectionPercent% Collected',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _analyticsCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COURSE SELECTION SCREEN
// ============================================================
// ============================================================
// ADD COLLEGE – STEP 2 (DEPARTMENTS & SUBJECTS)
// ============================================================
class AddCollegeStep2 extends StatefulWidget {
  final Map<String, dynamic> collegeData;
  const AddCollegeStep2({super.key, required this.collegeData});

  @override
  State<AddCollegeStep2> createState() => _AddCollegeStep2State();
}

class _AddCollegeStep2State extends State<AddCollegeStep2> {
  // Selected category
  String _selectedCategory = 'Arts & Science';

  // Selected departments (stores department names and their subjects)
  Map<String, List<String>> _selectedDepartments = {};

  // Custom department input
  final TextEditingController _customDeptController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  // For editing a department's subjects
  String? _editingDept;
  List<String> _tempSubjects = [];

  @override
  Widget build(BuildContext context) {
    final List<String> categories = CollegeDataUtils.getCategories();
    final List<String> availableDepts = CollegeDataUtils.getDepartments(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Departments & Subjects'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _selectedDepartments.isEmpty
                ? null
                : () {
                    // Save and go to next
                    final collegeData = {
                      ...widget.collegeData,
                      'departments': _selectedDepartments.entries.map((entry) {
                        return {
                          'name': entry.key,
                          'subjects': entry.value,
                        };
                      }).toList(),
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationAddPrincipalScreen(collegeData: collegeData),
                      ),
                    );
                  },
            child: const Text('Next →', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            // If switching to "Other", clear selected departments (they will be added manually)
                            if (category == 'Other') {
                              // Keep existing custom depts
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Department Selection
            if (_selectedCategory != 'Other') ...[
              const Text(
                'Select Departments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableDepts.map((dept) {
                  final isSelected = _selectedDepartments.containsKey(dept);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          // Remove department
                          _selectedDepartments.remove(dept);
                        } else {
                          // Add department with its predefined subjects
                          final subjects = CollegeDataUtils.getSubjects(_selectedCategory, dept);
                          _selectedDepartments[dept] = subjects.isNotEmpty ? subjects : [];
                          // Open subject editor after adding
                          _editingDept = dept;
                          _tempSubjects = List.from(_selectedDepartments[dept]!);
                          _showSubjectEditor();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C3BFF).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C3BFF) : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dept,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Custom Department (for "Other" or adding custom)
            const Text(
              'Add Custom Department',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customDeptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_customDeptController.text.trim().isEmpty) return;
                    final dept = _customDeptController.text.trim();
                    setState(() {
                      _selectedDepartments[dept] = [];
                      _customDeptController.clear();
                      // Open subject editor
                      _editingDept = dept;
                      _tempSubjects = [];
                      _showSubjectEditor();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Departments List with Subjects
            if (_selectedDepartments.isNotEmpty) ...[
              const Text(
                'Selected Departments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              ..._selectedDepartments.entries.map((entry) {
                final dept = entry.key;
                final subjects = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Color(0xFFFFD700)),
                    title: Text(dept, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${subjects.length} subjects',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _editingDept = dept;
                              _tempSubjects = List.from(subjects);
                              _showSubjectEditor();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedDepartments.remove(dept);
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // Show subjects in a dialog
                      _showSubjectsDialog(dept, subjects);
                    },
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Show Subject Editor Dialog
  void _showSubjectEditor() {
    if (_editingDept == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Subjects for ${_editingDept!}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pre-defined subjects (if any for this dept)
                  if (_tempSubjects.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tempSubjects.map((sub) {
                        return Chip(
                          label: Text(sub),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setStateModal(() {
                              _tempSubjects.remove(sub);
                            });
                          },
                          backgroundColor: const Color(0xFF6C3BFF).withValues(alpha: 0.2),
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Add Subject',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _addSubjectToTemp(setStateModal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addSubjectToTemp(setStateModal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C3BFF),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Save subjects to main list
                        setState(() {
                          if (_editingDept != null) {
                            _selectedDepartments[_editingDept!] = List.from(_tempSubjects);
                          }
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3BFF),
                      ),
                      child: const Text('Save Subjects'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSubjectToTemp(StateSetter setStateModal) {
    if (_subjectController.text.trim().isEmpty) return;
    setStateModal(() {
      _tempSubjects.add(_subjectController.text.trim());
      _subjectController.clear();
    });
  }

  // Show subjects in a dialog
  void _showSubjectsDialog(String dept, List<String> subjects) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dept, style: const TextStyle(color: Colors.white)),
        content: subjects.isEmpty
            ? const Text('No subjects added yet.', style: TextStyle(color: Colors.white60))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((sub) => Chip(label: Text(sub))).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }
}

// ============================================================
// REGISTRATION ADD PRINCIPAL SCREEN
// ============================================================
class RegistrationAddPrincipalScreen extends StatefulWidget {
  final Map<String, dynamic> collegeData;
  const RegistrationAddPrincipalScreen({super.key, required this.collegeData});

  @override
  State<RegistrationAddPrincipalScreen> createState() => _RegistrationAddPrincipalScreenState();
}

class _RegistrationAddPrincipalScreenState extends State<RegistrationAddPrincipalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _qualification = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String _photoBase64 = '';
  String _resumeBase64 = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 50);
    setState(() => _photoBase64 = base64Encode(compressed));
  }

  Future<void> _pickResume() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 800,
      imageQuality: 50,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 40);
    setState(() => _resumeBase64 = base64Encode(compressed));
  }

  Future<void> _addPrincipal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = userCredential.user!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'role': 'principal',
        'photo': _photoBase64,
        'resume': _resumeBase64,
        'qualification': _qualification.text.trim(),
        'mobile': _mobile.text.trim(),
        'collegeDomain': widget.collegeData['domain'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save college data to Firestore
      final collegeRef = await FirebaseFirestore.instance.collection('colleges').add({
        ...widget.collegeData,
        'principalAdded': true,
        'principalEmail': _email.text.trim(),
        'principalId': user.uid,
        'principalName': _name.text.trim(),
        'status': 'pending',
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chairman user doc with the new collegeId if needed
      await FirebaseFirestore.instance.collection('users').doc(widget.collegeData['chairmanId']).update({
        'collegeId': collegeRef.id,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already in use.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'Step 3 of 3',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Principal',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Principal will get official college email',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickPhoto,
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: _photoBase64.isNotEmpty
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        base64Decode(_photoBase64),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.camera_alt, color: Colors.white60),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Photo',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickResume,
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: _resumeBase64.isNotEmpty
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        base64Decode(_resumeBase64),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.description, color: Colors.white60),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Resume',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildField('Principal Name', _name, Icons.person),
                          _buildField('Qualification', _qualification, Icons.school),
                          _buildField('Mobile Number', _mobile, Icons.phone, keyboard: TextInputType.phone),
                          _buildField(
                            'Official Email',
                            _email,
                            Icons.email,
                            keyboard: TextInputType.emailAddress,
                            hint: 'principal@abc.com',
                          ),
                          _buildField('Password', _password, Icons.lock, obscure: true),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addPrincipal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C3BFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Submit & Proceed to Payment'),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboard = TextInputType.text,
        String? hint,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
        validator: (String? v) => v!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

// ============================================================
// PAYMENT SCREEN
// ============================================================
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  void _simulatePayment() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isProcessing = false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ₹8,000',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C3BFF),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan QR Code with any UPI App',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C3BFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'UPI ID: astra2007@upi.com',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _paymentChip('Google Pay', Icons.credit_card),
                    _paymentChip('PhonePe', Icons.mobile_friendly),
                    _paymentChip('Paytm', Icons.payments),
                    _paymentChip('UPI', Icons.qr_code),
                    _paymentChip('Card', Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _simulatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAYMENT SUCCESS SCREEN
// ============================================================
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  void _sendEmailNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Email notification sent to principal and chairman!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹8,000 Received Successfully',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Email Notification sent',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _sendEmailNotification(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION SCREEN
// ============================================================
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Principal Account Activated',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can now login with your credentials',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Email Notification sent to Chairman & Principal',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Go to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// ============================================================
// PROFILE SCREEN
// ============================================================
class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoUrl;
  String? _name;
  String? _email;
  String? _teacherId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _photoUrl = data['photo'];
        _name = data['name'] ?? 'User';
        _email = data['email'] ?? user.email;
        _teacherId = data['teacherId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty ? MemoryImage(base64Decode(_photoUrl!)) : null,
              child: (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(_name ?? 'Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_email ?? 'Email', style: const TextStyle(color: Colors.white60)),
            if (widget.role == 'Teacher' && _teacherId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Teacher ID: $_teacherId', style: const TextStyle(color: Colors.white70)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile feature coming soon'), backgroundColor: Colors.blue),
                );
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD COLLEGE FLOW - STEP 1
// ============================================================
class AddCollegeStep1 extends StatefulWidget {
  const AddCollegeStep1({super.key});

  @override
  State<AddCollegeStep1> createState() => _AddCollegeStep1State();
}

class _AddCollegeStep1State extends State<AddCollegeStep1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _collegeName = TextEditingController();
  final TextEditingController _chairmanName = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  String _photoBase64 = '';
  bool _isLoading = false;
  String _convertedEmail = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final compressed = img.encodeJpg(image, quality: 50);
    setState(() => _photoBase64 = base64Encode(compressed));
  }

  void _updateConvertedEmail(String value) {
    setState(() {
      if (value.trim().isNotEmpty) {
        _convertedEmail = EmailUtils.toRubyEmail(value);
      } else {
        _convertedEmail = '';
      }
    });
  }

  Future<void> _registerCollege() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chairmanEmail = _convertedEmail.isNotEmpty
          ? _convertedEmail
          : EmailUtils.toRubyEmail(_email.text);

      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: chairmanEmail,
        password: _password.text,
      );
      final user = userCredential.user!;

      final domainName = _collegeName.text.trim().toLowerCase().replaceAll(' ', '');
      final domain = domainName.length > 3 ? domainName.substring(0, 3) : domainName;

      final collegeData = {
        'name': _collegeName.text.trim(),
        'chairman': _chairmanName.text.trim(),
        'domain': domain,
        'state': _state.text.trim(),
        'district': _district.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'phone': _mobile.text.trim(),
        'website': _website.text.trim(),
        'email': _email.text.trim(),
        'logo': _photoBase64,
        'chairmanId': user.uid,
        'chairmanEmail': chairmanEmail,
      };

      if (!mounted) return;
      
      // Create Chairman user doc immediately
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _chairmanName.text.trim(),
        'email': chairmanEmail,
        'role': 'chairman',
        'collegeDomain': domain,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCollegeStep2(collegeData: collegeData),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already registered.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Registration'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Logo Upload
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _photoBase64.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(base64Decode(_photoBase64), fit: BoxFit.cover),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.white60, size: 32),
                        SizedBox(height: 4),
                        Text('Upload Logo', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('College Name', _collegeName, Icons.business),
              _buildTextField('Chairman Name', _chairmanName, Icons.person),
              _buildTextField('State', _state, Icons.map),
              _buildTextField('District', _district, Icons.location_city),
              _buildTextField('City', _city, Icons.location_on),
              _buildTextField('Full Address', _address, Icons.home, maxLines: 2),
              _buildTextField('Mobile Number', _mobile, Icons.phone, keyboard: TextInputType.phone),
              _buildTextField('Website', _website, Icons.language),
              // Email Field - Fixed duplicate issue
              TextFormField(
                controller: _email,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                onChanged: _updateConvertedEmail,
                decoration: InputDecoration(
                  labelText: 'Chairman Email',
                  hintText: 'you@gmail.com (auto → @ruby.edu)',
                  prefixIcon: const Icon(Icons.email, color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  helperText: _convertedEmail.isNotEmpty
                      ? '✅ Login Email: $_convertedEmail'
                      : 'Enter email → auto-converted to @ruby.edu',
                  helperStyle: TextStyle(
                    color: _convertedEmail.isNotEmpty ? Colors.green : Colors.white38,
                    fontSize: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField('Password', _password, Icons.lock, obscure: true),
              _buildTextField('Confirm Password', _confirmPassword, Icons.lock_outline, obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerCollege,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register College & Pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
        validator: (String? v) => v!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

// ============================================================
// EDIT COLLEGE SCREEN
// ============================================================
class EditCollegeScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> collegeData;

  const EditCollegeScreen({super.key, required this.docId, required this.collegeData});

  @override
  State<EditCollegeScreen> createState() => _EditCollegeScreenState();
}

class _EditCollegeScreenState extends State<EditCollegeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _domainController;
  late TextEditingController _chairmanController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  final TextEditingController _customDeptController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  bool _isLoading = false;
  String _selectedStatus = 'pending';
  String _selectedPaymentStatus = 'pending';

  Map<String, List<String>> _selectedDepartments = {};
  String? _editingDept;
  List<String> _tempSubjects = [];
  String _selectedCategory = 'Arts & Science';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collegeData['name'] ?? '');
    _domainController = TextEditingController(text: widget.collegeData['domain'] ?? '');
    _chairmanController = TextEditingController(text: widget.collegeData['chairman'] ?? '');
    _districtController = TextEditingController(text: widget.collegeData['district'] ?? '');
    _cityController = TextEditingController(text: widget.collegeData['city'] ?? '');
    _stateController = TextEditingController(text: widget.collegeData['state'] ?? '');
    _addressController = TextEditingController(text: widget.collegeData['address'] ?? '');
    _phoneController = TextEditingController(text: widget.collegeData['phone'] ?? '');
    _emailController = TextEditingController(text: widget.collegeData['email'] ?? '');
    _websiteController = TextEditingController(text: widget.collegeData['website'] ?? '');
    _selectedStatus = widget.collegeData['status'] ?? 'pending';
    _selectedPaymentStatus = widget.collegeData['paymentStatus'] ?? 'pending';

    // Load existing departments
    final existingDepts = widget.collegeData['departments'] as List? ?? [];
    for (var d in existingDepts) {
      if (d is Map) {
        final name = d['name'] as String?;
        final subs = (d['subjects'] as List?)?.map((e) => e.toString()).toList();
        if (name != null) {
          _selectedDepartments[name] = subs ?? [];
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    _chairmanController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _customDeptController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('colleges').doc(widget.docId).update({
        'name': _nameController.text.trim(),
        'domain': _domainController.text.trim().toLowerCase(),
        'chairman': _chairmanController.text.trim(),
        'district': _districtController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'status': _selectedStatus,
        'paymentStatus': _selectedPaymentStatus,
        'departments': _selectedDepartments.entries.map((entry) {
          return {
            'name': entry.key,
            'subjects': entry.value,
          };
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('College updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit College'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField('College Name', _nameController, Icons.business),
              _buildField('Domain', _domainController, Icons.link),
              _buildField('Chairman', _chairmanController, Icons.person),
              _buildField('District', _districtController, Icons.location_on),
              _buildField('City', _cityController, Icons.location_city),
              _buildField('State', _stateController, Icons.map),
              _buildField('Address', _addressController, Icons.home, maxLines: 2),
              _buildField('Phone', _phoneController, Icons.phone, keyboard: TextInputType.phone),
              _buildField('Email', _emailController, Icons.email, keyboard: TextInputType.emailAddress),
              _buildField('Website', _websiteController, Icons.language),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (value) => setState(() => _selectedPaymentStatus = value!),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const Text(
                'Departments & Subjects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 12),
              // Reusing logic from AddCollegeStep2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CollegeDataUtils.getCategories().map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.white24),
                            ),
                            child: Text(category, style: TextStyle(color: isSelected ? const Color(0xFFFFD700) : Colors.white70, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedCategory != 'Other') ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CollegeDataUtils.getDepartments(_selectedCategory).map((dept) {
                    final isSelected = _selectedDepartments.containsKey(dept);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDepartments.remove(dept);
                          } else {
                            final subjects = CollegeDataUtils.getSubjects(_selectedCategory, dept);
                            _selectedDepartments[dept] = List.from(subjects);
                            _editingDept = dept;
                            _tempSubjects = List.from(subjects);
                            _showSubjectEditor();
                          }
                        });
                      },
                      child: Chip(
                        label: Text(dept, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isSelected ? const Color(0xFF6C3BFF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: isSelected ? const Color(0xFF6C3BFF) : Colors.white24),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customDeptController,
                      decoration: const InputDecoration(labelText: 'Custom Dept', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_customDeptController.text.trim().isEmpty) return;
                      final dept = _customDeptController.text.trim();
                      setState(() {
                        _selectedDepartments[dept] = [];
                        _customDeptController.clear();
                        _editingDept = dept;
                        _tempSubjects = [];
                        _showSubjectEditor();
                      });
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12), shape: const CircleBorder()),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._selectedDepartments.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${entry.value.length} subjects', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () {
                            setState(() {
                              _editingDept = entry.key;
                              _tempSubjects = List.from(entry.value);
                              _showSubjectEditor();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => setState(() => _selectedDepartments.remove(entry.key)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectEditor() {
    if (_editingDept == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Edit Subjects for $_editingDept', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tempSubjects.map((sub) {
                      return Chip(
                        label: Text(sub, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setStateModal(() => _tempSubjects.remove(sub)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          decoration: const InputDecoration(labelText: 'Add Subject'),
                          onSubmitted: (v) => _addSubjectToTemp(setStateModal),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => _addSubjectToTemp(setStateModal)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedDepartments[_editingDept!] = List.from(_tempSubjects));
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSubjectToTemp(StateSetter setStateModal) {
    if (_subjectController.text.trim().isEmpty) return;
    setStateModal(() {
      _tempSubjects.add(_subjectController.text.trim());
      _subjectController.clear();
    });
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
        ),
        validator: (String? v) => v!.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

// ============================================================
// PRINCIPAL MESSAGING
// ============================================================
class PrincipalMessaging extends StatefulWidget {
  const PrincipalMessaging({super.key});

  @override
  State<PrincipalMessaging> createState() => _PrincipalMessagingState();
}

class _PrincipalMessagingState extends State<PrincipalMessaging> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String _targetRole = 'teachers';

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim().isEmpty ? 'Principal Announcement' : _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'targetRole': _targetRole,
        'sentBy': 'Principal',
        'sentByEmail': FirebaseAuth.instance.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      _titleController.clear();
      _messageController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Message sent!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Message')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Title (Optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _targetRole,
              decoration: const InputDecoration(labelText: 'Send To'),
              items: const [
                DropdownMenuItem(value: 'teachers', child: Text('All Teachers')),
                DropdownMenuItem(value: 'students', child: Text('All Students')),
                DropdownMenuItem(value: 'all', child: Text('Everyone')),
              ],
              onChanged: (v) => setState(() => _targetRole = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Message *',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3BFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Sent Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('sentBy', isEqualTo: 'Principal')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No messages sent', style: TextStyle(color: Colors.white60)));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(data['title'] ?? 'Message', style: const TextStyle(color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                              Text('To: ${data['targetRole']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              if (data['createdAt'] != null)
                                Text(
                                  DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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

// ============================================================
// TEACHER MESSAGING
// ============================================================
class TeacherMessaging extends StatelessWidget {
  const TeacherMessaging({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetRole', whereIn: ['all', 'teachers'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet', style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6C3BFF),
                    child: Icon(Icons.message, color: Colors.white),
                  ),
                  title: Text(data['title'] ?? 'Message', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                      Text('From: ${data['sentBy'] ?? 'Unknown'}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (data['createdAt'] != null)
                        Text(
                          DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// TEACHER ALL CLASSES
// ============================================================
class TeacherAllClasses extends StatelessWidget {
  const TeacherAllClasses({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Classes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
            return teachers.any((t) => t['email'] == user?.email);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No classes assigned', style: TextStyle(color: Colors.white60)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? 'Class', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Department: ${data['department'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                      Text('Students: ${students.length}', style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white60),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
                          classId: docs[index].id,
                          className: data['name'] ?? 'Class',
                          students: students,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// TEACHER ALL MARKS
// ============================================================
class TeacherAllMarks extends StatefulWidget {
  const TeacherAllMarks({super.key});

  @override
  State<TeacherAllMarks> createState() => _TeacherAllMarksState();
}

class _TeacherAllMarksState extends State<TeacherAllMarks> {
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      final classes = snapshot.docs.where((doc) {
        final data = doc.data();
        final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        return teachers.any((t) => t['email'] == user?.email);
      }).toList();

      if (classes.isNotEmpty) {
        _selectedClassId = classes.first.id;
        final data = classes.first.data();
        _students = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _subjects = List<String>.from(data['subjects'] ?? []);
      }
    } catch (e) {
      // Silent
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Marks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                    builder: (ctx, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final user = FirebaseAuth.instance.currentUser;
                      final classes = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final teachers = (data['teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                        return teachers.any((t) => t['email'] == user?.email);
                      }).toList();

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(labelText: 'Select Class'),
                        items: classes.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data['name'] ?? 'Class'),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setState(() => _selectedClassId = val);
                            final data = await FirebaseFirestore.instance.collection('classes').doc(val).get();
                            final d = data.data() as Map<String, dynamic>;
                            setState(() {
                              _students = (d['students'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                              _subjects = List<String>.from(d['subjects'] ?? []);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _students.isEmpty
                      ? const Center(child: Text('No students'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (ctx, index) {
                            final s = _students[index];
                            final marks = (s['marks'] as Map?)?.cast<String, dynamic>() ?? {};
                            return Card(
                              child: ListTile(
                                title: Text(s['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Roll: ${s['rollNumber'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: _subjects.map((sub) {
                                    final mark = marks[sub]?.toString() ?? '-';
                                    return Chip(
                                      label: Text('$sub: $mark', style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.grey.shade800,
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// TEACHER NOTIFICATIONS
// ============================================================
class TeacherNotifications extends StatelessWidget {
  const TeacherNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications', style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6C3BFF),
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(data['title'] ?? 'Notification', style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? '', style: const TextStyle(color: Colors.white60)),
                      if (data['createdAt'] != null)
                        Text(
                          DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate()),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// END OF FILE
// ============================================================
