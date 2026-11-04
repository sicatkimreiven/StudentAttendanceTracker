import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Mock data for students
  final DatabaseService _dbService = DatabaseService();
  final List<Map<String, dynamic>> students = [
    {'id': '1', 'name': 'Juan Dela Cruz', 'isPresent': true},
    {'id': '2', 'name': 'Maria Clara', 'isPresent': false},
    {'id': '3', 'name': 'Jose Rizal', 'isPresent': true},
    {'id': '4', 'name': 'Andres Bonifacio', 'isPresent': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Grade 5 - Section A',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          student['isPresent'] ? Colors.green : Colors.red,
                      child: Text(student['name'][0],
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(student['name']),
                    subtitle: Text(student['isPresent'] ? 'Present' : 'Absent'),
                    trailing: Switch(
                      value: student['isPresent'],
                      activeColor: Colors.green,
                      onChanged: (bool value) {
                        setState(() {
                          students[index]['isPresent'] = value;
                        });
                      },
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
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 1. Show a loading dialog while saving
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  // 2. Call the database service
                  await _dbService.saveAttendance(students);

                  // 3. Close the loading dialog (check if widget is still mounted)
                  if (context.mounted) {
                    Navigator.pop(context);

                    // 4. Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Attendance Saved to Firebase!')),
                    );

                    // 5. Go back to the dashboard
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Submit Attendance',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}