import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Students', '40', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard('Present', '35', Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard('Absent', '5', Colors.red),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Recent Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Mock list of reports
            Expanded(
              child: ListView(
                children: [
                  _buildReportTile('Grade 5 - Section A', '35/40 Present', Colors.green),
                  _buildReportTile('Grade 6 - Section B', '38/42 Present', Colors.green),
                  _buildReportTile('Grade 4 - Section C', '30/35 Present', Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
      // Logout Button is now correctly at the end of the Scaffold
            floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        },
        child: const Icon(Icons.logout),
      ),
    );
  }

  // Helper widget for the top summary cards
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Helper widget for the list items
  Widget _buildReportTile(String title, String subtitle, Color iconColor) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.assignment, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // We will make this navigate to a detailed view later
        },
      ),
    );
  }
}