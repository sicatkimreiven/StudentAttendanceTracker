import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'attendance_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _classCode;
  String _className = '';

  // Function to create a new class and generate a code
  Future<void> _createClass() async {
    String code = "CLS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    String teacherId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('classes').doc(code).set({
      'className': 'Grade 5 - Section A', 
      'teacherId': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _classCode = code;
      _className = 'Grade 5 - Section A';
    });
  }

  // Function to unenroll a student
  Future<void> _unenrollStudent(String enrollmentId) async {
    await FirebaseFirestore.instance.collection('enrollments').doc(enrollmentId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Removed')));
    }
  }

  // Logout Confirmation Prompt
  Future<void> _confirmLogout() async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Logout', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout, // CALLS THE CONFIRMATION FUNCTION NOW
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _classCode == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.class_, size: 80, color: Colors.blue),
                    const SizedBox(height: 20),
                    const Text('You have not created a class yet.', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _createClass,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Class & Get Code'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class: $_className', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Text('Join Code: ', style: TextStyle(fontSize: 18)),
                        Text(_classCode!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Enrolled Students:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('enrollments').where('classCode', isEqualTo: _classCode).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        var enrollments = snapshot.data!.docs;
                        if (enrollments.isEmpty) return const Text('No students enrolled yet. Share the code!');
                        
                        return ListView.builder(
                          itemCount: enrollments.length,
                          itemBuilder: (context, index) {
                            var data = enrollments[index].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(data['studentName']),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _unenrollStudent(enrollments[index].id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen(classCode: _classCode!, className: _className)));
                      },
                      icon: const Icon(Icons.checklist),
                      label: const Text('Mark Attendance for this Class'),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}