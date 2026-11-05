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
      await _db
          .collection('attendance_records')
          .doc(dateId)
          .set(attendanceData)
          .timeout(const Duration(seconds: 3));
      print("✅ Attendance saved successfully to Firestore!");
    } catch (e) {
      print("🚨 Network failed or timed out! Saving attendance locally...");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('offline_attendance_$dateId', jsonEncode(attendanceData));
      print("✅ Attendance saved locally. Will sync when online.");
    }
  }

  // NEW: Fetch real-time summary for Admin Dashboard
  Future<Map<String, int>> getTodayAttendanceSummary() async {
    final dateId = DateTime.now().toIso8601String().split('T')[0];
    try {
      DocumentSnapshot doc = await _db.collection('attendance_records').doc(dateId).get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List students = data['students'];
        
        int total = students.length;
        int present = students.where((s) => s['isPresent'] == true).length;
        int absent = students.where((s) => s['isPresent'] == false).length;
        
        return {'total': total, 'present': present, 'absent': absent};
      }
    } catch (e) {
      print("Error fetching summary: $e");
    }
    return {'total': 0, 'present': 0, 'absent': 0}; // Default if no data
  }
}