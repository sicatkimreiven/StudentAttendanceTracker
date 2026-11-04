import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveAttendance(List<Map<String, dynamic>> students) async {
    final dateId = DateTime.now().toIso8601String().split('T')[0];
    final attendanceData = {
      'date': dateId,
      'students': students,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Try to save to Firebase
      await _db.collection('attendance_records').doc(dateId).set(attendanceData);
      print("Attendance saved successfully to Firestore!");
      
    } catch (e) {
      // If internet fails (Offline Mode), save locally
      print("Network failed! Saving attendance locally...");
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('offline_attendance_$dateId', jsonEncode(attendanceData));
      
      print("Attendance saved locally. Will sync when online.");
    }
  }
}