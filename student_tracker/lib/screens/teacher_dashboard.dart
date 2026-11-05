import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'teacher_student_detail.dart';
import 'attendance_screen.dart';
import 'profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  String _searchQuery = '';
  bool _sortAscending = true;
  final String teacherId = FirebaseAuth.instance.currentUser!.uid; 

  Future<void> _confirmLogout() async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (result == true && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildHomePage(),
      _buildStudentsPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Sections'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'All Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // PAGE 1: Home
  Widget _buildHomePage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateClassDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create New Section'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('teacherId', isEqualTo: teacherId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var classes = snapshot.data!.docs;
              if (classes.isEmpty) return const Center(child: Text('No sections created yet.'));

              return ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  var data = classes[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.class_, color: Colors.white)),
                      title: Text(data['className'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Tap to view classroom'),
                      // NEW: Edit Button for Section Name
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditClassDialog(classes[index].id, data['className']),
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => AttendanceScreen(classCode: classes[index].id, className: data['className'])
                        ));
                      },
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

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Section'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Section Name (e.g., Grade 5 - A)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              String code = "CLS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
              await FirebaseFirestore.instance.collection('classes').doc(code).set({
                'className': nameController.text.trim(),
                'teacherId': teacherId,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
  }

  // NEW: Edit Class Name Dialog
  void _showEditClassDialog(String classCode, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Section Name'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Section Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('classes').doc(classCode).update({
                'className': nameController.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // PAGE 2: All Students
  Widget _buildStudentsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Search Student', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort),
                onPressed: () => setState(() => _sortAscending = !_sortAscending),
                tooltip: 'Sort A-Z',
              )
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: FirebaseFirestore.instance.collection('classes').where('teacherId', isEqualTo: teacherId).get().then((snapshot) => snapshot.docs.map((doc) => doc.id).toList()),
            builder: (context, classSnapshot) {
              if (!classSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              List<String> myClassCodes = classSnapshot.data!;
              if (myClassCodes.isEmpty) return const Center(child: Text('Create a section first to see students.'));

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('classCode', whereIn: myClassCodes)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var enrollments = snapshot.data!.docs;
                  
                  var filtered = enrollments.where((doc) => (doc['studentName'] as String).toLowerCase().contains(_searchQuery)).toList();
                  filtered.sort((a, b) => _sortAscending 
                      ? (a['studentName'] as String).compareTo(b['studentName']) 
                      : (b['studentName'] as String).compareTo(a['studentName']));

                  if (filtered.isEmpty) return const Center(child: Text('No students found.'));

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      var data = filtered[index].data() as Map<String, dynamic>;
                      String classCode = data['classCode'];
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
                        builder: (context, classSnapshot) {
                          String sectionName = 'Loading...';
                          if (classSnapshot.hasData && classSnapshot.data!.exists) {
                            sectionName = (classSnapshot.data!.data() as Map<String, dynamic>)['className'];
                          }

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.face)),
                              title: Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Section: $sectionName'), 
                              // NEW: Edit Button for Student Name
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditStudentDialog(filtered[index].id, data['studentName']),
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => TeacherStudentDetail(
                                    studentName: data['studentName'],
                                    classCode: classCode,
                                    sectionName: sectionName,
                                  )
                                ));
                              },
                            ),
                          );
                        }
                      );
                    },
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  // NEW: Edit Student Name Dialog
  void _showEditStudentDialog(String enrollmentId, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student Name'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('enrollments').doc(enrollmentId).update({
                'studentName': nameController.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  // PAGE 3: Profile
  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          const Text('Teacher Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          )
        ],
      ),
    );
  }
}