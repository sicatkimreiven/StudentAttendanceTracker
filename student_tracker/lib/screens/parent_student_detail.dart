import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentStudentDetail extends StatelessWidget {
  final String studentName;
  final String classCode;

  const ParentStudentDetail({super.key, required this.studentName, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(studentName), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fetch Section Name dynamically
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
              builder: (context, snapshot) {
                String sectionName = 'Loading...';
                if (snapshot.hasData && snapshot.data!.exists) {
                   sectionName = (snapshot.data!.data() as Map<String, dynamic>)['className'];
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.class_, color: Colors.blue),
                    title: const Text('Assigned Section'),
                    subtitle: Text(sectionName),
                  ),
                );
              }
            ),
            const SizedBox(height: 20),
            const Text('Attendance History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('attendance_records').orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  List<Widget> historyTiles = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    List students = data['students'];
                    
                    var studentRecord = students.firstWhere((s) => s['name'] == studentName, orElse: () => null);
                    
                    if (studentRecord != null) {
                      bool isPresent = studentRecord['isPresent'];
                      historyTiles.add(
                        Card(
                          child: ListTile(
                            leading: Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red),
                            title: Text(isPresent ? 'Present' : 'Absent', style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${data['date'] ?? 'Unknown'}'),
                          ),
                        ),
                      );
                    }
                  }
                  
                  if (historyTiles.isEmpty) return const Center(child: Text('No attendance records found.'));
                  return ListView(children: historyTiles);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}