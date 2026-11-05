import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Get the device token
    String? token = await _fcm.getToken();
    print("FCM Token: $token");

    // 3. Save token to Firestore for the current user
    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'role': 'parent',
        }, SetOptions(merge: true));
      }
    }

    // 4. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📬 Foreground message: ${message.notification?.title}");
    });
  }
}