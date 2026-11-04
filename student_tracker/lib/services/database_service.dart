import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveAttendance(List<Map<String, dynamic>> students) async {
    try {
      final dateId = DateTime.now().toIso8601String().split('T')[0]; 
      
      await _db.collection('attendance_records').doc(dateId).set({
        'date': dateId,
        'timestamp': FieldValue.serverTimestamp(),
        'students': students, 
      });
      
      // Check if there are absent students (for the notification requirement)
      bool hasAbsentees = students.any((student) => student['isPresent'] == false);
      
      if (hasAbsentees) {
        print("Absentees found! Ready to trigger push notification to parents.");
        // In a real app, your Node.js backend would listen to this Firestore collection 
        // and automatically send the push notification via Firebase Cloud Messaging.
      } else {
        print("All students present today.");
      }
      
      print("Attendance saved successfully to Firestore!");
    } catch (e) {
      print("Error saving attendance: $e");
    }
  }
}