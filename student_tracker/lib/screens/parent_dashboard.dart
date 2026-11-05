import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final String parentId = FirebaseAuth.instance.currentUser!.uid;

  // Logout confirmation
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
    if (result == true) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildHomePage(),
      _buildMyStudentsPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Parent Portal'),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'My Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // 1. Home Page
  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back, Parent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),
                  const Text('Enroll a new student using the code provided by your teacher.', textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text('Go to Enrollment'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. My Students Page (Enrollment + History)
  Widget _buildMyStudentsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: _buildEnrollDialogTrigger()),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('enrollments').where('parentId', isEqualTo: parentId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var enrollments = snapshot.data!.docs;
              if (enrollments.isEmpty) return const Center(child: Text('No students enrolled yet.'));

              return ListView.builder(
                itemCount: enrollments.length,
                itemBuilder: (context, index) {
                  var data = enrollments[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.face)),
                      title: Text(data['studentName']),
                      subtitle: Text('Class Code: ${data['classCode']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Open Attendance History Modal
                        _showAttendanceHistory(data['studentName']);
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

  Widget _buildEnrollDialogTrigger() {
    return ElevatedButton.icon(
      onPressed: () => _showEnrollDialog(),
      icon: const Icon(Icons.add),
      label: const Text('Enroll New Student'),
    );
  }

  void _showEnrollDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Class Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              String code = codeController.text.trim();
              if (code.isEmpty || nameController.text.isEmpty) return;

              var classDoc = await FirebaseFirestore.instance.collection('classes').doc(code).get();
              if (classDoc.exists) {
                await FirebaseFirestore.instance.collection('enrollments').add({
                  'classCode': code,
                  'studentName': nameController.text.trim(),
                  'parentId': parentId,
                  'enrolledAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Code')));
              }
            },
            child: const Text('Enroll'),
          )
        ],
      ),
    );
  }

  // 3. Attendance History Modal (The new feature)
  void _showAttendanceHistory(String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance History: $studentName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Showing all past records from the teacher.'),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('attendance_records').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    List<Widget> historyTiles = [];
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      List students = data['students'];
                      
                      // Check if this student is in this record
                      var studentRecord = students.firstWhere((s) => s['name'] == studentName, orElse: () => null);
                      
                      if (studentRecord != null) {
                        bool isPresent = studentRecord['isPresent'];
                        historyTiles.add(
                          ListTile(
                            leading: Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red),
                            title: Text(isPresent ? 'Present' : 'Absent'),
                            subtitle: Text(data['date'] ?? 'Unknown Date'),
                          ),
                        );
                      }
                    }
                    
                    if (historyTiles.isEmpty) return const Center(child: Text('No attendance records found yet.'));
                    return ListView(children: historyTiles);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Profile Page
  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          const Text('Parent Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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