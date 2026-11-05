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
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  // Function to enroll student
  Future<void> _enrollStudent() async {
    String code = _codeController.text.trim();
    String name = _nameController.text.trim();
    String parentId = FirebaseAuth.instance.currentUser!.uid;

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Check if the class code exists
    var classDoc = await FirebaseFirestore.instance.collection('classes').doc(code).get();
    if (!classDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Class Code!')));
      return;
    }

    // Add enrollment
    await FirebaseFirestore.instance.collection('enrollments').add({
      'classCode': code,
      'studentName': name,
      'parentId': parentId,
      'enrolledAt': FieldValue.serverTimestamp(),
    });

    _codeController.clear();
    _nameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Enrolled!')));
  }

  @override
  Widget build(BuildContext context) {
    String parentId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Portal'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enroll a Student', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Class Code (from Teacher)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _enrollStudent, child: const Text('Enroll')),
            const Divider(height: 40),
            const Text('My Enrolled Students', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('enrollments').where('parentId', isEqualTo: parentId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var enrollments = snapshot.data!.docs;
                if (enrollments.isEmpty) return const Text('No students enrolled yet.');

                return Column(
                  children: enrollments.map((doc) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.face),
                        title: Text(doc['studentName']),
                        subtitle: Text('Class: ${doc['classCode']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('enrollments').doc(doc.id).delete();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}