import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _allowTeacherRegistration = true;
  bool _enablePushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('User Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Allow Teacher Registration'),
            subtitle: const Text('If disabled, only Admins can create accounts.'),
            value: _allowTeacherRegistration,
            onChanged: (bool value) {
              setState(() {
                _allowTeacherRegistration = value;
              });
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('System Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Enable Push Notifications'),
            subtitle: const Text('Send alerts to parents when a student is absent.'),
            value: _enablePushNotifications,
            onChanged: (bool value) {
              setState(() {
                _enablePushNotifications = value;
              });
            },
          ),
          const ListTile(
            title: Text('School Name'),
            subtitle: Text('Student Attendance Tracker High School'),
            trailing: Icon(Icons.edit, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}