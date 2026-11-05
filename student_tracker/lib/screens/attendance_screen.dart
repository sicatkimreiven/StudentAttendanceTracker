import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  final List<Map<String, dynamic>> students = [
    {'id': '1', 'name': 'Maya Chen', 'rollNo': '01', 'isPresent': true},
    {'id': '2', 'name': 'Noah Williams', 'rollNo': '02', 'isPresent': true},
    {'id': '3', 'name': 'Olivia Patel', 'rollNo': '03', 'isPresent': true},
    {'id': '4', 'name': 'Ethan Brooks', 'rollNo': '04', 'isPresent': false},
    {'id': '5', 'name': 'Ava Thompson', 'rollNo': '05', 'isPresent': true},
    {'id': '6', 'name': 'Liam Garcia', 'rollNo': '06', 'isPresent': true},
  ];

  Future<void> _sendNotification(String studentName) async { /* Keep previous code */ }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light background from Figma
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grade 4 • Section A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text('5 Nov 2026 • Morning session', style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Icon(Icons.calendar_today, color: Colors.blue[400], size: 20),
                  ],
                ),
              ],
            ),
          ),
          // Summary bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('6 students', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('5 Present', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
                Text('1 Absent', style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                bool isPresent = student['isPresent'];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Text(
                        student['name'].toString().split(' ').map((e) => e[0]).join(),
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Roll no. ${student['rollNo']}', style: const TextStyle(color: Colors.grey)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Switch.adaptive(
                          value: isPresent,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (bool value) {
                            setState(() {
                              students[index]['isPresent'] = value;
                            });
                          },
                        ),
                        Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Submit logic here
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Submit Attendance', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}