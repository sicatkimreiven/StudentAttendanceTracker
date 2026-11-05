import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'parent_student_detail.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final String parentId = FirebaseAuth.instance.currentUser!.uid;

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

  // PAGE 1: Home
  Widget _buildHomePage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('enrollments').where('parentId', isEqualTo: parentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var enrollments = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              if (enrollments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 40, color: Colors.blue),
                        const SizedBox(height: 10),
                        const Text('You have no students enrolled yet.', textAlign: TextAlign.center),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () => setState(() => _currentIndex = 1),
                          child: const Text('Enroll a Student'),
                        )
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Enrolled Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...enrollments.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('classes').doc(data['classCode']).get(),
                        builder: (context, classSnapshot) {
                          String sectionName = 'Unknown Section';
                          if (classSnapshot.hasData && classSnapshot.data!.exists) {
                            sectionName = (classSnapshot.data!.data() as Map<String, dynamic>)['className'];
                          }
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: data['gender'] == 'Female' ? Colors.pink[100] : Colors.blue[100],
                                child: Icon(data['gender'] == 'Female' ? Icons.female : Icons.male, 
                                  color: data['gender'] == 'Female' ? Colors.pink : Colors.blue),
                              ),
                              title: Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Section: $sectionName'),
                            ),
                          );
                        }
                      );
                    }).toList(),
                  ],
                )
            ],
          ),
        );
      },
    );
  }

  // PAGE 2: My Students
  Widget _buildMyStudentsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showEnrollDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Enroll New Student'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
                  String classCode = data['classCode'];

                  // Fetch Class details
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
                    builder: (context, classSnapshot) {
                      String sectionName = 'Loading...';
                      String teacherId = '';

                      if (classSnapshot.hasData && classSnapshot.data!.exists) {
                        var classData = classSnapshot.data!.data() as Map<String, dynamic>;
                        sectionName = classData['className'];
                        teacherId = classData['teacherId'];
                      }

                      // Fetch Teacher Name
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(teacherId).get(),
                        builder: (context, teacherSnapshot) {
                          String teacherName = 'Unknown Teacher';
                          if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
                            teacherName = (teacherSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown Teacher';
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: data['gender'] == 'Female' ? Colors.pink[100] : Colors.blue[100],
                                child: Icon(data['gender'] == 'Female' ? Icons.female : Icons.male, 
                                  color: data['gender'] == 'Female' ? Colors.pink : Colors.blue),
                              ),
                              title: Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Section: $sectionName'),
                                  Text('Teacher: $teacherName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditStudentDialog(enrollments[index].id, data['studentName']),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => ParentStudentDetail(
                                    studentName: data['studentName'],
                                    classCode: classCode,
                                  )
                                ));
                              },
                            ),
                          );
                        }
                      );
                    }
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Enroll Dialog with Gender
  void _showEnrollDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    String selectedGender = 'Male';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Enroll Student'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
                const SizedBox(height: 10),
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Class Code')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (val) => setState(() => selectedGender = val!),
                ),
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
                      'gender': selectedGender,
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
          );
        }
      ),
    );
  }

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