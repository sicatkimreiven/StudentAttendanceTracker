import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String classCode;
  final String className;

  const AttendanceScreen({super.key, required this.classCode, required this.className});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // Fetch students enrolled in this class
  Future<void> _fetchStudents() async {
    var snapshot = await FirebaseFirestore.instance.collection('enrollments').where('classCode', isEqualTo: widget.classCode).get();
    students = snapshot.docs.map((doc) => {
      'id': doc.id,
      'name': doc['studentName'],
      'isPresent': true, // Default to present
    }).toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance: ${widget.className}')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : students.isEmpty 
          ? const Center(child: Text('No students enrolled in this class yet.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: SwitchListTile(
                          title: Text(students[index]['name']),
                          value: students[index]['isPresent'],
                          onChanged: (bool value) {
                            setState(() {
                              students[index]['isPresent'] = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Save to Firestore using the service
                        await _dbService.saveAttendance(students);
                        if(context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Submit Attendance'),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}