import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> _fetchStudents() async {
    var snapshot = await FirebaseFirestore.instance.collection('enrollments').where('classCode', isEqualTo: widget.classCode).get();
    students = snapshot.docs.map((doc) => {
      'id': doc.id,
      'name': doc['studentName'],
      'isPresent': true, // Default to present
    }).toList();
    setState(() => _isLoading = false);
  }

  // Optional: Notification trigger
  Future<void> _sendNotification(String studentName) async {
    try {
      QuerySnapshot parentQuery = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').limit(1).get();
      if (parentQuery.docs.isEmpty) return;
      String parentToken = parentQuery.docs.first.get('fcmToken');
      
      await http.post(
        Uri.parse('https://studentattendancetracker-khxi.onrender.com/notify-absence'), // Update IP if needed
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentName': studentName, 'parentToken': parentToken}),
      );
    } catch (e) {
      print("Error calling backend: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Class: ${widget.className}', style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : students.isEmpty 
          ? const Center(child: Text('No students enrolled in this class yet.'))
          : Column(
              children: [
                // Show Join Code here
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    children: [
                      const Text('Share this Join Code with Parents:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      SelectableText(widget.classCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      bool isPresent = students[index]['isPresent'];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Student Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(students[index]['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(isPresent ? 'Present' : 'Absent', 
                                      style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // Clear Present/Absent Buttons
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPresent ? Colors.green : Colors.grey[300],
                                      foregroundColor: isPresent ? Colors.white : Colors.black,
                                    ),
                                    onPressed: () => setState(() => students[index]['isPresent'] = true),
                                    child: const Text('Present'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: !isPresent ? Colors.red : Colors.grey[300],
                                      foregroundColor: !isPresent ? Colors.white : Colors.black,
                                    ),
                                    onPressed: () => setState(() => students[index]['isPresent'] = false),
                                    child: const Text('Absent'),
                                  ),
                                ],
                              )
                            ],
                          ),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () async {
                        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
                        await _dbService.saveAttendance(students);
                        
                        // Trigger notification for absentees
                        for (var student in students) {
                          if (student['isPresent'] == false) {
                            await _sendNotification(student['name']);
                          }
                        }

                        if(context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Saved!')));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit Attendance', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}